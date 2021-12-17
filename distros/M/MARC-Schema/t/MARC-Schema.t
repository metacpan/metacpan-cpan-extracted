use strict;
use warnings;
use Test::More;
use MARC::Schema;

# load default schema
{
    my $schema = MARC::Schema->new();
    isa_ok $schema, 'MARC::Schema';
    can_ok $schema, qw(check _initialize _load_schema);
    ok $schema->{fields}, 'load default schema';
    ok $schema->{fields}->{LDR}, 'got a schema definition';
    is $schema->{fields}->{LDR}->{positions}->{'00-04'}->{label},
        'Record length', 'got a schema property \'label\'';
}

# load inline schema
{
    my $schema = MARC::Schema->new(
        {
            fields => {
                LDR => {
                    positions =>
                        [{position => '00-04', label => 'Record length'}],
                    repeatable => 0,
                },
                '001' => {label => 'Control Number', repeatable => 0}
            }
        }
    );
    ok $schema->{fields}, 'load inline schema';
    ok $schema->{fields}->{'LDR'}, 'got a schema definition for LDR';
    ok $schema->{fields}->{'001'}, q{got a schema definition for tag '001'};
    is $schema->{fields}->{'001'}->{label}, 'Control Number',
        'got schema property \'label\'';
}

# validate record

{
    my $record = {
        _id    => 'fol05865967',
        record => [
            ['LDR', undef, undef, '_', '00661nam  22002538a 4500'],
            ['001', undef, undef, '_', 'fol05865967'],
            ['001', undef, undef, '_', 'fol05865967'],
            ['016', undef, undef, 'a', '730032015'],
            ['016', undef, undef, 'a', '84074272XE'],
            [
                '245',                                        '1',
                '0',                                          'a',
                'Programming Perl /',                         'c',
                'Larry Wall, Tom Christiansen & Jon Orwant.', 'a',
                'subfield is not repeatable',                 'x',
                'unknown subfield',                           '8',
                '1',                                          '8',
                '2',
            ],
            ['130', 'a',   'x',   'a', 'test'],
            ['240', '1',   'x',   'a', 'test'],
            ['999', undef, undef, '_', 'not a standard field'],
        ]
    };

    my $schema = MARC::Schema->new();
    my @check  = $schema->check($record);
    ok @check > 0, 'got errors';
    is $check[0]->{error}, 'field is not repeatable',
        'field is not repeatable';
    is $check[0]->{tag},   '001',   'got field tag';
    is $check[0]->{type},  'field', 'got error type';
    is $check[1]->{error}, 'subfield is not repeatable',
        'subfield is not repeatable';
    is $check[1]->{value}, 'a',                'got subfield code';
    is $check[1]->{type},  'subfield',         'got error type';
    is $check[2]->{error}, 'unknown subfield', 'unknown subfield';
    is $check[3]->{error}, 'unknown first indicator',
        'unknown first indicator';
    is $check[3]->{value}, 'a',         'got first indicator code';
    is $check[3]->{type},  'indicator', 'got error type';
    is $check[4]->{error}, 'unknown second indicator',
        'unknown second indicator';
    is $check[5]->{error}, 'unknown field', 'unknown field';
    is $check[5]->{type},  'field',         'got error type';
}

done_testing;
