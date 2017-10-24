use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use File::Spec;
use Config       qw/%Config/;
use IPC::Cmd     qw/can_run run/;
use Getopt::Long qw/GetOptions/;

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

my $INSTALL_BASE;
foreach my $arg ( grep defined, @ARGV, $ENV{PERL_MM_OPT} ) {
    next unless $arg =~ /\bINSTALL_BASE=((?:\S+|\s(?!\S+=))+)\b/sm;
    $INSTALL_BASE = $1;
    last;    
}

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
        unshift @libpaths, $rootdir, File::Spec->catdir($rootdir, "lib");
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
    clean => { FILES => 'MariaDB-NonBlocking-* t/lib.pl' },
);
