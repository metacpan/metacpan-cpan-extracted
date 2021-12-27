use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

use Health::SHC::Extract;
use Health::SHC::Validate;

my $shc = Health::SHC::Extract->new();
isa_ok($shc, 'Health::SHC::Extract');

my @qrcodes = $shc->extract_qr_from_png('t/testdata/sample-qr-code.png');
ok(@qrcodes, 'Successfully called extract_qr_from_png');
my $keys_json = 't/testdata/sample-qr-code-keys.json';

my $shc_valid = Health::SHC::Validate->new();
isa_ok($shc_valid, 'Health::SHC::Validate');

foreach my $qr (@qrcodes) {
    ok($qr =~ m/shc:\//, '    Smart Health Card Data Found');

    my $data = $shc_valid->get_valid_data($qr, $keys_json);
    isa_ok($data, 'HASH');

    use Health::SHC;
    my $sh = Health::SHC->new();
    my @patients = $sh->get_patients($data);

    foreach (@patients) {
        print "Patient: ", $_->{given}, " ", $_->{middle}, " ", $_->{family}, "\n";
    }

    my @immunizations = $sh->get_immunizations($data);

    print "Vacination Provider", "\t", "Date", "\n";
    foreach (@immunizations) {
        print $_->{provider}, "\t", $_->{date}, "\n";
    }

    my @vaccines = $sh->get_vaccines($data);

    print "Manufacturer\tLot Number\tCode\tCode System\n";
    foreach (@vaccines) {
        print $_->{manufacturer}, "\t\t", $_->{lotNumber}, "\t\t";
        my $codes = $_->{codes};
        foreach my $tmp (@$codes) {
            print   $tmp->{code}, "\t",
                    $tmp->{system}, "\t";
        }
        print "\n";
    }
}
