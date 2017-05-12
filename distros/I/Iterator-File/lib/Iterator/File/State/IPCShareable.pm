package Iterator::File::State::IPCShareable;

## $Id: IPCShareable.pm,v 1.4 2008/06/11 05:20:07 wdr1 Exp $

use 5.006;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use IO::File;
use Digest::MD5 qw|md5_hex|;

use IPC::Shareable;

use Iterator::File::State::Interface;

our @ISA = qw(Iterator::File::State::Interface);
our $VERSION = substr(q$Revision: 1.4 $, 10);

our %default_config = ();


sub new {
  my ($class, %config) = @_;

  confess("No IPC key given!") unless ($config{ipc_key});

  %config = (%default_config, %config);
  my $self = $class->SUPER::new( %config );
  bless($self, $class);

  $self->_verbose("IPC key is '", $self->{'ipc_key'}, "'...\n");

  return $self;
}



sub initialize {
  my ($self) = @_;

  $self->_debug( __PACKAGE__ . " initializing... ");
  
  my $ipc_key = $self->{'ipc_key'};
  my $marker;
  my $ipc_object = tie $marker, 'IPC::Shareable', $ipc_key, { 'create' => 1 };
  confess( "Unable to shared memory segment!  Key: '$ipc_key'" )
    unless (defined $ipc_object);

  $marker ||= 0;
  
  $self->{'ipc_object'} = $ipc_object;
  $self->{'marker'}     = $marker;

  $self->_verbose( "Starting marker location is '$marker'..." );
}



sub set_marker {
  my ($self, $num) = @_;
  
  $self->{'marker'} = $num;
  $self->{'ipc_object'}->STORE( $self->{'marker'} );
}



sub finish {
  my ($self) = @_;

  $self->_verbose("Removing '", $self->{'ipc_key'}, "'...\n");
  $self->{'ipc_object'}->remove();
}



sub marker {
  my ($self) = @_;
  
  return $self->{'marker'};
}



sub ipc_key {
  my ($self) = @_;

  return $self->{'ipc_key'};
}



# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Iterator::File::State::IPCShareable

=head1 DESCRIPTION

All data sources should subclass Iterator::File::Source::Interface, overriding
methods as appropriate.

=over 4

=item B<new(%config)>

Constructor options:

=over 4

=item B<ipc_key> (required)

4 character identified passed to IPC::Shareable.

=back

=cut

=item B<ipc_key()>

Read-only.  Return the selected ipc_key.

=cut

=back

=head1 SEE ALSO

Iterator::File, Iterator::File::State::IPCShareable, IPC::Shareable

=head1 AUTHOR

William Reardon, E<lt>wdr1@pobox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by William Reardon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

