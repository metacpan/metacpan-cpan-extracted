package MHA::AWS;

use 5.008001;
use strict;
use warnings;
use Log::Minimal;
use AWS::CLIWrapper;
use Time::HiRes qw/ sleep /;
use Scalar::Util qw/ blessed /;
use Moo;

our $VERSION             = "0.05";
our $API_APPLIED_TIMEOUT = 120;
our $CHECK_INTERVAL      = 5;

has host             => ( is => "rw" );
has orig_master_host => ( is => "rw" );
has new_master_host  => ( is => "rw" );
has attachment_id    => ( is => "rw" );
has vip              => ( is => "rw" );
has ssh_user         => ( is => "rw" );
has instance_ids     => ( is => "rw", default => sub { +{} } );
has interface_id     => ( is => "rw" );
has failover_method  => ( is => "rw", required => 1 );
has route_table_id   => ( is => "rw" );
has aws => (
    is      => "rw",
    default => sub {
        AWS::CLIWrapper->new();
    },
);
has current_attached_instance_id => ( is => "rw" );

sub _init_eni {
    my $self = shift;
    my $res;
    $res = $self->ec2("describe-network-interfaces", {
        network_interface_ids => $self->interface_id,
    });
    my $interface = $res->{NetworkInterfaces}->[0];
    unless ($interface) {
        critf "Can't find network interface: %s", $self->interface_id;
        die;
    }

    $self->attachment_id( $interface->{Attachment}->{AttachmentId} );
    $self->current_attached_instance_id( $interface->{Attachment}->{InstanceId} );
    $self->vip( $interface->{PrivateIpAddress} );
}

sub _init_route_table {
    my $self = shift;
    my $res;
    my $destination_cidr_block = sprintf("%s/32", $self->vip);
    $res = $self->ec2("describe-route-tables", {
        route_table_id => $self->route_table_id,
    });
    if ( !$res->{RouteTables}->[0] ) {
        critf "Can't find route_table: %s", $self->route_table_id;
        die;
    }
    for my $route (@{ $res->{RouteTables}->[0]->{Routes} }) {
        if ($route->{DestinationCidrBlock} eq $destination_cidr_block) {
            $self->current_attached_instance_id($route->{InstanceId});
            return 1;
        }
    }
}

sub init {
    my $self = shift;

    if ($self->failover_method eq "eni") {
        $self->_init_eni;
    }
    else {
        $self->_init_route_table;
    }

    # create mapping table (hostname => instance-id) from tags
    my $res = $self->ec2("describe-tags");
    for my $tag (@{ $res->{Tags} }) {
        if ($tag->{ResourceType} eq "instance" && $tag->{Key} eq "Name") {
            $self->instance_ids->{ $tag->{Value} } = $tag->{ResourceId};
        }
    }

    if ( $self->new_master_host && !$self->new_master_instance_id ) {
        critf "Can't detect new_master_instance_id. abort";
        die;
    }
    if ( $self->orig_master_host && !$self->orig_master_instance_id ) {
        critf "Can't detect orig_master_instance_id. abort";
        die;
    }
}

sub ec2 {
    my $self = shift;
    my ($command, $args) = @_;
    infof "aws ec2 %s %s", $command, defined($args) ? ddf $args : "";
    my $res = $self->aws->ec2($command, $args);
    if ($res) {
        debugf "result: %s", ddf $res;
    }
    else {
        critf "failed";
        die;
    }
    $res;
}

sub ping {
    my $self    = shift;
    my $ip_addr = shift;
    system(qw/ timeout 3 ping -c 1 -t 3 /, $ip_addr) == 0 ? 1 : 0;
}

sub host_instance_id {
    my $self = shift;
    $self->instance_ids->{ $self->host };
}

sub new_master_instance_id {
    my $self = shift;
    $self->instance_ids->{ $self->new_master_host };
}

sub orig_master_instance_id {
    my $self = shift;
    $self->instance_ids->{ $self->orig_master_host };
}

sub dispatch {
    my $self    = shift;
    my $command = shift;
    if ( my $method = $self->can("_command_${command}") ) {
        infof "Invoke command: %s::%s", ref $self, $command;
        my $success = $method->($self);
        if ($success) {
            infof "Complete!";
        }
        else {
            infof "Failed!";
            die;
        }
    }
    else {
        critf("Unknown command: %s", $command);
        die;
    }
}

sub info {
    my $self = shift;
    my $info = {};
    for my $key (sort keys %$self) {
        next if Scalar::Util::blessed($self->{$key});
        $info->{$key} = $self->{$key};
    }
    $info;
}

1;
__END__

=encoding utf-8

=head1 NAME

MHA::AWS - A support script for "MySQL Master HA" running on AWS

=head1 SYNOPSIS

    $ mhaws [subcommand] --interface_id=ENI-id [... args passed by MHA]
    $ mhaws [subcommand] --route_table_id=[RouteTable-id] --vip=[master VIP] [... args passed by MHA]

    required arguments:
      1. failover method is ENI attach/detach
        --interface_id=[ENI-id for master VIP]

      2. failover method is RouteTable change destination
        --route_table_id=[RouteTable-id]
        --vip=[master VIP]

    subcommand:
      master_ip_failover
      master_ip_online_change
      shutdown


    /etc/masterha_default.cnf

    [server default]
    master_ip_failover_script=mhaws master_ip_failover --interface_id=eni-xxxxxxxx
    master_ip_online_change_script=mhaws master_ip_online_change --interface_id=eni-xxxxxxxx
    shutdown_script=mhaws shutdown --interface_id=eni-xxxxxxxx

=head1 DESCRIPTION

MHA::AWS is a support script for "MySQL Master HA" which running on Amazon Web Service.

=head1 REQUIREMENTS

=over 4

=item * EC2 instance's "Name" tags must be resolved as DNS name in internal.

=item * root user must be allowed to ssh login between each MySQL instances.

=item * aws-cli is installed and available.

=back

=head2 Failover method = ENI attach/detach

=over 4

=item * One ENI (Elastic Network Interface) must be attached to the MySQL master instance. Clients accesses for the ENI's IP address.

=back

=head2 Failover method = VPC route table rewriting

=over 4

=item * Prepare a VIP address in your VPC.

=item * All MySQL hosts(master, slaves) can handle the VIP.

=item * Clients accesses for the VIP address.

=back

=head1 FAILOVER FLOW

=over 4

=item 1 MHA detect master failure.

=item 2 "mhaws master_ip_failover --command stop", ENI will be detached from the old master instance.

=over 8

=item * (ENI) ENI will be detached from the old master instance.

=item * (Route table) Route to VIP will be removed from VPC route table.

=back

=item 3 "mhaws shutdown --command (stopssh|stop)", Old master mysqld process will be killed (if ssh connection is available). Or old master instance will be stopped via AWS API (if ssh connection is NOT available).

=item 4 MHA will elect the new master and set up replication.

=item 5 "mhaws master_ip_failver --command start", ENI will be attached to the new master instance.

=over 8

=item * (ENI) ENI will be attached to the new master instance.

=item * (Route table) Route to VIP will be set to new master instance.

=back

=back

=head1 SEE ALSO

L<AWS::CLIWrapper>, L<https://code.google.com/p/mysql-master-ha/>

=head1 LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

FUJIWARA Shunichiro E<lt>fujiwara.shunichiro@gmail.comE<gt>

=cut

