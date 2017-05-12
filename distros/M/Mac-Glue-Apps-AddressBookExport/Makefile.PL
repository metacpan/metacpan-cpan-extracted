use ExtUtils::MakeMaker;

my %pre_req = (
	'Text::vCard'	=> 1.9,
	'Template'	=> 2,
	'Test::More' 	=> 0.1,
	'Encode'	=> 0.1,
);

# Find out if OS is a Mac
my $is_mac = 0;
$is_mac = 1 if ($^O eq 'darwin');

# Only want Mac::Glue installed on macs!
$pre_req{'Mac::Glue'} = 1.22 if $is_mac;

WriteMakefile(
    'NAME'		=> 'Mac::Glue::Apps::AddressBookExport',
    'VERSION_FROM'	=> 'lib/Mac/Glue/Apps/AddressBookExport.pm',
    'PREREQ_PM'		=> \%pre_req,
);
