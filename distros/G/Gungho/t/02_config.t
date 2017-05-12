use strict;
use Test::More (tests => 3);

BEGIN
{
    use_ok("Gungho");
    use_ok("Data::Dumper");
}

my $config = Gungho->load_config("t/data/02_config/yaml.yml");

is($config->{foo}, 1, "Expected foo = 1, but got " . Dumper($config));