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
    my $res = sub {
        if ($env->{PATH_INFO} eq '/get') {
            my $data = $session->get('data') || 'NO DATA';
            return [200, [], [$data]];
        } elsif ($env->{PATH_INFO} eq '/set') {
            my $data = do { local $/; my $fh = $env->{'psgi.input'}; <$fh> };
            $session->set('data', $data);
            return [200, [], [$data]];
        } else {
            return [404, [], []];
        }
    }->();
    $session->finalize_psgi_response($res);
    return $res;
};
my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
is $mech->get('/get')->content, 'NO DATA';
is $mech->post('/set', Content => 'hoge:hoge')->content, 'hoge:hoge';
is $mech->get('/get')->content, 'hoge:hoge';

done_testing;
