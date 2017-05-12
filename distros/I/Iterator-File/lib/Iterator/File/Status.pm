package Iterator::File::Status;

## $Id: Status.pm,v 1.11 2008/06/18 06:47:51 wdr1 Exp $

use 5.006;
use strict;
use warnings;

use UNIVERSAL 'can';

our $VERSION = substr(q$Revision: 1.11 $, 10);

our %default_config =
  (
   '_status_scale'         => 1,
   'status_line_interval' => 10,
   'status_time_interval' => 2,
   'status_line'   => "Processing row '%d'...\n",
   'status_filehandle'    => \*STDERR,
   'status_method' => 'emit_status_logarithmic',
   
   '_status_time_last'     => time,
  );

sub new {
  my ($class, %config) = @_;

  %config = (%default_config, %config);
  my $self =  bless(\%config, $class);

  unless (can( __PACKAGE__, $config{'status_method'} )) {
    confess($default_config{'status_method'} .
            " is not a valid status_method arguement!");
  }
  
  return $self;
}


sub emit_status_logarithmic {
  my ($self, $marker) = @_;

  my $status = "";
  my $scale  = $self->{_status_scale};

  return if  ($marker % $scale);

  if ($marker >= $self->{_status_scale} * 10) {
    $self->{_status_scale} *= 10;
  }
  
  $self->emit_status_line( $marker );
}



sub emit_status_fixed_line_interval {
  my ($self, $marker) = @_;

  my $status   = "";
  my $interval = $self->{status_line_interval};

  return if ($marker % $interval);

  $self->emit_status_line( $marker );
}



sub emit_status_fixed_time_interval {
  my ($self, $marker) = @_;

  return unless (time - $self->{'_status_time_last'} >= $self->{'status_time_interval'});

  $self->{'_status_time_last'} = time;

  $self->emit_status_line( $marker );
}



sub emit_status_line {
  my ($self, $marker) = @_;

  my $fh = $self->{'status_filehandle'};
  printf $fh $self->{'status_line'}, $marker;
}



sub emit_status {
  my $self = shift;

  my $method = $self->{'status_method'};
  $self->$method( @_ );
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Iterator::File::Utility - IF utility functions

=head1 DESCRIPTION

=over 4

Private mixin status class for Iterator::File.

Not intended to be used directly or externally. 

=item B<new()>


=cut

=item B<emit_status_logarithmic()>

=cut

=item B<emit_status_fixed_line_interval()>

=cut

=item B<emit_status_fixed_time_interval()>

=cut

=back

=head1 SEE ALSO

Iterator::File

=head1 AUTHOR

William Reardon, E<lt>wdr1@pobox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by William Reardon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
