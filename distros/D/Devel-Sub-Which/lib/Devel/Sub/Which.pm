#!/usr/bin/perl

use 5.006;

package Devel::Sub::Which;

use strict;
use warnings;

our $VERSION = "0.05";

use Sub::Identify qw(sub_fullname);
use Scalar::Util qw/reftype/;
use Carp qw/croak/;

use Sub::Exporter -setup => {
	exports => [qw(which ref_to_name)],
	collectors => {
		':universal' => sub { *UNIVERSAL::which = \&which; return 1 },
	}
};

sub which ($;$) {
	my $obj = shift;
	my $sub = shift;

	return sub_fullname($obj) if not defined $sub; # just a sub, no object

	if (ref($sub) and reftype($sub) eq 'CODE'){
		return sub_fullname($sub);
	} else {
		my $ref = $obj->can($sub);
		croak("$obj\->can($sub) did not return a code reference")
			unless ref($ref) and reftype($ref) eq 'CODE';
		return sub_fullname($ref);
	}
}

sub ref_to_name ($) {
	my $sub = shift;

	unless (ref($sub) and reftype($sub) eq 'CODE'){
		croak "$sub is not a code reference";
	}

	sub_fullname($sub);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Devel::Sub::Which - Name information about sub calls à la L<UNIVERSAL/can> and
<which(1)>.

=head1 SYNOPSIS

	{
		# inject 'which' into a class:
		package Foo;
		use Devel::Sub::Which qw(which);
	}

	# or into UNIVERSAL (best avoided except as a temporary measure)
	use Devel::Sub::Which qw(:universal);


	# introspect like this:
	$obj->which("foo"); # returns the name of the sub that
	                    # will implement the "foo" method

	# or like this:
	Devel::Sub::Which::which( $obj, "foo" );


	# which is equivalent to:
	my $code_ref = $obj->can("foo");
	Devel::Sub::Which::which($code_ref);

=head1 DESCRIPTION

I don't like the perl debugger. I'd rather print debug statements as I go
along, mostly saying "i'm going to do so and so", so I know what to look for
when stuff breaks.

I also like to make extensive use of polymorphism. Due to the richness of
Perl's OO, we have multiple inheritence, delegations, runtime generated
classes, method calls on non predeterminate values, etc, and it often makes
sense to do:

	my $method = "foo";;

	debug("i'm going to call $method on $obj. FYI, it's going to be "
		. $obj->which($method));

	$obj->$method()

In order to figure out exactly which definition of C<$method> is going to be
invoked. This helps the above debugging style by providing more deterministic
reporting.

=head1 METHODS

=over 4

=item OBJ->which( METHOD )

This method determines which subroutine reference will be executed for METHOD,
using L<UNIVERSAL::can> (or any overriding implementation),

You can get this method by importing it as a function into a class, or using
the C<:universal> export.

=back

=head1 FUNCTIONS

=over 4

=item which OBJ METHOD

=item which CODEREF

The first form has the same effect as OBJ->which(METHOD), and the second form
just delegates to L<Sub::Identify>

=back

=head1 EXPORTS


Nothing is exported by default.

This module uses L<Sub::Exporter>, so exports can be renamed, etc.

=over 4

=item :universal

This causes C<which> to become a method in L<UNIVERSAL>, so that you can call
it on any object.

=item which

You can import this into a class and then use it as a method.

=item ref_to_name

Provided for compatibility. Just use L<Sub::Identify>.

=back

=head1 ACKNOWLEGEMENTS

Yitzchak Scott-Thoennes provided the know-how needed to get the name of a sub
reference. I've since switched to using L<Sub::Identify>, which abstract those
details away.

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/Devel-Sub-Which/>, and use C<darcs send> to
commit changes.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT & LICENSE

        Copyright (c) 2004 Yuval Kogman. All rights reserved
        This program is free software; you can redistribute
        it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Sub::Identify>, L<DB>, L<perldebug>, L<UNIVERSAL>, L<B>

=cut
