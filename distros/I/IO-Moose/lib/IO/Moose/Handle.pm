#!/usr/bin/perl -c

package IO::Moose::Handle;

=head1 NAME

IO::Moose::Handle - Reimplementation of IO::Handle with improvements

=head1 SYNOPSIS

  use IO::Moose::Handle;

  my $fh = IO::Moose::Handle->new;
  $fh->fdopen( fileno(STDIN) );
  print $fh->getline;
  my $content = $fh->slurp;
  $fh->close;

  my $fh = IO::Moose::Handle->fdopen( \*STDERR, '>' );
  $fh->autoflush(1);
  $fh->say('Some text');
  undef $fh;  # calls close at DESTROY

=head1 DESCRIPTION

This class extends L<IO::Handle> with following differences:

=over

=item *

It is based on L<Moose> object framework.

=item *

The C<stat> method returns L<File::Stat::Moose> object.

=item *

It uses L<Exception::Base> for signaling errors. Most of methods are throwing
exception on failure.

=item *

The modifiers like C<input_record_separator> are supported on per file handle
basis.

=item *

It also implements additional methods like C<say>, C<slurp>.

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

extends L<MooseX::GlobRef::Object>

=over 2

=item   *

extends L<Moose::Object>

=back

=item *

extends L<IO::Handle>

=back

=cut

extends 'MooseX::GlobRef::Object', 'IO::Handle';


=head1 EXCEPTIONS

=over

=cut

use Exception::Base (
    '+ignore_package'  => [ __PACKAGE__, qr/^MooseX?::/, qr/^Class::MOP::/ ],
);

=item L<Exception::Argument>

Thrown whether method is called with wrong argument.

=cut

use Exception::Argument;

=item L<Exception::Fatal>

Thrown whether fatal error is occurred by core function.

=cut

use Exception::Fatal;

=back

=cut


# TRUE and FALSE
use constant::boolean;
use English '-no_match_vars';

use Scalar::Util 'blessed', 'reftype', 'looks_like_number';
use Symbol       'qualify', 'qualify_to_ref';

# stat method
use File::Stat::Moose;


# EBADF error code.
use Errno;


# Assertions
use Test::Assert ':assert';

# Debugging flag
use if $ENV{PERL_DEBUG_IO_MOOSE_HANDLE}, 'Smart::Comments';


# Additional types
use MooseX::Types::OpenModeStr;
use MooseX::Types::CanonOpenModeStr;


=head1 ATTRIBUTES

=over

=item file : Num|FileHandle|OpenHandle {ro}

File (file descriptor number, file handle or IO object) as a parameter for new
object or argument for C<fdopen> method.

=cut

# File to open (descriptor number or existing file handle)
has 'file' => (
    is        => 'ro',
    isa       => 'Num | FileHandle | OpenHandle',
    reader    => 'file',
    writer    => '_set_file',
    clearer   => '_clear_file',
    predicate => 'has_file',
);

=item mode : CanonOpenModeStr {ro} = "<"

File mode as a parameter for new object or argument for C<fdopen> method.  Can
be Perl-style (C<E<lt>>, C<E<gt>>, C<E<gt>E<gt>>, etc.) or C-style (C<r>,
C<w>, C<a>, etc.)

=cut

has 'mode' => (
    is        => 'ro',
    isa       => 'CanonOpenModeStr',
    lazy      => TRUE,
    default   => '<',
    coerce    => TRUE,
    reader    => 'mode',
    writer    => '_set_mode',
    clearer   => '_clear_mode',
    predicate => 'has_mode',
);

=item fh : GlobRef {ro}

File handle used for internal IO operations.

=cut

has 'fh' => (
    is        => 'ro',
    isa       => 'GlobRef | FileHandle | OpenHandle',
    reader    => 'fh',
    writer    => '_set_fh',
);

=item autochomp : Bool = false {rw}

If is true value the input will be auto chomped.

=cut

has 'autochomp' => (
    is        => 'rw',
    isa       => 'Bool',
    default   => FALSE,
);

=item tainted : Bool = ${^TAINT} {rw}

If is false value and tainted mode is enabled the C<untaint> method will be
called after C<fdopen>.

=cut

has 'tainted' => (
    is        => 'ro',
    isa       => 'Bool',
    default   => !! ${^TAINT},
    reader    => 'tainted',
    writer    => '_set_tainted',
);

=item blocking : Bool = true {rw}

If is false value the non-blocking IO will be turned on.

=cut

has 'blocking' => (
    is        => 'rw',
    isa       => 'Bool',
    default   => TRUE,
    reader    => '_get_blocking',
    writer    => '_set_blocking',
);

=item copyfh : Bool = false {ro}

If is true value the file handle will be copy of I<file> argument.  If
I<file> argument is not a file handle, the L<Exception::Argument> is
thrown.

=cut

has 'copyfh' => (
    is        => 'ro',
    isa       => 'Bool',
    default   => FALSE,
);

=item tied : Bool = true {ro}

By default the object's file handle is tied variable, so it can be used with
standard, non-OO interface (C<open>, C<print>, C<getc> functions and
C<< <> >> operator).  This interface is slow and can be disabled if the OO
interface only is used.

=cut

has 'tied' => (
    is        => 'ro',
    isa       => 'Bool',
    default   => TRUE,
);

=item strict_accessors : Bool = false {rw}

By default the accessors might be avoided for performance reason.  This
optimization can be disabled if the attribute is set to true value.

=cut

has 'strict_accessors' => (
    is        => 'rw',
    isa       => 'Bool',
    default   => FALSE,
);

=item format_formfeed : Str {rw, var="$^L"}

=item format_line_break_characters : Str {rw, var="$:"}

=item input_record_separator : Str {rw, var="$/"}

=item output_field_separator : Str {rw, var="$,"}

=item output_record_separator : Str {rw, var="$\"}

These are attributes assigned with Perl's built-in variables. See L<perlvar>
for complete descriptions.  The fields have accessors available as per file
handle basis if called as C<$io-E<gt>accessor> or as global setting if called
as C<IO::Moose::Handle-E<gt>accessor>.

=cut

# IO modifiers per file handle with special accessor
{
    foreach my $attr ( qw{
        format_formfeed
        format_line_break_characters
        input_record_separator
        output_field_separator
        output_record_separator
    } ) {

        has "$attr" => (
            is        => 'rw',
            isa       => 'Maybe[Str]',
            reader    => "_get_$attr",
            writer    => "_set_$attr",
            clearer   => "clear_$attr",
            predicate => "has_$attr",
        );

    };
};

# Flag if error was occured in IO operation
has '_error' => (
    isa       => 'Bool',
    default   => FALSE,
    reader    => '_get_error',
    writer    => '_set_error',
);

=back

=cut


use namespace::clean -except => 'meta';


## no critic qw(ProhibitOneArgSelect)
## no critic qw(ProhibitBuiltinHomonyms)
## no critic qw(ProhibitCaptureWithoutTest)
## no critic qw(RequireArgUnpacking)
## no critic qw(RequireCheckingReturnValueOfEval)
## no critic qw(RequireLocalizedPunctuationVars)

=head1 IMPORTS

=over

=item use IO::Moose::Handle '$STDIN', '$STDOUT', '$STDERR';

=item use IO::Moose::Handle ':std';

=item use IO::Moose::Handle ':all';

Creates handle as a copy of standard handle and imports it into caller's
namespace.  This handles won't be created until explicit import.

  use IO::Moose::Handle ':std';
  print $STDOUT->autoflush(1);
  print $STDIN->slurp;

=cut

# Import standard handles
sub import {
    ### IO::Moose::Handle::import: @_

    my ($pkg, @args) = @_;

    my %setup = ref $args[0] eq 'HASH' ? %{ shift @args } : ();

    my %vars;
    foreach my $arg (@args) {
        if (defined $arg and $arg =~ /^:(all|std)$/) {
            %vars = map { $_ => 1 } qw{ STDIN STDOUT STDERR };
        }
        elsif (defined $arg and $arg =~ /^\$(STDIN|STDOUT|STDERR)$/) {
            $vars{$1} = 1;
        }
        else {
            Exception::Argument->throw(
                message => ['Unknown argument for import: %s', (defined $arg ? $arg : 'undef')],
            );
        };
    };

    my $caller = $setup{into} || caller($setup{into_level} || 0);

    # Standard handles
    our ($STDIN, $STDOUT, $STDERR);

    foreach my $var (keys %vars) {
        if ($var eq 'STDIN') {
            $STDIN  = __PACKAGE__->new( file => \*STDIN,  mode => '<', copyfh => 1 ) if not defined $STDIN;
            *{qualify_to_ref("${caller}::STDIN")}  = \$STDIN;
        }
        elsif ($var eq 'STDOUT') {
            $STDOUT = __PACKAGE__->new( file => \*STDOUT, mode => '>', copyfh => 1 ) if not defined $STDOUT;
            *{qualify_to_ref("${caller}::STDOUT")} = \$STDOUT;
        }
        elsif ($var eq 'STDERR') {
            $STDERR = __PACKAGE__->new( file => \*STDERR, mode => '>', copyfh => 1 ) if not defined $STDERR;
            *{qualify_to_ref("${caller}::STDERR")} = \$STDERR;
        }
        else {
            assert_false("Unknown variable \$$var") if ASSERT;
        };
    };

    return TRUE;
};


=back

=head1 CONSTRUCTORS

=over

=item new( I<args> : Hash ) : Self

Creates the C<IO::Moose::Handle> object and calls C<fdopen> method if the
I<mode> parameter is defined.

  $io = IO::Moose::Handle->new( file => \*STDIN, mode => "r" );

The object can be created with unopened file handle which can be opened later.

  $in = IO::Moose::Handle->new( file => \*STDIN );
  $in->fdopen("r");

If I<copyfh> is true value and I<file> contains a file handle, this file
handle is copied rather than new file handle created.

  $tmp = File::Temp->new;
  $io = IO::Moose::Handle->new( file => $tmp, copyfh => 1, mode => "w" );

=cut

# Object initialization
sub BUILD {
    ### IO::Moose::Handle::BUILD: @_

    my ($self, $params) = @_;

    $self->_init_fh;

    return $self;
};


# Initialize file handle
sub _init_fh {
    ### IO::Moose::Handle::BUILD: @_

    my ($self) = @_;

    assert_equals('GLOB', reftype $self) if ASSERT;

    my $strict_accessors = $self->strict_accessors;
    my $tied = $strict_accessors ? $self->tied : *$self->{tied};
    my $copyfh = $strict_accessors ? $self->copyfh : *$self->{copyfh};

    my $fd = $strict_accessors ? $self->file : *$self->{file};

    # initialize anonymous handle
    if ($copyfh) {
        # Copy file handle
        if (blessed $fd and $fd->isa(__PACKAGE__)) {
            if ($strict_accessors) {
                $self->_set_fh( $fd->fh );
            }
            else {
                *$self->{fh} = $fd->fh;
            };
            if (not $tied) {
                my $fh = $fd->fh;
                *$self = *$fh{IO};
            }
        }
        elsif ((ref $fd || '') eq 'GLOB' or (reftype $fd || '') eq 'GLOB') {
            if ($self->strict_accessors) {
                $self->_set_fh( $fd );
            }
            else {
                *$self->{fh} = $fd;
            };
            if (not $tied) {
                *$self = *$fd{IO};
            }
        }
        else {
            Exception::Argument->throw(
                message => 'Cannot copy file handle from bad file argument'
            );
        };
    }
    else {
        # Create the new handle
        select select my $fh;
        if ($self->strict_accessors) {
            $self->_set_fh( $fh );
        }
        else {
            *$self->{fh} = $fh;
        };
        if (not $tied) {
            *$self = *$fh{IO};
        };
    };

    my $is_opened;

    if (not $copyfh) {
        $is_opened = eval { $self->_open_file };
        if ($EVAL_ERROR) {
            my $e = Exception::Fatal->catch;
            $e->throw( message => 'Cannot new' );
        };
        assert_not_null($is_opened) if ASSERT;
    };

    $self->_tie if $tied and not $is_opened;

    return $self;
};


# Open file if is defined
sub _open_file {
    #### IO::Moose::Handle::_open_file: @_

    my ($self) = @_;

    if ($self->has_file) {
        # call fdopen if file is defined; it also ties handle
        $self->fdopen( $self->file, $self->mode );
        return TRUE;
    };

    return FALSE;
};


# Tie self object
sub _tie {
    ### IO::Moose::Handle::_tie: @_

    my ($self) = @_;

    assert_equals('GLOB', reftype $self) if ASSERT;
    assert_true($self->tied) if ASSERT;

    tie *$self, blessed $self, $self;

    assert_not_null(tied *$self) if ASSERT;

    return $self;
};


# Untie self object
sub _untie {
    ### IO::Moose::Handle::_untie: @_

    my ($self) = @_;

    assert_equals('GLOB', reftype $self) if ASSERT;
    assert_true($self->tied) if ASSERT;

    untie *$self;

    return $self;
};


# Clone standard handler for tied handle
sub _open_tied {
    ### IO::Moose::Handle::_open_tied: @_

    my ($self) = @_;

    assert_equals('GLOB', reftype $self) if ASSERT;
    assert_true($self->tied) if ASSERT;
    assert_not_null($self->mode) if ASSERT;

    my $mode = $self->mode;

    # clone standard handler for tied handler
    $self->_untie;
    eval {
        CORE::open *$self, "$mode&", $self->fh;
    };
    if ($EVAL_ERROR) {
        Exception::Fatal->throw( message => 'Cannot fdopen' );
    };
    $self->_tie;

    return $self;
};


# Close tied handle
sub _close_tied {
    ### IO::Moose::Handle::_close_tied: @_

    my ($self) = @_;

    assert_equals('GLOB', reftype $self) if ASSERT;
    assert_true($self->tied) if ASSERT;

    $self->_untie;

    CORE::close *$self;

    $self->_tie;

    return $self;
};


=item new_from_fd( I<fd> : Num|FileHandle|OpenHandle, I<mode> : CanonOpenModeStr = "<") : Self

Creates the C<IO::Moose::Handle> object and immediately opens the file handle
based on arguments.

  $out = IO::Moose::Handle->new_from_fd( \*STDOUT, "w" );

=cut

sub new_from_fd {
    ### IO::Moose::Handle::new_from_fd: @_

    my $class = shift;
    Exception::Argument->throw(
        message => ['Usage: %s->new_from_fd(FD, [MODE])', __PACKAGE__],
    ) if @_ < 1 or @_ > 2;

    my ($fd, $mode) = @_;

    my $io = eval {
        $class->new(
            file => $fd,
            defined $mode ? (mode => $mode) : ()
        )
    };
    if ($EVAL_ERROR) {
        my $e = Exception::Fatal->catch;
        $e->throw( message => 'Cannot new_from_fd' );
    };
    assert_isa(__PACKAGE__, $io) if ASSERT;

    return $io;
};


=back

=head1 METHODS

=over

=item fdopen( I<fd> : Num|FileHandle|OpenHandle, I<mode> : CanonOpenModeStr = "<" ) : Self

Opens the previously created file handle.  If the file was already opened, it
is closed automatically and reopened without resetting its line counter.  The
method also sets the C<file> and C<mode> attributes.

  $out = IO::Moose::Handle->new;
  $out->fdopen( \*STDOUT, "w" );

  $dup = IO::Moose::Handle->new;
  $dup->fdopen( $dup, "a" );

  $stdin = IO::Moose::Handle->new;
  $stdin->fdopen( 0, "r");

=cut

sub fdopen {
    ### IO::Moose::Handle::fdopen: @_

    my $self = shift;
    Exception::Argument->throw(
        message => 'Usage: $io->fdopen(FD, [MODE])',
    ) if not blessed $self or @_ < 1 or @_ > 2 or not defined $_[0];

    my ($fd, $mode) = @_;

    my $status;
    eval {
        # check constraints and fill attributes
        $fd = $self->_set_file($fd);
        $mode = defined $mode ? $self->_set_mode($mode) : do { $self->_clear_mode; $self->mode };

        assert_not_null($fd) if ASSERT;
        assert_not_null($mode) if ASSERT;

        if (blessed $fd and $fd->isa(__PACKAGE__)) {
            #### fdopen: "open(fh, $mode&, \$fd->fh)"
            $status = CORE::open $self->fh, "$mode&", $fd->fh;
        }
        elsif ((ref $fd || '') eq 'GLOB') {
            #### fdopen: "open(fh, $mode&, \\$$fd)"
            $status = CORE::open $self->fh, "$mode&", $fd;
        }
        elsif ((reftype $fd || '') eq 'GLOB') {
            #### fdopen: "open(fh, $mode&, *$fd)"
            $status = CORE::open $self->fh, "$mode&", *$fd;
        }
        elsif ($fd =~ /^\d+$/) {
            #### fdopen: "open(fh, $mode&=$fd)"
            $status = CORE::open $self->fh, "$mode&=$fd";
        }
        else {
            # should be caught by constraint
            assert_false("Bad file descriptor");
        };
    };
    if (not $status) {
        $self->_set_error(TRUE);
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $e->throw( message => 'Cannot fdopen' );
    };
    assert_true($status) if ASSERT;

    $self->_set_error(FALSE);

    $self->_open_tied if $self->tied;

    if (${^TAINT} and not $self->tainted) {
        $self->untaint;
    };

    if (${^TAINT} and not $self->_get_blocking) {
        $self->blocking(FALSE);
    };

    return $self;
};


=item close(I<>) : Self

Closes the opened file handle.  The C<file> and C<mode> attributes are cleared
after closing.

=cut

sub close {
    ### IO::Moose::Handle::close: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->close()'
    ) if not blessed $self or @_ > 0;

    if (not CORE::close $self->fh) {
        $self->_set_error(TRUE);
        Exception::IO->throw( message => 'Cannot close' );
    };

    $self->_set_error(FALSE);

    # clear file and mode attributes
    $self->_clear_file;
    $self->_clear_mode;

    $self->_close_tied if $self->tied;

    return $self;
};


=item eof(I<>) : Bool

=cut

sub eof {
    ### IO::Moose::Handle::eof: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->eof()'
    ) if not blessed $self or @_ > 0;

    my $status;
    eval {
        $status = CORE::eof $self->fh;
    };
    if ($EVAL_ERROR) {
        my $e = Exception::Fatal->catch;
        $e->throw( message => 'Cannot eof' );
    };
    return $status;
};


=item fileno(I<>) : Int

=cut

sub fileno {
    ### IO::Moose::Handle::fileno: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->fileno()'
    ) if not blessed $self or @_ > 0;

    my $fileno = CORE::fileno $self->fh;
    if (not defined $fileno) {
        local $! = Errno::EBADF;
        Exception::IO->throw( message => 'Cannot fileno' );
    };

    return $fileno;
};


=item opened(I<>) : Bool

=cut

sub opened {
    ### IO::Moose::Handle::opened: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->opened()'
    ) if not blessed $self or @_ > 0;

    my $fileno;
    eval {
        $fileno = CORE::fileno $self->fh;
    };

    return defined $fileno;
};


=item print( I<args> : Array ) : Self

=cut

sub print {
    ### IO::Moose::Handle::print: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->print(ARGS)'
    ) if not ref $self;

    my $status;
    eval {
        # IO modifiers based on object's attributes
        local $OUTPUT_FIELD_SEPARATOR
            = $self->has_output_field_separator
            ? $self->_get_output_field_separator
            : $OUTPUT_FIELD_SEPARATOR;
        local $OUTPUT_RECORD_SEPARATOR
            = $self->has_output_record_separator
            ? $self->_get_output_record_separator
            : $OUTPUT_RECORD_SEPARATOR;

        {
            # IO modifiers based on tied fh modifiers
            my $oldfh = select *$self;
            my $var = $|;
            select $self->fh;
            $| = $var;
            select $oldfh;
        };

        $status = CORE::print { $self->fh } @_;
    };
    if (not $status) {
        $self->_set_error(TRUE);
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $e->throw( message => 'Cannot print' );
    };
    assert_true($status) if ASSERT;

    return $self;
};


=item printf( I<fmt> : Str = "", I<args> : Array = (I<>) ) : Self

=cut

sub printf {
    ### IO::Moose::Handle::printf: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->printf(FMT, [ARGS])'
    ) if not ref $self;

    {
        # IO modifiers based on tied fh modifiers
        my $oldfh = select *$self;
        my $var = $|;
        select $self->fh;
        $| = $var;
        select $oldfh;
    };

    my $status;
    eval {
        $status = CORE::printf { $self->fh } @_;
    };
    if (not $status) {
        $self->_set_error(TRUE);
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $e->throw( message => 'Cannot printf' );
    };
    assert_true($status) if ASSERT;

    return $self;
};


=item sysread( out I<buf>, I<len> : Int, I<offset> : Int = 0 ) : Int

=cut

sub sysread {
    ### IO::Moose::Handle::sysread: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->sysread(BUF, LEN [, OFFSET])'
    ) if not ref $self or @_ < 2 or @_ > 3;

    my $bytes;
    eval {
        $bytes = CORE::sysread($self->fh, $_[0], $_[1], $_[2] || 0);
    };
    if (not defined $bytes) {
        $self->_set_error(TRUE);
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $e->throw( message => 'Cannot sysread' );
    };
    assert_not_null($bytes) if ASSERT;
    return $bytes;
};


=item syswrite( I<buf> : Str, I<len> : Int, I<offset> : Int = 0 ) : Int

=cut

sub syswrite {
    ### IO::Moose::Handle::syswrite: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->syswrite(BUF [, LEN [, OFFSET]])'
    ) if not ref $self or @_ < 1 or @_ > 3;

    my $bytes;
    eval {
        if (defined($_[1])) {
            $bytes = CORE::syswrite($self->fh, $_[0], $_[1], $_[2] || 0);
        }
        else {
            $bytes = CORE::syswrite($self->fh, $_[0]);
        };
    };
    if (not defined $bytes) {
        $self->_set_error(TRUE);
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $e->throw( message => 'Cannot syswrite' );
    };
    assert_not_null($bytes) if ASSERT;
    return $bytes;
};


=item getc(I<>) : Char

=cut

sub getc {
    ### IO::Moose::Handle::getc: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->getc()'
    ) if not blessed $self or @_ > 0;

    my $strict_accessors = $self->strict_accessors;

    my $hashref;
    $hashref = \%{*$self} if not $strict_accessors;

    undef $!;
    my $char;
    eval {
        $char = CORE::getc $self->fh;
    };
    if ($EVAL_ERROR or (not defined $char and $! and $! != Errno::EBADF)) {
        $self->_set_error(TRUE);
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $e->throw( message => 'Cannot getc' );
        assert_false("Should throw an exception ealier") if ASSERT;
    };

    if (${^TAINT} and defined $char and not ($strict_accessors ? $self->tainted : $hashref->{tainted})) {
        # Bug on Ubuntu intrepid: does not work: $char =~ /(.*)/; $char = $1
        ord($char) =~ /(\d+)/;
        my $c = chr($1);
        $char = $c;
    };

    return $char;
};


=item read( out I<buf>, I<len> : Int, I<offset> : Int = 0 ) : Int

=cut

sub read {
    ### IO::Moose::Handle::read: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->read(BUF, LEN [, OFFSET])'
    ) if not ref $self or @_ < 2 or @_ > 3;

    my $bytes;
    eval {
        $bytes = CORE::read($self->fh, $_[0], $_[1], $_[2] || 0);
    };
    if (not defined $bytes) {
        $self->_set_error(TRUE);
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $e->throw( message => 'Cannot read' );
    };
    assert_not_null($bytes) if ASSERT;

    return $bytes;
};


=item truncate( I<len> : Int ) : Self

These are front ends for corresponding built-in functions.  Most of them
throws exception on failure which can be caught with try/catch:

  use Exception::Base;
  eval {
    open $f, "/etc/hostname";
    $io = IO::Moose::Handle->new( file => $f, mode => "r" );
    $c = $io->getc;
  };
  if ($@) {
    my $e = Exception::Base->catch) {
    warn "problem with /etc/hostname file: $e";
  };

The C<fdopen>, C<close>, C<print>, C<printf> and C<truncate> methods returns
this object.

=cut

sub truncate {
    ### IO::Moose::Handle::truncate: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->truncate(LEN)'
    ) if not ref $self or @_ != 1 or not looks_like_number $_[0];

    my $status;
    eval {
        $status = CORE::truncate($self->fh, $_[0]);
    };
    if ($EVAL_ERROR or not $status) {
        $self->_set_error(TRUE);
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $e->throw( message => 'Cannot truncate' );
    };
    assert_true($status) if ASSERT;

    return $self;
};


=item write( I<buf> : Str, I<len> : Int, I<offset> : Int = 0 ) : Int

The opposite of B<read>. The wrapper for the perl L<perlfunc/write> function is called
C<format_write>.

=cut

sub write {
    ### IO::Moose::Handle::write: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->write(BUF [, LEN [, OFFSET]])'
    ) if not blessed $self or @_ > 3 or @_ < 1;

    my ($buf, $len, $offset) = @_;

    my $bytes;
    my $status;
    eval {
        # clean IO modifiers
        local $OUTPUT_RECORD_SEPARATOR = '';

        {
            # IO modifiers based on tied fh modifiers
            my $oldfh = select *$self;
            my $var = $OUTPUT_AUTOFLUSH;
            select $self->fh;
            $OUTPUT_AUTOFLUSH = $var;
            select $oldfh;
        };

        my $output = substr($buf, $offset || 0, defined $len ? $len : length($buf));
        $bytes = length($output);
        $status = CORE::print { $self->fh } $output;
    };
    if (not $status) {
        $self->_set_error(TRUE);
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $e->throw( message => 'Cannot write' );
    };
    assert_true($status) if ASSERT;
    assert_not_null($bytes) if ASSERT;

    return $bytes;
};


=item format_write( I<format_name> : Str ) : Self

The wrapper for perl L<perlfunc/format> function.

=cut

sub format_write {
    ### IO::Moose::Handle::format_write: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->format_write([FORMAT_NAME])'
    ) if not blessed $self or @_ > 1;

    my ($fmt) = @_;

    my $e;
    my $status;
    {
        my ($oldfmt, $oldtopfmt);

        # New format in argument
        if (defined $fmt) {
            $oldfmt = $self->format_name(qualify($fmt, caller));
            $oldtopfmt = $self->format_top_name(qualify($fmt . '_TOP', caller));
        }

        # IO modifiers based on object's attributes
        my @vars_obj = ($FORMAT_LINE_BREAK_CHARACTERS, $FORMAT_FORMFEED);

        # Global variables without local scope
        $FORMAT_LINE_BREAK_CHARACTERS
            = $self->has_format_line_break_characters
            ? $self->_get_format_line_break_characters
            : $FORMAT_LINE_BREAK_CHARACTERS;
        $FORMAT_FORMFEED
            = $self->has_format_formfeed
            ? $self->_get_format_formfeed
            : $FORMAT_FORMFEED;

        # IO modifiers based on tied fh modifiers
        {
            my $oldfh = select *$self;
            my @vars_tied = (
                $OUTPUT_AUTOFLUSH, $FORMAT_PAGE_NUMBER,
                $FORMAT_LINES_PER_PAGE, $FORMAT_LINES_LEFT, $FORMAT_NAME,
                $FORMAT_TOP_NAME, $INPUT_LINE_NUMBER,
            );
            select $self->fh;
            (
                $OUTPUT_AUTOFLUSH, $FORMAT_PAGE_NUMBER,
                $FORMAT_LINES_PER_PAGE, $FORMAT_LINES_LEFT, $FORMAT_NAME,
                $FORMAT_TOP_NAME, $INPUT_LINE_NUMBER,
            ) = @vars_tied;
            select $oldfh;
        };

        eval {
            $status = CORE::write $self->fh;
        };
        $e = Exception::Fatal->catch;

        # Restore previous settings
        ($FORMAT_LINE_BREAK_CHARACTERS, $FORMAT_FORMFEED) = @vars_obj;
        if (defined $fmt) {
            $self->format_name($oldfmt);
            $self->format_top_name($oldtopfmt);
        };
    };
    if (not $status) {
        $self->_set_error(TRUE);
        $e = Exception::IO->new unless $e;
        $e->throw( message => 'Cannot format_write' );
    };
    assert_true($status) if ASSERT;

    return $self;
};


=item readline(I<>) : Maybe[Str|Array]

=cut

# TODO POD
sub readline {
    ### IO::Moose::Handle::readline: @_

    my ($self) = @_;

    Exception::Argument->throw(
        message => 'Usage: $io->readline()'
    ) if not ref $self or @_ > 1;

    my ($status, @lines, $line);
    my $strict_accessors = $self->strict_accessors;

    my $hashref;
    $hashref = \%{*$self} if not $strict_accessors;

    my $wantarray = wantarray;

    undef $!;
    eval {
        # IO modifiers based on object's attributes
        local $INPUT_RECORD_SEPARATOR
            = ($strict_accessors ? $self->has_input_record_separator : exists $hashref->{input_record_separator})
            ? ($strict_accessors ? $self->_get_input_record_separator : $hashref->{input_record_separator})
            : $INPUT_RECORD_SEPARATOR;

        # scalar or array context
        if ($wantarray) {
            $status = scalar(@lines = CORE::readline ($strict_accessors ? $self->fh : $hashref->{fh}));
            chomp @lines if ($strict_accessors ? $self->autochomp : $hashref->{autochomp});
        }
        else {
            $status = defined($line = CORE::readline ($strict_accessors ? $self->fh : $hashref->{fh}));
            chomp $line if $strict_accessors ? $self->autochomp : $hashref->{autochomp};
        };
    };
    if ($EVAL_ERROR or (not $status and $!)) {
        $self->_set_error(TRUE);
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $e->throw( message => 'Cannot readline' );
    };

    return $wantarray ? @lines : $line;
};


=item getline(I<>) : Str

The C<readline> method which is called always in scalar context.

  $io = IO::Moose::Handle->new( file=>\*STDIN, mode=>"r" );
  push @a, $io->getline;  # reads only one line

=cut

sub getline {
    ### IO::Moose::Handle::getline: @_

    my $self = shift;

    my $line;
    eval {
        $line = $self->readline(@_);
    };
    if ($EVAL_ERROR) {
        my $e = Exception::Fatal->catch;
        if ($e->isa('Exception::Argument')) {
            $e->throw( message => 'Usage: $io->getline()' );
        }
        else {
            $e->throw( message => 'Cannot getline' );
        };
        assert_false("Should throw an exception ealier") if ASSERT;
    };

    return $line;
};


=item getlines(I<>) : Array

The C<readline> method which is called always in array context.

  $io = IO::Moose::Handle->new( file => \*STDIN, mode => "r" );
  print scalar $io->getlines;  # error: can't call in scalar context.

=cut

sub getlines {
    ### IO::Moose::Handle::getlines: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Cannot call $io->getlines in a scalar context, use $io->getline'
    ) if not wantarray;

    my @lines;
    eval {
        @lines = $self->readline(@_);
    };
    if ($EVAL_ERROR) {
        my $e = Exception::Fatal->catch;
        if ($e->isa('Exception::Argument')) {
            $e->throw( message => 'Usage: $io->getlines()' );
        }
        else {
            $e->throw( message => 'Cannot getlines' );
        };
        assert_false("Should throw an exception ealier") if ASSERT;
    };

    return @lines;
};


=item ungetc( I<ord> : Int ) : Self

Pushes a character with the given ordinal value back onto the given handle's
input stream.

  $io = IO::Moose::Handle->new( file => \*STDIN, mode => "r" );
  $io->ungetc(ord('A'));
  print $io->getc;  # prints A

=cut

sub ungetc {
    ### IO::Moose::Handle::ungetc: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->ungetc(ORD)'
    ) if not blessed $self or @_ != 1 or not looks_like_number $_[0];

    my ($ord) = @_;

    eval {
        IO::Handle::ungetc( $self->fh, $ord );
    };
    if ($EVAL_ERROR) {
        my $e = Exception::Fatal->catch;
        $e->throw( message => 'Cannot ungetc' );
    };

    return $self;
};


=item say( I<args> : Array ) : Self

The C<print> method with EOL character at the end.

  $io = IO::Moose::Handle->new( file => \*STDOUT, mode => "w" );
  $io->say("Hello!");

=cut

sub say {
    ### IO::Moose::Handle::say: @_

    my $self = shift;

    eval {
        $self->print(@_, "\n");
    };
    if ($EVAL_ERROR) {
        my $e = Exception::Fatal->catch;
        if ($e->isa('Exception::Argument')) {
            $e->throw( message => 'Usage: $io->say(ARGS)' );
        }
        else {
            $e->throw( message => 'Cannot say' );
        };
    };

    return $self;
};


=item IO::Moose::Handle->slurp( I<file> : Num|FileHandle|OpenHandle, I<args> : Hash ) : Str|Array

Creates the C<IO::Moose::Handle> object and returns its content as a scalar in
scalar context or as an array in array context.

  open $f, "/etc/passwd";
  $passwd_file = IO::Moose::Handle->slurp($f);

Additional I<args> are passed to C<IO::Moose::Handle> constructor.

=item slurp(I<>) : Str|Array

Reads whole file and returns its content as a scalar in scalar context or as
an array in array context (like C<getlines> method).

  open $f, "/etc/passwd";

  $io1 = IO::Moose::Handle->new( file => $f, mode => "r" );
  $passwd_file = $io1->slurp;

  $io2 = IO::Moose::Handle->new( file => $f, mode => "r" );
  $io2->autochomp(1);
  @passwd_lines = $io2->slurp;

=cut

sub slurp {
    ### IO::Moose::Handle::slurp: @_

    my $self = shift;
    my $class = ref $self || $self || __PACKAGE__;
    my %args = @_;

    Exception::Argument->throw(
        message => ['Usage: $io->slurp() or %s->slurp(file=>FILE)', __PACKAGE__],
    ) if not blessed $self and not defined $args{file} or blessed $self and @_ > 0;

    if (not blessed $self) {
        $self = eval { $self->new( %args ) };
        if ($EVAL_ERROR) {
            my $e = Exception::Fatal->catch;
            $e->throw( message => 'Cannot slurp' );
        };
        assert_isa(__PACKAGE__, $self) if ASSERT;
    };

    my (@lines, $string);
    my $wantarray = wantarray;

    my $old_separator = $self->_get_input_record_separator;
    my $old_autochomp = $self->autochomp;

    undef $!;
    eval {
        # scalar or array context
        if ($wantarray) {
            $self->_set_input_record_separator("\n");
            @lines = $self->readline;
        }
        else {
            $self->_set_input_record_separator(undef);
            $self->autochomp(FALSE);
            $string = $self->readline;
        };
    };
    my $e = Exception::Fatal->catch;

    $self->_set_input_record_separator($old_separator);
    $self->autochomp($old_autochomp);

    if ($e) {
        $e->throw( message => 'Cannot slurp' );
    };

    return $wantarray ? @lines : $string;
};


=item stat(I<>) : File::Stat::Moose

Returns C<File::Stat::Moose> object which represents status of file pointed by
current file handle.

  open $f, "/etc/passwd";
  $io = IO::Moose::Handle->new( file => $f, mode => "r" );
  $st = $io->stat;
  print $st->size;  # size of /etc/passwd file

=cut

sub stat {
    ### IO::Moose::Handle::stat: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->stat()'
    ) if not ref $self or @_ > 0;

    my $stat;
    eval {
        $stat = File::Stat::Moose->new( file => $self->fh );
    };
    if ($EVAL_ERROR) {
        my $e = Exception::Fatal->catch;
        $self->_set_error(TRUE);
        $e->throw( message => 'Cannot stat' );
    };
    assert_isa('File::Stat::Moose', $stat) if ASSERT;

    return $stat;
};


=item error(I<>) : Bool

Returns true value if the file handle has experienced any errors since it was
opened or since the last call to C<clearerr>, or if the handle is invalid.

It is recommended to use exceptions mechanism to handle errors.

=cut

sub error {
    ### IO::Moose::Handle::error: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->error()'
    ) if not blessed $self or @_ > 0;

    return $self->_get_error || ! defined CORE::fileno $self->fh;
};


=item clearerr(I<>) : Bool

Clear the given handle's error indicator.  Returns true value if the file
handle is valid or false value otherwise.

=cut

sub clearerr {
    ### IO::Moose::Handle::clearerr: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->clearerr()'
    ) if not blessed $self or @_ > 0;

    $self->_set_error(FALSE);
    return defined CORE::fileno $self->fh;
};


=item sync(I<>) : Self

Synchronizes a file's in-memory state with that on the physical medium.  It
operates on file descriptor and it is low-level operation.  Returns this
object on success or throws an exception.

=cut

sub sync {
    ### IO::Moose::Handle::sync: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->sync()'
    ) if not blessed $self or @_ > 0;

    my $status;
    eval {
        $status = IO::Handle::sync($self->fh);
    };
    if ($EVAL_ERROR or not defined $status) {
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $self->_set_error(TRUE);
        $e->throw( message => 'Cannot sync' );
    };
    assert_not_null($status) if ASSERT;

    return $self;
};


=item flush(I<>) : Self

Flushes any buffered data at the perlio API level.  Returns self object on
success or throws an exception.

=cut

sub flush {
    ### IO::Moose::Handle::flush: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->flush()'
    ) if not blessed $self or @_ > 0;

    my $oldfh = select $self->fh;
    my @var = ($OUTPUT_AUTOFLUSH, $OUTPUT_RECORD_SEPARATOR);
    $OUTPUT_AUTOFLUSH = 1;
    $OUTPUT_RECORD_SEPARATOR = undef;

    my $e;
    my $status;
    eval {
        $status = CORE::print { $self->fh } '';
    };
    if ($EVAL_ERROR) {
        $e = Exception::Fatal->catch;
    };

    ($OUTPUT_AUTOFLUSH, $OUTPUT_RECORD_SEPARATOR) = @var;
    select $oldfh;

    if ($e) {
        $self->_set_error(TRUE);
        $e->throw( message => 'Cannot flush' );
    };
    assert_null($e) if ASSERT;

    return $self;
};


=item printflush( I<args> : Array ) : Self

Turns on autoflush, print I<args> and then restores the autoflush status.
Returns self object on success or throws an exception.

=cut

sub printflush {
    ### IO::Moose::Handle::printflush: @_

    my $self = shift;

    if (blessed $self) {
        my $oldfh = select *$self;
        my $var = $OUTPUT_AUTOFLUSH;
        $OUTPUT_AUTOFLUSH = 1;

        my $e;
        my $status;
        eval {
            $status = $self->print(@_);
        };
        if ($EVAL_ERROR) {
            $e = Exception::Fatal->catch;
        };

        $OUTPUT_AUTOFLUSH = $var;
        select $oldfh;

        if ($e) {
            $e->throw( message => 'Cannot printflush' );
        };

        return $status;
    }
    else {
        local $OUTPUT_AUTOFLUSH = 1;
        return CORE::print @_;
    };
};


=item blocking(I<>) : Bool

=item blocking( I<bool> : Bool ) : Bool

If called with an argument blocking will turn on non-blocking IO if I<bool> is
false, and turn it off if I<bool> is true.  C<blocking> will return the value
of the previous setting, or the current setting if I<bool> is not given.

=cut

sub blocking {
    ### IO::Moose::Handle::blocking: @_

    my $self = shift;

    Exception::Argument->throw(
          message => 'Usage: $io->blocking([BOOL])'
    ) if not blessed $self or @_ > 1;

    # constraint checking
    my $old_blocking = $self->_get_blocking;
    eval {
        $self->_set_blocking($_[0]);
    };
    Exception::Fatal->catch->throw(
        message => 'Cannot blocking'
    ) if $EVAL_ERROR;

    my $status;
    eval {
        if (defined $_[0]) {
            $status = IO::Handle::blocking($self->fh, $_[0]);
        }
        else {
            $status = IO::Handle::blocking($self->fh);
        };
    };
    if ($EVAL_ERROR or not defined $status) {
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $self->_set_error(TRUE);
        $self->_set_blocking($old_blocking);
        $e->throw( message => 'Cannot blocking' );
    };
    assert_not_null($status) if ASSERT;

    return $status;
};


=item untaint(I<>) : Self {rw}

Marks the object as taint-clean, and as such data read from it will also be
considered taint-clean.  It has meaning only if Perl is running in tainted
mode (C<-T>).

=cut

sub untaint {
    ### IO::Moose::Handle::untaint: @_

    my $self = shift;

    Exception::Argument->throw(
        message => 'Usage: $io->untaint()'
    ) if not blessed $self or @_ > 0;

    my $status;
    eval {
        $status = IO::Handle::untaint($self->fh);
    };
    if ($EVAL_ERROR or not defined $status or $status != 0) {
        my $e = $EVAL_ERROR ? Exception::Fatal->catch : Exception::IO->new;
        $self->_set_error(TRUE);
        $e->throw( message => 'Cannot untaint' );
    };
    assert_equals(0, $status) if ASSERT;

    $self->_set_tainted(FALSE);

    return $self;
};


# Clean up on destroy
sub DEMOLISH {
    ### IO::Moose::Handle::DESTROY: @_

    my ($self) = @_;

    local $@ = '';
    eval {
        $self->_untie;
    };

    return $self;
};


# Tie hook by proxy class
sub TIEHANDLE {
    ### IO::Moose::Handle::TIEHANDLE: @_

    my ($class, $self) = @_;

    return $self;
};


# Called on untie.
sub UNTIE {
    ### IO::Moose::Handle::UNTIE: @_
};


=item format_lines_left(I<>) : Str {var="$-"}

=item format_lines_left( I<value> : Str ) : Str {var="$-"}

=item format_lines_per_page(I<>) : Str {var="$="}

=item format_lines_per_page( I<value> : Str ) : Str {var="$="}

=item format_page_number(I<>) : Str {var="$%"}

=item format_page_number( I<value> : Str ) : Str {var="$%"}

=item input_line_number(I<>) : Str {var="$."}

=item input_line_number( I<value> : Str ) : Str {var="$."}

=item output_autoflush(I<>) : Str {var="$|"}

=item output_autoflush( I<value> : Str ) : Str {var="$|"}

=item autoflush(I<>) : Str {var="$|"}

=item autoflush( I<value> : Str ) : Str {var="$|"}

=item format_name(I<>) : Str {var="$~"}

=item format_name( I<value> : Str ) : Str {var="$~"}

=item format_top_name(I<>) : Str {var="$^"}

=item format_top_name( I<value> : Str ) : Str {var="$^"}

These are accessors assigned with Perl's built-in variables. See L<perlvar>
for complete descriptions.

=cut

{
    # Generate accessors for IO modifiers (global and local)
    my @standard_accessors = (
        'format_formfeed',              # $^L
        'format_line_break_characters', # $:
        'input_record_separator',       # $/
        'output_field_separator',       # $,
        'output_record_separator',      # $\
    );
    foreach my $func (@standard_accessors) {
        my $var = qualify_to_ref(uc($func));
        __PACKAGE__->meta->add_method( $func => sub {
            ### IO::Moose::Handle::$func: $func, @_
            my $self = shift;
            Exception::Argument->throw(
                message => ['Usage: $io->%2$s([EXPR]) or %1$s->%2$s([EXPR])', __PACKAGE__, $func],
            ) if @_ > 1;
            if (ref $self) {
                my $prev = do { \%{*$self} }->{$func};
                if (@_ > 0) {
                    do { \%{*$self} }->{$func} = shift;
                };
                return $prev;
            }
            else {
                my $prev = ${*$var};
                if (@_ > 0) {
                    ${*$var} = shift;
                };
                return $prev;
            };
        } );
    };
};

{
    # Generate accessors for IO modifiers (output modifiers which require select)
    my @output_accessors = (
        'format_lines_left',            # $-
        'format_lines_per_page',        # $=
        'format_page_number',           # $%
        'input_line_number',            # $.
        'output_autoflush',             # $|
    );
    foreach my $func (@output_accessors) {
        my $var = qualify_to_ref(uc($func));
        __PACKAGE__->meta->add_method( $func => sub {
            ### IO::Moose::Handle::$func: $func, @_
            my $self = shift;
            Exception::Argument->throw(
                message => ['Usage: $io->%2$s([EXPR]) or %1$s->%2$s([EXPR])', __PACKAGE__, $func],
            ) if @_ > 1;
            if (ref $self) {
                my $oldfh = select *$self;
                my $prev = ${*$var};
                if (@_ > 0) {
                    ${*$var} = shift;
                };
                select $oldfh;
                return $prev;
            }
            else {
                my $prev = ${*$var};
                if (@_ > 0) {
                    ${*$var} = shift;
                };
                return $prev;
            };
        } );
    };
};

{
    # Generate accessors for IO modifiers (qualified format name)
    my @format_name_accessors = (
        'format_name',                  # $~
        'format_top_name',              # $^
    );
    foreach my $func (@format_name_accessors) {
        my $var = qualify_to_ref(uc($func));
        __PACKAGE__->meta->add_method( $func => sub {
            ### IO::Moose::Handle::$func: $func, @_
            my $self = shift;
            Exception::Argument->throw(
                message => ['Usage: $io->%2$s([EXPR]) or %1$s->%2$s([EXPR])', __PACKAGE__, $func],
            ) if @_ > 1;
            if (ref $self) {
                my $oldfh = select *$self;
                my $prev = ${*$var};
                if (@_ > 0) {
                    my $value = shift;
                    ${*$var} = defined $value ? qualify($value, caller) : undef;
                };
                select $oldfh;
                return $prev;
            }
            else {
                my $prev = ${*$var};
                my $value = shift;
                ${*$var} = defined $value ? qualify($value, caller) : undef;
                return $prev;
            };
        } );
    };
};

# Aliasing accessor
__PACKAGE__->meta->add_method(
    'autoflush' => __PACKAGE__->meta->get_method('output_autoflush')
);


# Aliasing tie hooks to real functions
foreach my $hook (qw{ CLOSE FILENO PRINT PRINTF READLINE GETC }) {
    my $method = lc($hook);
    __PACKAGE__->meta->add_method(
        $hook => sub {
            ### IO::Moose::Handle::$hook: $hook, @_
            shift()->$method(@_)
        }
    );
};

__PACKAGE__->meta->add_method( 'EOF' => sub {
    ### IO::Moose::Handle::EOF: @_
    shift()->eof;
} );

foreach my $hook (qw{ READ WRITE }) {
    my $method = 'sys' . lc($hook);
    __PACKAGE__->meta->add_method(
        $hook => sub {
            ### IO::Moose::Handle::$hook: $hook, @_
            shift()->$method(@_)
        }
    );
};


# Make immutable finally
__PACKAGE__->meta->make_immutable;


1;


=back

=begin umlwiki

= Class Diagram =

[                                 IO::Moose::Handle
 --------------------------------------------------------------------------------------
 +file : Num|FileHandle|OpenHandle {ro}
 +mode : CanonOpenModeStr = "<" {ro}
 +fh : GlobRef {ro}
 +autochomp : Bool = false {rw}
 +untaint : Bool = ${^TAINT} {ro}
 +blocking : Bool = true {ro}
 +copyfh : Bool = false {ro}
 +strict_accessors : Bool = false {rw}
 +format_formfeed : Str {rw}
 +format_line_break_characters : Str {rw}
 +input_record_separator : Str {rw}
 +output_field_separator : Str {rw}
 +output_record_separator : Str {rw}
 #_error : Bool
 --------------------------------------------------------------------------------------
 <<create>> +new( args : Hash ) : Self
 <<create>> +new_from_fd( fd : Num|FileHandle|OpenHandle, mode : CanonOpenModeStr ) : Self
 <<create>> +slurp( file : Num|FileHandle|OpenHandle, args : Hash ) : Str|Array
 +fdopen( file : Num|FileHandle|OpenHandle, mode : CanonOpenModeStr = '<' ) : Self
 +close() : Self
 +eof() : Bool
 +opened() : Bool
 +fileno() : Int
 +print( args : Array ) : Self
 +printf( fmt : Str = "", args : Array = () ) : Self
 +readline() : Maybe[Str|Array]
 +getline() : Str
 +getlines() : Array
 +ungetc( ord : Int ) : Self
 +sysread( out buf, len : Int, offset : Int = 0 ) : Int
 +syswrite( buf : Str, len : Int, offset : Int = 0 ) : Int
 +getc() : Char
 +read( out buf, len : Int, offset : Int = 0 ) : Int
 +write( buf : Str, len : Int, offset : Int = 0 ) : Int
 +format_write( format_name : Str ) : Self
 +say( args : Array ) : Self
 +slurp() : Str|Array
 +truncate( len : Int ) : Self
 +stat() : File::Stat::Moose
 +error() : Bool
 +clearerr() : Bool
 +sync() : Self
 +flush() : Self
 +printflush( args : Array ) : Self
 +blocking() : Bool
 +blocking( bool : Bool ) : Bool
 +untaint() : Self {rw}
 +clear_input_record_separator()
 +clear_output_field_separator()
 +clear_output_record_separator()
 +clear_format_formfeed()
 +clear_format_line_break_characters()
 +format_lines_left() : Str
 +format_lines_left( value : Str ) : Str
 +format_lines_per_page() : Str
 +format_lines_per_page( value : Str ) : Str
 +format_page_number() : Str
 +format_page_number( value : Str ) : Str
 +input_line_number() : Str
 +input_line_number( value : Str ) : Str
 +autoflush() : Str
 +autoflush( value : Str ) : Str
 +output_autoflush() : Str
 +output_autoflush( value : Str ) : Str
 +format_name() : Str
 +format_name( value : Str ) : Str
 +format_top_name() : Str
 +format_top_name( value : Str ) : Str
 #_open_file() : Bool
                                                                            ]

[IO::Moose::Handle] ---|> [MooseX::GlobRef::Object] [IO::Handle]

[IO::Moose::Handle] ---> <<use>> [File::Stat::Moose]

[IO::Moose::Handle] ---> <<exception>> [Exception::Fatal] [Exception::IO] [Exception::Argument]

=end umlwiki

=head1 DEBUGGING

The debugging mode can be enabled if C<PERL_DEBUG_IO_MOOSE_HANDLE> environment
variable is set to true value.  The debugging mode requires L<Smart::Comments>
module.

The run-time assertions can be enabled with L<Test::Assert> module.

=head1 INTERNALS

This module uses L<MooseX::GlobRef::Object> and stores the object's attributes
in glob reference.  They can be accessed with C<< *$self->{attr} >>
expression or with standard accessors C<< $self->attr >>.

There are two handles used for IO operations: the original handle used for
real IO operations and tied handle which hooks IO functions interface.

The OO-style uses original handle stored in I<fh> field.

  # Usage:
  $io->print("OO style");

  # Implementation:
  package IO::Moose::Handle;
  sub print {
      my $self = shift;
      CORE::print { $self->fh } @_
  }

The IO functions-style uses object reference which is dereferenced as a
handle tied to proxy object which operates on original handle.

  # Usage:
  print $io "IO functions style";

  # Implementation:
  package IO::Moose::Handle;
  sub PRINT { shift()->print(@_) };
  sub print {
      my $self = shift;
      CORE::print { $self->fh } @_
  }

=head1 SEE ALSO

L<IO::Handle>, L<MooseX::GlobRef::Object>, L<Moose>.

=head1 BUGS

The API is not stable yet and can be changed in future.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright 2007, 2008, 2009 by Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
