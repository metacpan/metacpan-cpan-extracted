use inc::Module::Install;
use Config;
use ExtUtils::CppGuess;
use ExtUtils::Typemaps;
use ExtUtils::Typemaps::ObjectMap;
use ExtUtils::Typemaps::STL;
use List::Util qw(first);

all_from 'lib/Mesos.pm';
readme_pod_from 'lib/Mesos.pm';

homepage   'https://github.com/mark-5/perl-mesos';
bugtracker 'https://github.com/mark-5/perl-mesos/issues';
repository 'https://github.com/mark-5/perl-mesos.git';

assert_mesos_libs();
assert_protobuf_headers(2005000);

requires_cplusplus;
cc_append_to_ccflags guess_cpp_standard();
cc_include_paths 'include';
cc_libs '-lmesos';
cc_src_paths 'src';
clean_files 'src/typemap';
create_typemap('src/typemap');
makemaker_args XSOPT => "-hiertype";
use_ppport;

author_tests 'xt';

no_index directory => 'bin';
clean_files 'inc', 'Makefile', 'MANIFEST.SKIP.', 'META.*', 'MYMETA.*', 'ppport.h';
cpanfile;
WriteAll;


sub create_typemap {
    my ($file) = @_;
    my $map = ExtUtils::Typemaps->new;
    $map->merge(typemap => $_->new) for qw(
        ExtUtils::Typemaps::ObjectMap
        ExtUtils::Typemaps::STL
    );
    $map->merge(typemap => ExtUtils::Typemaps->new(file => $_))
        for glob "src/*.map";
    $map->write(file => $file);
}

sub assert_mesos_libs {
    my $result = _assert_mesos_libs();
    return if $result->{success};

    my %extra = _find_mesos_extra_args();
    if (%extra) {
        my $inc = "-I$extra{inc}" if $extra{inc};
        my $lib = "-L$extra{lib}" if $extra{lib};
        $result = _assert_mesos_libs($inc, $lib);
        cc_include_paths $extra{inc} if $extra{inc};
        cc_libs $lib if $lib;
    }

    if (!$result->{success}) {
        my $message = "Can't link/include mesos C++ library:\n";
        $message .= "$result->{cmd}\n\n";
        $message .= "$result->{output}\n\n";
        warn $message;
        exit 0;
    }
}

sub _assert_mesos_libs {
    my ($inc, $lib) = @_;
    my $src = write_cpp(headers => ["mesos/mesos.hpp"]);
    (my $bin = $src) =~ s/\.cpp$//;

    my $cmd = sprintf "%s %s %s -lmesos -o $bin $src", cpp_compiler(), $inc//"", $lib//"";
    my $output = `$cmd 2>&1`;
    my $failed = $?;
    -e $_ and unlink $_ for $bin, $src;

    return {
        cmd     => $cmd,
        output  => $output,
        success => !$failed,
    };
}

sub _find_mesos_extra_args {
    my %extra;
    my $inc = $ENV{PERL_MESOS_INCLUDE} // first {-e "$_/mesos.hpp"} qw(
        /usr/include
        /usr/local/include
    );
    $extra{inc} = $inc if $inc;

    my $lib = $ENV{PERL_MESOS_LIB};
    $extra{lib} = $lib if $lib;

    return %extra;
}

sub assert_protobuf_headers {
    my ($need_version) = @_;
    my $code = q|printf("%d", GOOGLE_PROTOBUF_VERSION);|;
    my $src = write_cpp(
        code    => $code,
        headers => ["google/protobuf/message.h", "cstdio"],
    );
    (my $bin = $src) =~ s/\.cpp$//;

    my %extra = _find_mesos_extra_args();
    my $inc = '';
    my $lib = '';
    if (%extra) {
        $inc = "-I$extra{inc}" if $extra{inc};
        $lib = "-L$extra{lib}" if $extra{lib};
    }

    my $cmd = sprintf "%s %s %s -o %s %s", cpp_compiler(), $inc, $lib, $bin, $src;
    my $output = `$cmd 2>&1`;
    my $failed = $?;

    if ($failed) {
        my $message = "Can't link/include protobuf C++ library\n";
        $message .= "$cmd\n\n";
        $message .= "$output\n";
        warn $message;
        exit 0;
    }

    my $version = qx|$bin|;
    unless ($version and $version >= $need_version) {
        warn "Protobuf version must $need_version or above. Detected $version";
        exit 0;
    }

    -e $_ and unlink $_ for $bin, $src;
}

sub write_cpp {
    my (%args) = @_;
    my($fh, $path) = File::Temp::tempfile(SUFFIX => '.cpp');
    print $fh "#include <$_>\n" for @{$args{headers}||[]};
    print $fh "int main(void) { $args{code} return 0; }\n";
    close $fh;
    return $path;
}

our $_cpp_compiler;
sub cpp_compiler {
    $_cpp_compiler ||= do {
        my $guess = ExtUtils::CppGuess->new->guess_compiler;
        sprintf join " ", $Config{cc}, @{$guess}{qw(extra_cflags extra_lflags)};
    };
}

sub guess_cpp_standard {
    my @standards = qw(-std=c++11 -std=c++0x);
    for my $std (@standards) {
        my $src = write_cpp(code => '');
        (my $bin = $src) =~ s/\.cpp$//;
        my $cmd = sprintf "%s $std -o $bin $src", cpp_compiler();

        my $output = `$cmd 2>&1`;
        my $failed = $?;
        -e $_ and unlink $_ for $bin, $src;

        return $std unless $failed;
    }

    warn "Couldn't guess language standard flag that works with $Config{cc}.\n";
    warn "Tried @standards.\n";
    exit 0;
}
