#  Handles.pm
#    - interface to the handles used by GnuPG::Interface
#
#  Copyright (C) 2000 Frank J. Tobin <ftobin@cpan.org>
#
#  This module is free software; you can redistribute it and/or modify it
#  under the same terms as Perl itself.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#  $Id: Handles.pm,v 1.8 2001/12/09 02:24:10 ftobin Exp $
#

package GnuPG::Handles;
use Moo;
use MooX::late;
with qw(GnuPG::HashInit);

use constant HANDLES => qw(
    stdin
    stdout
    stderr
    status
    logger
    passphrase
    command
);

has "$_" => (
    isa     => 'Any',
    is      => 'rw',
    clearer => 'clear_' . $_,
) for HANDLES;

has _options => (
    isa        => 'HashRef',
    is         => 'rw',
    lazy_build => 1,
);

sub options {
    my $self = shift;
    my $key = shift;

    return $self->_options->{$key};
}

sub _build__options { {} }

sub BUILD {
    my ( $self, $args ) = @_;

    # This is done for the user's convenience so that they don't
    # have to worry about undefined hashrefs
    $self->_options->{$_} = {} for HANDLES;
    $self->hash_init(%$args);
}

1;

=head1 NAME

GnuPG::Handles - GnuPG handles bundle

=head1 SYNOPSIS

  use IO::Handle;
  my ( $stdin, $stdout, $stderr,
       $status_fh, $logger_fh, $passphrase_fh,
     )
    = ( IO::Handle->new(), IO::Handle->new(), IO::Handle->new(),
        IO::Handle->new(), IO::Handle->new(), IO::Handle->new(),
      );
 
  my $handles = GnuPG::Handles->new
    ( stdin      => $stdin,
      stdout     => $stdout,
      stderr     => $stderr,
      status     => $status_fh,
      logger     => $logger_fh,
      passphrase => $passphrase_fh,
    );

=head1 DESCRIPTION

GnuPG::Handles objects are generally instantiated
to be used in conjunction with methods of objects
of the class GnuPG::Interface.  GnuPG::Handles objects
represent a collection of handles that are used to
communicate with GnuPG.

=head1 OBJECT METHODS

=head2 Initialization Methods

=over 4

=item new( I<%initialization_args> )

This methods creates a new object.  The optional arguments are
initialization of data members.

=item hash_init( I<%args> ).


=back

=head1 OBJECT DATA MEMBERS

=over 4

=item stdin

This handle is connected to the standard input of a GnuPG process.

=item stdout

This handle is connected to the standard output of a GnuPG process.

=item stderr

This handle is connected to the standard error of a GnuPG process.

=item status

This handle is connected to the status output handle of a GnuPG process.

=item logger

This handle is connected to the logger output handle of a GnuPG process.

=item passphrase

This handle is connected to the passphrase input handle of a GnuPG process.

=item command

This handle is connected to the command input handle of a GnuPG process.

=item options

This is a hash of hashrefs of settings pertaining to the handles
in this object.  The outer-level hash is keyed by the names of the
handle the setting is for, while the inner is keyed by the setting
being referenced.  For example, to set the setting C<direct> to true
for the filehandle C<stdin>, the following code will do:

    # assuming $handles is an already-created
    # GnuPG::Handles object, this sets all
    # options for the filehandle stdin in one blow,
    # clearing out all others
    $handles->options( 'stdin', { direct => 1 } );

    # this is useful to just make one change
    # to the set of options for a handle
    $handles->options( 'stdin' )->{direct} = 1;

    # and to get the setting...
    $setting = $handles->options( 'stdin' )->{direct};

    # and to clear the settings for stdin
    $handles->options( 'stdin', {} );

The currently-used settings are as follows:

=over 4

=item direct

If the setting C<direct> is true for a handle, the GnuPG
process spawned will access the handle directly.  This is useful for
having the GnuPG process read or write directly to or from
an already-opened file.

=back

=back

=head1 SEE ALSO

L<GnuPG::Interface>,

=cut
