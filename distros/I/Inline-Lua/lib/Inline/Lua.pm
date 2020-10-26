## no critic (RequireUseStrict)
package Inline::Lua;
$Inline::Lua::VERSION = '0.17';
## use critic (RequireUseStrict)
use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;
require Inline;
use Fcntl qw/:seek/;

our @ISA = qw(Inline);

$Inline::Lua::_undef = undef;

sub register {
    return {
	language    => 'Lua',
	aliases	    => [ qw/lua/ ],
	type	    => 'interpreted',
	suffix	    => 'luadat',
    };
}

sub validate { 
    my $o = shift;
    
    while (@_) {
	my ($key, $val) = splice @_, 0, 2;
	if (uc $key eq 'UNDEF') {
	    # Don't think I am stupid because I am going through those hoops to
	    # pass a reference correctly.  If I don't do it that way, an SvPVIV
	    # (with the ROK flag set!) is passed for some reason.
	    Inline::Lua->register_undef(\@$val), next if ref $val eq 'ARRAY';
	    Inline::Lua->register_undef(\%$val), next if ref $val eq 'HASH';
	    Inline::Lua->register_undef(\*$val), next if ref $val eq 'GLOB';
	    Inline::Lua->register_undef(\&$val), next if ref $val eq 'CODE';
	    Inline::Lua->register_undef($val);
	}
    }
    return;
}

sub build {
    my $o = shift;
    my $code = $o->{API}{code};
    my $caller = $o->{API}{pkg};
    
    my @funcs;
    while ($code =~ /((?:local)?\s*function\s*(\w+)\s*\((.*?)\)(.*?)end)/gs) {
	my $name = $2;
	
	my $body = my $proto = $1;

	# lua_load is not smart enough to compile whole functions 
	# but only function bodies
	#$body	=~ s/\s*function\s*$name\s*\(.*?\)\s*//s;
	#$body	=~ s/\s*end\s*$//g;
	
	$proto	=~ s/\s*function\s*$name\s*\((.*?)\).*/$1/s;
	
	push @funcs, { $name => { body  => $body,
				  proto => [ split /\s*,\s*/, $proto ] } };
    }
    
    my $lua = $o->{ILSM}{lua} = Inline::Lua->interpreter;
    
    my $path = "$o->{API}{install_lib}/auto/$o->{API}{modpname}";
    my $obj = $o->{API}{location};
    if (! -d $path) {
	$o->mkpath($path);
	$lua->compile($o->{API}{code}, "$obj.bc", 1);
    } 
     
    my $lua_fh;
    open $lua_fh, '>', $obj or croak "Can't open $obj for output: $!"; ## no critic (InputOutput::RequireBriefOpen)
    print $lua_fh <<EOCODE;
package $caller;
require Inline::Lua;
EOCODE
    
    for (@funcs) {
	my ($name, $func) = each %$_;
	print $lua_fh <<EOCODE;
sub $name {
    \$lua->call(\"$name\", @{[ scalar grep $_ ne '...', @{ $func->{proto} } ]}, \@_);
}
EOCODE
    }

    print $lua_fh <<EOCODE;
1;
EOCODE
    close $lua_fh;
    return;
}

sub load {
    my $o = shift;
    my $obj = $o->{API}{location};
    {
	local $/;
        my $bc_fh;
	open $bc_fh, '<', $obj . '.bc'
	    or die "Bytecode mysteriously vanished: $!";
	my $bc = <$bc_fh>;
        close $bc_fh;
	($o->{ILSM}{lua} = Inline::Lua->interpreter)->compile($bc, "", 0);
    }
    my $lua_fh;
    open $lua_fh, '<', $obj or croak "Can't open $obj for input: $!"; ## no critic (InputOutput::RequireBriefOpen)
    {
	local $/;
	my $lua = $o->{ILSM}{lua};
	my $code = <$lua_fh>;
	eval <<EOCODE; ## no critic
my \$lua = Inline::Lua->interpreter;
$code;
EOCODE
    }
    close $lua_fh;
    return;
}
  
sub create_func_ref {
    my ($lua, $func) = @_;
    return sub { $lua->call($func, -1, @_) };
}

sub DESTROY { }

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Inline::Lua::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Inline::Lua', $Inline::Lua::VERSION);

package # hide from PAUSE
    Inline::Lua::Boolean;

use warnings;
use strict;

use overload
	fallback	=> undef,
	'0+'		=> \&tonumber,
	'+'		=> \&add,
	'-'		=> \&subtract,
	'<=>'		=> \&compare,
	'cmp'		=> \&compare;


sub TRUE  { return __PACKAGE__->new(1) }
sub FALSE { return __PACKAGE__->new(0) }


sub new {
        my $class       = shift;
        my $bool        = (shift)? 1 : 0;
        my $self        = bless \$bool, $class;

        return $self;
} # new


sub add {
	my $self	= shift;
	my $rop		= shift;

	return int($self) + $rop;
} # add


sub subtract {
	my $self	= shift;
	my $rop		= shift;
	my $swap	= shift;

	return ($swap)? $rop - int($self) : int($self) - $rop;
} # subtract


sub compare {
	my $self	= shift;
	my $rop		= shift;
	my $swap	= shift;

	return ($swap)? ($rop <=> int($self)) : (int($self) <=> $rop);
} # compare


sub tonumber {
	my $self	= shift;

	return (${$self})? 1 : 0;
} # tonumber


1;

=pod

=encoding UTF-8

=head1 NAME

Inline::Lua - Perl extension for embedding Lua scripts into Perl code

=head1 VERSION

version 0.17

=head1 SYNOPSIS

    use Inline 'Lua';
    print "The answer to life, the universe and everything is ", answer(6, 7), "\n";

    __END__
    __Lua__
    function answer (a, b)
	return a*b 
    end

=head1 DESCRIPTION

Inline::Lua allows you to write functions in Lua. Those of you who are not yet
familiar with Lua should have a cursory glance at L<http://www.lua.org/> to get
a taste of this language. In short:

Lua was designed to be embedded into other applications and not so much as a
language on its own.  However, despite its small set of language features, it
is an extremely powerful and expressive language. Its strong areas are an
elegant and yet concise syntax, good overall performance and a beautiful
implementation of some concepts from the world of functional programming.

=head1 USING Inline::Lua

Lua code can be included in the usual Inline style. Pass it as string at C<use> time:

    use Inline Lua => 'function pow (a, b) return a^b end';
    print pow(2, 8);  # prints 256

Heredocs may come in handy for that:

    use Inline Lua => <<EOLUA;
    function pow (a, b)
	return a^b
    end
    EOLUA

    print pow(2, 8);

Or append it to your script after the C<__END__> token:

    use Inline 'Lua';

    print pow(2, 8)

    __END__
    __Lua__
    function pow (a, b)
	return a^b 
    end

All of those are equivalent.

=head2 Exchanging values with Lua functions

Lua datatypes map exceptionally well onto Perl types and vice versa. Lua knows
about eight distinct types:

=over 4

=item * B<nil>

This is Perl's C<undef>

=item * B<number>

A Perl scalar with a, guess what, number in it.

=item * B<string>

A Perl scalar with a string in it.

=item * B<function>

Lua functions act as first class data types. The Perl equivalent is a
code-reference.

=item * B<userdata>

Lua being an embeddable language uses this one to handle generic C types. As of
now, this is not yet supported by Inline::Lua.

=item * B<thread>

Used to implement coroutines. Not yet handled by Inline::Lua

=item * B<table>

Lua tables act as arrays or hashes depending on what you put into them.
Inline::Lua can handle that transparently.

=back

=head1 PASSING VALUES TO LUA FUNCTIONS

Whenever you call a Lua function, Inline::Lua looks at the arguments you passed
to the function and converts them accordingly before executing the Lua code. 

=head2 Plain Perl scalars

Scalars either holding a number, a string or C<undef> are converted to the
corresponding Lua types. Considering that those are all very basic types, this
is not a very deep concept:

    use Inline Lua => <<EOLUA;
    function luaprint (a)
	io.write(a)
    end
    EOLUA
    
    lua_print("foobar");
    lua_print(42);

Care must be taken with C<undef>. Lua is less forgiving than Perl in this
respect. In particular, C<nil> is not silently transformed into a useful value and
you'll get a fatal error from Lua when you try

    lua_print(undef);

Inline::Lua offers some means to deal with this problem. See L<"DEALING WITH
UNDEF AND NIL"> further below.

=head2 Array and hash references

Those are turned into Lua tables:

    use Inline Lua => <<EOLUA;
    function print_table (t)
      for k, v in pairs(t) do
        print(k, v)
      end
    end
    EOLUA
    
    print_table( [1, 2, 3] );
    print_table( { key1 => 'val1',
                   key2 => 'val2' } );

This should print:

    array:
    1       1
    2       2
    3       3
    hash:
    key1    val1
    key2    val2

Nested Perl arrays are handled as well:

    print_table( [1, 2, 3, { key1 => 'val' } ] );

will result in

    1       1
    2       2
    3       3
    4       table: 0x8148128

=head2 Function references

That's the real interesting stuff. You are allowed to call Lua functions with
function references as arguments and the Lua code will do the right thing:

    use Inline Lua => EOLUA
    function table_foreach (func, tab)
        for k, v in pairs(tab) do
          func(k, v)
        end
    end
    EOLUA

    sub dump {
        my ($key, $val) = @_;
	print "$key => $val\n";
    }
    
    table_foreach( \&dump, { key1 => 1, key2 => 2 } );

Here's a bit of currying. The Lua code calls the code-reference passed to it.
This code-reference itself returns a reference to a Perl functions which eventually
is triggered by Lua and its result is printed:

    use Inline Lua => <<EOLUA;
    function lua_curry (f, a, b) 
	local g = f(a)
	io.write( g(b) )
	-- or simply: io.write( f(a)(b) )
    end
    EOLUA

    sub curry {
	my $arg = shift;
	return sub { return $arg * shift };
    }

    lua_curry( \&curry, 6, 7);	# prints 42

It should be obvious that you are also allowed to pass references to anonymous functions, so

    lua_curry( sub { my $arg = shift; ... }, 6, 7);

will work just as well.

=head2 Filehandles

From a technical point of view, Lua doesn't have a distinct type for that. It uses
the I<userdata> type for it. If you pass a reference to a filehandle to your Lua 
function, Inline::Lua will turn it into the thingy that Lua can deal with:

    use Inline Lua => <<EOLUA;
    function dump_fh (fh)
	for line in fh:lines() do
	    io.write(line, "\n")
	end
    end
    EOLUA

    open F, "file" or die $!;
    dump_fh(\*F);

=head2 Things you must not pass to Lua

You must not pass a reference to a scalar to any Lua function. Lua doesn't know
about call-by-reference, hence trying it doesn't make much sense. You get a
fatal runtime-error when you try for instance this:

    function_defined_in_lua (\$var);

=head1 RETURNING VALUES FROM LUA FUNCTIONS

Returning stuff from your inlined functions is as trivial as passing them into
them.

=head2 Numbers, strings, nil and boolean values

Those can be translated 1:1 into Perl:

    use Inline Lua => <<EOLUA;
    function return_basic ()
	local num = 42
	local str = "twenty-four"
	local boo = true
	return num, str, boo, nil
    end
    EOLUA

    my ($num, $str, $boo, $undef) = return_basic();

=head2 Tables

Whenever you return a Lua table, it gets returned as either a reference to a
hash or a reference to an array. This depends on the values in the table. If all
keys are numbers, then an array-ref is returned. Otherwise a hash-ref:

    use Data::Dumper;
    use Inline Lua => <<EOLUA;
    function return_tab () 
        local ary  = { 1, 2, 3, [5] = 5 }
        local hash = { 1, 2, 3, key = 5 }
        return ary, hash
    end
    EOLUA

    my ($ary, $hash) = return_tab();
    print Dumper $ary;
    print Dumper $hash;

    __END__
    $VAR1 = [
              '1',
              '2',
              '3',
              undef,
              '5'
            ];
    $VAR1 = {
              '1' => '1',
              '3' => '3',
              '2' => '2',
              'key' => 'val'
            };

A couple of things worthy mention: Lua table indexes start at 1 as opposed to 0
in Perl. Inline::Lua will substract 1 from the index if the table is returned
as an array so your Perl array will be 0-based. This does not happen for tables
that get returned as a hash-reference as you can see in the above example.

Another thing you have to be aware of is potential holes in the array. You can
create a Lua table where only the, say, 10000th element is set. Since 10000 is
a number, it gets returned as an array. This array naturally will have 9999
undefined elements. In this case it might be better to forcefully turn this key
into a string:

    local ary = { [ tostring(10000) ] = 1 }

The tables you return can be arbitrarily deeply nested. The returned Perl
structure will then also be nested.

What you cannot do is return a Lua table which uses values other than strings
or numbers as keys. In Lua, a key can be any object, including a table, a
function or whatever. There is no sensible way to mimick this behaviour in Perl
so you will get a runtime error if you try something like this:

    return { [{1, 2, 3}] = 1 }

There is no limitation on the values you put into a Lua table, though.

=head2 Functions

If your Lua function returns a function, the function is turned into a Perl function
reference. If you are tired of having Perl calulcate the n-th Fibonacci number, let 
Lua do the hard work. This snippet below shows how a Lua function can return a Fibonacci
number generator to Perl:

    use Inline Lua => <<EOLUA;
    function fib ()
        local f
        f = function (n)
            if n < 2 then return 1 end
            return f(n-1) + f(n-2)
        end
        return f
    end
    EOLUA

    my $fib = fib();
    print $fib->(11);
    __END__
    144

You can get as fancy as you want. Return a Lua function that itself returns a
Lua function that returns another Lua function and so on. There should be no
limitations at all.

=head2 Filehandles

Just as you can pass filehandles to Lua functions, you may also return them:

    use Inline Lua => <<EOLUA;
    function open_file (filename)
	return io.open(filename, "r")
    end
    EOLUA

    my $fh = open_file(".bashrc");
    while (<$fh>) {
	...
    }

It's a fatal error if your Lua code tries to return a closed filehandle.

=head1 DEALING WITH UNDEF AND NIL

You can change C<undef>'s default conversion so that Inline::Lua wont transform it to C<nil>
when passing the value to Lua:

    use Inline Lua	=> 'DATA',	# source code after the __END__ token
	       Undef	=> 0;

With the above, every C<undef> value is turned into a Lua number with the value 0. Likewise

    use Inline Lua      => 'DATA', 
	       Undef	=> '';

This will turn C<undef> into the empty string. Any valid Perl scalar can be
specified for I<Undef>, this includes references to hashes, arrays, functions
etc. A basic example:

    use Inline Lua   => 'DATA',
	       Undef => 'Undefined value';
    
    print_values(1, 2, 3, undef, 4, 5);

    __END__
    __Lua__
    function print_values (...)
        for k, v in pairs {...} do
            print(k, v)
        end
    end

This would come out as

    1       1
    2       2
    3       3
    4       Undefined value
    5       5
    6       6

Sometimes however it is important to return a real C<nil> to Lua.  Inline::Lua
provides a Perl value which is always converted to C<nil>:
C<$Inline::Lua::Nil>.

=head1 LUA FUNCTION PROTOTYPES

Lua functions have prototypes. When compiling those functions to bytecode,
Inline::Lua looks at their prototype. When calling one of those functions
later, it makes sure that the function arguments are padded with C<undef> if
you supply less arguments than mentioned in the prototype:

    use Inline Lua => <<EOLUA;
    function foo (a, b, c, ...)
	print(a, b, c)
    end
    EOLUA

    foo(1);	# actually: foo(1, undef, undef)

Those padded C<undef>s are also handled accordingly to the value of I<Undef>.
Also note that C<...> in a prototype is never padded (as you can see in the above).

=head1 LUA SCRIPTS AS INLINE CODE

You are allowed to provide whole Lua scripts in your Inline section. Anything outside
a function is then run at compile-time:

    use Inline 'Lua';

    __END__
    __Lua__
    print(1, 2)

Moreover, Lua scripts may return values to their caller. You can get these values at
any point with C<"Inline::Lua->main_returns">:

    use Inline 'Lua';

    my @ret = Inline::Lua->main_returns;

    __END__
    __Lua__

    print("I return a list of values")
    return 1, 2, 3

Note that a Lua script's return value is only retrieved once at compile-time. Hence
something like this might B<not> do what you expect:

    use Inline 'Lua';

    print join "+", Inline::Lua->main_returns;
    
    luafunc();
    
    print "\n";
    print join "+", Inline::Lua->main_returns;

    __END__
    __Lua__
    a = 1
    b = 2
    
    function luafunc ()
	a = a + 1
	b = b + 1
    end

    return a, b

This will print

    1+2
    1+2

and not

    1+2
    2+3

as you might expect.

=head1 BUGS

There must be some. My first suspicion is memory leaks that may hide somewhere in the code.
Checking for memory leaks is on my agenda for the next release.

Other than that, you might enjoy an occasional segfault.

If you encounter any of the above, please report it to me.

=head1 TODO

=over 4

=item * Check for memory leaks.

=item * Find a smart way to handle objects elegantly.

=item * Look closer at the I<thread> type and figure out whether a sensible conversion exists.

=item * Improve error messages. So far you get messages such as

    Attempt to pass unsupported reference type (SCALAR) to Lua at (eval 3) line 6.

=item * In general: Have Inline::Lua croak less often.

=back

=head1 FAQ

=head2 What do I do if I want to sandbox my code?

Many solutions exist for this, and determining which one to use depends on
your needs.  Please consult http://lua-users.org/wiki/SandBoxes for more
information.

=head1 SEE ALSO

L<Inline>

Lua's home can be found at L<http://www.lua.org/>.

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/hoelzro/inline-lua/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__END__

# ABSTRACT: Perl extension for embedding Lua scripts into Perl code

