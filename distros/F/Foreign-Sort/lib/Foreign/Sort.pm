package Foreign::Sort;
use strict;
use warnings;
use Attribute::Handlers;
our $VERSION = '0.01';

sub import {
    my ($pkg, @others) = shift;
    my $caller = caller;
    no strict 'refs';
    for my $p ($caller, @others) {
	push @{"$p\::ISA"}, $pkg;
    }
}

sub Foreign : ATTR(CODE) {
    my ($pkg, $sym, $code) = @_;
    my $p2 = *{$sym}{PACKAGE};
    no warnings 'redefine';
    *{ $sym } = sub {
	no strict 'refs';
	my $p1 = caller;
	local ${"$p2\::a"} = ${"$p1\::a"};
	local ${"$p2\::b"} = ${"$p1\::b"};
	$code->();
    };
}

1;

=head1 NAME

Foreign::Sort - subroutine attribute to allow call to sort routine from other package

=head1 VERSION

0.01

=head1 SYNOPSIS

    package X1;
    use Foreign::Sort;
    sub by_middle : Foreign { 
        (substr($a,4) // "") cmp (substr($b,4) // "")
           ||      $a cmp $b 
    }

    package X2;
    @env_keys = sort X1::by_middle keys %ENV;

=head1 THE PROBLEM

The builtin L<"sort"|perlfunc/"sort"> function takes an optional 
subroutine name to use as a comparison function. Just before calling
the comparison function, Perl temporarily sets the variables 
C<$a> and C<$b> from the calling package with the values to be compared. 
The comparison function is expected to decide an ordering for
C<$a> and C<$b> and to return an appropriate value.

A problem arises when the calling package is not the same as the
package that defines the comparison function.

    package X2;
    sort by_42 {
        ($b eq '42') <=> ($a eq '42)   ||  $a <=> $b
    }

    @y = (17, 19, 42, 83, 47);
    @yy = sort X2::by_42 @y;

    package X1;
    @x = (17, 19, 42, 83, 47);
    @xx = sort X2::by_42 @x;

The first C<sort> call will succeed (returning the values in the
order C<42,17,18,47,83>) but the second C<sort> call will fail.
This is because the C<by_42> function, declared in package C<X2>,
is implictly operating on the package variables C<$X2::a> and
C<$X2::b>, and the sort call from package C<X1> is setting the
package variables C<$X1::a> and C<$X1::b> instead.

One relatively common place this problem arises is in inheritance
heirarchies, where it may be cumbersome to use a comparison function
in a superclass from a subclass.

=head1 THE SOLUTION

The C<Foreign::Sort> package defines the subroutine attribute
C<Foreign> that can be applied to comparison functions.
A comparison function with the C<Foreign> attribution will
perform its comparison on the C<$a> and C<$b> values from
the I<calling> package, not (necessarily) the package where
the comparison function is defined. This allows you to define
a comparison function that other users may call from other
packages, and save them the trouble of setting 
C<$a> and C<$b> in the right package.

    package X2;
    use Foreign::Sort;
    sub by_42 : Foreign {
        ($b eq '42') <=> ($a eq '42)   ||  $a <=> $b
    }

    package X1;
    @x = (17, 19, 42, 83, 47);
    @xx = sort X2::by_42 @x;

In this case, the call succeeds because the C<Foreign::Sort>
package was copying the values from C<$X1::a> and C<$X1::b>
to C<$X2::a> and C<$X2::b> with each call to the C<X2::by_42>
function.

This module was inspired by a discussion at
L<https://stackoverflow.com/q/54842607>.

=head1 LIMITATIONS

All testing for initial release done on Perl v5.22 and better. 
Future versions will attempt to make this module compatible 
with older Perls, if necessary.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Foreign::Sort


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Foreign-Sort>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Foreign-Sort>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Foreign-Sort>

=item * Search CPAN

L<http://search.cpan.org/dist/Foreign-Sort/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2019, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut
