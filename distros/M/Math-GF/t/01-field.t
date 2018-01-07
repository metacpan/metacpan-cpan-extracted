use strict;
use Test::More;
use Data::Dumper;
$Data::Dumper::Indent = 1;

use Math::GF;

{
   my $Z2 = Math::GF->new(order => 2);
   ok defined($Z2), 'field for GF(2)';
   isa_ok $Z2, 'Math::GF';

   my $zero = $Z2->additive_neutral;
   isa_ok $zero, 'Math::GF::Zn';
   my $one = $Z2->multiplicative_neutral;
   isa_ok $one, 'Math::GF::Zn';
}

{
   Math::GF->import_builder(8);    # -> GF_2_3 as in GF(2^3)
   ok __PACKAGE__->can('GF_2_3'), 'import_builder for GF(2^3)';
   my $zero = GF_2_3(0);
   ok defined($zero), 'GF(2^3) zero element created';
   isa_ok $zero, 'Math::GF::Extension';

   my $field = $zero->field;
   ok defined($field), 'field for GF(2^3) from zeroth element';
   isa_ok $field, 'Math::GF';

   is $zero->field->additive_neutral, $zero, 'additive neutral in GF(2^3)';
   my $one = GF_2_3(1);
   isa_ok $one, 'Math::GF::Extension';
   is $field->multiplicative_neutral, $one,
     'multiplicative neutral in GF(2^3)';

   is $field->order, 8, 'order of field';
   is $field->p, 2, 'characteristic of field';
   is $field->n, 3, 'extension degree';
   ok !$field->order_is_prime, 'GF(2^2) is an extension field';
   isa_ok $zero, $field->element_class, '$zero';

   my @all = $field->all;
   is scalar(@all), 8, 'GF(2^3) has 8 elements';
   is $all[0], $zero, 'zeroth element is... zero';
   is $all[1], $one, 'oneth element is... one';
   is $all[-1], $field->e(7), 'seventh element has tag 7';
}

done_testing();
__END__

my $poly = $Z2->can('__get_irreducible_polynomial')->($Z2, 2);
diag $poly;

my $polys = $Z2->can('__generate_polynomials')->($Z2, 2);
diag join "\n", @$polys;

my ($sum, $prod) = $Z2->can('__tables')->(4);
print_aoa($sum);
print_aoa($prod);

done_testing();


sub print_aoa {
   my $aoa = shift;
   diag sprintf "%3d. (%s)\n", $_, join ', ', @{$aoa->[$_]}
     for 0 .. $#$aoa;
}
