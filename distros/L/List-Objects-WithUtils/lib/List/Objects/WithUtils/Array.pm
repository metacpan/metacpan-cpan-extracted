package List::Objects::WithUtils::Array;
$List::Objects::WithUtils::Array::VERSION = '2.028003';
use strictures 2;

require Role::Tiny;
Role::Tiny->apply_roles_to_package( __PACKAGE__,
  qw/
    List::Objects::WithUtils::Role::Array
    List::Objects::WithUtils::Role::Array::WithJunctions
   /
);

use Exporter ();
our @EXPORT = 'array';

sub import {
  my $pkg = caller;
  { no strict 'refs';
    ${"${pkg}::a"} = ${"${pkg}::a"}; ${"${pkg}::b"} = ${"${pkg}::b"};
  }
  goto &Exporter::import
}

sub array { __PACKAGE__->new(@_) }

1;

=pod

=head1 NAME

List::Objects::WithUtils::Array - Array-type objects WithUtils

=head1 SYNOPSIS

  use List::Objects::WithUtils 'array';

  my $array = array(qw/ a b c /);

=head1 DESCRIPTION

This class is the basic concrete implementation of
L<List::Objects::WithUtils::Role::Array>. Methods are documented there.

This class also consumes
L<List::Objects::WithUtils::Role::Array::WithJunctions>, which adds the
B<any_items> & B<all_items> junction-returning methods; see the POD for
L<List::Objects::WithUtils::Role::Array::WithJunctions> and
L<List::Objects::WithUtils::Array::Junction> for details.

=head2 array

Creates a new array object.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Derived from L<Data::Perl> by Matt Phillips (CPAN: MATTP) et al

Licensed under the same terms as Perl

=cut
