#!/usr/bin/env perl
#  Copyright (C) 2006, 2008, 2011-2012, 2014, 2017
#  Rocky Bernstein <rockycpan.org>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Module::Build;
use ExtUtils::PkgConfig;
use Config;
use File::Copy;

my %libcdio_pkgcfg = ExtUtils::PkgConfig->find ('libcdio');
use constant MIN_LIBCDIO_VERSION => 1.1;
my $lv = $libcdio_pkgcfg{'modversion'};
if (exists($libcdio_pkgcfg{'modversion'})) {
    $libcdio_pkgcfg{'modversion'} =~ m{\A((?:\d+)(?:\.\d+))};
    my $libcdio_version = $1;
    if (defined($libcdio_version)) {
	if ($libcdio_version < MIN_LIBCDIO_VERSION) {
	    printf STDERR "
***
*** You need to have libcdio %s or greater installed. (You have $lv).
*** Get libcdio from http://www.gnu.org/software/libcdio/download.html
", MIN_LIBCDIO_VERSION;
	    die "OS unsupported - or maybe it is. This message is here to appease testing services like CPANTS that look for messages like this";

	} else {
	    print "Good, I found libcdio version $lv installed.\n";

	}
    } else {
	print STDERR "
***
*** Can't parse libcdio version $lv.
";
	exit 1;
    }
} else {
    print STDERR "
***
*** Can't find libcdio configuration info. Is libcdio installed?
*** Get libcdio from http://www.gnu.org/software/libcdio/download.html
";
    die "OS unsupported - or maybe it is. This message is here to appease testing services like CPANTS that look for messages like this";
}


my $class = Module::Build->subclass( class => 'MyModuleBuild',
    code => q!
        use File::Basename;
        use Data::Dumper;
        sub process_swig_files {
            my $self = shift;
            my $verb = $self->runtime_params('verbose');
            $verb = 0 if $self->runtime_params('quiet');
            #my @p = @_;
            print "process swig files\n" if $verb;
            my $swigdeps = $self->config('swig_source');
            my @swig_flags = $self->split_like_shell($self->config('swig_flags'));
            my @swigsource = keys %$swigdeps;
            my $lib = 'lib';
            #my $blib_lib = File::Spec->catfile('blib', 'lib');
            foreach my $file (@swigsource) {
                #FIXME add dir $self->config('swig_files')
                my $basename = basename($file, '.swg');
                my $cfile = $basename."_wrap.c";
                my $pmfile = File::Spec->catfile($lib,"$basename.pm");
                if ($self->up_to_date($swigdeps->{$file}, $cfile) &&
                    $self->up_to_date($swigdeps->{$file}, $pmfile)) {
                    next if $self->up_to_date($file, $cfile) &&
                        $self->up_to_date($cfile, $pmfile);
                }
                print "swig: $file -> $cfile\n" if $verb;
                $self->do_system('swig', '-o', $cfile, '-perl', '-outdir',
                    $lib, @swig_flags, $file);
                $self->copy_if_modified(from => $pmfile, to_dir => 'blib');
            }
            return 1;
        }
        sub process_c_files {
            my $self = shift;
            my $verb = $self->runtime_params('verbose');
            $verb = 0 if $self->runtime_params('quiet');
            #my @p = @_;
            print "process c files\n" if $verb;
            my $cfiles = $self->rscan_dir('./',qr/\.c$/);
            # if none return
            #set $self->quiet() for CBuilder->new
            $self->quiet($verb?0:1);
            my $cb = $self->cbuilder(); # get a ExtUtils::CBuilder object
            print "  CBuilder: ",$cb->VERSION,"\n" if $verb;
            #setenv TMPDIR for cc ??
            foreach my $file (@$cfiles) {
                my $basename = basename($file, '_wrap.c');
                $basename = basename($file, '.c') if not defined $basename;
                my $libname = $basename.".".$self->config('dlext');
                $libname = File::Spec->catfile('blib', 'arch',$libname);
                next if $self->up_to_date($file,$libname);
                print "(CC) $file -> $basename.so\n" if $verb;
                my $obj = $cb->compile(source => $file,
                    ## include_dirs => $self->config('include_dirs'),
                    extra_compiler_flags => $self->config('extra_compiler_flags'));
                print "CB compiled: $obj\n" if $verb;
                my $lib = $cb->link(objects => $obj,
                    extra_linker_flags => $self->config('extra_linker_flags'));
                print "CB generated: $lib\n" if $verb;
                $self->copy_if_modified(from => $lib, to => $libname);
            }
            return 1;
        }
    !);
#

my $builder = $class->new(
    module_name         => 'Device::Cdio',
    add_to_cleanup      => [ 'Device-Cdio-*', 'tmp*', 'cover_db'],
    configure_requires  => { 'Module::Build' => 0.38 },
    create_makefile_pl  => 'small',
    dist_abstract       =>
    'Perl bindings for CD Input and control library (libcdio)',
    dist_author         => 'Rocky Bernstein <rocky@cpan.org>',
    dist_version_from   => 'lib/Device/Cdio.pm',
    license             => 'gpl',
    needs_compiler      => 1,
    release_status      => 'stable',  # or 'testing' which will append TRIAL to tarball
    meta_merge => {
	resources => {
	    bugtracker  => 'https://github.com/rocky/Perl-Device-Cdio/issues',
	    repository  => 'http://github.com/rocky/Perl-Device-Cdio'
	}
    },

    requires => {
        'ExtUtils::PkgConfig'     => '1.03',
        'Test::More'              => 0,
        'version'                 => 0,
        'ExtUtils::CBuilder'      => '0.28',
    },
    sign                => 1);

$builder->config(swig_files          => './');
$builder->config(swig_source => {   # with dependencies as hash value
    'swig/perlcdio.swg' =>
        ['swig/audio.swg', 'swig/device.swg',
        'swig/disc.swg', 'swig/device_const.swg', 'swig/disc.swg',
        'swig/read.swg', 'swig/track.swg', 'swig/types.swg'],
    'swig/perliso9660.swg' => ['swig/types.swg'],
    'swig/perlmmc.swg', => ['swig/types.swg']} );

if($builder->have_c_compiler()) {
    $builder->notes('c_compiler' => 1);
    print "C compiler found - check swig\n" if $builder->config('verbose');
    if(!$builder->config('obj_ext')) {
        $builder->config('obj_ext','.o');
    }
    if(!$builder->config('dlext')) {
        $builder->config('dlext','so');
    }
    my $swig_installed = check_swig(
        verbose => $builder->config('verbose'));
    $builder->notes(swig_installed => $swig_installed);
    my ($ccflags, $ldflags,$swig_flags) = check_c_compiler(
        $builder->config('cc'), $builder->config('ccflags'));
    $builder->config(extra_linker_flags  => $ldflags);
    $builder->config(extra_compiler_flags => $ccflags);
    if($swig_installed) {
        $builder->config(swig_flags => $swig_flags);
        $builder->add_build_element('swig');
        $builder->add_to_cleanup('lib/perl*.pm','*.c');
    }
    $builder->add_build_element('c');
    $builder->add_to_cleanup('*.o','*.so','tmp*',);
    # better: $builder->config('dlext') $builder->config('obj_ext')
    #add a cleanup build_element ??
    #rearrange order of the build process
    my @el = @{$builder->build_elements};
    my $i = grep {$el[$_] eq 'c'} 0..$#el;
    unshift @el, splice @el, $i, 1;
    @el = @{$builder->build_elements};
    $i = grep {$el[$_] eq 'swig'} 0..$#el;
    unshift @el, splice @el, $i, 1;
    #if ($builder->config('verbose')) {
    #    foreach my $i (@el) {
    #        print " $i ";
    #    }
    #    print "\n";
    #}
}
#distclean : unlink lib/perliso9660.pm, lib/perlmmc.pm lib/perlcdio.pm
# c files?
$builder->create_build_script();

sub try_compile {
    my ($c, %args) = @_;

    my $ok = 0;
    my $tmp = "tmp$$";
    local(*TMPC);

    my $obj_ext = $builder->config('obj_ext') || ".o";
    unlink("$tmp.c", "$tmp$obj_ext");

    if (open(TMPC, ">", "$tmp.c")) {
	print TMPC $c;
	close(TMPC);

	my $cccmd = $builder->config('cc');
	my $errornull;
	my $ccflags = $builder->config('ccflags');
        $ccflags .= " $args{ccflags}" if $args{ccflags};

        if ($args{silent} ) {
	    $errornull = "2>/dev/null" unless defined $errornull;
	} else {
	    $errornull = '';
	}

    $cccmd = "$cccmd -o $tmp $ccflags $tmp.c $errornull";

	printf "cccmd = $cccmd\n" if $args{verbose};
	my $res = system($cccmd);
	$ok = defined($res) && $res == 0;

	if ( !$ok ) {
	    my $errno = $? >> 8;
	    local $! = $errno;
	    print "

*** The test compile of '$tmp.c' failed: status $?
*** (the status means: errno = $errno or '$!')
*** DO NOT PANIC: this just means that *some* you may get some innocuous
*** compiler warnings.
";
	}
	unlink("$tmp.c");

    }
    return $ok;
}

sub try_cflags ($) {
    my ($ccflags) = @_;
    my $c_prog = "int main () { return 0; }\n";
    print "Checking if ",$builder->config('cc')," supports \"$ccflags\"...";
    my $result = try_compile($c_prog, ccflags=>$ccflags);
    if ($result) {
	print "yes\n";
	return " $ccflags";
    }
    print "no\n";
    return '';

}

sub check_swig {

print "Checking for SWIG...";
my @swig_version = `swig -version 2>&1`;
if ($?) {
    my $errno = $? >> 8;
    print "
*** I don't see SWIG installed. I'll use the SWIG-generated file
*** that comes with the distribution. If you want SWIG, get it
*** from http://www.swig.org
";
    print "*** Output was:
	@swig_version
" if @swig_version;
} else {
    print "ok\n";
    return 1;
}
    return 0;
}

sub check_c_compiler {
    my $cc= shift;
    my $ccflags = shift;
    $ccflags .= ' '. $libcdio_pkgcfg{cflags};
    ## Swig produces a number of GCC warnings. Turn them off if we can.
    $ccflags .= try_cflags("-Wno-strict-aliasing");
    $ccflags .= try_cflags("-Wno-unused-function");
    $ccflags .= try_cflags("-Wno-unused-value");
    $ccflags .= try_cflags("-Wno-unused-function");
    $ccflags .= try_cflags("-Wno-unused-variable");

    my %libiso9660_pkgcfg = ExtUtils::PkgConfig->find ('libiso9660');
    my $ldflags = "$libcdio_pkgcfg{libs} $libiso9660_pkgcfg{libs} -lcdio";
    my $swig_flags='';

if ('cygwin' eq $Config{osname} &&
    $Config{shrpenv} =~ m{\Aenv LD_RUN_PATH=(.*)\Z} ) {
    $ldflags .= " -L$1 -lperl";
    # Should we check the 32-ness?
    $swig_flags = '-DNEED_LONG';
} elsif ('darwin' eq $Config{osname}) {
    $ldflags .= " -bundle -flat_namespace";
}
#lddlflags ??
$ccflags =~ s/^\s+//;
$ccflags =~ s/\s+$//;
$ldflags =~ s/^\s+//;
$ldflags =~ s/\s+$//;

return ($ccflags, $ldflags, $swig_flags);
}
