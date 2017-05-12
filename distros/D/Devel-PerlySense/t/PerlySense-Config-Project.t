#!/usr/bin/perl -w
use strict;

use Test::More tests => 29;
use Test::Exception;

use File::Path;
use Path::Class;
use File::Slurp qw/ write_file /;

use Data::Dumper;

use lib "lib";

use_ok("Devel::PerlySense::Config::Project");
use_ok("Devel::PerlySense");





ok(
    my $oPerlySense = Devel::PerlySense->new(),
    "New PerlySense object ok",
);


my $dir = "t/data/config";
my $dirTemp = "$dir/temp";

note("Creating temp dir");
rmtree($dirTemp);
mkpath($dirTemp);
ok(-e $dirTemp, "Temp dir created ok");
END {
    note("Removing  temp dir");
    rmtree($dirTemp);
    ok( ! -e $dirTemp, "Temp file gone");
}



ok(
    my $oConfig = Devel::PerlySense::Config::Project->new(),
    "Created config in temp dir ok",
);



is_deeply($oConfig->rhConfig, {}, "Empty config");

throws_ok(
    sub {
        $oConfig->loadConfig(dirRoot => $dirTemp);
    },
    qr/Could not open config file .t.data.config.temp..PerlySenseProject.project.yml./,
    "Can't load nonexisting config file ok",
);

is_deeply($oConfig->rhConfig, {}, "  Empty config");
is($oConfig->dirRoot, undef, "  No dirRoot set");


ok( ! -e "dirTemp/.PerlySenseProject", "No project dir");
ok(
    $oConfig->createFileConfigDefault(dirRoot => $dirTemp),
    "Created new project config",
);
like(
    $oConfig->dirRoot,
    qr/t.data.config.temp$/,
    "dirRoot set to the new location",
);
ok(-e "$dirTemp/.PerlySenseProject", "Project dir created");
ok(-e "$dirTemp/.PerlySenseProject/project.yml", "Project config file created");
is(scalar keys %{$oConfig->rhConfig}, 5, "  Loaded config");
is(
    $oConfig->rhConfig->{run_file}->[0]->{moniker},
    "Test",
    "Sample key in structure is correct",
);


ok(
    $oConfig->createFileCriticDefault(dirRoot => $dirTemp),
    "Created new project Perl::Critic config",
);
ok(-e "$dirTemp/.PerlySenseProject/.perlcritic", "Perl::Critic config file created");





note("Re-create, rename file");
my $globBackupProject = file("$dirTemp/.PerlySenseProject/project.yml") . ".*";

ok($oConfig->rhConfig->{run_file}->[0]->{moniker} = "Blah", "Changed moniker");
ok(
    $oConfig->createFileConfigDefault(dirRoot => $dirTemp),
    "Created new project config",
);
my @aFileBackup = glob($globBackupProject);
is(
    scalar @aFileBackup,
    1,
    "Original Project config file renamed",
) or warn("GLOB ($globBackupProject)\n");
like(
    $oConfig->dirRoot,
    qr/t.data.config.temp$/,
    "dirRoot set to the new location",
);
is(
    $oConfig->rhConfig->{run_file}->[0]->{moniker},
    "Test",
    "Sample key in structure is correct",
);



my $globBackupCritic = file("$dirTemp/.PerlySenseProject/.perlcritic") . ".*";

ok(
    $oConfig->createFileCriticDefault(dirRoot => $dirTemp),
    "Created new Critic config",
);
my @aFileBackupCritic = glob($globBackupCritic);
is(
    scalar @aFileBackupCritic,
    1,
    "Original Critic config file renamed",
) or warn("GLOB ($globBackupCritic)\n");



note("Create another one");
sleep(1);
ok(
    $oConfig->createFileConfigDefault(dirRoot => $dirTemp),
    "Created new project config",
);
@aFileBackup = glob("$dirTemp/.PerlySenseProject/project.yml.*");
is(
    scalar @aFileBackup,
    2,
    "Original Project config file renamed",
);



#parse config file with syntax error
my $fileConfig = file($dirTemp, $oConfig->nameFileConfig) . "";
write_file($fileConfig, "lskdjf  sdf this isn't YAML at all\n\n");
throws_ok(
    sub { $oConfig->loadConfig(dirRoot => $dirTemp); },
    qr/Could not read \.PerlySense Project config file \(.+?\): YAML::Tiny /,
    "Died correctly on invalid YAML",
);




__END__
