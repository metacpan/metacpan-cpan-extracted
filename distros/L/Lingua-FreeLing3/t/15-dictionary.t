# -*- cperl -*-

use warnings;
use strict;
use utf8;
use Test::More tests => 5;
use Lingua::FreeLing3::Dictionary;

my $es_dic = Lingua::FreeLing3::Dictionary->new(lang => "es",
                                                inverseAccess => 1,
                                                retokContractions => 0);

# defined
ok($es_dic);

# is a L::FL::Dictionary
isa_ok($es_dic => 'Lingua::FreeLing3::Dictionary');

# is of the right class'
isa_ok($es_dic => 'Lingua::FreeLing3::Bindings::dictionary');

# ok, the object can tokenize?
can_ok($es_dic => 'get_forms');

my $forms = $es_dic->get_forms('carro', 'NCMP000');
my $x = $forms->[0];
is($x, "carros");

__END__
