
use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;

use File::Basename;
use Path::Class qw/ dir file /;
use File::chdir;

use lib "lib";


use_ok("File::Corresponding");
use_ok("File::Corresponding::Group");
use_ok("File::Corresponding::File::Profile");



{
    local $CWD = dir( dirname(__FILE__), "data" );

    ok(
        my $corresponding = File::Corresponding->new({ }),
        "Create new corresponding ok",
    );
    is_deeply($corresponding->profile_groups, [], "default profile_groups empty");

    throws_ok(
        sub { $corresponding->load_config_file("Missing file") },
        qr/Could not read config file .Missing file..+?File 'Missing file' does not exist/s,
        "load_config_file missing file dies ok",
    );

    my $file = file("example", ".corresponding_file");
    $corresponding->load_config_file($file);
    is_deeply(
        $corresponding->profile_groups,
        [
            File::Corresponding::Group->new({
                name => 'All MyApp classes',
                file_profiles => [
                    File::Corresponding::File::Profile->new({
                        regex   => '/Controller.(\w+)\.pm$/',
                        name    => 'Cat Controller',
                        sprintf => 'Controller/%s.pm'
                    }),
                    File::Corresponding::File::Profile->new({
                        regex   => '/Model.Schema.(\w+)\\.pm$/',
                        name    => 'DBIC Schema',
                        sprintf => 'Model/Schema/%s.pm'
                    }),
                    File::Corresponding::File::Profile->new({
                        regex   => '/root.template.(\w+)\.pm$/',
                        name    => 'Template',
                        sprintf => 'root/template/%s.pm'
                    }),
                ],
            }),
        ],
    );

}



__END__
