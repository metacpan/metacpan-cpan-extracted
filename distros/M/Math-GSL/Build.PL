#!/usr/bin/perl -w
# This has been heavily modified from the Device::Cdio Build.PL
# Jonathan "Duke" Leto <jonathan@leto.net>

#    Copyright (C) 2006 Rocky Bernstein <rocky@cpan.org>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
use strict;
use warnings;
use Config;
use Data::Dumper;
use Module::Build;
use lib 'inc';
use GSLBuilder;
use Ver2Func;
use File::Spec::Functions qw/:ALL/;
use Math::GSL::Alien;
use File::Temp qw(tempdir);

our $MIN_GSL_VERSION = "1.15";

my $gsl_conf;

check_alien_gsl_share_dir();
$gsl_conf = check_gsl_version_gsl_config();
$gsl_conf = check_gsl_version_alien_gsl() if not $gsl_conf;
$gsl_conf = check_gsl_version_pkgconfig() if not $gsl_conf;

my ($major,$minor,$tiny) = split /\./, $gsl_conf->{gsl_version};
my $ccflags = $gsl_conf->{gsl_cflags};
my $ldflags = $gsl_conf->{gsl_libs};

# In case GSL in installed in the system-wide directory, $ccflags is
# empty (because pkg-config remove -I/usr/include), but swig needs it

my $swig_flags = '';
$swig_flags = ' -I/usr/include' if $ccflags =~ /^\s*$/;

$ccflags .= " $Config{ccflags}"; # we need this for some Linuxes

## Swig produces a number of GCC warnings. Turn them off if we can.
$ccflags .= try_cflags("-Wall");
$ccflags .= try_cflags("-Wno-sometimes-uninitialized");
#$ccflags .= try_cflags("-Wno-strict-aliasing");
$ccflags .= try_cflags("-Wno-unused-function");
$ccflags .= try_cflags("-Wno-unused-value");
$ccflags .= try_cflags("-Wno-unused-function");
$ccflags .= try_cflags("-Wno-unused-variable");
$ccflags .= try_cflags("-Wno-gnu");
$ccflags .= try_cflags("-g");

$swig_flags = "$gsl_conf->{gsl_cflags} $swig_flags";

if ( GSLBuilder::is_cygwin()  && $Config{shrpenv} =~ m{\Aenv LD_RUN_PATH=(.*)\Z} ) {
    $ldflags .= " -L$1 -lperl";
    # Should we check the 32-ness?
    $swig_flags = '-DNEED_LONG';
} elsif (GSLBuilder::is_msys()) {
    # It is not possible to leave a symbol in a PE DLL undefined at link time, 
    # to be satisfied at runtime, as it is instead possible with most UNIX shared objects
    # See https://autotools.io/libtool/windows.html
    # So we need to link with libperl.dll.a on MSYS2
    $ldflags .= " -L$Config{archlib}/CORE -lperl";
} elsif (GSLBuilder::is_darwin()) {
    $ldflags .= ' -bundle -flat_namespace ';
}

if ($Config{archname} =~ /x86_64|amd64/ ) {
    $ldflags .= ' -fPIC  -fno-omit-frame-pointer ';
    $ccflags .= ' -fPIC  -fno-omit-frame-pointer ';
}
# this causes warnings with clang + OSX
$ccflags = $Config{cccdlflags} . ' ' . $ccflags unless GSLBuilder::is_darwin();
my $platform_uses_signed_char = platform_uses_signed_char();

my $ver2func = Ver2Func->new( $gsl_conf->{gsl_version}, $platform_uses_signed_char );

my $cleanup = qq{
                 xs/*_wrap*.c core *.core swig/system.i swig/renames.i
                 swig/*.o Makefile Math-GSL-* tmp* pod2ht*.tmp _build pm
                 lib/Math/GSL/[A-z]+/* blib *.so *.orig
                } . join " ", map { catfile( (qw/lib Math GSL/, "$_.pm") ) } $ver2func->subsystems;


$ldflags = '-shared ' . $ldflags unless GSLBuilder::is_darwin();

my $swig_version;

unless (GSLBuilder::is_release()) {
    $swig_version = swig_version();
    if ((split(/\./, $swig_version))[0] < 2) {
        print "
***
*** You need to have SWIG 2.0 or greater installed. (You have $swig_version).
*** Get SWIG at http://www.swig.org/\n";
        exit 0;
    }
}

$ccflags = "$ccflags " . ($ENV{CC_FLAGS}||''),

my $builder = GSLBuilder->new(
    module_name         => 'Math::GSL',
    add_to_cleanup      => [ $cleanup ],
    dist_abstract       => 'Interface to the GNU Scientific Library using SWIG',
    dist_author         => 'Jonathan Leto <jonathan@leto.net>',
    dist_version_from   => catfile(qw/lib Math GSL.pm/),
    include_dirs        => [],
    extra_linker_flags  => $ldflags,
    extra_compiler_flags=> $ccflags . " " . $swig_flags,
    # suppress swig warnings about GSL source code
    swig_flags          => $swig_flags . " -w451,454",
    license             => 'gpl',
    meta_merge     => {
        resources => {
            repository  => 'https://github.com/hakonhagland/perl-math-gsl/tree/master'
        },
    },
    build_requires => {
        'Test::Most'      => '0.31',
        'Test::More'      => 0,
        'Test::Exception' => '0.21',
        'Test::Class'     => '0.12',
        'Test::Taint'     => '1.06',
    },
    requires => {
        'Math::Complex'   => 0,
        'Scalar::Util'    => 0,
        'version'         => '0.77',
        'perl'            => '5.8.1',
        'parent'          => 0,
    },
    sign                  => 0,
    configure_requires => {
        'PkgConfig'         => '0.07720',
        'Module::Build'     => '0.38',
        'Math::GSL::Alien'  => '1.03',
    },
    swig_version          => $swig_version,
    current_version       => $gsl_conf->{gsl_version},
    gsl_prefix            => $gsl_conf->{gsl_prefix},
);


$builder->add_build_element('swig');

$builder->create_build_script();

print "Have a great day!\n";


### aux functions

sub swig_version {
    my $swig = GSLBuilder::swig_binary_name();
    my $cmd  = "$swig -version";
    my $out  = `$cmd`;

    if ($?) {
        die "Can't run [$cmd] : $out";
    }
    if ($out =~ /swig\s+version\s+([\d\.]+)\n/i) {
        return $1;
    } else {
        die "Can't parse SWIG version from this output:\n$out";
    }
}

sub modify_env {
    $ENV{PKG_CONFIG_PATH} ||= '';

    # TODO: What about windows and darwin?
    my @guess = qw(/usr/pkgconfig /usr/lib/pkgconfig /usr/local/lib/pkgconfig
                   /usr/local/pkgconfig /usr/libdata/pkgconfig
                   /usr/local/libdata/pkgconfig /opt/pkgconfig);

    unshift @guess, $ENV{PKG_CONFIG_PATH} if $ENV{PKG_CONFIG_PATH};

    $ENV{PKG_CONFIG_PATH} = join(":", @guess);
}

sub try_compile {
    my ($c, %args) = @_;

    my $ok = 0;
    my $tmp = "tmp$$";
    local(*TMPC);

    my $obj_ext = $Config{_o} || ".o";
    unlink("$tmp.c", "$tmp$obj_ext");

    if (open(TMPC, ">", "$tmp.c")) {
    print TMPC $c;
    close(TMPC);

    my $cccmd = $args{cccmd};
    my $errornull;
    my $ccflags =  $Config{'ccflags'};
    $ccflags .= " $args{ccflags}" if $args{ccflags};

    if ($args{silent} ) {
        $errornull = "2>/dev/null" unless defined $errornull;
    } else {
        $errornull = '';
    }

        $cccmd = "$Config{'cc'} -o $tmp $ccflags $tmp.c $errornull"
        unless defined $cccmd;

    printf "cccmd = $cccmd\n" if $args{verbose};
    my $res = system($cccmd);
    $ok = defined($res) && $res == 0;

    if ( !$ok ) {
        my $errno = $? >> 8;
        local $! = $errno;
        print "

*** The test compile of '$tmp.c' failed: status $?
*** (the status means: errno = $errno or '$!')
*** DO NOT PANIC: this just means that you may get some innocuous
*** compiler warnings.
";
    }
    unlink("$tmp.c");

    }
    return $ok;
}

sub try_cflags {
    my ($ccflags) = @_;
    my $c_prog = "int main () { return 0; }\n";
    print "Checking if $Config{cc} supports \"$ccflags\"...";
    my $result = try_compile($c_prog, ccflags=>$ccflags);
    if ($result) {
        print "yes\n";
        return " $ccflags";
    }
    print "no\n";
    return '';
}

# Returns true if the platform uses signed char
sub platform_uses_signed_char {
    my $c_prog = <<'END';
#include <limits.h>  // Include limits.h to use CHAR_MIN
// Test if char is signed on the given platform
// If CHAR_MIN is not 0, then char is signed
// Returns 0 if char is signed, 1 if char is unsigned
int main() {
    if (CHAR_MIN != 0) {
        return 0;
    }
    else {
        return 1;
    }
}
END
    # Create a temporary directory for the C program and executable
    my $tempdir = tempdir(CLEANUP => 1);
    my $prog_name = 'signed_char';
    my $prog_name_path = catfile($tempdir, "${prog_name}.c");
    open (my $fh, '>', $prog_name_path) or die "Could not open file '$prog_name_path' $!";
    print $fh $c_prog;
    close $fh;
    my $executable = catfile($tempdir, $prog_name);
    my $sub_name = 'platform_uses_signed_char()';
    # Compile the C program
    system($Config{'cc'}, '-o', $executable, $prog_name_path);
    if ($? == -1) {
        print "${sub_name}: failed to execute: $!\n";
    }
    elsif ($? & 127) {
        printf "${sub_name}: child died with signal %d, %s coredump\n",
            ($? & 127),  ($? & 128) ? 'with' : 'without';
    }
    elsif ($? >> 8) {
        printf "${sub_name}: gcc: failed to compile: exit value %d\n", $? >> 8;
    }
    # Execute the compiled program and capture the return value
    system($executable);
    if ($? == -1) {
        die "${sub_name}: Failed to execute the compiled program: $!";
    }
    elsif ($? & 127) {
        printf "${sub_name}: child died with signal %d, %s coredump\n",
            ($? & 127),  ($? & 128) ? 'with' : 'without';
    }
    # The return value from the C program is in the high 8 bits of the exit status
    my $return_value = $? >> 8;
    if ($return_value == 0) {
        print "platform: char is signed\n";
    }
    else {
        print "platform: char is unsigned\n";
    }
    return $return_value == 0;
}



sub check_alien_gsl_share_dir {
    if (Math::GSL::Alien->install_type eq "share") {
        my $dist_dir = Math::GSL::Alien->dist_dir;
        my $bin_dir = File::Spec->catfile( $dist_dir, "bin" );
        # Try to use gsl-config in the share directory first, so add that to the PATH
        $ENV{PATH} .= ":$bin_dir";
    }
    else {
        # If Math::GSL::Alien->install_type is "system", gsl-config
        # might be in the PATH already, but not necessarily. The user could also have installed
        # GSL in a non-standard location, then set PKG_CONFIG_PATH before installing Math::GSL::Alien.
        my $command = 'gsl-config';
        my $check_command = $^O eq 'MSWin32' ? 'where' : 'which';
        # Check if the command exists in PATH
        my $exists = qx($check_command $command 2>/dev/null);
        if (!$exists) {
            # Math::GSL::Alien property bin_dir is usually not set in this case
            my $bin_dir = Math::GSL::Alien->bin_dir;
            if ($bin_dir && (-d $bin_dir)) {
                $ENV{PATH} .= ":$bin_dir";
            }
            else {
                # We might get lucky and derive the bin dir from the libs value
                my $libs = Math::GSL::Alien->libs;
                my $lib_dir = $libs =~ m{-L(\S+)} ? $1 : '';
                if ($lib_dir) {
                    my $bin_dir = $lib_dir =~ s{/lib}{/bin}r;
                    if (-d $bin_dir) {
                        $ENV{PATH} .= ":$bin_dir";
                    }
                }
            }
        }
    }
}

sub check_gsl_version_alien_gsl {
    my $gsl_version = Math::GSL::Alien->version;
    if (!defined $gsl_version) {
        print "***
*** Can't find GSL with Math::GSL::Alien (this should not happen)
*** Trying with PkgConfig.\n";
        return undef;
    }
    my $libs = Math::GSL::Alien->libs;
    my $config = Math::GSL::Alien->runtime_prop;
    my $prefix = $config->{prefix};
    my $cflags = Math::GSL::Alien->cflags;
    return {
        gsl_version => $gsl_version,
        gsl_prefix  => $prefix,
        gsl_libs    => $libs,
        gsl_cflags  => $cflags,
    };
}

sub check_gsl_version_pkgconfig {

    eval { require PkgConfig };
    if ($@) {
        print "\nI see that you are a CPANTester, you really should install PkgConfig !\n"
            if $ENV{AUTOMATED_TESTING};
        print "\nPkgConfig is currently needed to find GSL for the compilation of this module.\n";
        exit 0;
    }

    modify_env();
    print "\nAsking PkgConfig with ENV{PKG_CONFIG_PATH}=" . ($ENV{PKG_CONFIG_PATH} || '') . "\n\n";
    my $gsl_pkgcfg = PkgConfig->find ('gsl');

    if ($gsl_pkgcfg->errmsg) {
        my $errmsg = $gsl_pkgcfg->errmsg;
        print "
***
*** PkgConfig failed with error message: $errmsg
*** Probably you need to install GSL?
***  On Debian/Ubuntu you can use:
***      sudo apt-get install libgsl0-dev
***  On Mac you can use homebrew (http://brew.sh/):
***      brew install gsl
***  On Fedora/CentOS/RedHat/openSUSE you can use
***      sudo yum install gsl-devel
*** Or get GSL at http://www.gnu.org/software/gsl\n";
        exit 0;
    }

    my $gsl_version = $gsl_pkgcfg->pkg_version;
    if (GSLBuilder::cmp_versions($gsl_version, $MIN_GSL_VERSION) == -1) {
                printf "
***
*** You need to have GSL %s or greater installed. (You have $gsl_version).
*** Get GSL at http://www.gnu.org/software/gsl\n", $MIN_GSL_VERSION;
                exit 0;
            }

    return {
        gsl_version => $gsl_version,
        gsl_prefix  => $gsl_pkgcfg->get_var("prefix"),
        gsl_libs    => join (" ", $gsl_pkgcfg->get_ldflags),
        gsl_cflags  => join (" ", $gsl_pkgcfg->get_cflags),
    };
}

sub check_gsl_version_gsl_config {

    print "Checking for GSL using gsl-config\n";

    my $gsl_version = qx{gsl-config --version};
    if (not defined $gsl_version) {
        print "
***
*** Can't find GSL with gsl-config.
*** Trying with PkgConfig.
    ";
        return undef;
    }

    chomp($gsl_version);
    chomp(my $gsl_prefix  = qx{gsl-config --prefix});
    chomp(my $gsl_cflags  = qx{gsl-config --cflags});
    chomp(my $gsl_libs    = qx{gsl-config --libs});

    my $path_system = catfile(qw/swig system.i/);

    open my $fh, ">", "$path_system" or die "Could not create $path_system : $!";

    my $current_version;

    if ($gsl_version =~ m{\A(\d+(?:\.\d+)+)}) {
        $current_version = $1;
        my @current = split /\./, $current_version;
        print $fh "#define GSL_VERSION $current[0].$current[1]\n";
        print $fh "#define GSL_MAJOR_VERSION $current[0]\n";
        print $fh "#define GSL_MINOR_VERSION $current[1]\n";

        if (GSLBuilder::cmp_versions($current_version, $MIN_GSL_VERSION) == -1) {
            printf "
***
*** You need to have GSL %s or greater installed. (You have $gsl_version).
*** Get GSL at http://www.gnu.org/software/gsl\n", $MIN_GSL_VERSION;
            exit 0;
        } else {
            print "Found GSL $gsl_version (via gsl-config) installed in $gsl_prefix\n";
            return {
                gsl_version => $current_version,
                gsl_prefix  => $gsl_prefix,
                gsl_libs    => $gsl_libs,
                gsl_cflags  => $gsl_cflags,
            };
        }
    } else {
        print "
***
*** Can't parse GSL version $gsl_version.
*** Trying with PkgConfig.
";
        return undef;
    }
    close $fh or die "Could not close $path_system : $!";
}
