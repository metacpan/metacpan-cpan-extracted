use strict;
use warnings;
use inc::Module::Install;
use ExtUtils::Depends;

mkdir 'build';
my $pkg = ExtUtils::Depends->new( 'Hiredis::Raw', 'XS::Object::Magic' );

my $hiredis_prefix
    = defined $ENV{HIREDIS_PREFIX}    ? $ENV{HIREDIS_PREFIX}
    : -d '/usr/local/include/hiredis' ? '/usr/local'
    : -d '/usr/include/hiredis'       ? '/usr'
    :                                   '/usr/local'
    ;
my $hiredis_lib     = "$hiredis_prefix/lib";
my $hiredis_include = "$hiredis_prefix/include/hiredis";

if (!-d $hiredis_include) {
    warn qq{*** the include dir '$hiredis_include' wasn't found.  You may }
       .  q{need to install hiredis or set the HIREDIS_PREFIX environment }
       .  q{variable to the location of your hiredis install};
}

checklibs(
    libpath => $hiredis_lib,
    incpath => $hiredis_include,
    lib     => 'hiredis',
    header  => 'hiredis.h',
);

$pkg->set_inc("-I$hiredis_include");
$pkg->set_libs("-L$hiredis_prefix/lib -lhiredis");
$pkg->add_xs('hiredis.xs');
$pkg->add_pm(
    './lib/Hiredis/Raw.pm'            => '$(INST_LIBDIR)/Raw.pm',
    './lib/Hiredis/Async.pm'          => '$(INST_LIBDIR)/Async.pm',
    './lib/Hiredis/Raw/Constants.pm'  => '$(INST_LIBDIR)/Raw/Constants.pm',
);
$pkg->add_typemaps('typemap');
$pkg->save_config('build/IFiles.pm');

# use DDS;
# warn Dump({$pkg->get_makefile_vars});
makemaker_args(
    $pkg->get_makefile_vars,
);

name 'Hiredis-Raw';
license 'Perl_5';
perl_version '5.010';
all_from 'lib/Hiredis/Raw.pm';
readme_from 'lib/Hiredis/Async.pm';
ppport;


configure_requires 'ExtUtils::Depends';
configure_requires 'XS::Object::Magic' => '0.04';
requires 'Sub::Exporter';
requires 'XS::Object::Magic';
test_requires 'File::Which';
test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Test::TCP';
test_requires 'Test::Deep';

WriteAll;
