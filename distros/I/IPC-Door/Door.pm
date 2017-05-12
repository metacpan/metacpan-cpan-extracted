# $Id: Door.pm 37 2005-06-07 05:50:05Z asari $

=head1 NAME

IPC::Door - Interface to Solaris (>= 2.6) Door library

=head1 SYNOPSIS

The server script:

    use IPC::Door::Server;
    use Fcntl;
    my  $door = "/path/to/door";
    my  $dserver = new IPC::Door::Server($door, &mysub);
    while (1) {
        die "$door disappeared: $!\n" unless IPC::Door::is_door($door);
        sysopen( DOOR, $door, O_WRONLY ) || die "Can't write to $door: $!\n";
        close DOOR;
        select undef, undef, undef, 0.2;
    }

    sub mysub {
        my $arg = shift;
        # do something
        my $ans;
        return $ans;
    }

The client script:

    use IPC::Door::Client;
    use Fcntl;
    my  $door = "/path/to/door";
    my  $dclient = new IPC::Door::Client($door);
    my  $data;
    my  $answer = $client->call($data, O_RDWR);

=cut

package IPC::Door;

use 5.006;
use strict;
use warnings;
use Carp;

use POSIX qw[ :fcntl_h uname ];

# Make sure we're on an appropriate version of Solaris
my ( $sysname, $release ) = ( POSIX::uname() )[ 0, 2 ];
my ( $major, $minor ) = split /\./, $release;
die "This module requires Solaris 2.6 and later.\n"
  unless $sysname eq 'SunOS' && $major >= 5 && $minor >= 6;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw(
          DOOR_ATTR_MASK
          DOOR_BIND
          DOOR_CALL
          DOOR_CREATE
          DOOR_CREATE_MASK
          DOOR_CRED
          DOOR_DELAY
          DOOR_DESCRIPTOR
          DOOR_EXIT
          DOOR_HANDLE
          DOOR_INFO
          DOOR_INVAL
          DOOR_IS_UNREF
          DOOR_KI_CREATE_MASK
          DOOR_LOCAL
          DOOR_PRIVATE
          DOOR_QUERY
          DOOR_REFUSE_DESC
          DOOR_RELEASE
          DOOR_RETURN
          DOOR_REVOKE
          DOOR_REVOKED
          DOOR_UCRED
          DOOR_UNBIND
          DOOR_UNREF
          DOOR_UNREF_ACTIVE
          DOOR_UNREF_MULTI
          DOOR_UNREFSYS
          DOOR_WAIT
          )
    ],

    # door attributes (including "miscellaneous" ones)
    'attr' => [
        qw(
          DOOR_ATTR_MASK
          DOOR_CREATE_MASK
          DOOR_DELAY
          DOOR_IS_UNREF
          DOOR_KI_CREATE_MASK
          DOOR_LOCAL
          DOOR_PRIVATE
          DOOR_REFUSE_DESC
          DOOR_REVOKED
          DOOR_UNREF
          DOOR_UNREF_ACTIVE
          DOOR_UNREF_MULTI
          )
    ],

    # attributes for door_desc_t data
    'attr_desc' => [
        qw(
          DOOR_DESCRIPTOR
          DOOR_HANDLE
          DOOR_RELEASE
          )
    ],

    # constant door descriptors
    'desc' => [
        qw(
          DOOR_INVAL
          DOOR_QUERY
          )
    ],

    # errors
    'errors' => [
        qw(
          DOOR_EXIT
          DOOR_WAIT
          )
    ],

    # door operation subcodes
    'subcodes' => [
        qw(
          DOOR_BIND
          DOOR_CALL
          DOOR_CREATE
          DOOR_CRED
          DOOR_INFO
          DOOR_RETURN
          DOOR_REVOKE
          DOOR_UCRED
          DOOR_UNBIND
          DOOR_UNREFSYS
          )
    ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

sub AUTOLOAD {

    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ( $constname = $AUTOLOAD ) =~ s/.*:://;
    croak "&IPC::Door::constant not defined" if $constname eq 'constant';
    my ( $error, $val ) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';

        # Fixed between 5.005_53 and 5.005_61
        #XXX	if ($] >= 5.00561) {
        #XXX	    *$AUTOLOAD = sub () { $val };
        #XXX	}
        #XXX	else {
        *$AUTOLOAD = sub { $val };

        #XXX	}
    }
    goto &$AUTOLOAD;
}

our $VERSION = '0.11';

require XSLoader;
XSLoader::load( 'IPC::Door', $VERSION );

=head1 ABSTRACT

IPC::Door is a Perl extension to the door library present in
Solaris 2.6 and later.

=cut

=head1 COMMON CLASS METHODS

=head2 new

The method C<new> initializes the object, taking a mandatory argument
C<$path>.
Each C<IPC::Door::*> object is thus associated with a door
through which it communicates with a server (if the object is a
C<::Client>) or a client (if the object is a C<::Server>).

In addition, the C<IPC::Door::Server> object requires a reference to a
code block C<&mysub>, which will be a part of the server process upon
compilation.
See L<IPC::Door::Server>.

=cut

sub new {
    my ( $this, $path, $subref, $attr ) = @_;
    croak("Too few arguements for the 'new' method.\n") unless defined($path);
    my $class = ref($this) || $this;
    my $self = { 'path' => $path };

    if ( $class eq 'IPC::Door::Server' ) {
        $attr = 0 unless defined( $attr );
        unless ( defined($subref) ) {
            carp "Too few arguments for the 'new' method.\n";
        }
        bless $self, $class;
        $self->{'callback'} = $subref;
        die "Can't create door to $path: $!\n"
          unless $self->__create( $path, $subref, $attr );
    }
    elsif ( $class eq 'IPC::Door::Client' ) {
        bless $self, $class;
    }

    return $self;
}

=head2 is_door

    $dserver->is_door;

    IPC::Door::is_door('/path/to/door');

Subroutine C<is_door> can be called either as an object method or
as a subroutine.

If the former, it determines if the path name assoicated with the object
is a door.
In the latter case, it determines if the path name passed to it is a
door.

=cut

# Note that is_door() is implemented in C.

=head2 info

    my ($target, $attr, $uniq) = IPC::Door::info($door);

Subroutine C<info> takes the path to a door and return array
C<($target, $attributes, $uniquifer)>.
C<$target> is the server process id that is listening through the door.
C<$attributes> is the integer that represents the attributes of the door
(see L<Door attributes>),
and C<$uniquifer> is the system-wide unique number associated with the
door.

=head3 Door attributes

When testing for a door's attributes, it is convenient to import
some symbols:

C<use IPC::Door qw( :attr );>

This imports symbols
C<DOOR_ATTR_MASK>
C<DOOR_CREATE_MASK>
C<DOOR_DELAY>
C<DOOR_IS_UNREF>
C<DOOR_KI_CREATE_MASK>
C<DOOR_LOCAL>
C<DOOR_PRIVATE>
C<DOOR_REVOKED>
C<DOOR_UNREF>
C<DOOR_UNREF_ACTIVE>
C<DOOR_UNREF_MULTI>

Note that not all symbols are available in all versions of Solaris.

=cut

sub info ($) {
    my $self = shift;
    my $path = ( ref($self) =~ m/^IPC::Door::(Server|Client)$/ )
    ? $self->{'path'}  # We are called as an object method
    : $self;           # Called as in 'IPC::Door::info($path)'

    return __info($path, ref($self));
    # When we are called as an IPC::Door::Server method, we want to
    # pass DOOR_QUERY as the file descriptor to door_info().
    # (This is supposed to work, according to Stevens, but it doesn't
    # seem to.)

}

sub DESTROY {
    my $self = shift;

}

1;    # end of IPC::Door

__END__

=head1 KNOWN ISSUES

=over 4

=item 1.  Incomaptible with threaded perl

I know this module does not work nicely if perl was configured with
C<-Dusethreads> option.
I know that the precompiled package from L<http://www.blastwave.org> has
this option set.
I am not sure about the one from L<http://www.sunfreeware.com>.

=item 2.  Compatibility with other door clients and servers

The doors created by C<IPC::Door::Server> evaluates the passed data in the
scalar context before passing it to the door server.  If you want to
pass complex data structures, use the L<Storable> module, which is
standard as of Perl 5.8.0.

Data an C<IPC::Door::Server> object returns are probably incomprehensible and
useless for non-C<IPC::Door::Client> processes.  You can read the source
to find out exactly what are passed around, but it might not be worth
your while to do that, when you can simply use C<IPC::Door::Client>.
(And of course, I might change the internal data structure in the
future.)

Conversely, C<IPC::Door::Client> can read data from doors created by
non-C<IPC::Door::Server> processes, but it is entirely up to the
C<IPC::Door::Client> process to make sense of what's read.

=item 3.  Some C<door_*> routines not implemented

Some door library routines
C<door_bind>, C<door_revoke>, C<door_server_create>,
and C<door_unbind> still need to be implemented.
These routines contribute to custom door server creation, which may be
too complicated and unnecessary for this module's needs; if such a fine
control over the server creation process is required, perhaps you should
be writing your utility in C!
If you are really interested in this sort of thing, contact the author.

C<door_info> is only partially implemented.

=item 4.  Incomplete error checking

There should be more robust error checking and more friendly error
messages throughout.

=item 5.  Limited testing

C<IPC::Door> has been tested on Solaris 8 (with Sun Workshop compiler),
9 (with gcc 3.3), and 10 (with gcc 4.0.0) (all on SPARC).

I need more testing on following configurations (both SPARC and x86
unless otherwisse noted):

=over 4

=item *

Solaris 9 and 10 with Sun ONE Studio compiler (or whatever Sun calls its
C compiler these days).

=item *

64-bit perl executable.

=item *

Threaded perl.  (See above.)

=item *

Solaris 10 on x86.

=back

Please let me know if you can help me test the module on these
configurations.

=item 6.  A little inconsistent XS code

I'm still a beginner at XS (some may argue also at Perl), so the code,
especially the XS portion, can be improved.
Any suggestions are welcome.

=item 7.  Unicode compatibility

In my limited testing, I found that this module has difficulty dealing
with Unicode data.

=back

=head1 SEE ALSO

L<IPC::Door::Client>, L<IPC::Door::Server>

door_bind(3DOOR) (L<http://docs.sun.com/db/doc/817-0697/6mgfsdh3m?a=view>),

door_call(3DOOR) (L<http://docs.sun.com/db/doc/817-0697/6mgfsdh3n?a=view>),

door_create(3DOOR) (L<http://docs.sun.com/db/doc/817-0697/6mgfsdh3n?a=view>),

door_cred(3DOOR) (L<http://docs.sun.com/db/doc/817-0697/6mgfsdh3p?a=view>),

door_info(3DOOR) (L<http://docs.sun.com/db/doc/817-0697/6mgfsdh3q?a=view>),

door_return(3DOOR) (L<http://docs.sun.com/db/doc/817-0697/6mgfsdh3r?a=view>),

door_revoke(3DOOR) (L<http://docs.sun.com/db/doc/817-0697/6mgfsdh3s?a=view>),

door_server_create(3DOOR) (L<http://docs.sun.com/db/doc/817-0697/6mgfsdh3t?a=view>),

door_ucred(3DOOR) (L<http://docs.sun.com/app/docs/doc/816-5171/6mbb6dcnk?a=view>),

door_unbind(3DOOR) (L<http://docs.sun.com/db/doc/817-0697/6mgfsdh3u?a=view>),

I<UNIX Network Programming Volume 2: Interprocess Communications>
(L<http://www.kohala.com/start/unpv22e/unpv22e.html>)

I<Solaris Internals: Core Kernel Architecture>
(L<http://www.solarisinternals.com>)

=head1 AUTHOR

ASARI Hirotsugu <asarih at cpan dot org>

(L<http://www.asari.net/perl>)

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2005 by ASARI Hirotsugu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
