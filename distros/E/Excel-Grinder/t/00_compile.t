use strict;
use Test::More 0.98 tests => 4;

# make sure it loads
use_ok $_ for qw(
    Excel::Grinder
);

# and that we can create the object
my $temp_dir = '/tmp/excel_grinder';
my $xlsx = Excel::Grinder->new($temp_dir);
isa_ok( $xlsx, 'Excel::Grinder', 'Object created' );

# attempt to create a basic spreadsheet
my $full_file_path = $xlsx->write_excel(
	'filename' => 'our_family.xlsx',
	'headings_in_data' => 1,
	'worksheet_names' => ['Dogs','People'],
	'the_data' => [
		[
			['Name','Main Trait','Age Type'],
			['Ginger','Wonderful','Old'],
			['Pepper','Loving','Passed'],
			['Polly','Fun','Young'],
			['Daisy','Crazy','Puppy']
		],
		[
			['Name','Main Trait','Age Type'],
			['Melanie','Smart','Oldish'],
			['Lorelei','Fun','Young'],
			['Eric','Fat','Old']
		]
	],
);

my $file_was_created = 0;
if (-d $full_file_path) {
	$file_was_created = 1;
}
ok($full_file_path, 'Create a Excel file');

# and attempt to read said XLSX file
my $test_data = $xlsx->read_excel('our_family.xlsx');
my $data_verified = 0;
if ($$test_data[0][1][1] eq 'Wonderful' && $$test_data[1][2][2] eq 'Young') {
	$data_verified = 1;
}
ok($data_verified, 'Read data back in from Excel');

# clean up
unlink $full_file_path;
rmdir $temp_dir;

done_testing;

