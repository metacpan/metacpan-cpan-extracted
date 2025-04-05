use Test2::V0;
use Excel::XLSX qw( from_xlsx to_xlsx );

imported_ok( qw( from_xlsx to_xlsx ) );

my ( $xlsx, $data_out );
my $data_in = {
    formats => [
        {
            font => 'Arial',
            size => 12,
        },
        {
            font => 'Arial',
            size => 10,
            color => '#00FF00',
        },
    ],
    worksheets => [
        {
            name => 'Example Worksheet',
            cells => {
                12 => {
                    7 => {
                        format_id => 0,
                        value     => 'Hello world!',
                    },
                },
            },
        },
    ],
};

ok( lives { $xlsx     = to_xlsx($data_in) }, 'to_xlsx'   ) or note $@;
ok( lives { $data_out = from_xlsx($xlsx)  }, 'from_xlsx' ) or note $@;

done_testing;
