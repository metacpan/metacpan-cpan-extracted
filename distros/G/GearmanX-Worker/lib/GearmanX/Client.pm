package GearmanX::Client;

use Data::Dumper;
use GearmanX::Serialization;

=head1 NAME

GearmanX::Client - Gearman client which works with GearmanX::Worker

=cut

our $VERSION = '0.01';

=pod

=head1 SYNOPSIS

  use GearmanX::Client;
  my $c = new GearmanX::Client ( SERVERS => ['1.1.1.1'] );

  # launch job and wait for results
  $result = $c->job ('jobname', { one => 'param', at => 'a time' });
  # same thing
  $result = $c->job_sync (....);

  # launch job and continue
  $jobid = $c->job_async ('jobname', { one => 'param', at => 'a time' });

=head1 DESCRIPTION

This class is simply a convenience to work comfortably alongside L<GearmanX::Worker>. In that it
mostly takes care that the single parameter (a scalar, a hash reference or a list reference) is
serialized before the job is submitted to the gearman server.

=head1 INTERFACE

=head2 Constructor

The constructor expects the following fields:

=over

=item C<SERVERS>

This is a list reference holding the list of IP addresses of the involved gearman job servers.

=back

=cut

sub new {
    my $class = shift;
    my %options = @_;
    my $self = bless \%options, $class;
    use Gearman::Client;
    $self->{client} = Gearman::Client->new ( job_servers => $self->{SERVERS} );
    return $self;
}

=pod

=head2 Methods

=over

=item B<status>

die unless I<$client>->status

Returns non-zero if a jobserver can be contact. Launches a fake job to test that.

=cut

sub status {
    my $self = shift;
    my $r = $self->{client}->dispatch_background ('xadjmw32345fjasdcsdfsd9sdf');  # HACK: unlikely to be registered
    return defined $r; # anything non zero means the server is running
}

=pod

=item B<job>, B<job_sync>

I<$client>->job (I<$jobname>, I<$parameter>);

Launches a job, serializes the parameter and waits for the result. That will be deserialized.

=cut

sub job {
    my $self = shift;
    return $self->job_sync (@_);
}

sub job_sync {
    my $self   = shift;
    my $jname  = shift || die "need a job name";
    my $param  = shift;

    my $s = GearmanX::Serialization::_serialize ($param);
#    warn "client before sending ".Dumper $s;
	     
    $s = $self->{client}->do_task( $jname, $s );                                      # only one scalar is passed there
#    warn "client got ".Dumper $s;

    return GearmanX::Serialization::_deserialize ($s);
}

=pod

=item C<job_async>

I<$client>->job_async (I<$jobname>, I<$parameter>);

Launches a job, serializes the parameter and immediately returns the job id.

=cut

sub job_async {
    my $self  = shift;
    my $jname = shift || die "need a job name";
    my $param = shift;

    my $s = GearmanX::Serialization::_serialize ($param);
    return $self->{client}->dispatch_background( $jname, $s );
}

=pod

=back

=pod

=head1 AUTHOR

Robert Barta, C<< <rho at devc.at> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-gearmanx-worker at rt.cpan.org>, or through the
web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GearmanX-Worker>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

"against all gods";
