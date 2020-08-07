use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use File::Spec;
use Config       qw/%Config/;
use Cwd          qw//;
use FindBin      qw/$Bin/;
use IPC::Cmd     qw/can_run run/;
use Getopt::Long qw/GetOptions/;
use File::Basename qw//;
use File::Path qw//;

my $opt = {};
GetOptions(
    $opt,
    "static_link_to_mariadbclient",
    "mariadb_path=s",
    "testdb=s",
    "testhost=s",
    "testport=s",
    "testuser=s",
    "testpassword=s",
    "testsocket=s",
);
my $mariadb_path = $opt->{mariadb_path};

sub _run {
    my @cmd = @_;
    print "Will run: @cmd\n";
    system { $cmd[0] } @cmd;
}

use constant MARIADB_TARBALL_BASENAME => 'mariadb-connector-c-3.1.9-src.tar.gz';
use constant MARIADB_SRC_BASENAME     => 'mariadb-connector-c-3.1.9-src';
sub compile_mariadb_connector_c {
    my $our_src_root = $Bin;
    my $deps_dir     = File::Spec->catdir($our_src_root, 'deps');

    my $mariadb_src_tarball = File::Spec->catfile($deps_dir, MARIADB_TARBALL_BASENAME);
    my $mariadb_src_dir     = File::Spec->catdir($deps_dir, MARIADB_SRC_BASENAME);

    return $mariadb_src_dir if -x File::Spec->catfile($mariadb_src_dir, 'mariadb_config');

    File::Path::remove_tree($mariadb_src_dir);

    my $untar_out           = `tar -xf $mariadb_src_tarball -C $deps_dir`;

    my $patches = [
        {
            orig_file  => File::Spec->catfile($mariadb_src_dir, 'plugins', 'auth', 'CMakeLists.txt'),
            patch_file => File::Spec->catfile($deps_dir, 'statically_link_auth_plugins.patch'),
            explain    => 'authentication plugins are dynamically linked to libmariadbclient, we need them statically linked',
        }
    ];

    my $cwd = Cwd::cwd();
    {
        # Apply patches:
        foreach my $patch ( @$patches ) {
            my $target_file = $patch->{orig_file};
            my $patch_file  = $patch->{patch_file};
            _run( patch => $target_file => $patch_file );
        }
        chdir $mariadb_src_dir or die "cannot chdir to '$mariadb_src_dir': $!";
        my @cmake_args = qw(
            -DCMAKE_BUILD_TYPE=RelWithDebInfo
            -DWITH_SSL=OPENSSL
        );

        # cargo-cult; without this cmake cannot find openssl, but why is it hardcoded to these directories??
        push @cmake_args, qw<-DOPENSSL_ROOT_DIR=/usr/local/opt/openssl -DOPENSSL_LIBRARIES=/usr/local/opt/openssl/lib>
            if $^O eq 'darwin';
        _run(cmake => @cmake_args);
        _run(make => qw< mariadb_config >);
        _run(make => qw< mariadbclient  >);
        chdir $cwd;
    }

    return $mariadb_src_dir;
}

my $INSTALL_BASE;
foreach my $arg ( grep defined, @ARGV, $ENV{PERL_MM_OPT} ) {
    next unless $arg =~ /\bINSTALL_BASE=((?:\S+|\s(?!\S+=))+)\b/sm;
    $INSTALL_BASE = $1;
    last;
}

$mariadb_path ||= compile_mariadb_connector_c();
local $ENV{PATH} .= ':' . $mariadb_path if $mariadb_path; # TODO: pathsep

sub write_config_for_tests {
    my $opt = $_[0];
    my @opts_from_file = eval { require "t/mysql.mtest" };
    @opts_from_file    = eval { require "../t/mysql.mtest" }
        if @opts_from_file;

    my @ordered_options = qw/
        testhost
        testport
        testuser
        testsocket
        testpassword
        testdb
        force-embedded
        mysql_config
    /;

    for (0..$#ordered_options) {
        my $opt_name        = $ordered_options[$_];
        my $value           = $opts_from_file[$_];
        $opt->{$opt_name} ||= $value || '';
    }

    my $test_lib = File::Spec->catfile("t", "lib.pl");
    my $source_to_print = <<"EOPERL";
\$::test_host     = q\0$opt->{testhost}\0;
\$::test_port     = q\0$opt->{testport}\0;
\$::test_user     = q\0$opt->{testuser}\0 || \$ENV{'DBI_USER'} || '';
\$::test_socket   = q\0$opt->{testsocket}\0;
\$::test_password = q\0$opt->{testpassword}\0 || \$ENV{'DBI_PASS'} || '';
\$::test_db       = q\0$opt->{testdb}\0;
\$::test_force_embedded = 0+q\0$opt->{'force-embedded'}\0 if 0+q\0$opt->{'force-embedded'}\0;
\$::test_mysql_config = q\0$opt->{mysql_config}\0;

1;
EOPERL

    open my $fh, '>', $test_lib;
    print $fh $source_to_print;
    close $fh || die "Failed to create $test_lib: $!";
}

sub libname_to_so_names {
    my ($wanted_lib) = @_;

    my @config_entries = qw/dlext so/;

    my @libs_as_paths = map +( $_, "lib$_" ),
                        map "${wanted_lib}$_",
                        map +(/\A\./ ? $_ : ".$_"),
                        grep +(defined($_) && length($_)),
                          @Config{@config_entries};

    return @libs_as_paths;
}

sub get_paths_out_of_config_and_split {
    my @paths;
    foreach my $config_key ( @_ ) {
        next unless defined($Config{$config_key})
                 && length($Config{$config_key});
        # TODO: Embedded spaces???
        push @paths, split /\s+/, $Config{$config_key};
    }
    return grep defined, @paths;
}

{
    my @libpaths = get_paths_out_of_config_and_split(qw/
                        libpth
                        libpath
                        libspath
                        loclibpth
                        xlibpth
                        glibpth
                        glibpath
                    /);

    for my $rootdir ( grep defined, $mariadb_path, $INSTALL_BASE ) {
        unshift @libpaths,
            $rootdir,
            File::Spec->catdir($rootdir, "lib"),
            File::Spec->catdir($rootdir, "libmariadb"),
        ;
    }

    sub find_libpath_for { grep defined, map find_file_in($_, @libpaths), @_ }
}

{
    my @incpaths = get_paths_out_of_config_and_split(qw/
                        incpath
                        incpth
                        locincpth
                        locincpath
                        usrinc
                    /);

    for my $rootdir ( grep defined, $mariadb_path, $INSTALL_BASE ) {
        unshift @incpaths, $rootdir, File::Spec->catdir($rootdir, "include");
    }

    sub find_incpath_for { grep defined, map find_file_in($_, @incpaths), @_ }
}

sub find_file_in {
    my ($file, @dirs) = @_;

    foreach my $dir ( @dirs ) {
        my @try_in = (
            $dir,
            map scalar File::Spec->catdir($dir, $_), qw/mariadb maria mysqldb mysql/,
        );

        for my $path (@try_in) {
	        my $full_path = File::Spec->catfile($path, $file);
	        if (-f $full_path) {
	            return $path;
	        }
        }
    }

    return;
}


sub run_grab_output {
    my ($cmd) = @_;
    my( undef, undef, $full_buf, $stdout_buf, $stderr_buf )
        = run( command => $cmd, verbose => 0 );

    my $out = @{$stdout_buf // []}[0] // '';

    chomp($out);

    return $out;
}

write_config_for_tests($opt);

my @wanted_libs = qw( ssl crypto iconv  );

my ($libs, $inc, $ccflags, $lddlflags) = map $_//'',@Config{qw/libs inc ccflags lddlflags/};

# Perl might want to compile using -lgdbm or somesuch, but
# no such file may exist on this system.  So so some sleuthing.
my $cleaned_libs = "";
foreach my $lib ( split / /, $libs ) {
    if ( $lib !~ /\A-l/ ) {
        $cleaned_libs .= "$lib ";
        next;
    }

    my $wanted_lib = $lib;
    $wanted_lib =~ s/-l//;

    my @wanted_so = libname_to_so_names($wanted_lib);

    next unless @wanted_so;
    next unless find_libpath_for(@wanted_so);

    $cleaned_libs .= "$lib ";
}
$libs = $cleaned_libs;

$opt->{static_link_to_mariadbclient} //= 1;

if ( $opt->{static_link_to_mariadbclient} ) {
    my @needed_libs = qw( mariadbclient );

    my $ext = $Config{lib_ext};
    my @libfilenames = map {
        ( "lib${_}${ext}", "${_}${ext}" )
    } @needed_libs;

    my @libpaths = find_libpath_for(@libfilenames);

    LIB:
    foreach my $path (@libpaths) {
        PATH:
        foreach my $lib (@libfilenames) {
            my $file = File::Spec->catfile($path, $lib);
            next unless -f $file;
            $libs      .= " -L$path -lmariadbclient";
            next LIB;
        }
    }
}
else {
    push @wanted_libs, 'mariadbclient';

    if ( can_run('mariadb_config') ) {
        # woo!
        $libs    .= ' ' . run_grab_output([qw/mariadb_config --libs_r/]);
        $inc     .= ' ' . run_grab_output([qw/mariadb_config --include/]);
        $ccflags .= ' ' . run_grab_output([qw/mariadb_config --cflags/]);
    }
}

LIB:
foreach my $wanted_lib (@wanted_libs) {
    my @libs_as_paths = libname_to_so_names($wanted_lib);

    foreach my $lib ( @libs_as_paths ) {
        my ($libpath) = find_libpath_for($lib);
        next unless $libpath;

        $ccflags .= ' -L'.$libpath;
        $libs    .= ' -l'.$wanted_lib;

        next LIB;
    }
}

$inc = join " ", map('-I'.$_, find_incpath_for('mysql.h')), $inc;

WriteMakefile(
    NAME             => 'MariaDB::NonBlocking',
    AUTHOR           => q{Brian Fraser <fraserbn@gmail.com>},
    VERSION_FROM     => 'lib/MariaDB/NonBlocking.pm',
    ABSTRACT_FROM    => 'lib/MariaDB/NonBlocking.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    LIBS    => $libs,
    INC     => $inc,
    CCFLAGS   => $ccflags,
    LDDLFLAGS => $lddlflags,
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MariaDB-NonBlocking-* t/lib.pl dist/*' },
);
