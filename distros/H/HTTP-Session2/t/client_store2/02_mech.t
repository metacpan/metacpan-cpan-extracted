use strict;
use warnings;
use Test::More;
use HTTP::Session2::ClientStore2;
use Crypt::CBC;
use Crypt::Rijndael;
use Test::WWW::Mechanize::PSGI;

my $cipher = Crypt::CBC->new(
    {
        key    => 'abcdefghijklmnop',
        cipher => 'Rijndael',
    }
);
my $app = sub {
    my $env = shift;
    my $session = HTTP::Session2::ClientStore2->new(
        env => $env,
        secret => 'very long secret string',
        cipher => $cipher,
    );
    my $cnt = $session->get('cnt') || 0;
    $cnt++;
    $session->set('cnt' => $cnt);
    my $res = [200, [], [$cnt]];
    $session->finalize_psgi_response($res);
    return $res;
};
my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
is $mech->get('/')->content, 1;
is $mech->get('/')->content, 2;
is $mech->get('/')->content, 3;

done_testing;
