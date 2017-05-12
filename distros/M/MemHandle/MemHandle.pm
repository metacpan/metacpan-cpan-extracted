package MemHandle;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
require IO::Handle;
require IO::Seekable;
use Symbol;
use MemHandle::Tie;

require Exporter;
use 5.000;

@ISA = qw(IO::Handle IO::Seekable Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.07';


# Preloaded methods go here.
sub new {
    my( $class, $mem ) = @_;
    $class = ref( $class ) || $class || 'MemHandle';
    my $fh = gensym;

    ${*$fh} = tie *$fh, 'MemHandle::Tie', $mem;

    bless $fh, $class;
}

sub seek {
    my $fh = shift;
    ${*$fh}->SEEK( @_ );
}

sub tell {
    my $fh = shift;
    ${*$fh}->TELL( @_ );
}

sub mem {
    my $fh = shift;
    ${*$fh}->mem( @_ );
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

MemHandle - supply memory-based FILEHANDLE methods

B<DEPRECATED> - Please use L<IO::Scalar> from CPAN package L<IO::stringy> instead!

=head1 SYNOPSIS

    use MemHandle;
    use IO::Seekable;

    my $mh = new MemHandle;
    print $mh "foo\n";
    $mh->print( "bar\n" );
    printf $mh "This is a number: %d\n", 10;
    $mh->printf( "a string: \"%s\"\n", "all strings come to those who wait" );

    my $len = $mh->tell();  # Use $mh->tell();
                            # tell( $mh ) will NOT work!
    $mh->seek(0, SEEK_SET); # Use $mh->seek($where, $whence)
                            # seek($mh, $where, $whence)
                            # will NOT work!

    my $memory = $mh->mem();

    Here's the real meat:

    my $mh = new MemHandle;
    my $old = select( $mh );
    .
    .
    .
    print "foo bar\n";
    print "baz\n";
    &MyPrintSub();
    select( $old );

    print "here it all is: ", $mh->mem(), "\n";

=head1 DESCRIPTION

Generates inherits from C<IO::Handle> and C<IO::Seekable>. It provides
an interface to the file routines which uses memory instead.  See
perldoc IO::Handle, and perldoc IO::Seekable as well as L<perlfunc>
for more detailed descriptions of the provided built-in functions:

    print
    printf
    readline
    sysread
    syswrite
    getc
    gets

The following functions are provided, but tie doesn't allow them to be
tied to the built in functions.  They should be used by calling the
appropriate method on the MemHandle object.

    seek
    tell

call them like this:

    my $mh = new MemHandle();
    .
    .
    .
    my $pos = $mh->tell();
    $mh->seek( 0, SEEK_SET );

=head1 CONSTRUCTOR

=over 4

=item new( [mem] )

Creates a C<MemHandle>, which is a reference to a newly created symbol
(see the C<Symbol> package).  It then ties the FILEHANDLE to
C<MemHandle::Tie> (see L<perltie/"Tying FileHandles">).  Tied methods in C<MemHandle::Tie>
translate file operations into reads/writes into a string, which can
be accessed by calling C<MemHandle::mem>.

=back

=head1 METHODS

=over 4

=item seek( POS, WHENCE )

Sets the read/write position to WHENCE + POS.  WHENCE is one of
the constants which are available from IO::Seekable or POSIX:

    SEEK_SET # absolute position from the beginning.
    SEEK_CUR # offset from the current location.
    SEEK_END # from the end (POS can be negative).

=item tell()

Returns the current position of the mem-file, similar to the way tell
would.  (See L<perlfunc>).

=item mem( [mem] )

gets or sets the memory.  If called with a parameter, it copies it to
the memory and sets the position to be immediately after (so if you
write more to it, you append the string).  Returns the current value
of memory.

=back

=head1 NOTES

I don't have much time to contribute to this.  If you'd like to
contribute, please fork https://github.com/scr/cpan and send me a pull
request.

=head1 AUTHOR

"Sheridan C. Rawlins" <scr14@cornell.edu>

=head1 SEE ALSO

L<perl>.
L<perlfunc>.
L<perltie/"Tying FileHandles">.
perldoc IO::Handle.
perldoc IO::Seekable.
perldoc Symbol.

=cut
