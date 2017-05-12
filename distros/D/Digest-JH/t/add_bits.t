use strict;
use warnings;
use Test::More tests => 2;
use Digest::JH;

my $msg  = 'ABC';
my $bits = unpack 'B*', $msg;

my $d = Digest::JH->new(224);

is(
    $d->reset->add($msg)->hexdigest,
    $d->reset->add_bits($bits)->hexdigest,
    'full message'
);

TODO: {
    local $TODO = 'consecutive calls to add_bits with non-bytes';

    is(
        $d->reset->add_bits(substr $bits, 0, 11)->hexdigest,
        eval {
            $d->reset->add_bits(substr $bits, 0, 3)
                    ->add_bits(substr $bits, 3, 5)
                    ->add_bits(substr $bits, 8, 3)
                    ->hexdigest
        },
        'consecutive calls to add_bits with non-bytes'
    );
}
