use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;

subtest 'generate signature' => sub {
    my $fb = Facebook::OpenGraph->new(+{
        access_token        => 'qwerty',
        secret              => 'TheKingHasEarsShapedLikeADonkey',
        use_appsecret_proof => 1,
    });
    my $appsecret_proof = $fb->gen_appsecret_proof;
    is $appsecret_proof, '94a4877c83fbc2e1a0b182b3927a1f90dbf3f6e0e35513448a50c72aa49a12f4', 'appsecret_proof';
};

done_testing;
