package Test::DistHome;
use Dist::HomeDir;

sub test_get_home {
    return Dist::HomeDir::dist_home;
}

1;
