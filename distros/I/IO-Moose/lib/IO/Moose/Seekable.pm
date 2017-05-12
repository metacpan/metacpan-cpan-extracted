#!/usr/bin/perl -c

package IO::Moose::Seekable;

=head1 NAME

IO::Moose::Seekable - Reimplementation of IO::Seekable with improvements

=head1 SYNOPSIS

  package My::IO;
  use Moose;
  extends 'IO::Moose::Handle';
  with 'IO::Moose::Seekable';

  package main;
  my $stdin = My::IO->new( file => \*STDIN, mode => 'r' );
  print $stdin->slurp;
  print $stdin->tell, "\n";

=head1 DESCRIPTION

This class provides an interface mostly compatible with L<IO::Seekable>.  The
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

=cut


use 5.008;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.1004';

use Moose;


=head1 INHERITANCE

=over 2

=item *

extends L<IO::Moose::Handle>

=over 2

=item   *

extends L<MooseX::GlobRef::Object>

=over 2

=item     *

extends L<Moose::Object>

=back

=back

=item *

extends L<IO::Seekable>

=over 2

=item   *

extends L<IO::Handle>

=back

=back

=cut

extends 'IO::Moose::Handle', 'IO::Seekable';


=head1 EXCEPTIONS

=over

=item L<Exception::Argument>

Thrown whether method is called with wrong argument.

=item L<Exception::Fatal>

Thrown whether fatal error is occurred by core function.

=back

=cut

use Exception::Base (
    '+ignore_package' => [ __PACKAGE__ ],
);


use constant::boolean;
use English '-no_match_vars';

use Scalar::Util 'blessed', 'looks_like_number', 'reftype';


# Assertions
use Test::Assert ':assert';

# Debugging flag
use if $ENV{PERL_DEBUG_IO_MOOSE_SEEKABLE}, 'Smart::Comments';


use namespace::clean -except => 'meta';


## no critic qw(ProhibitBuiltinHomonyms)
## no critic qw(RequireArgUnpacking)
## no critic qw(RequireCheckingReturnValueOfEval)

=head1 METHODS

=over

=item seek( I<pos> : Int, I<whence> : Int ) : Self

Seek the file to position I<pos>, relative to I<whence>:

=over

=item I<whence>=0 (SEEK_SET)

I<pos> is absolute position. (Seek relative to the start of the file)

=item I<whence>=1 (SEEK_CUR)

I<pos> is an offset from the current position. (Seek relative to current)

=item I<whence>=2 (SEEK_END)

=back

I<pos> is an offset from the end of the file. (Seek relative to end)

The SEEK_* constants can be imported from the L<Fcntl> module if you don't
wish to use the numbers 0, 1 or 2 in your code.  The SEEK_* constants are more
portable.

Returns self object on success or throws an exception.

  use Fcntl ':seek';
  $file->seek(0, SEEK_END);
  $file->say("*** End of file");

=cut

sub seek {
    ### IO::Moose::Seekabe::seek: @_

    my $self = shift;

    # handle tie hook
    $self = $$self if blessed $self and reftype $self eq 'REF';

    Exception::Argument->throw(
          message => 'Usage: $io->seek(POS, WHENCE)',
    ) if not blessed $self or @_ != 2 or not looks_like_number $_[0] or not looks_like_number $_[1];

    my $status;
    eval {
        $status = CORE::seek $self->fh, $_[0], $_[1];
    };
    if (not $status) {
        $self->_set_error(FALSE);
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $e->throw( message => 'Cannot seek' );
    };
    assert_true($status) if ASSERT;

    return $self;
};


=item sysseek( I<pos> : Int, I<whence> : Int ) : Int

Uses the system call lseek(2) directly so it can be used with B<sysread> and
B<syswrite> methods.

Returns the new position or throws an exception.

=cut

sub sysseek {
    ### IO::Moose::Seekabe::sysseek: @_

    my $self = shift;

    Exception::Argument->throw(
          message => 'Usage: $io->sysseek(POS, WHENCE)'
    ) if not blessed $self or @_ != 2 or not looks_like_number $_[0] or not looks_like_number $_[1];

    my $position;
    eval {
        $position = CORE::sysseek $self->fh, $_[0], $_[1];
    };
    if (not $position) {
        $self->_set_error(TRUE);
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $e->throw( message => 'Cannot sysseek' );
    };
    assert_true($position) if ASSERT;

    return int $position;
};


=item tell(I<>) : Int

Returns the current file position, or throws an exception on error.

=cut

sub tell {
    ### IO::Moose::Seekabe::tell: @_

    my $self = shift;

    # handle tie hook
    $self = $$self if blessed $self and reftype $self eq 'REF';

    Exception::Argument->throw(
          message => 'Usage: $io->tell()'
    ) if not blessed $self or @_ > 0;

    my $position;
    eval {
        $position = CORE::tell $self->fh;
    };
    if ($EVAL_ERROR or $position < 0) {
        $self->_set_error(TRUE);
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $e->throw( message => 'Cannot tell' );
    };
    assert_not_null($position) if ASSERT;

    return $position;
};


=item getpos(I<>) : Int

Returns a value that represents the current position of the file.  This method
is implemented with B<tell> method.

=cut

sub getpos {
    ### IO::Moose::Seekabe::getpos: @_

    my $self = shift;

    Exception::Argument->throw(
          message => 'Usage: $io->getpos()'
    ) if not blessed $self or @_ > 0;

    my $position;
    eval {
        $position = $self->tell;
    };
    if ($EVAL_ERROR or $position < 0) {
        $self->_set_error(TRUE);
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $e->throw( message => 'Cannot tell' );
    };
    assert_not_null($position) if ASSERT;

    return $position;
};


=item setpos( I<pos> : Int ) : Self

Goes to the position stored previously with B<getpos> method.  Returns this
object on success, throws an exception on failure.  This method is implemented
with B<seek> method.

  $pos = $file->getpos;
  $file->print("something\n");
  $file->setpos($pos);
  print $file->readline;  # prints "something"

=cut

sub setpos {
    # IO::Moose::Seekabe::setpos: @_

    my $self = shift;

    Exception::Argument->throw(
          message => 'Usage: $io->setpos(POS)'
    ) if not blessed $self or @_ != 1 or not looks_like_number $_[0];

    my ($pos) = @_;

    my $status;
    eval {
        # Fcntl::SEEK_SET is 0
        $status = $self->seek( $pos, 0 );
    };
    if (not $status) {
        $self->_set_error(TRUE);
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $e->throw( message => 'Cannot setpos' );
    };
    assert_true($status) if ASSERT;

    return $self;
};


# Aliasing tie hooks to real functions
{
    foreach my $func (qw{ tell seek }) {
        __PACKAGE__->meta->add_method(
            uc($func) => __PACKAGE__->meta->get_method($func)
        );
    };
};


1;


=back

=begin umlwiki

= Class Diagram =

[              IO::Moose::Seekable
 -----------------------------------------------
 +seek( pos : Int, whence : Int ) : Self
 +sysseek( pos : Int, whence : Int ) : Int
 +tell() : Int
 +getpos() : Int
 +setpos( pos : Int ) : Self
 -----------------------------------------------
                                                ]

[IO::Moose::Seekable] ---|> [IO::Moose::Handle] [IO::Seekable]

[IO::Moose::Seekable] ---> <<exception>> [Exception::Fatal] [Exception::IO]

=end umlwiki

=head1 SEE ALSO

L<IO::Seekable>, L<IO::Moose>, L<IO::Moose::Handle>.

=head1 BUGS

The API is not stable yet and can be changed in future.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright 2008, 2009 by Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
