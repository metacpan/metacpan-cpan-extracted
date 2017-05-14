# --8<--8<--8<--8<--
#
# Copyright (C) 2010 Smithsonian Astrophysical Observatory
#
# This file is part of Lua-API
#
# Lua is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package Lua::API;

use 5.008000;
use strict;
use warnings;
use Carp;

our @ISA = qw();

our $VERSION = '0.04';

use vars qw[ &COPYRIGHT &ENVIRONINDEX &ERRERR &ERRFILE &ERRMEM &ERRRUN
	     &ERRSYNTAX &GCCOLLECT &GCCOUNT &GCCOUNTB &GCRESTART
	     &GCSETPAUSE &GCSETSTEPMUL &GCSTEP &GCSTOP &GLOBALSINDEX
	     &HOOKCALL &HOOKCOUNT &HOOKLINE &HOOKRET &HOOKTAILRET
	     &MASKCALL &MASKCOUNT &MASKLINE &MASKRET &MINSTACK
	     &MULTRET &NOREF &REFNIL &REGISTRYINDEX &RELEASE
	     &TBOOLEAN &TFUNCTION &TLIGHTUSERDATA &TNIL
	     &TNONE &TNUMBER &TSTRING &TTABLE &TTHREAD
	     &TUSERDATA &VERSION_NUM &YIELD 
	  ] ;


sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Lua::constant not defined" if $constname eq 'constant';
    $constname = 'LUA_' . $constname;
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	## no critic (ProhibitNoStrict)
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

require XSLoader;
XSLoader::load('Lua::API', $VERSION);

#---------------------------------------------------------

# Perl only wrappers/replacements
{
    package Lua::API::State;

    # These functions use C's stdarg facility, which makes it impossible
    # to create a Perl interface to them.  Instead, Perl-ify them a bit.
    # They should be coded in XS. The functionality in Perl's sprintf
    # is a superset of what Lua's push[v]fstring does so this is not
    # exactly compatible.

    sub pushfstring {
	my $self = shift;
	my $fmt = shift;
	return $self->pushstring( sprintf( $fmt, @_ ) );
    }

    sub pushvfstring {
	my $self = shift;
	my $fmt = shift;
	return $self->pushstring( sprintf( $fmt, @_ ) );
    }

    sub error {

	my $self = shift;

	if ( @_ )
	{
	    my @caller = caller(1);
	    $caller[3] = join( '::', @caller[1,2]) if $caller[3] eq '(eval)';
	    $self->pushstring( $caller[3] . ': ' );
	    $self->pushvfstring( @_ );
	    $self->concat( 2 );
	}

	my $scalar;
	bless \$scalar,  "Lua::API::State::Error";
	die( \$scalar );
    }


    #---------------------------------------------------------

    # This is a pretty-much direct translation of lua_register and
    # luaL_register into Perl, but Perl-ified.

    # calling sequence is

    #   $L->register( $name, $f )      -> lua_register( L, name, f );
    #   $L->register( \%l )            -> luaL_register( L, "", l )
    #   $L->register( $libname, \%l )  -> luaL_register( L, libname, l )

    sub register {

	my ( $L ) = shift;

	# luaL_register; can't call it directly as it doesn't use
	# lua_register
	if ( (@_ == 1 || @_ == 2) && 'HASH' eq ref $_[-1] )
	{
	    my $l = pop;
	    my $libname = shift;

	    if (defined $libname)
	    {
		my $size = keys %$l;

		# check whether lib already exists
		$L->findtable( Lua::API::REGISTRYINDEX, "_LOADED", 1);
		$L->getfield(-1, $libname); # get _LOADED[libname]

		# not found?
		if (! $L->istable(-1))
		{
		    $L->pop(1);	# remove previous result

		    # try global variable (and create one if it does not exist)
		    if (defined $L->findtable( Lua::API::GLOBALSINDEX, $libname, $size) )
		    {
			$L->error( "name conflict for module '$libname'" );
		    }
		    $L->pushvalue( -1 );
		    $L->setfield( -3, $libname); # _LOADED[libname] = new table
		}
		$L->remove( -2 ); # remove _LOADED table
	    }

	    while ( my ( $name, $func ) = each %$l )
	    {
		$L->pushcclosure( $func, 0);
		$L->setfield( -2, $name);
	    }

	}

	# lua_register
	elsif ( @_ == 2 )
	{
	    $L->lua_register( @_ );
	}

	else
	{
	    croak( "Lua::APIState::register: incorrect parameters\n" );
	}


    }

}

#---------------------------------------------------------

1;
__END__


=head1 NAME

Lua::API - interface to Lua's embedding API

=head1 SYNOPSIS

  use Lua::API;


=head1 DESCRIPTION

B<Lua> is a simple, expressive, extension programming language that is
easily embeddable.  B<Lua::API> provides Perl bindings to Lua's
C-based embedding API.  It allows Perl routines to be called from Lua
as if they were written in C, and allows Perl routines to directly
manipulate the Lua interpreter and its environment.  It presents a
very low-level interface (essentially equivalent to the C interface),
so is aimed at developers who need that sort of access.

B<Lua::API> is not the first place to turn to if you need a simple, more
Perl-ish interface; for that, try B<Inline::Lua>, which takes a much
higher level approach and masks most of the underlying complexity in
communicating between Lua and Perl.  Unfortunately by hiding the
complexity, this approach also prevents full operability.  For
B<Inline::Lua> this is a necessary tradeoff, but it does mean that you
cannot create as tight an integration with Lua.


=head2 Translating from Lua's C interface to Lua::API

The B<Lua> C API is based upon the following structures: C<lua_State>,
C<lua_Buffer>, C<lua_Debug>, and C<luaL_Reg>.  C<lua_State> is by far
the most important, as it represents an instance of the Lua
interpreter.  Currently C<lua_State>, C<lua_Buffer>, and C<lua_Debug>
are supported as the Perl classes B<Lua::API::State>,
B<Lua::API::Buffer>, and B<Lua::API::Debug>. The functionality
provided by the C<luaL_Reg> object is provided in a more Perlish
fashion by B<Lua::API> and it is thus not exposed.

The B<Lua> C API also defines the following function interfaces:
C<lua_Alloc>, C<lua_CFunction>, C<lua_Reader>, C<lua_Writer>.  At
present, only C<lua_CFunction> is supported.  Any routine using the
other interfaces is not supported.

The B<Lua> C API consists of two sets of functions: the base set (via
F<lua.h> and F<lualib.h>) and the auxiliary set (via F<lauxlib.h>).
Functions manipulating C<lua_State> occur in both sets, while
functions manipulating C<lua_Debug> occur only in the base set and
functions manipulating C<lua_Buffer> appear only in the auxiliary set.

In B<Lua::API> the C function names are stripped of their prefixes
(C<lua_>, C<luaL_>), and made methods of B<Lua::API::State>,
B<Lua::API::Debug> and B<Lua::API::Buffer> classes, as appropriate.
Unfortunately, after stripping prefixes there are several name
collisions between the base and auxiliary functions; these are
discussed below.

=head2 Perl functions as CFunctions, Closures, and Hooks

Wherever the Lua API calls for a C<lua_CFunction> or a C<lua_Hook>, a
reference to a Perl function should be used.

B<Lua::API> uses trampoline functions to call the Perl functions.  In
most cases it is possible to transparently pass to the trampoline
function information about which Perl function to call. In some cases,
it is not.

=over

=item Hooks via C<sethook()>

Hooks are supported transparently.

=item CFunctions via C<register()> and C<pushcfunction()>

Perl functions which are passed to Lua via these methods are supported
by creating a C closure around the trampoline function and providing
the Perl function as an upvalue for the closure.  This should be
transparent to the caller.

=item CFunctions via C<cpcall()>

These are supported transparently.

=item CFunctions via C<pushcclosure()>

To support these, B<Lua::API> adds an extra upvalue containing the
Perl function to the closure (e.g. if the caller pushes C<n> upvalues
on the stack, this will be the C<n+1> upvalue).  Unfortunately, this
means that the C<getinfo()> method will report one more upvalue than
the caller has pushed onto the stack.

=back

=head2 C<lua.h> constants

C<lua.h> defines a number of constants.  They are available in the
C<Lua::API> namespace, with the C<LUA_> prefix removed
(e.g. C<Lua::API::REGISTRYINDEX>).  They are B<not> exported (either
implicitly or by request).

=head2 Lua C<error> and Perl C<die>

Lua's version of Perl's C<die> is C<error>.  In order to ensure that
Perl's stack handling isn't mucked about with when C<error> is called,
a call to B<Lua::API::State::error> is implemented as a call to C<die>
which throws an exception of class C<Lua::API::State::Error>.  When
returning to Lua, an exceptions are converted into a true call to
C<lua_error>.  This I<should> be transparent to the user.

Calls to C<die> from within code invoked by Lua are treated as calls
call to C<Lua::API::State::error>.

The implementation (and the format of the errors) will probably change
as B<Lua::API> matures.

=head2 Lua API routines which throw errors

Some of the Lua auxiliary API routines throw errors using
C<lua_error()>.  In order to protect Perl's runtime environment, these
are wrapped and then called using Lua's protected call facility.  Any
errors are translated into Perl exceptions of class
C<Lua::API::State::Error>; the actual Lua error object is left on the
Lua stack.  This results in an extra layer in the call stack, when
C<lua_error()> is called.

=head2 Using Lua::API

Because the Perl interface closely tracks the C interface, the Lua API
documentation serves for both.  The type of the first argument in the
C function determines to which Perl class its companion Perl method
belongs.  For example, if the first argument is a C<lua_State *>, it
is a method of the C<Lua::API::State> class.

There are some slight differences, however, which are noted here.

=head3 Lua::API::State

=head4 Constructors

The Lua API provides two constructors, C<lua_newstate> and
C<luaL_newstate>.  They differ in that C<lua_newstate> requires a
memory allocator while C<luaL_newstate> uses Lua's default allocator.
Specification of a memory allocator is currently not supported in
B<Lua::API>.  The constructor may be called as

  $L = Lua::API::State->new;
  $L = Lua::API::State->open;
  $L = Lua::API::State->newstate;

=head4 Destructors

B<Lua> uses the C<lua_close> function to destroy a C<lua_State>
object.  This is automatically called when a B<Lua::API::State>
object passes out of scope. Tt may also be explicitly invoked:

  $L->close;


=head4 Special handling of certain functions

=over

=item C<lua_pushfstring>, C<lua_vpushfstring>

These functions are emulated in Perl (as the C<pushfstring> and
C<vpushfstring> methods) using Perl's C<sprintf> function, which looks
to have a superset of the Lua routines' functionality.

=item C<lua_error>, C<luaL_error>

These two functions are combined into the C<error> method with the
following Perl to C mapping:

  $L->error;              -> lua_error( L );
  $L->error( $fmt, ... ); -> luaL_error( L, fmt, ... );

In the latter case it uses the emulated version of
C<lua_pushvfstring>.

=item C<lua_register>, C<luaL_register>

C<lua_register> registers a single Perl function with Lua.
C<luaL_register> opens a library.  These two functions are combined
into the C<register> method, with the following Perl to C mapping:

  $L->register( $name, $f );      -> lua_register( L, name, f );
  $L->register( \%l );            -> luaL_register( L, "", l )
  $L->register( $libname, \%l );  -> luaL_register( L, libname, l )

The C<%l> argument is a hash whose keys are the names of the functions
and whose values are references to Perl functions.

=item C<lua_checkstack>, C<luaL_checkstack>

These two routines are combined into the C<checkstack> method with
the following Perl to C mapping:

  $L->checkstack($extra);        -> lua_checkstack( L, extra );
  $L->checkstack($sz, $msg );    -> luaL_checkstack( L, sz, msg );

=item C<lua_getmetatable>, C<luaL_getmetatable>

These two routines have the same number of arguments with differing
second arguments: C<lua_getmetatable> takes a numerical argument,
while C<luaL_getmetatable> takes a string.  They are combined into the
C<getmetatable> method, which attempts to discern between them.  The
individual routines are also available under their C names.

=item C<lua_typename>, C<luaL_typename>

These two routines have the same calling conventions so it is not
possible to disambiguate the calls.  The B<Lua::API> C<typename>
method corresponds to C<lua_typename>.  Both routines are also
available under their C names.

=back

=head3 Lua::API::Debug

=head4 Constructor

B<Lua::API::Debug> objects are created using the C<new> method:

  $dbg = Lua::API::Debug->new;

=head4 Attributes

The public attributes of the object ( e.g. C<event>, C<name>, etc.)
are available via methods of the same name.  It is not possible to
change those attributes from the Perl interface.  (My reading of the
Lua API is that these should be read-only).

=head4 Destructor

There is no documented method for destroying a C<lua_Debug> object, so
while the Perl object cleans up after itself, it may leave Lua
allocated memory behind.


=head3 Lua::API::Buffer


=head4 Constructor

B<Lua::API::Buffer> objects are created using the C<new> method:

  $buf = Lua::API::Debug->new;

=head4 Attributes

There are no publically accessible attributes for this object.

=head4 Destructor

As with C<lua_Debug>, there is no documented method for destroying a
C<lua_Buffer> object, so while the Perl object cleans up after itself
it may leave Lua allocated memory behind.

=head1 EXAMPLES

The F<examples> directory in the B<Lua::API> distribution contains a
translation of the F<lua.c> front-end (distributed with Lua 5.1.4)
into Perl.

=head1 COMPATIBILITY

B<Lua::API> was designed and tested with Lua 5.1.4.

=head1 SEE ALSO

L<http:lua.org>, B<Inline::Lua>

=head1 AUTHOR

Diab Jerius, E<lt>djerius@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010, Smithsonian Astrophysical Observatory

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut
