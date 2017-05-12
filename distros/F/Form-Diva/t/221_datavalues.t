use strict;
use warnings;
use Test::More 1.001003;
use Test::Deep 0.112;

use Storable qw(dclone);

use_ok('Form::Diva');

my $diva = Form::Diva->new(
    label_class => 'testclass',
    input_class => 'form-control',
    form_name   => 'diva1',
    form        => [
        {   n => 'foodname',
            t => 'text',
            p => 'Your Name',
            l => 'Full_Name',
            d => 'Delicious'
        },
        { name => 'phone', type => 'tel', extra => 'required', comment => 'phone comment' },
        {qw / n email t email l Email c form-email placeholder doormat/},
        { name => 'our_id', type => 'number', extra => 'disabled' },
    ],
);

my $data1 = {
    foodname => 'spaghetti',
    our_id   => 41,
    email    => 'dinner@food.food',
};
{
    note('testing without moredata set');
    my $nodata    = $diva->datavalues;
    my $withdata  = $diva->datavalues($data1);
    my $skipempty = $diva->datavalues( $data1, 'skipempty' );

    is( $nodata->[0]{name}, 'foodname', 'checked name of 0 row' );
    is( $nodata->[0]{comment}, undef, 'checked comment of 0 row is undef' );    
    is( $nodata->[1]{type}, 'tel',      'row 1 type' );
    is( $nodata->[1]{comment}, 'phone comment',  'row 1 comment' );
    
    is( scalar(@$nodata),       4,  'nodata form returned 4 rows' );
    is( scalar(@$withdata),     4,  'withdata form returned 4 rows' );
    is( scalar(@$skipempty),    3,  'skipempty nodata form returned 3 rows' );
    is( $skipempty->[2]{value}, 41, 'skipempty last row value is 41' );
    is( $withdata->[2]{value},
        'dinner@food.food', 'withdata provided value for email' );

    is( $nodata->[0]{label}, 'Full_Name', 'nodata label is correct' );
    is( $withdata->[3]{label},
        'Our_id', 'withdata label was created from name' );
    is( $skipempty->[1]{label}, 'Email',
        'skipempty field 1 is Email because a record was deliberately skipped'
    );
}
{
    note('testing with moredata set');
    my $nodata   = $diva->datavalues( undef,  'moredata' );
    my $withdata = $diva->datavalues( $data1, 'moredata' );
    my $skipempty = $diva->datavalues( $data1, 'moredata', 'skipempty' );

    #repeat a few of the tests to make sure nothing dissappears.
    is( $nodata->[0]{name}, 'foodname', 'checked name of 0 row' );
    is( $nodata->[1]{type}, 'tel',      'row 1 type' );
    is( scalar(@$nodata),   4,          'nodata form returned 4 rows' );
    is( scalar(@$withdata), 4,          'withdata form returned 4 rows' );
    is( scalar(@$skipempty),    3,  'skipempty nodata form returned 3 rows' );
    is( $skipempty->[2]{value}, 41, 'skipempty last row value is 41' );
    is( $withdata->[2]{value},
        'dinner@food.food', 'withdata provided value for email' );
    is( $nodata->[0]{placeholder},
        'Your Name', 'placeholder is provided for first row' );
    is( $nodata->[1]{placeholder},
        undef, 'placeholder still undef for second row' );
    is( $nodata->[2]{class}, 'form-email', 'class is provided for email' );
    is( $nodata->[1]{class},
        'form-control', 'class is default for a different row' );
    is( $withdata->[0]{extra}, undef,      'extra is undef for foodname' );
    is( $withdata->[1]{extra}, 'required', 'extra is required for phone' );
    is( $nodata->[3]{extra},   'disabled', 'row 3 extra' );
    is( $skipempty->[0]{default},
        'Delicious', 'foodname defaults to delicious' );
    is( $skipempty->[1]{default}, undef, 'form-email has no default(undef)' );
}

cmp_deeply( 
    $diva->datavalues( undef, 'moredata', 'skipempty'),
    [], 
    'using skipempty without data returns nothing' );

my $divaselect = Form::Diva->new(
    label_class => 'label',
    input_class => 'input',
    form        => [
        { n => 'hasnt', t => 'select', v => [qw /abc def xyz/] },
        {   n  => 'has',
            t  => 'select',
            id => 'zmyxfd',
            v  => [qw /abc def xyz/]
        },
    ],
);
my $expect_array = [qw /abc def xyz/];
my $select = $divaselect->datavalues( undef, 'moredata' );

cmp_deeply( $select->[0]{values},
    $expect_array, 'values contains the value list for a select input' );

done_testing();
