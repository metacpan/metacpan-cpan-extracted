use strict;
use File::Find;
use File::Temp;
use Module::Build::WithXSpp;

my @mesos_include_dirs;
find(sub {push @mesos_include_dirs, $File::Find::name if -d}, 'include');

my $build = Module::Build::WithXSpp->new(
    dist_abstract   => 'lib/Mesos.pm',
    dist_author     => 'Mark Flickinger <maf@cpan.org>',
    module_name     => 'Mesos',
    license         => 'perl',
    recommends      => {
        'Test::LeakTrace' => 0,
    },
    requires        => {
        'version'          => 0,
        'AnyEvent'         => 0,
        'Exporter'         => 0,
        'Moo'              => 1.006000,
        'Try::Tiny'        => 0,
        'Type::Tiny'       => 0,
        'Package::Stash'   => 0,
        'Async::Interrupt' => 0,
        'ExtUtils::ParseXS'       => 3.18,
        'Google::ProtocolBuffers' => 0,
    },
    configure_requires => {
        'File::Find' => 0,
        'File::Temp' => 0,
    },
    test_requires => {
        'Test::Most'     => 0,
        'FindBin::libs'  => 0,
    },
    extra_typemap_modules => {
        'ExtUtils::Typemaps::ObjectMap' => '0',
        'ExtUtils::Typemaps::STL'       => '0',
    },
    early_includes       => [qw(mesos/scheduler.hpp mesos/executor.hpp)],
    extra_compiler_flags => [qw(-std=c++11)],
    extra_linker_flags   => [qw(-lmesos)],
    release_status       => "stable",
    meta_merge           => {
        resources => {
            homepage   => "https://github.com/mark-5/perl-mesos",
            bugtracker => "https://github.com/mark-5/perl-mesos/issues",
            repository => "https://github.com/mark-5/perl-mesos.git",
        },
    },
);

my $include_dirs = $build->include_dirs;
my $compiler = $build->config('cc');

assert_protobuf_libs(compiler => $compiler, include_dirs => $include_dirs);

unless (check_mesos_libs(compiler => $compiler, include_dirs => $include_dirs)) {
    my $extra_includes = find_mesos_install_path();
    push @$include_dirs, $extra_includes;
    check_mesos_libs(assert => 1, compiler => $compiler, include_dirs => $include_dirs);
}

if (lc $^O eq 'darwin' and lc $compiler eq 'cc') {
    push @{$build->extra_compiler_flags}, '-Wno-reserved-user-defined-literal';
}

push @$include_dirs, @mesos_include_dirs; 

$build->create_build_script;

sub check_mesos_libs {
    my (%args) = @_;
    my $include = join ' ', map {"-I$_"} @{$args{include_dirs}||[]};
    my $in = write_lib_check(headers => "mesos/mesos.hpp");
    (my $out = $in) =~ s/\.cpp$//;

    my $command = "$args{compiler} $include -lmesos -o $out $in";
    my $output = qx|$command 2>&1|;
    my $failed = $?;
    -e $_ and unlink $_ for $in, $out;

    if ($failed and $args{assert}) {
        my $message = "Can't link/include mesos C++ library:\n";
        $message .= "\t" . $output;
        warn $message;
        exit 0;
    }
    return !$failed;
}

sub assert_protobuf_libs {
    my (%args) = @_;
    my $include = join ' ', map {"-I$_"} @{$args{include_dirs}||[]};
    my $code = q|printf("%d", GOOGLE_PROTOBUF_VERSION);|;
    my $in = write_lib_check(code => $code, headers => ["google/protobuf/message.h", "cstdio"]);
    (my $out = $in) =~ s/\.cpp$//;

    my $output = qx|$args{compiler} $include -o $out $in 2>&1|;
    my $failed = $?;

    if ($failed) {
        my $message = "Can't link/include mesos C++ library:\n";
        $message .= "\t" . $output;
        warn $message;
        exit 0;
    }

    my $version = qx|$out|;
    unless ($version and $version >= 2005000) {
        warn "Protobuf version must 2.5.0 or above. Detected $version";
        exit 0;
    }

    -e $_ and unlink $_ for $in, $out;
    return 1;
}

sub write_lib_check {
    my (%args) = @_;
    my($fh, $in) = File::Temp::tempfile(SUFFIX => '.cpp');
    print $fh "#include <$_>\n" for ref $args{headers} ? @{$args{headers}} : $args{headers};
    print $fh "int main(void) { $args{code} return 0; }\n";
    close $fh;
    return $in;
}

sub find_mesos_install_path {
    my ($path) = grep {-d} map {"$_/mesos"} qw(/usr/include /usr/local/include);
    unless ($path) {
        $path = Module::Build->prompt("Please enter path to mesos headers", "/usr/local/include/mesos");
    }
    return $path;
}
