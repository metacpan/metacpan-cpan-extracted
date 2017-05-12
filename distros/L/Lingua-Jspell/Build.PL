use strict;
use warnings;

use lib 'inc';
use File::Spec::Functions qw.catdir catfile.;
use MyBuilder;
use File::Copy;

my $version = get_version();
my $builder = MyBuilder->new
  (
   module_name    => 'Lingua::Jspell',
   license        => 'perl',
   dist_author    => ['Alberto Simões <ambs@cpan.org>',
                      'José João Almeida <jj@di.uminho.pt">',
                      'Ulisses Pinto'],
   needs_compiler => 1,
   requires => {
                'File::Copy'         => '0',
                'ExtUtils::Manifest' => '0',
                'Archive::Any'       => '0.0932',
                'Data::Compare'      => '1.22',
                'LWP::Simple'        => '0',
                'IPC::Open2'         => '0',
                'YAML'               => '0.72',
               },
   configure_requires => {
                          'Config::AutoConf'   => '0.14',
                          'ExtUtils::CBuilder' => '0.27',
                          'ExtUtils::LibBuilder' => '0.01',
                          'Module::Build'      => '0.3603',
                         },
   meta_merge => {
        resources  => {
                       repository => 'https://natura.di.uminho.pt/svn/main/Lingua/Jspell/',
        },
    },
   build_requires => {
                      'Config::AutoConf'   => '0.14',
                      'ExtUtils::CBuilder' => '0.27',
                      'ExtUtils::LibBuilder' => '0.01',
                      'Module::Build'      => '0.3603',
                      'Test::More'         => '0',
                     },
   add_to_cleanup => [
                      'src/*.o',
                      'src/*.so',
                      'src/*.dylib',
                      'src/*.dll',
                      'Lingua-Jspell-*',
                     ],
  );

$builder = detect_curses($builder);

## HACK  HACK  HACK  HACK
my $libdir = $builder->install_destination("bin");
my $pkgconfig = $libdir;
my $incdir    = $libdir;
if ($^O =~ /mswin32/i) {
    $libdir = undef;
    # Find a place where we can write.
    my @folders = split /;/, $ENV{PATH};
    my $installed = 0;
    my $target = "jspell-test.$$";
    while(@folders && !$installed) {
        $libdir = shift @folders;	

        copy("MANIFEST", catfile($libdir,$target));
        $installed = 1 if -f catfile($libdir, $target);
    }
    if (!$installed) {
        warn("Wasn't able to find a suitable place for libjspell.dll!");
    } else {
        print STDERR "libjspell.dll will be installed in $libdir\n";
        unlink catfile($libdir, $target);
    }
    $pkgconfig = undef;
    $incdir    = undef;
} else {
    $libdir =~ s/\bbin\b/lib/;
    $incdir =~ s/\bbin\b/include/;
    $pkgconfig =~ s/\bbin\b/catdir("lib","pkgconfig")/e;
}

$builder->notes('version'  => $version);
$builder->notes('libdir'   => $libdir);

$builder->config_data("version" => $version);
$builder->config_data("libdir"  => $libdir);
$builder->config_data("incdir"  => $incdir);
$builder->config_data("bindir"  => $builder->install_destination('bin'));

$builder->add_build_element('usrlib');
$builder->add_build_element('incdir');
$builder->add_build_element('pcfile');
$builder->install_path( 'usrlib' => $libdir );
$builder->install_path( 'incdir' => $incdir );
$builder->install_path( 'pcfile' => $pkgconfig );

$builder->create_build_script;


sub get_version {
    my $version = undef;
    open PM, "lib/Lingua/Jspell.pm" or die "Cannot open 'lib/Lingua/Jspell.pm' for reading: $!\n";
    while (<PM>) {
        if (m!^our\s+\$VERSION\s*=\s*'([^']+)'!) {
            $version = $1;
            last;
        }
    }
    close PM;
    die "Could not find VERSION on your .pm file. Weirdo!\n" unless $version;
}


sub detect_curses {
    my $builder = shift;

    my $LCURSES="";
    my $CCURSES="";
    if (not Config::AutoConf->check_header("ncurses.h")) {
	$CCURSES="-DNOCURSES";
    }

    if ($CCURSES ne "-DNOCURSES") {
        if (not Config::AutoConf->check_lib("ncurses", "tgoto")) {
            $CCURSES="-DNOCURSES";
        } else {
            $LCURSES="-lncurses";
        }
    }

    if ($^O eq "MSWin32") {
	$CCURSES.=" -D__WIN__"
    }

    $builder->notes('ccurses' => $CCURSES);
    $builder->notes('lcurses' => $LCURSES);

    return $builder;
}
