package Hash::FieldHash;

use 5.008_005;
use strict;

our $VERSION = '0.15';

use parent qw(Exporter);
our @EXPORT_OK   = qw(fieldhash fieldhashes from_hash to_hash);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub fieldhashes{
	foreach my $hash_ref(@_){
		&fieldhash($hash_ref);
	}
}

1;
__END__

=for stopwords uvar CPAN rw-accessors chainable

[![Build Status](https://travis-ci.org/gfx/p5-Hash-FieldHash.svg?branch=master)](https://travis-ci.org/gfx/p5-Hash-FieldHash)

=head1 NAME

Hash::FieldHash - Lightweight field hash for inside-out objects

=head1 VERSION

This document describes Hash::FieldHash version 0.15.

=head1 SYNOPSIS

	use Hash::FieldHash qw(:all);

	fieldhash my %foo;

	fieldhashes \my(%bar, %baz);

	{
		my $o = Something->new();

		$foo{$o} = 42;

		print $foo{$o}; # => 42
	}
	# when $o is released, $foo{$o} is also deleted,
	# so %foo is empty in here.

	# in a class
	{
		package Foo;
		use Hash::FieldHash qw(:all);

		fieldhash my %bar, 'bar'; # make an accessor
	}

	my $obj = bless {}, 'Foo';
	$obj->bar(10); # does $bar{$obj} = 10

=head1 DESCRIPTION

C<Hash::FieldHash> provides the field hash mechanism which supports
the inside-out technique.

You may know C<Hash::Util::FieldHash>. It's a very useful module,
but too complex to understand the functionality and only available in 5.10.
C<H::U::F::Compat> is available for pre-5.10, but it is too slow to use.

This is a better alternative to C<H::U::F> with following features:

=over 4

=item Simpler interface

C<Hash::FieldHash> provides a few functions:  C<fieldhash()> and C<fieldhashes()>.
That's enough.

=item Higher performance

C<Hash::FieldHash> is faster than C<Hash::Util::FieldHash>, because
its internals use simpler structures.

=item Relic support

Although C<Hash::FieldHash> uses a new feature introduced in Perl 5.10,
I<the uvar magic for hashes> described in L<Hash::Util::Fieldhash/"GUTS">,
it supports Perl 5.8 using the traditional tie-hash layer.

=back

=head1 INTERFACE

=head2 Exportable functions

=over 4

=item C<< fieldhash(%hash, ?$name, ?$package) >>

Creates a field hash. The first argument must be a hash.

Optional I<$name> and I<$package> indicate the name of the field, which will
create rw-accessors, using the same name as I<$name>.

Returns nothing.

=item C<< fieldhashes(@hash_refs) >>

Creates a number of field hashes. All the arguments must be hash references.

Returns nothing.

=item C<< from_hash($object, \%fields) >>

Fills the named fields associated with I<$object> with I<%fields>.
The keys of I<%fields> can be simple or fully qualified.

Returns I<$object>.

=item C<< to_hash($object, ?-fully_qualify) >>

Serializes I<$object> into a hash reference.

If the C<-fully_qualify> option is supplied , field keys are fully qualified.

For example:

	package MyClass;
	use FieldHash qw(:all);

	fieldhash my %foo => 'foo';

	sub new{
		my $class = shift;
		my $self  = bless {}, $class;
		return from_hash($self, @_);
	}

	package MyDerivedClass;
	use parent -norequire => 'MyClass';
	use FieldHash qw(:all);

	fieldhash my %bar => 'bar';

	package main;

	my $o = MyDerivedClass->new(foo => 10, bar => 20);
	my $p = MyDerivedClass->new('MyClass::foo' => 10, 'MyDerivedClass::bar' => 20);

	use Data::Dumper;
	print Dumper($o->to_hash());
	# $VAR1 = { foo => 10, bar => 20 }

	print Dumper($o->to_hash(-fully_qualify));
	# $VAR1 = { 'MyClass::foo' => 10, 'MyDerived::bar' => 20 }

=back

=head1 ROBUSTNESS

=head2 Thread support

As C<Hash::Util::FieldHash> does, C<Hash::FieldHash> fully supports threading
using the C<CLONE> method.

=head2 Memory leaks

C<Hash::FieldHash> itself does not leak memory, but it may leak memory when
you uses hash references as field hash keys because of an issue of perl 5.10.0.

=head1 NOTES

=head2 The type of field hash keys

C<Hash::FieldHash> accepts only references and registered addresses as its
keys, whereas C<Hash::Util::FieldHash> accepts any type of scalars.

According to L<Hash::Util::FieldHash/"The Generic Object">,
Non-reference keys in C<H::U::F> are used for class fields. That is,
all the fields defined by C<H::U::F> act as both object fields and class fields
by default. It seems confusing; if you do not want them to be class fields,
you must check the type of I<$self> explicitly. In addition,
these class fields are never inherited.
This behavior seems problematic, so C<Hash::FieldHash>
restricts the type of keys.

=head2 The ID of field hash keys

While C<Hash::Util::FieldHash> uses C<refaddr> as the IDs of field
hash keys, C<Hash::FieldHash> allocates arbitrary integers as the
IDs.

=head2 What accessors return

The accessors C<fieldhash()> creates are B<chainable> accessors.
That is, it returns the I<$object> (i.e. C<$self>) with a parameter,
where as it returns the I<$value> without it.

For example:

    my $o = YourClass->new();
    $o->foo(42);           # returns $o itself
    my $value = $o->foo(); # retuns 42

=head1 DEPENDENCIES

Perl 5.8.5 or later, and a C compiler.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 SEE ALSO

L<Hash::Util::FieldHash>.

L<Hash::Util::FieldHash::Compat>.

L<perlguts/"Magic Virtual Tables">.

L<Class::Std> describes the inside-out technique.

=head1 AUTHOR

Fuji, Goro (gfx) E<lt>gfuji(at)cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2010, Fuji, Goro. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
