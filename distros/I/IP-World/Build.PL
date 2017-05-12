# script to set up for the installation of IP::World
use strict;
use warnings;
use Module::Build;
use Config;
use Probe::Perl();

# set up for compile tests
my $cc = $Config{'cc'};
$cc =~ s/\s+-.+$//; # remove possible trailing options
my $errwarn = qr/(^|\b)(warning|error)(\b|$)/im;

# test which cc optimize flags are allowed
my $opt;
# move '#' from following line to next line for debugging
# for my $s ('-g') {
for my $s ('-O3', '-O2', $Config{'optimize'}) {
    if (!$s) {last}
    $_ = `$cc -c $s test.c 2>&1`;
    if (!/$errwarn/) {
        $opt = $s;
        last;
}   }
unlink('test.o');

# derive a class from Module::Build that calls IP::World::Builder in each phase
my $class = Module::Build->subclass(code => <<'ZZZZ');
  use lib '.';
  use IP::World::Builder;
  sub process_dat_files {
    IP::World::Builder::do_dat($_[0]);
  }
ZZZZ

# create our Module::Build object with the parameters we want
my $build = $class->new(
    build_requires     => {'ExtUtils::CBuilder' => 0,
                           'File::Copy'         => 0,
                           'Test::More'         => 0},
    configure_requires => {'Config'             => 0,
                           'CPAN::DistnameInfo' => 0,
                           'Module::Build'      => '0.3607',
                           'Probe::Perl'        => 0},
    dist_author        => 'Craig MacKenna <craig@animalhead.com>',
    dynamic_config     => 1,
    license            => 'perl',
    module_name        => 'IP::World',
    requires           => {'perl'           => '5.7.3',
                           'Carp'           => 0,
                           'File::ShareDir' => 0,
                           'LWP::UserAgent' => '5.817',
                           'Test::More'     => 0.88, # done_testing
                           'HTTP::Status'   => '5.817',
                           'Time::HiRes'    => 0},
    script_files        => 'script',
    meta_merge => {
        license => 'other',
        resources => {
            repository => 'https://github.com/DrHyde/perl-modules-IP-World',
            bugtracker => 'https://github.com/DrHyde/perl-modules-IP-World/issues'
        }
    },
);
# set the optimize code determined above for the C compiler
if ($opt) {$build->config(optimize => $opt)}

# this arranges for 'process_dat_files' during each Build step
#   and thus maint_ip_world_db to be called during the install step
$build->add_build_element('dat');

# ask whether the user wants maint_ip_world_db to run a command when the DB is updated
my $cmd = $build->prompt("Should the DB-update utility run a command when the "
                       . "DB is updated?\nIf so enter it (if not just return):", "");

# if so, store the command to run in the config_data structure(s)
if ($cmd) {$build->config_data(cmd => $cmd)}

# save the path to the perl being used
my $perl = Probe::Perl->find_perl_interpreter();
$build->config_data(perl => $perl);

# make the Build file that we use to compile, test, and install
$build->create_build_script;
