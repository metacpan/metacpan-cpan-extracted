package Meow;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.22';

# Store specs for use after JIT compilation (for inheritance)
# This is accessed from XS via get_hv("Meow::SPECS", ...)
our %SPECS;

require XSLoader;
XSLoader::load('Meow', $VERSION);

1;

__END__

=encoding UTF-8

=head1 NAME

Meow - Object ฅ^•ﻌ•^ฅ Orientation

=head1 VERSION

Version 0.22

=cut

=head1 SYNOPSIS

This module is experimental. Many basic features do not yet exist.

	package Cat;

	use Meow;
	use Basic::Types::XS qw/Str Num/;

	ro name => Str;

	rw age => Default(Num, 0);

	make_immutable;

	1;

...

	package Siberian;

	use Meow;

	extends qw/Cat/;

	make_immutable;

	1;

...

	use Siberian;
	BEGIN { Meow::import_accessors("Siberian", name => "cat_name", age => "cat_age"); }

	my $cat = Siberian->new(
		name => 'Simba',
		age => 10
	);

	print cat_name $cat; # Simba
	print cat_age $cat; # 10;

	$cat->age(11);

=head1 DESCRIPTION

Meow provides a fast, minimalist object system in XS, supporting:

=over 4

=item * Read-write (C<rw>) and read-only (C<ro>) attributes

=item * Attribute specification with a Type, C<Default>, C<Coerce>, C<Trigger>, and C<Builder>

=item * Multiple inheritance via C<extends>

=item * Perl-style constructor (C<new>)

=back

=head1 EXPORTS

=head2 rw $name, $spec

Defines a read-write attribute.

=head2 ro $name, $spec

Defines a read-only attribute.

=head2 Default $spec, $value

Sets a default value for an attribute.

=head2 Coerce $spec, $coderef

Sets a coercion coderef for an attribute.

=head2 Trigger $spec, $coderef

Sets a trigger coderef to be called when the attribute is set.

=head2 Builder $spec, $coderef

Sets a builder coderef for lazy attribute construction.

=head2 extends @parents

Adds one or more parent classes to C<@ISA> and copies their attribute specs.

=head2 new %args

Constructs a new object, applying defaults, coercions, triggers, and builders as specified.

=head2 slot $package, $attr_name

Returns the numeric slot index for an attribute in a package. Returns -1 if the
attribute is not found.

    my $NAME_IDX = slot('Cat', 'name');
    my $name = $cat->[$NAME_IDX];

=head2 import_accessors $class, @attrs

Exports accessor functions to the caller's namespace for ultra-fast inline op access.
When called at compile time (in a C<BEGIN> block), accessor calls are replaced with
custom ops that bypass XS call overhead entirely.

B<When class is in the same file:>

    BEGIN {
        package Cat;
        use Meow;
        ro name => undef;
        ro age => undef;
        make_immutable;
    }
    
    BEGIN { Meow::import_accessors("Cat"); }
    
    my $cat = Cat->new(name => "Whiskers", age => 3);
    print name($cat);  # Inline op

B<When class is in a separate file (Cat.pm):>

    use Cat;  # 'use' runs at compile time, so Cat is available
    BEGIN { Meow::import_accessors("Cat"); }
    
    my $cat = Cat->new(name => "Whiskers");
    print name($cat);  # Inline op

B<Import specific accessors only:>

    use Cat;
    BEGIN { Meow::import_accessors("Cat", qw/name/); }  # Only imports 'name'

B<Aliasing accessors:>

    use Cat;
    use Dog;
    BEGIN { 
        Meow::import_accessors(
            "Cat", name => "cat_name", age => "cat_age",
            "Dog", name => "dog_name"
        ); 
    }
    
    print cat_name($cat);  # Aliased accessor
    print dog_name($dog);

B<Multiple classes:>

    use Cat;
    use Dog;
    BEGIN { Meow::import_accessors("Cat", "Dog"); }  # Import all from both

B<IMPORTANT:> The C<import_accessors> call must be in a C<BEGIN> block I<after>
the class is available (either via C<use> or a preceding C<BEGIN> block). 
If called at runtime, the accessors will still work but without the inline 
op optimization.

=head2 Slot Variables

When C<make_immutable> is called, uppercase read-only package variables are 
automatically created for each attribute's slot index:

    package Cat {
        use Meow;
        ro name => Str;
        ro age => Int;
        make_immutable;  # Creates $Cat::NAME, $Cat::AGE
    }
    
    # Direct slot access - 43M ops/sec (vs 25M for ->name)
    my $n = $cat->[$Cat::NAME];

=head2 Inline Op Example

    use strict;
    use warnings;
    
    BEGIN {
        package Point;
        use Meow;
        ro x => ();
        ro y => ();
        make_immutable;
    }
    
    BEGIN { Meow::import_accessors("Point"); }
    
    my $p = Point->new(x => 10, y => 20);
    
    # Inline op access - maximum speed
    print x($p), ", ", y($p);  # 63M accessor ops/sec

=head2 Direct Slot Access Example

    use strict;
    use warnings;
    no warnings 'once';  # Meow creates variables at runtime
    
    package Point {
        use Meow;
        ro x => ();
        ro y => ();
        make_immutable;  # Creates $Point::X, $Point::Y
    }
    
    # Standard access - clean API
    my $p = Point->new(x => 10, y => 20);
    print $p->x;  # 27M accessor ops/sec
    
    # Direct slot access 
    print $p->[$Point::X];  # 54M accessor ops/sec

=head1 BENCHMARK

	{
		package Foo::Mouse;

		use Mouse;
		use Types::Standard qw/Str Num/;

		has one => (
			is => 'ro',
			isa => Str,
			default => sub { 100 },
		);

		has two => (
			is => 'ro',
			isa => Num,
			default => sub { 200 },
		);

		1;
	}

	{
		package Foo::Extends::Mouse;

		use Mouse;
		extends qw/Foo::Mouse/;

		1;
	}


	{
		package Foo::Moo;

		use Moo;
		use Types::Standard qw/Str Num/;

		has one => (
			is => 'ro',
			isa => Str,
			default => sub { 100 },
		);

		has two => (
			is => 'ro',
			isa => Num,
			default => sub { 200 },
		);

		1;
	}

	{
		package Foo::Extends::Moo;

		use Moo;
		extends qw/Foo::Moo/;

		1;
	}

	{
		package Foo::Meow;
		use Meow;
		use Basic::Types::XS qw/Str Num/;

		ro one => Default(Str, 100);

		ro two => Default(Num, 200);

		make_immutable;

		1;
	}


	{
		package Foo::Extends::Meow;

		use Meow;
		extends qw/Foo::Meow/;

		make_immutable;

		1;
	}

	{
		package Foo::Marlin;
		use Types::Common -lexical, qw/Int/;
		use Marlin
			'one' => { isa => Int, default => 100 },
			'two' => { isa => Int, default => 200 };

		1;
	}


	{
		package Foo::Extends::Marlin;

		use Marlin
			-extends => [qw/Foo::Marlin/];

		1;
	}

	my $ONE = $Foo::Extends::Meow::ONE;
	my $TWO = $Foo::Extends::Meow::TWO;

	BEGIN { Meow::import_accessors("Foo::Extends::Meow"); }

	my $r = timethese(-5, {
		'Moo' => sub {
			my $foo = Foo::Extends::Moo->new();
			$foo->one;
			$foo->two;
		},
		'Meow' => sub {
			my $foo = Foo::Extends::Meow->new();
			$foo->one;
			$foo->two;
		},
		'Meow (direct)' => sub {
			my $foo = Foo::Extends::Meow->new();
			my $one = $foo->[$ONE];
			my $two = $foo->[$TWO];
		 },
		 'Meow (op)' => sub {
			my $foo = Foo::Extends::Meow->new();
			my $one = one $foo;
			my $two = two $foo;
		},
		'Mouse' => sub {
			my $foo = Foo::Extends::Mouse->new();
			$foo->one;
			$foo->two;
		},
		'Marlin' => sub {
			my $foo = Foo::Extends::Marlin->new();
			$foo->one;
			$foo->two;
		},
		
	});

	cmpthese $r;

...

	Benchmark: running Marlin, Meow, Meow (direct), Meow (op), Moo, Mouse for at least 5 CPU seconds...
	    Marlin:  6 wallclock secs ( 5.09 usr +  0.11 sys =  5.20 CPU) @ 4766685.58/s (n=24786765)
	      Meow:  5 wallclock secs ( 5.29 usr +  0.01 sys =  5.30 CPU) @ 6289606.79/s (n=33334916)
	Meow (direct):  5 wallclock secs ( 5.32 usr +  0.01 sys =  5.33 CPU) @ 7172480.86/s (n=38229323)
	 Meow (op):  5 wallclock secs ( 5.16 usr +  0.01 sys =  5.17 CPU) @ 7394453.19/s (n=38229323)
	       Moo:  4 wallclock secs ( 5.44 usr +  0.02 sys =  5.46 CPU) @ 816865.93/s (n=4460088)
	     Mouse:  4 wallclock secs ( 5.18 usr +  0.01 sys =  5.19 CPU) @ 1605727.55/s (n=8333726)

			   Rate      Moo   Mouse  Marlin    Meow Meow (direct) Meow (op)
	Moo            816866/s       --    -49%    -83%    -87%          -89%      -89%
	Mouse         1605728/s      97%      --    -66%    -74%          -78%      -78%
	Marlin        4766686/s     484%    197%      --    -24%          -34%      -36%
	Meow          6289607/s     670%    292%     32%      --          -12%      -15%
	Meow (direct) 7172481/s     778%    347%     50%     14%            --       -3%
	Meow (op)     7394453/s     805%    361%     55%     18%            3%        --

... so without types and against python

	# Python slots class - fastest Python OO pattern
	class Foo:
	    __slots__ = ('_one', '_two')

	    def __init__(self):
		self._one = 100
		self._two = 200

	    @property
	    def one(self):
		return self._one

	    @property
	    def two(self):
		return self._two


	class FooExtends(Foo):
	    __slots__ = ()


	def benchmark():
	    """Run benchmark and return elapsed time."""
	    start = time.perf_counter()
	    for _ in range(ITERATIONS):
		foo = FooExtends()
		_ = foo.one
		_ = foo.two
	    return time.perf_counter() - start


... Meow fastest implementation

	BEGIN {
	    package Foo::Meow;
	    use Meow;

	    ro one => Default(100);
	    ro two => Default(200);

	    make_immutable;
	    1;
	}

	BEGIN {
	    package Foo::Extends::Meow;
	    use Meow;
	    extends 'Foo::Meow';

	    make_immutable;
	    1;
	}

	BEGIN { Meow::import_accessors("Foo::Extends::Meow"); }

	sub benchmark {
	    my $start = time();
	    for (1 .. $ITERATIONS) {
		my $foo = Foo::Extends::Meow->new();
		my $one = one $foo;
		my $two = two $foo;
	    }
	    return time() - $start;
	}

...

	============================================================
	Python Direct Benchmark (slots + property accessors)
	============================================================
	Python version: 3.9.6 (default, Dec  2 2025, 07:27:58)
	[Clang 17.0.0 (clang-1700.6.3.2)]
	Iterations: 5,000,000
	Runs: 5
	------------------------------------------------------------
	Run 1: 0.649s (7,704,306/s)
	Run 2: 0.647s (7,733,902/s)
	Run 3: 0.646s (7,736,307/s)
	Run 4: 0.648s (7,720,909/s)
	Run 5: 0.649s (7,702,520/s)
	------------------------------------------------------------
	Median rate: 7,720,909/s
	============================================================

	============================================================
	Perl/Meow Benchmark Comparison
	============================================================
	Perl version: 5.042000
	Iterations: 5000000
	Runs: 5
	------------------------------------------------------------

	Inline Op (one($foo)):
	  Run 1: 0.638s (7,841,811/s)
	  Run 2: 0.629s (7,954,031/s)
	  Run 3: 0.631s (7,929,850/s)
	  Run 4: 0.631s (7,926,316/s)
	  Run 5: 0.633s (7,901,675/s)
	  Median: 7,926,316/s

	============================================================
	Summary:
	------------------------------------------------------------
	  Inline Op:    7,926,316/s
	============================================================

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-meow at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Meow>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Meow

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Meow>

=item * Search CPAN

L<https://metacpan.org/release/Meow>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Meow
