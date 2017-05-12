package MHA::AWS::MasterIpFailover;

use strict;
use warnings;
use parent "MHA::AWS";
use Log::Minimal;

sub _command_stopssh {
    my $self = shift;
    $self->_command_stop;
}

sub _command_stop {
    my $self = shift;
    if ($self->failover_method eq "eni") {
        $self->_command_stop_eni;
    }
    else {
        $self->_command_stop_route_table;
    }
}

sub _command_stop_eni {
    my $self = shift;

    my $res = $self->ec2("detach-network-interface", {
        attachment_id => $self->attachment_id,
    });
    infof "result: %s", ddf $res;
    my $timeout = time + $MHA::AWS::API_APPLIED_TIMEOUT;
  DETACHED:
    while ( time < $timeout ) {
        $res = $self->ec2("describe-network-interfaces", {
            network_interface_ids => $self->interface_id,
        });
        if ( $res->{NetworkInterfaces}->[0]->{Status} eq "available" ) {
            infof "detach completed.";
            return 1;
        }
        sleep $MHA::AWS::CHECK_INTERVAL;
    }
    critf "TIMEOUT: %d sec. Can't complete detach-network-interface: %s", $MHA::AWS::FAILOVER_TIMEOUT, $self->interface_id;
    return;
}

sub _command_stop_route_table {
    my $self = shift;

    my $destination_cidr_block = sprintf("%s/32", $self->vip);

    my $res = $self->ec2("delete-route", {
        route_table_id         => $self->route_table_id,
        destination_cidr_block => $destination_cidr_block,
    });
    infof "result: %s", ddf $res;
    my $timeout = time + $MHA::AWS::API_APPLIED_TIMEOUT;
 WAITING:
    while ( time < $timeout ) {
        $res = $self->ec2("describe-route-tables", {
            route_table_id => $self->route_table_id,
        });
        my @routes = @{ $res->{RouteTables}->[0]->{Routes} };
        for my $route (@routes) {
            if ( $route->{DestinationCidrBlock} eq $destination_cidr_block ) {
                sleep $MHA::AWS::CHECK_INTERVAL;
                next WAITING;
            }
        }
        infof "delete-route completed.";
        return 1;
    }
    critf "TIMEOUT: %d sec. Can't complete delete-route: %s %s", $MHA::AWS::FAILOVER_TIMEOUT, $self->route_table_id, $destination_cidr_block;
    return;
}

sub _command_start {
    my $self = shift;

    if ($self->failover_method eq "eni") {
        $self->_command_start_eni;
    }
    else {
        $self->_command_start_route_table;
    }
}

sub _command_start_route_table {
    my $self = shift;

    my $destination_cidr_block = sprintf("%s/32", $self->vip);

    my $res = $self->ec2("create-route", {
        route_table_id         => $self->route_table_id,
        instance_id            => $self->new_master_instance_id,
        destination_cidr_block => $destination_cidr_block,
    });
    infof "result: %s", ddf $res;
    my $timeout = time + $MHA::AWS::API_APPLIED_TIMEOUT;
 WAITING:
    while ( time < $timeout ) {
        $res = $self->ec2("describe-route-tables", {
            route_table_id => $self->route_table_id,
        });
        my @routes = @{ $res->{RouteTables}->[0]->{Routes} };
        for my $route (@routes) {
            if (
                $route->{DestinationCidrBlock} eq $destination_cidr_block
             && $route->{InstanceId} eq $self->new_master_instance_id
             ) {
                infof "create-route complated.";
                return 1;
            }
        }
        sleep $MHA::AWS::CHECK_INTERVAL;
    }
    critf "TIMEOUT %d sec. Can't complete create-route: %s %s", $MHA::AWS::API_APPLIED_TIMEOUT, $self->route_table_id, $destination_cidr_block;
    return;
}

sub _command_start_eni {
    my $self = shift;

    my $res = $self->ec2("attach-network-interface", {
        network_interface_id => $self->interface_id,
        instance_id          => $self->new_master_instance_id,
        device_index         => 2,
    });
    infof "result: %s", ddf $res;
    my $timeout = time + $MHA::AWS::API_APPLIED_TIMEOUT;
  ATTACHED:
    while ( time < $timeout ) {
        $res = $self->ec2("describe-network-interfaces", {
            network_interface_ids => $self->interface_id,
        });
        my $if = $res->{NetworkInterfaces}->[0];
        if ( $if->{Status} eq "in-use"
          && $if->{Attachment}
          && $if->{Attachment}->{Status} eq "attached"
          && $self->ping($self->vip)
        )
        {
            infof "attache completed.";
            return 1;
        }
        sleep $MHA::AWS::CHECK_INTERVAL;
    }
    critf "TIMEOUT %d sec. Can't complete attach-network-interface: %s", $MHA::AWS::API_APPLIED_TIMEOUT, $self->interface_id;
    return;
}

sub _command_status {
    my $self = shift;

    if ($self->failover_method eq "eni") {
        $self->_command_status_eni;
    }
    else {
        $self->_command_status_route_table;
    }
}

sub _command_status_eni {
    my $self = shift;

    if ($self->orig_master_instance_id eq $self->current_attached_instance_id) {
        return 1;
    }
    else {
        critf "orig_master_instance_id: %s != current_attached_instance_id: %s", $self->orig_master_instance_id, $self->current_attached_instance_id;
        return;
   }
}

sub _command_status_route_table {
    my $self = shift;

    if ($self->orig_master_instance_id eq $self->current_attached_instance_id) {
        return 1;
    }
    else {
        critf "orig_master_instance_id: %s != current_attached_instance_id: %s", $self->orig_master_instance_id, $self->current_attached_instance_id;
        return;
   }
}

1;
