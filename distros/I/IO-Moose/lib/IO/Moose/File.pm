#!/usr/bin/perl -c

package IO::Moose::File;

=head1 NAME

IO::Moose::File - Reimplementation of IO::File with improvements

=head1 SYNOPSIS

  use IO::Moose::File;
  my $file = IO::Moose::File->new( file => "/etc/passwd" );
  my @passwd = $file->getlines;

=head1 DESCRIPTION

This class provides an interface mostly compatible with L<IO::File>.  The
differences:

=over

=item *

It is based on L<Moose> object framework.

=item *

It uses L<Exception::Base> for signaling errors. Most of methods are throwing
exception on failure.

=item *

It doesn't export any constants.  Use L<Fcntl> instead.

=back

=for readme stop

=cut


use 5.008;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.1004';

use Moose;


=head1 INHERITANCE

=over 2

=item *

extends L<IO::Moose::Seekable>

=over 2

=item   *

extends L<IO::Moose::Handle>

=over 2

=item     *

extends L<MooseX::GlobRef::Object>

=over 2

=item       *

extends L<Moose::Object>

=back

=back

=back

=item *

extends L<IO::File>

=over 2

=item   *

extends L<IO::Seekable>

=over 2

=item     *

extends L<IO::Handle>

=back

=back

=back

=cut

extends 'IO::Moose::Seekable', 'IO::File';


use MooseX::Types::OpenModeWithLayerStr;
use MooseX::Types::PerlIOLayerStr;


=head1 EXCEPTIONS

=over

=item L<Exception::Argument>

Thrown whether method is called with wrong argument.

=item L<Exception::Fatal>

Thrown whether fatal error is occurred by core function.

=back

=cut

use Exception::Base (
    '+ignore_package' => [ __PACKAGE__, 'Carp', 'File::Temp' ],
);


use constant::boolean;
use English '-no_match_vars';

use Scalar::Util 'looks_like_number', 'reftype';


# For new_tmpfile
use File::Temp;


# Assertions
use Test::Assert ':assert';

# Debugging flag
use if $ENV{PERL_DEBUG_IO_MOOSE_FILE}, 'Smart::Comments';


=head1 ATTRIBUTES

=over

=item file : Str|FileHandle|OpenHandle {ro}

File (file name, file handle or IO object) as a parameter for new object or
C<open> method.

=cut

has '+file' => (
    isa       => 'Str | FileHandle | OpenHandle',
);

=item mode : OpenModeWithLayerStr|CanonOpenModeStr = "<" {ro}

File mode as a parameter for new object or C<open> method.  Can be Perl-style
string (E<lt>, E<gt>, E<gt>E<gt>, etc.) with optional PerlIO layer after colon
(i.e. C<E<lt>:encoding(UTF-8)>) or C-style string (C<r>, C<w>, C<a>, etc.)

=cut

has '+mode' => (
    isa       => 'OpenModeWithLayerStr | CanonOpenModeStr',
);

=item sysmode : Num {ro}

File mode as a parameter for new object or C<sysopen> method.  Can be decimal
number (C<O_RDONLY>, C<O_RDWR>, C<O_CREAT>, other constants from standard
module L<Fcntl>).

=cut

has 'sysmode' => (
    is        => 'ro',
    isa       => 'Num',
    writer    => '_set_sysmode',
    clearer   => '_clear_sysmode',
    predicate => 'has_sysmode',
);

=item perms : Num = 0666 {ro}

Permissions to use in case a new file is created and mode was decimal number.
The permissions are always modified by umask.

=cut

has 'perms' => (
    is        => 'ro',
    isa       => 'Num',
    default   => oct(666),
    lazy      => TRUE,
    reader    => 'perms',
    writer    => '_set_perms',
    clearer   => '_clear_perms',
    predicate => 'has_perms',
);

=item layer : PerlIOLayerStr = "" {ro}

PerlIO layer string.

=cut

has 'layer' => (
    is        => 'ro',
    isa       => 'PerlIOLayerStr',
    reader    => 'layer',
    writer    => '_set_layer',
    clearer   => '_clear_layer',
    predicate => 'has_layer',
);

=back

=cut


use namespace::clean -except => 'meta';


## no critic qw(ProhibitBuiltinHomonyms)
## no critic qw(RequireArgUnpacking)
## no critic qw(RequireCheckingReturnValueOfEval)

=head1 CONSTRUCTORS

=over

=item new( I<args> : Hash ) : Self

Creates an object.  If I<file> is defined and is a string or array
reference, the C<open> method is called; if the open fails, the object
is destroyed.  Otherwise, it is returned to the caller.

  $io = IO::Moose::File->new;
  $io->open("/etc/passwd");

  $io = IO::Moose::File->new( file => "/var/log/perl.log", mode => "a" );

If I<file> is a file handler, the C<fdopen> method is called.

  $tmp = IO::Moose::File->new( file => \*STDERR, mode => 'w' );
  $tmp->say("Some important message");

If I<layer> is defined, the C<binmode> method is called.

  $io = IO::Moose::File->new( file => "test.txt", layer => ":utf8" );

=cut

override '_open_file' => sub {
    ### IO::Moose::File::_open_file: @_

    my ($self) = @_;

    # Open file with our method
    if ($self->has_file) {
        # call fdopen if it was handler
        if ((reftype $self->file || '') eq 'GLOB') {
            $self->fdopen( $self->file, $self->mode );
            if ($self->has_layer) {
                $self->binmode( $self->layer );
            };
            return TRUE;
        }
        else {
            # call open otherwise
            if ($self->has_perms) {
                $self->open( $self->file, $self->mode, $self->perms );
            }
            else {
                $self->open( $self->file, $self->mode );
            };
            if (defined $self->layer) {
                $self->binmode( $self->layer );
            };
            return TRUE;
        };
    };

    return FALSE;
};

=item new_tmpfile( I<args> : Hash ) : Self

Creates the object with opened temporary and anonymous file for read/write.
If the temporary file cannot be created or opened, the object is destroyed.
Otherwise, it is returned to the caller.

All I<args> will be passed to the L<File::Temp> and L<IO::Moose::Handle>
constructors.

  $io = IO::Moose::File->new_tmpfile( UNLINK => 1, SUFFIX => '.jpg' );
  $pos = $io->getpos;  # save position
  $io->say("foo");
  $io->setpos($pos);   # rewind
  $io->slurp;          # prints "foo"

  $tmp = IO::Moose::File->new_tmpfile( output_record_separator => "\n" );
  $tmp->print("say");  # with eol

=cut

sub new_tmpfile {
    ### IO::Moose::File::new_tmpfile: @_

    my $class = shift;

    my $io;

    eval {
        # Pass arguments to File::Temp constructor
        my $tmp = File::Temp->new( @_ );

        # create new empty object with new default mode
        $io = $class->new( @_, file => $tmp, mode => '+>', copyfh => TRUE );
    };
    if ($EVAL_ERROR) {
        my $e = Exception::Fatal->catch;
        $e->throw( message => 'Cannot new_tmpfile' );
    };
    assert_not_null($io) if ASSERT;

    return $io;
};

=back

=head1 METHODS

=over

=item open( I<file> : Str, I<mode> : OpenModeWithLayerStr|CanonOpenModeStr = "<" ) : Self

Opens the I<file> with L<perlfunc/open> function and returns self object.

  $io = IO::Moose::File->new;
  $io->open("/etc/passwd");

  $io = IO::Moose::File->new;
  $io->open("/var/tmp/output", "w");

=cut

# Wrapper for CORE::open
sub open {
    ### IO::Moose::File::open: @_
    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->open(FILENAME [,MODE]) or $io->open(FILENAME, IOLAYERS)'
    ) if not blessed $self or @_ < 1 or @_ > 2 or ref $_[0];

    my ($file, $mode) = @_;
    my $layer = '';

    my $status;
    eval {
        # check constraints
        $file  = $self->_set_file($file);
        $mode  = defined $mode ? $self->_set_mode($mode) : do { $self->_clear_mode; $self->mode };

        if ($mode =~ s/(:.*)//) {
            $layer = $self->_set_layer($1);
            $mode  = $self->_set_mode($mode);
        };

        ### open: "open(fh, $mode, $file)"
        $status = CORE::open( $self->fh, $mode, $file );
    };
    if (not $status) {
        $self->_set_error(TRUE);
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $e->throw( message => 'Cannot open' );
    };
    assert_true($status) if ASSERT;

    $self->_set_error(FALSE);

    $self->_open_tied if $self->tied;

    if (${^TAINT} and not $self->tainted) {
        $self->untaint;
    };

    return $self;
};

=item sysopen( I<file> : Str, I<sysmode> : Num, I<perms> : Num = 0600 ) : Self

Opens the I<file> with L<perlfunc/sysopen> function and returns self object.
The I<sysmode> is decimal value (it can be C<O_XXX> constant from standard
module L<Fcntl>).  The default I<perms> are set to C<0666>.  The C<mode>
attribute is set based on I<sysmode> value.

  use Fcntl;
  $io = IO::Moose::File->new;
  $io->open("/etc/hosts", O_RDONLY);
  print $io->mode;   # prints "<"

=cut

sub sysopen {
    ### IO::Moose::File::sysopen: @_
    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->sysopen(FILENAME, SYSMODE [,PERMS]])'
    ) if not blessed $self or @_ < 2 or @_ > 3 or ref $_[0];

    my ($file, $sysmode, $perms) = @_;
    my $layer = '';

    my $status;
    eval {
        # check constraints
        $file    = $self->_set_file($file);
        $sysmode = $self->_set_sysmode($sysmode);
        $perms   = defined $perms ? $self->_set_perms($perms) : do { $self->_clear_perms; $self->perms };

        # normalize mode string for tied handler
        my $mode = ($sysmode & 2 ? '+' : '') . ($sysmode & 1 ? '>' : '<');
        $self->_set_mode($mode);

        ### open: "sysopen(fh, $file, $mode, $perms)"
        $status = CORE::sysopen( $self->fh, $file, $sysmode, $perms );
    };
    if (not $status) {
        $self->_set_error(TRUE);
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $e->throw( message => 'Cannot open' );
    };
    assert_true($status) if ASSERT;

    $self->_set_error(FALSE);

    $self->_open_tied if $self->tied;

    if (${^TAINT} and not $self->tainted) {
        $self->untaint;
    };

    return $self;
};


# Also clear sysmode on close
after 'close' => sub {
    ### IO::Moose::File::close: @_

    my ($self) = @_;
    $self->_clear_sysmode;

    return $self;
};


=item binmode(I<>) : Self

=item binmode( I<layer> : PerlIOLayerStr ) : Self

Sets binmode on the underlying IO object.  On some systems (in general, DOS
and Windows-based systems) binmode is necessary when you're not working with
a text file.

It can also sets PerlIO layer (C<:bytes>, C<:crlf>, C<:utf8>,
C<:encoding(XXX)>, etc.). More details can be found in L<PerlIO::encoding>.

In general, C<binmode> should be called after C<open> but before any I/O is
done on the file handler.

Returns self object.

  $io = IO::Moose::File->new( file => "/tmp/picture.png", mode => "w" );
  $io->binmode;

  $io = IO::Moose::File->new( file => "/var/tmp/fromdos.txt" );
  $io->binmode(":crlf");

=cut

# Wrapper for CORE::binmode
sub binmode {
    ### IO::Moose::File::binmode: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->binmode([LAYER])'
    ) if not blessed $self or @_ > 1;

    my ($layer) = @_;

    $layer = $self->_set_layer($layer) if defined $layer;

    my $status;
    eval {
        if (defined $layer) {
            $status = CORE::binmode( $self->fh, $layer );
        }
        else {
            $status = CORE::binmode( $self->fh );
        };
    };

    if (not $status) {
        $self->_set_error(FALSE);
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $e->throw( message => 'Cannot open' );
    };
    assert_true($status) if ASSERT;

    return $self;
};

=back

=cut


# Aliasing tie hooks to real functions
__PACKAGE__->meta->add_method( 'BINMODE' => sub {
    ### IO::Moose::File::BINMODE: @_
    shift()->binmode(@_);
} );

__PACKAGE__->meta->add_method( 'OPEN' => sub {
    ### IO::Moose::File::OPEN: @_
    my $self = shift;
    return $self->sysopen(@_) if defined $_[1] and looks_like_number $_[1];
    return $self->open(@_);
} );


# Make immutable finally
__PACKAGE__->meta->make_immutable;


1;


=begin umlwiki

= Class Diagram =

[                     IO::Moose::File
 -----------------------------------------------------------------
 +file : Str|FileHandle|OpenHandle {ro}
 +mode : OpenModeWithLayerStr|CanonOpenModeStr = "<" {ro}
 +sysmode : Num {ro}
 +perms : Num = 0666 {ro}
 +layer : PerlIOLayerStr = "" {ro}
 -----------------------------------------------------------------
 +new( args : Hash ) : Self
 +new_tmpfile( args : Hash ) : Self
 +open( file : Str, mode : OpenModeWithLayerStr|CanonOpenModeStr = "<" ) : Self
 +sysopen( file : Str, sysmode : Num, perms : Num = 0600 ) : Self
 +binmode() : Self
 +binmode( layer : PerlIOLayerStr ) : Self
                                                                  ]

[IO::Moose::File] ---|> [IO::Moose::Seekable] [IO::File]

[IO::Moose::File] ---> <<exception>> [Exception::Fatal] [Exception::IO]

=end umlwiki

=head1 SEE ALSO

L<IO::File>, L<IO::Moose>, L<IO::Moose::Handle>, L<IO::Moose::Seekable>,
L<File::Temp>.

=head1 BUGS

The API is not stable yet and can be changed in future.

=for readme continue

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright 2008, 2009 by Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
