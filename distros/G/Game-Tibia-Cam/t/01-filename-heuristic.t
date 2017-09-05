use Test::More;

BEGIN {
    use_ok 'Game::Tibia::Cam';
}

my $cam = Game::Tibia::Cam->new(rec => "\x03\x01Hey");
ok $cam->{is_str};

done_testing;

