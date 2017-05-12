use 5.006;
use strict;
use warnings;

use Exporter ();

package Devel::StrictMode;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';
our @ISA       = qw( Exporter );
our @EXPORT    = qw( STRICT );
our @EXPORT_OK = qw( LAX );

BEGIN {
	my $strict = 0;
	$ENV{$_} && $strict++
		for qw(
			EXTENDED_TESTING
			AUTHOR_TESTING
			RELEASE_TESTING
			PERL_STRICT
		);
	
	eval "
		sub STRICT () { !! $strict }
		sub LAX    () {  ! $strict }
	";
};

1;

__END__

=pod

=encoding utf-8

=for stopwords pragmata

=head1 NAME

Devel::StrictMode - determine whether strict (but slow) tests should be enabled

=head1 SYNOPSIS

   package MyClass;
   
   use Moose;
   use Devel::StrictMode;
   
   has input_data => (
      is       => 'ro',
      isa      => STRICT ? "HashRef[ArrayRef[Str]]" : "HashRef",
      required => 1,
   );

=head1 DESCRIPTION

This module provides you with a constant C<STRICT> which you can use to
determine whether additional strict (but slow) runtime tests are
executed by your code.

C<STRICT> is true if any of the following environment variables have
been set to true:

   PERL_STRICT
   EXTENDED_TESTING
   AUTHOR_TESTING
   RELEASE_TESTING

C<STRICT> is false otherwise.

It is anticipated that you might set one or more of the above variables
to true while running your test suite, but leave them all false in your
production scenario.

Although not exported by default, a constant C<LAX> is also provided,
which returns the opposite of C<STRICT>.

=head2 Using STRICT with Moose/Moo/Mouse attributes

Type constraint checks (C<isa>) are conducted at run time. Slow checks
can slow down your constructor and accessors. As shown above, C<STRICT>
can be used to alternate between a slower by stricter type constraint
check, and a faster but looser one.

Don't try this if your attribute coerces. It will subtly break things.

=head2 Using STRICT to perform assertions in function and method calls

You may protect blocks of assertions with an C<< if (STRICT) { ... } >>
conditional to ensure that they only run in your testing environment.

   sub fibonacci
   {
      my $n = $_[0];
      
      if (STRICT)
      {
         die "expected exactly one argument"
            unless @_ == 1;
         die "expected argument to be a natural number"
            unless $n =~ /\A[0-9]+\z/;
      }
      
      $n < 2 ? $n : fibonacci($n-1)+fibonacci($n-2);
   }

Because C<STRICT> is a constant, the Perl compiler will completely
optimize away the C<if> block when running in your production
environment.

=head2 Using STRICT with pragmata

Thanks to L<if> it's easy to use C<STRICT> to conditionally load
pragmata.

   use Devel::StrictMode;

   use strict;
   use warnings STRICT ? qw(FATAL all) : qw(all);
   
   no if STRICT, "bareword::filehandles";
   no if STRICT, "autovivification";

See also L<autovivification>, L<bareword::filehandles>, L<indirect>,
L<multidimensional>, etc.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Devel-StrictMode>.

=head1 SEE ALSO

L<strictures>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=begin trustme

=item LAX

=end trustme

=cut
