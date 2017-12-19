use Test::More;
use MARC::Spec;
use MARC::Spec::Field;
use MARC::Spec::Indicator;
use MARC::Spec::Subfield;
use MARC::Spec::Comparisonstring;
use MARC::Spec::Subspec;

# new Comparisonstring
my $cmp = MARC::Spec::Comparisonstring->new('test');

# new Subspec
my $subspec = MARC::Spec::Subspec->new;

# Comparisonstring is right subterm
$subspec->right($cmp);

# Operator is equal
$subspec->operator('=');

# Parsed MARCspec as right subterm
$subspec->left(MARC::Spec::parse('245$b'));

# new Field
my $field = MARC::Spec::Field->new('245');

# Field attributes
$field->index_start(1);
$field->index_end(3);

# adding one subspec
$field->add_subspec($subspec);

# creating more subspecs
my $subspecs = [
    MARC::Spec::Subspec->new( {right=> MARC::Spec::parse('245$e')} ),
    MARC::Spec::Subspec->new( {right => MARC::Spec::parse('245$f')} )
];

# and adding more subspecs
$field->add_subspecs($subspecs);

# creating lot more subspecs
my $or_subspecs = [
    [
        MARC::Spec::Subspec->new( {right=> MARC::Spec::parse('245$g')} ),
        MARC::Spec::Subspec->new( {right => MARC::Spec::parse('245$h')} )
    ]
];

# and adding more subspecs
$field->add_subspecs($or_subspecs);

# new Subfield
my $subfield_a = MARC::Spec::Subfield->new('a');
my $subfield_c = MARC::Spec::Subfield->new('c');
my $subfield_d = MARC::Spec::Subfield->new('d');

# new MARCspec with field
my $ms = MARC::Spec->new($field);

# add subfield a
$ms->add_subfield($subfield_a);

# add other subfields
$ms->add_subfields([$subfield_c, $subfield_d]);


ok $ms->field->tag eq '245', 'field tag';
ok $ms->field->index_start == 1, 'index start';
ok $ms->field->index_end == 3, 'index end';
ok scalar @{$ms->field->subspecs} == 4, 'number of AND subspecs'; 
ok scalar @{$ms->field->subspecs->[3]} == 2, 'number of OR subspecs'; 
ok ref $ms->field->subspecs->[0]->right eq 'MARC::Spec::Comparisonstring', 'right subterm Comparisonstring'; 
ok scalar @{$ms->subfields} == 3, 'number of subfields';

my $indicator = MARC::Spec::Indicator->new('2');
# and adding more subspecs
$indicator->add_subspecs($subspecs);
my $field2 = MARC::Spec::Field->new('245');
my $ms2 =  MARC::Spec->new($field2);
$ms2->indicator($indicator);

ok $ms2->indicator->position eq '2', 'indicator position';
ok $ms2->indicator->base eq '^2', 'indicator position';
ok scalar @{$ms2->indicator->subspecs} == 2, 'indicator subspecs';

done_testing();