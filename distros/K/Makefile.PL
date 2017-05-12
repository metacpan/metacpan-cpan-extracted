use strict;
use warnings;
use inc::Module::Install;
use ExtUtils::Depends;

mkdir 'build';
my $pkg = ExtUtils::Depends->new('K');

my $c_o = $ENV{KOBJ};
if (!defined $c_o || !-f $c_o) {
    die  q{*** Unable to find the required file c.o which is distributed by }
      .  q{kx.com.  Set the environment variable KOBJ to the location of your }
      .  q{c.o. Find the correct file for your system here: http://kx.com/q. }
      .  q{For example the url for 64 bit linux systems is }
      . qq{http://kx.com/q/l64/c.o .\n}
      ;
}

my $kh_dir = $ENV{KHDIR};
if (!defined $kh_dir || !-f "$kh_dir/k.h") {
    die  q{*** Unable to find the required file k.h which is distributed by }
      .  q{kx.com.  Set the environment variable KHDIR to the directory }
      .  q{containing k.h. The latest version of k.h can be found here: }
      .  q{http://code.kx.com/wsvn/code/kx/kdb+/c/c/k.h . Be sure to use the }
      . qq{k.h file that corresponds to the c.o file that you're using.\n}
      ;
}

my $kx_ver = $ENV{KXVER};
if (!$kx_ver) {
    print "*** Defaulting to KXVER=3. Set the env variable KXVER to overide.\n";
    $kx_ver = 3;
}

$pkg->set_inc("-Iq");
$pkg->set_libs("-lpthread"); # not always needed
$pkg->add_xs('K.xs');
$pkg->add_pm(
    './lib/K/Raw.pm' => '$(INST_LIBDIR)/K/Raw.pm',
    './lib/K.pm'     => '$(INST_LIBDIR)/K.pm',
);
$pkg->add_typemaps('typemap');
$pkg->save_config('build/IFiles.pm');

makemaker_args(
    $pkg->get_makefile_vars,
    OBJECT => "\$(O_FILES) $c_o", # link all the C files too
    DEFINE => "-DKXVER=$kx_ver",
    INC    => "-I$kh_dir",
    # OPTIMIZE => '-g -DDEBUG',
);

name 'K';
license 'Perl_5';
perl_version '5.010';
repository 'http://github.com/wjackson/k-perl';
all_from 'lib/K.pm';
ppport;

configure_requires 'ExtUtils::Depends';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Math::Int64';
test_requires 'File::Which';
test_requires 'FindBin';
test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Test::TCP';

WriteAll;
