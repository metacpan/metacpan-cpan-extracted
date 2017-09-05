use Test::More;

BEGIN {
    use_ok 'Game::Tibia::Packet::Login';
}

my $instance = Game::Tibia::Packet::Login->new(version => 860);

done_testing;



