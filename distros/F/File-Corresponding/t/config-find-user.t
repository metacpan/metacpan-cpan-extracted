
use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;

use File::chdir;
use File::Basename;
use Path::Class qw/ dir file /;

use lib "lib";



use_ok("File::Corresponding::Config::Find");



diag("user_config");
{
    local $CWD = dir( dirname(__FILE__), "data" );

    is(
        File::Corresponding::Config::Find->new()->user_config("Dude, no way there is a file name like this!"),
        undef,
        "Missing file name returned undef",
    );
    is(
        File::Corresponding::Config::Find->new(preferred_dirs => [dir(".")])->user_config(
            "Dude, no way there is a file name like this!"
        ),
        undef,
        "Missing file name with cwd as preferred_dirs returned undef",
    );


    is_deeply(
        File::Corresponding::Config::Find->new(preferred_dirs => [dir(".")])->user_config(
            "config/myapp.ini"
        ),
        my $found_config_file = file(".", "config/myapp.ini"),
        "Found file name with cwd as referred_dirs",
    );
    ok(-r $found_config_file, "  and it's readable");

    is_deeply(
        File::Corresponding::Config::Find->new(preferred_dirs => [dir("config")])->user_config(
            "myapp.ini"
        ),
        file("config", "myapp.ini"),
        "Found file name with config as referred_dirs",
    );


}



__END__
