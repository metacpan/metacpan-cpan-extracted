# t/04_tempdir.t
use strict;
use warnings;

use Test::More tests =>  8;

use_ok('File::Save::Home', qw|
    get_home_directory
    make_subhome_temp_directory 
| );
use_ok('File::Spec::Functions', qw| splitdir |);
use_ok('Cwd');


my ($cwd, $homedir);
$cwd = cwd();

ok($homedir = get_home_directory(), 'home directory is defined');
ok(chdir $homedir, "able to change to $homedir");

opendir my $DIRH, $homedir or die "Unable to open $homedir for reading: $!";
my %subdirs =  map {$_, 1} 
            grep { -d $_ and ! ($_ eq '.' or $_ eq '..') } 
            readdir($DIRH);
closedir $DIRH or die "Unable to close $homedir after reading: $!";

ok(chdir $cwd, "able to change to $cwd");

my $tmpdir = make_subhome_temp_directory();
ok(  (-d $tmpdir), "$tmpdir exists");

my @homedirels = splitdir($homedir);
my @tmpdirels = splitdir($tmpdir);
shift(@tmpdirels) for @homedirels;
ok(! exists $subdirs{$tmpdirels[0]}, 
    "directory $tmpdirels[0] did not previously exist");

