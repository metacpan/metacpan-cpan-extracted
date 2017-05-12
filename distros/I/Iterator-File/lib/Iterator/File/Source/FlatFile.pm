package Iterator::File::Source::FlatFile;

## $Id: FlatFile.pm,v 1.6 2008/06/16 07:42:08 wdr1 Exp $

use 5.006;
use strict;
use warnings;

use Carp;
use IO::File;
use Data::Dumper;

use Iterator::File::Source::Interface;

our @ISA = qw(Iterator::File::Source::Interface);

our $VERSION = substr(q$Revision: 1.6 $, 10);

our %default_config = ();

sub new {
  my ($class, %config) = @_;

  croak("No file name given!") unless ($config{filename});
  %config = (%default_config, %config);
  $config{'_current_value'} = undef;

  ## Instantiation
  my $self = $class->SUPER::new( %config );
  bless($self, $class);

  return $self;
}


sub initialize {
  my ($self) = @_;
  
  $self->_debug( __PACKAGE__ . " initializing... ");
  
  my $fh = new IO::File ($self->{filename})
    || croak("Couldn't open '", $self->{filename}, "': $!");
  $self->{'_file_handle'} = $fh;

}


sub next {
  my ($self) = @_;

  my $fh = $self->{_file_handle};
  $self->{'_current_value'} = <$fh>;
  
  if ( $self->{'chomp'} && $self->{'_current_value'} ) {
    chomp( $self->{'_current_value'} );
  }
  
  return $self->{'_current_value'};
}  


sub advance_to {
  my ($self, $marker) = @_;

  return unless ($marker);
  
  $self->_verbose("Advancing to '$marker'...");
  my $i = 0;
  while ($i++ <= $marker) {
    $self->next();
  }
}


sub value {
  my ($self) = @_;

  return $self->{'_current_value'};
}


sub finish {
  my ($self) = @_;

  my $fh = $self->{'_file_handle'};
  $fh->close() || warn("Couldn't close '", $self->{'filename'}, "': $!");
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Iterator::File::Source::FlatFile

=head1 DESCRIPTION

Iterator::File class for iteratoring over a flat file.  I.e., a file
with one entry per line.

Iterator::File::Source::FlatFile does not implement any methods in addition
to those described in Iterator::File::Source::Interface.


=head1 SEE ALSO

Iterator::File::State::Interface

=head1 AUTHOR

William Reardon, E<lt>wdr1@pobox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by William Reardon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
