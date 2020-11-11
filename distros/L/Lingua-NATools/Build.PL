use strict;
use warnings;
use lib 'inc';
use Config::AutoConf '0.19';
use File::Spec::Functions 'catdir';
use Capture::Tiny 'capture';
use MyBuilder;


my ($a,$b,$version) = capture {
    `$^X -MNAT -e 'print NAT->VERSION'`;
};
if ($version && $version =~ /^\d+\.\d+$/) {
    print STDERR "\nOld NATools files found.\n";
    print STDERR "Please use 3rdParty/rm-old-nat.pl script to uninstall old NATools\n\n";
    exit 0;
}

my $DEBUG = 1;
my $builder = MyBuilder->new
  (
   module_name    => 'Lingua::NATools',
   license        => 'perl',
   dist_author    => ['Alberto Simões <ambs@cpan.org>'],
   meta_merge => {
       resources => {
           repository => 'https://natura.di.uminho.pt/svn/main/Lingua/NATools/',
           bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Lingua-NATools',
       }
   },
   needs_compiler => 1,
   recursive_test_files => 1,
   requires => {
                'File::Copy'           => '0',
                'Lingua::PT::PLNbase'  => '0.17',
                'IO::Socket'           => '1.28',
                'XML::TMX'             => '0.21',
                'XML::DT'              => '0.44',
                'Test::Harness'        => '2.26',
                'Storable'             => '2.04',
                'MLDBM'                => '2.00',
                'Fcntl'                => '1.03',
                'POSIX'                => '0',
                'DB_File'              => '1.804',
                'DBI'                  => '0',
                'DBD::SQLite'          => '1.30',
                'File::Path'           => '1.06',
                'File::Spec'           => '0.86',
                'File::Copy'           => '2.06',
                'IPC::Open2'           => '1.01',
                'Time::HiRes'          => '1.2',
                'Term::ReadLine'       => '1.01',
                'Lingua::PTD'          => '1.00',
                'URI::Escape'          => '3.26',
                'Lingua::Identify'     => '0.17',
                'Test::Pod'            => '1.20',
                'Test::Pod::Coverage'  => '1.06',
                'ExtUtils::Manifest'   => '0',
                'ExtUtils::MakeMaker'  => '6.31',
                'Memoize'              => '0',
                'Text::NSP'            => '1.09',
                'List::MoreUtils'      => '0',
                'Parse::Yapp::Driver'  => '1.05',
                'Compress::Zlib'       => '1.16',
                'CGI'                  => '0',
               },
   configure_requires => {
                          'Config::AutoConf'   => '0.311',
                          'ExtUtils::PkgConfig' => '1.12',
                          'Capture::Tiny'        => '0.15',
                          'Parse::Yapp::Driver'  => '1.05',
                          'ExtUtils::CBuilder' => '0.27',
                          'ExtUtils::LibBuilder' => '0.01',
                          'Module::Build'      => '0.3603',
                         },
   build_requires => {
                      'Config::AutoConf'     => '0.311',
                      'ExtUtils::CBuilder'   => '0.27',
                      'Pod::Man'             => '0',
                      'ExtUtils::LibBuilder' => '0.01',
                      'Parse::Yapp::Driver'  => '1.05',
                      'Module::Build'        => '0.3603',
                      'Capture::Tiny'        => '0',
                      'Test::More'           => '0',
                     },
   script_files => [map { "scripts/nat-$_" } qw(StarDict dict mkMakefile rank
                                                addDict dumpDicts mkRealDict sentence-align
                                                codify	examplesExtractor ngramsIdx shell
                                                compareDicts lex2perl pair2tmx substDict
                                                create makeCWB tmx2pair)],
   add_to_cleanup => [
                      'src/*.o',
                      'src/*.so',
                      'src/*.dylib', 'src/*.dll',
                      'xs/*.c',
                      '*.log',
                      'lib/Lingua/NATools/PatternRules.pm',
                      'xs/*.o',
                      't/bin/*.o', 't/bin/*.exe',
                      't/bin/corpus', 't/bin/words',
                      'Lingua-NATools-*',
                      '_build',
                     ],
  );


our $CAC = Config::AutoConf->new();

# Check our version
$builder->set_version($CAC);

# Check stdc headers
$CAC->check_stdc_headers || $builder->FAIL;

# check libm
$builder->notes('cflags' => ""); # just make sure it gets initialized
my $lib = $CAC->check_lm(undef, sub { $builder->FAIL });
if ($lib) {
    $builder->notes('libs' => "-l$lib");
}

# check zlib
if ($CAC->check_lib("z", "gzopen")  &&
    $CAC->check_lib("z", "gzread")  &&
    $CAC->check_lib("z", "gzwrite") &&
    $CAC->check_lib("z", "gzclose")) {
    $builder->notes('libs' => ($builder->notes('libs') || "") . " -lz");
} else { $builder->FAIL }

# check glib-2.0
$builder->pkg_config_check($CAC, 'glib-2.0', '2.8');

# check sqlite3
$builder->pkg_config_check($CAC, 'sqlite3', '3.5.0');
# check we have the binary in the path
$builder->check_sqlite3($CAC);

# check berkeley DB
$builder->check_berkeley_db($CAC, "4.3");

if ($DEBUG) {
    $CAC->msg_notice("LIBS: "  ,$builder->notes('libs'));
    $CAC->msg_notice("CFLAGS: ",$builder->notes('cflags'));
}

# check snow leopard without wcsdup
$builder->notes('have_wcsdup' => 1);
if ($^O eq 'darwin') {
  require POSIX;
  my (undef, undef, $release) = POSIX::uname();
  if ($release =~ /^(\d+)/ and $1 < 11) {
      $builder->notes('have_wcsdup' => 0);
  }
}

$builder->compute_lib_dir();
$builder->write_config_h();

$builder->add_build_element('usrlib');
$builder->install_path( 'usrlib' => $builder->notes('libdir') );

# $builder->add_build_element('pcfile');
# $builder->install_path( 'pcfile' => $builder->notes('pkgdir') );

# write build script
$builder->create_build_script;





