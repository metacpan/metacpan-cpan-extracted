use Test::More;
use MARC::Spec;

my $parser = MARC::Spec::parse('999$a[#]{245^1=\1}{$a=\Foo|$a=\Y}');

#checking subspecs
ok scalar @{$parser->subfields->[0]->subspecs} == 2, 'subbfield a subspec count';
ok scalar @{$parser->subfields->[0]->subspecs->[1]} == 2, 'subfield a subspec count2';
ok $parser->subfields->[0]->subspecs->[0]->left->indicator->position eq 1, 'subfield a subspec indicator postion';

my $field = $parser->field;
#creating more subspecs
my $subspecs = [
    MARC::Spec::Subspec->new( {right=> MARC::Spec::parse('245$e')} ),
    MARC::Spec::Subspec->new( {right => MARC::Spec::parse('245$f')} )
];

#and adding more subspecs
$field->add_subspecs($subspecs);

#creating lot more subspecs
my $or_subspecs = [
    [
        MARC::Spec::Subspec->new( {right=> MARC::Spec::parse('245$g')} ),
        MARC::Spec::Subspec->new( {right => MARC::Spec::parse('245$h')} )
    ]
];

#and adding more subspecs
$field->add_subspecs($or_subspecs);

ok scalar @{$field->subspecs} == 3, 'field subspec count';
ok scalar @{$field->subspecs->[2]} == 2, 'field or subspec count';

done_testing();