use strict;
use warnings;
use Crypt::CBC;
use HTTP::Session2::ClientStore2;
use Test::More;

my $cipher = Crypt::CBC->new(
    {
        key              => 'abcdefghijklmnop',
        cipher           => 'Rijndael',
    }
);

{
    my $warn = '';
    local $SIG{__WARN__} = sub {
        $warn .= "@_";
    };
    my $session = HTTP::Session2::ClientStore2->new(
        env => {
        },
        secret => 's3cret',
        cipher => $cipher,
    );
    like $warn, qr/Secret string too short/;
}
{
    my $warn = '';
    local $SIG{__WARN__} = sub {
        $warn .= "@_";
    };
    my $session = HTTP::Session2::ClientStore2->new(
        env => {
        },
        secret => 's3cretooooooooooooooooooo',
        cipher => $cipher,
    );
    unlike $warn, qr/Secret string too short/;
}

done_testing;
