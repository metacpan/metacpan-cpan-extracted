package Meow;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.19';

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

Version 0.19

=cut

=head1 SYNOPSIS

This module is experimental. Many basic features do not yet exist.

	package Cat;

	use Meow;
	use Basic::Types::XS qw/Str Num/;

	ro name => Str;

	rw age => Default(Num, 0);

	1;

...

	package Siberian;

	use Meow;

	extends qw/Cat/;

	1;

...

	my $cat = Siberian->new(
		name => 'Simba',
		age => 10
	);

	$cat->name; # Simba;
	$cat->age; # 10;

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

		1;
	}


	{
		package Foo::Extends::Meow;

		use Meow;
		extends qw/Foo::Meow/;

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


	my $r = timethese(5000000, {
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
		'Mouse' => sub {
			my $foo = Foo::Extends::Mouse->new();
			$foo->one;
			$foo->two;
		},
		'Marlin' => sub {
			my $foo = Foo::Extends::Marlin->new();
			$foo->one;
			$foo->two;
		}
	});

	cmpthese $r;

...

	Benchmark: timing 5,000,000 iterations of Marlin, Meow, Moo, Mouse...
	    Marlin:  1 wallclock secs ( 0.98 usr +  0.02 sys =  1.00 CPU) @ 5000000.00/s (n=5000000)
	      Meow:  1 wallclock secs ( 0.96 usr +  0.00 sys =  0.96 CPU) @ 5208333.33/s (n=5000000)
	       Moo:  6 wallclock secs ( 5.70 usr +  0.00 sys =  5.70 CPU) @ 877192.98/s (n=5000000)
	     Mouse:  3 wallclock secs ( 3.05 usr +  0.01 sys =  3.06 CPU) @ 1633986.93/s (n=5000000)

		    Rate    Moo  Mouse Marlin   Meow
	Moo     877193/s     --   -46%   -82%   -83%
	Mouse  1633987/s    86%     --   -67%   -69%
	Marlin 5000000/s   470%   206%     --    -4%
	Meow   5208333/s   494%   219%     4%     --

Note: Type::Tiny::XS is installed and so is the other optional XS dependancies for Moo.

	Benchmark: running Cor, Marlin for at least 5 CPU seconds... Marlin and Meow has type constraint checking
	       Cor:  5 wallclock secs ( 5.13 usr +  0.02 sys =  5.15 CPU) @ 2886788.16/s (n=14866959)
	    Marlin:  5 wallclock secs ( 5.01 usr +  0.11 sys =  5.12 CPU) @ 4523074.80/s (n=23158143)
	      Meow:  5 wallclock secs ( 5.16 usr + -0.01 sys =  5.15 CPU) @ 5196218.06/s (n=26760523)
	
	Benchmark: running Marlin, Meow, Moo, Mouse for at least 5 CPU seconds...
	    Marlin:  5 wallclock secs ( 5.22 usr +  0.13 sys =  5.35 CPU) @ 4814728.04/s (n=25758795)
	      Meow:  5 wallclock secs ( 5.23 usr +  0.01 sys =  5.24 CPU) @ 5203329.96/s (n=27265449)
	       Moo:  4 wallclock secs ( 5.28 usr +  0.00 sys =  5.28 CPU) @ 860649.81/s (n=4544231)
	     Mouse:  6 wallclock secs ( 5.29 usr +  0.01 sys =  5.30 CPU) @ 1603849.25/s (n=8500401)

		    Rate    Moo  Mouse Marlin   Meow
	Moo     860650/s     --   -46%   -82%   -83%
	Mouse  1603849/s    86%     --   -67%   -69%
	Marlin 4814728/s   459%   200%     --    -7%
	Meow   5203330/s   505%   224%     8%     --

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
