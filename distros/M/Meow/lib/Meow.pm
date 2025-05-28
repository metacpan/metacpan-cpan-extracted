package Meow;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.13';

require XSLoader;
XSLoader::load('Meow', $VERSION);

1;

__END__

=encoding UTF-8

=head1 NAME

Meow - Object ฅ^•ﻌ•^ฅ Orientation 

=head1 VERSION

Version 0.13

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

		use Moo;
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

		use Moo;
		extends qw/Foo::Meow/;

		1;
	}


	my $r = timethese(1000000, {
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
		}
	});

	cmpthese $r;

...

	Benchmark: timing 1000000 iterations of Meow, Moo, Mouse...
	      Meow: 1.30834 wallclock secs ( 1.31 usr +  0.01 sys =  1.32 CPU) @ 757575.76/s (n=1000000)
	       Moo: 1.56353 wallclock secs ( 1.57 usr +  0.00 sys =  1.57 CPU) @ 636942.68/s (n=1000000)
	     Mouse: 1.34627 wallclock secs ( 1.34 usr +  0.00 sys =  1.34 CPU) @ 746268.66/s (n=1000000)
		  Rate   Moo Mouse  Meow
	Moo   636943/s    --  -15%  -16%
	Mouse 746269/s   17%    --   -1%
	Meow  757576/s   19%    2%    --

Note: Type::Tiny::XS is installed and so is the other optional XS dependancies for Moo.

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
