use strict;
use Test::More 0.98;

use Imager::IMBarcode::JP;

subtest 'zipcode' => sub {
    {
        my $imbjp = eval { Imager::IMBarcode::JP->new(zipcode => 'abcdef') };
        like(
            $@,
            qr/Attribute\s\(zipcode\)\sdoes\snot\spass\sthe\stype\sconstraint/,
            'non-integer',
        );
    }

    {
        my $imbjp = eval { Imager::IMBarcode::JP->new(zipcode => '123') };
        ok(!$@, 'can make instance with an int with missing digits');
        isa_ok($imbjp, 'Imager::IMBarcode::JP', 'new instance');

        my $imager = eval { $imbjp->draw };
        like(
            $@,
            qr/^Invalid\szipcode\(\):\s123\b/,
            'croak',
        );
    }

    {
        my $imbjp = eval { Imager::IMBarcode::JP->new(zipcode => '1234567') };
        ok(!$@, 'can make instance with valid attribute');
        isa_ok($imbjp, 'Imager::IMBarcode::JP', 'new instance');
        my $imager = eval { $imbjp->draw };
        ok(!$@, 'can draw()');
        isa_ok($imager, 'Imager');
    }
};

subtest 'address' => sub {
    {
        my $imbjp = eval { Imager::IMBarcode::JP->new(address => sub { 1 }) };
        like(
            $@,
            qr/Attribute\s\(address\)\sdoes\snot\spass\sthe\stype\sconstraint/,
            'non-string',
        );
    }

    {
        my $imbjp = eval { Imager::IMBarcode::JP->new(address => '!!!') };
        ok(!$@, 'can make instance with an unauthorized chars');
        isa_ok($imbjp, 'Imager::IMBarcode::JP', 'new instance');

        my $imager = eval { $imbjp->draw };
        like(
            $@,
            qr/^Invalid\saddress\(\):\s!!!\s*/,
            'croak',
        );
    }

    {
        my $imbjp = eval { Imager::IMBarcode::JP->new(address => 'FOO-BAR') };
        ok(!$@, 'can make instance with valid attribute');
        isa_ok($imbjp, 'Imager::IMBarcode::JP', 'new instance');
        my $imager = eval { $imbjp->draw };
        ok(!$@, 'can draw()');
        isa_ok($imager, 'Imager');
    }
};

done_testing;
