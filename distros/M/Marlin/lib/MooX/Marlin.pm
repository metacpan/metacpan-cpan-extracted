use 5.008008;
use strict;
use warnings;

package MooseX::Marlin;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.011000';

use Marlin ();
use Moo 2.004000;
use Moo::Role ();

$_->inject_moo_metadata for values %Marlin::META;

sub import {
	no strict 'refs';
	my $class = shift;
	my $caller = caller;
	
	Moo->is_class( $caller )
		or Moo::Role->is_role( $caller )
		or Marlin::_croak("Package '$caller' does not use Moo");
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooX::Marlin - 🐮 ❤️ 🐟 inherit from Marlin classes in Moo

=head1 SYNOPSIS

  use v5.20.0;
  no warnings "experimental::signatures";
  
  package Person {
    use Types::Common -lexical, -all;
    use Marlin::Util -lexical, -all;
    use Marlin
      'name'  => { is => ro, isa => Str, required => true },
      'age'   => { is => rw, isa => Int, predicate => true };
  }
  
  package Employee {
    use Moo;
    use MooX::Marlin;
    extends 'Person';
    
    has employee_id => ( is => 'ro', required => 1 );
  }

=head1 WARNING

This appears to work, but it is not thoroughly tested.

=head1 DESCRIPTION

Loading this class will do a few things:

=over

=item *

Ensures you are using at least Moo 2.004000 (released in April 2020).

=item *

Loop through all Marlin classes and roles which have already been defined
(also any foreign classes like Class::Tiny ones which Marlin has learned
about by inheritance, etc) and inject metadata about them into Moo's innards,
enabling them to be used by Moo.

=item *

Tells Marlin to keep injecting metadata into Moo's innards for any Marlin
classes or roles that are loaded later.

=item *

Checks that the caller package is a Moo class or Moo role, and
complains otherwise. (Make sure to C<< use Moo >> or C<< use Moo::Role >>
I<before> you C<< use Moo::Marlin >>!)

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-marlin/issues>.

=head1 SEE ALSO

L<Marlin>, L<Moo>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
