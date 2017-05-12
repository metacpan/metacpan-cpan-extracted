use Test::More;
use IO::File;
use Finance::Currency::Convert::XE;

# Skip if doing a regular install
plan skip_all => "Author tests not required for installation"
    unless ( $ENV{AUTOMATED_TESTING} );

my $fh = IO::File->new('Changes','r')   or plan skip_all => "Cannot open Changes file";

plan no_plan;

my $latest = 0;
while(<$fh>) {
    next        unless(m!^\d!);
    $latest = 1 if(m!^$Finance::Currency::Convert::XE::VERSION!);
    like($_, qr!\d[\d._]+\s+(\d{2}/\d{2}/\d{4}|\w{3} \w{3} \d{2} \d{4}|\w{3} \w{3}\s+\d{1,2} \d{2}:\d{2}:\d{2} \d{4})!,'... version has a datestamp');
}

is($latest,1,'... latest version not listed');
