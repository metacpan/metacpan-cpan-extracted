package Ganglia::Gmetric::XS;

use strict;
use warnings;
use Carp;

our $VERSION = '1.06';

require XSLoader;
XSLoader::load('Ganglia::Gmetric::XS', $VERSION);

sub new {
    my $class = shift;
    my %args  = @_;

    my $config = delete $args{config} || "/etc/gmond.conf";
    my $spoof = delete $args{spoof};
    return _ganglia_initialize($class, $config, $spoof);
}

sub send {
    my($self,%args) = @_;

    return _ganglia_send(
        $self,
        $args{name}  || "",
        exists $args{value} ? $args{value} : "",
        $args{type}  || "",
        $args{units} || "",
        $args{group} || "",
        $args{desc}  || "",
        $args{title} || "",
        3, 60, 0,
        $args{spoof} || "",
    );
}

sub heartbeat {
    my ($self, %args) = @_;

    return _ganglia_heartbeat(
        $self,
        $args{spoof} || "",
    );
}

1;

__END__

=head1 NAME

Ganglia::Gmetric::XS - send a metric value to gmond with libganglia C library

=head1 SYNOPSIS

    use Ganglia::Gmetric::XS;

    my $gg = Ganglia::Gmetric::XS->new(config => "/etc/gmond.conf");
    $gg->send(name  => "db_conn",
              value => 32,
              type  => "uint32",
              units => "connection",
             );



    my $gg = Ganglia::Gmetric::XS->new(
        config => "/etc/gmond.conf",
        spoof => 'aServer:192.168.1.3'
    );
    $gg->heartbeat();


=head1 DESCRIPTION

Ganglia::Gmetric::XS can send a metric value to gmond with libganglia
C library.

=head1 METHODS

=head2 new

  $gg = Ganglia::Gmetric::XS->new( %option );

This method constructs a new "Ganglia::Gmetric::XS" instance and
returns it. %option may have the following keys:

=over

=item config

Example: "/etc/gmond.conf" - The configuration file to use for finding send channels

=item spoof

If this object should spoof every metric value sent to gmond, then the
spoof IP Address and hostname (colon separated) may be specified here.

=back

=head2 send

  $gg->send( %param ) or carp "failed to send metric";

send a metric value. %param is following:

  KEY    VALUE
  ----------------------------
  name   name of the metric
  value  value of the metric
  type   either string|int8|uint8|int16|uint16|int32|uint32|float|double
  units  unit of measure for the value e.g. "Kilobytes", "Celcius"
  group  group name of metric. (optional)
  desc   description of metric. (optional)
  title  title of metric. (optional)
  spoof  IP address and hostname (colon separated) of the host to spoof (optional)

=head2 heartbeat

  $gg->heartbeat( %param )

If you are spoofing the existence of a host, you will need to
periodically send heartbeat messages to tell gmond that the host is
up.

send a heartbeat. %param is following:

  KEY    VALUE
  ----------------------------
  spoof  IP address and hostname (colon separated) of the host to spoof (optional)

=head1 SEE ALSO

L<http://ganglia.info>

=head1 AUTHOR

HIROSE Masaaki, C<< <hirose31@gmail.com> >>

=head1 REPOSITORY

L<http://github.com/hirose31/ganglia-gmetric-xs/tree/master>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-ganglia-gmetric-xs@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
