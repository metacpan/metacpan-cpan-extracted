use 5.008008;
use strict;
use warnings;

package MooseX::Marlin;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.011000';

use Marlin ();
use Moose 2.2004 ();
use Moose::Object ();
use Moose::Util ();

$_->inject_moose_metadata for values %Marlin::META;

sub import {
	no strict 'refs';
	my $class = shift;
	my $caller = caller;
	
	my $caller_meta = Moose::Util::find_meta($caller)
		or Marlin::_croak("Package '$caller' does not use Moose");
	
	if ( $caller_meta->isa('Class::MOP::Class') ) {
		for my $method ( qw/ new does BUILDARGS BUILDALL DEMOLISHALL / ) {	
			if ( not exists &{"${caller}::${method}"} ) {
				*{"${caller}::${method}"} = \&{"Moose::Object::${method}"};
			}
		}
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooseX::Marlin - 🫎 ❤️ 🐟 inherit from Marlin classes in Moose

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
    use Moose;
    use MooseX::Marlin;
    extends 'Person';
    
    has employee_id => ( is => 'ro', isa => 'Int', required => 1 );
  }

=head1 WARNING

This appears to work, but it is not thoroughly tested.

=head1 DESCRIPTION

Loading this class will do a few things:

=over

=item *

Ensures you are using at least Moose 2.2004 (released in January 2017).

=item *

Loop through all Marlin classes and roles which have already been defined
(also any foreign classes like Class::Tiny ones which Marlin has learned
about by inheritance, etc) and inject metadata about them into Class::MOP,
enabling them to be used by Moose.

=item *

Tells Marlin to keep injecting metadata into Class::MOP for any Marlin
classes or roles that are loaded later.

=item *

Checks that the caller package is a Moose class or Moose role, and
complains otherwise. (Make sure to C<< use Moose >> or C<< use Moose::Role >>
I<before> you C<< use MooseX::Marlin >>!)

=item *

Imports C<new>, C<does>, C<BUILDARGS>, C<BUILDALL>, and C<DEMOLISHALL>
from L<Moose::Object> into the caller package, if the caller package is
a Moose class.

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-marlin/issues>.

=head1 SEE ALSO

L<Marlin>, L<Moose>.

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
