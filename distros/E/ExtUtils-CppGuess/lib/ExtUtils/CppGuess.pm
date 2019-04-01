package ExtUtils::CppGuess;

use strict;
use warnings;

=head1 NAME

ExtUtils::CppGuess - guess C++ compiler and flags

=head1 SYNOPSIS

With L<Extutils::MakeMaker>:

    use ExtUtils::CppGuess;

    my $guess = ExtUtils::CppGuess->new;

    WriteMakefile
      ( # MakeMaker args,
        $guess->makemaker_options,
        );

With L<Module::Build>:

    my $guess = ExtUtils::CppGuess->new;

    my $build = Module::Build->new
      ( # Module::Build arguments
        $guess->module_build_options,
        );
    $build->create_build_script;

=head1 DESCRIPTION

C<ExtUtils::CppGuess> attempts to guess the system's C++ compiler
that is compatible with the C compiler that your perl was built with.

It can generate the necessary options to the L<Module::Build>
constructor or to L<ExtUtils::MakeMaker>'s C<WriteMakefile>
function.

=head1 METHODS

=head2 new

Creates a new C<ExtUtils::CppGuess> object.
Takes the path to the C compiler as the C<cc> argument,
but falls back to the value of C<$Config{cc}>, which should
be what you want anyway.

You can specify C<extra_compiler_flags> and C<extra_linker_flags>
(as strings) which will be merged in with the auto-detected ones.

=head2 module_build_options

Returns the correct options to the constructor of C<Module::Build>.
These are:

    extra_compiler_flags
    extra_linker_flags
    config => { cc => ... }, # as of 0.15

Please note the above may have problems on Perl <= 5.8 with
L<ExtUtils::CBuilder> <= 0.280230 due to a Perl RE issue.

=head2 makemaker_options

Returns the correct options to the C<WriteMakefile> function of
C<ExtUtils::MakeMaker>.
These are:

    CCFLAGS
    dynamic_lib => { OTHERLDFLAGS => ... }
    CC # as of 0.15

If you specify the extra compiler or linker flags in the
constructor, they'll be merged into C<CCFLAGS> or
C<OTHERLDFLAGS> respectively.

=head2 is_gcc

Returns true if the detected compiler is in the gcc family.

=head2 is_msvc

Returns true if the detected compiler is in the MS VC family.

=head2 is_clang

Returns true if the detected compiler is in the Clang family.

=head2 is_sunstudio

Returns true if the detected compiler is in the Sun Studio family.

=head2 add_extra_compiler_flags

Takes a string as argument that is added to the string of extra compiler
flags.

=head2 add_extra_linker_flags

Takes a string as argument that is added to the string of extra linker
flags.

=head2 compiler_command

Returns the string that can be passed to C<system> to execute the compiler.
Will include the flags returned as the Module::Build
C<extra_compiler_flags>.

Added in 0.13.

=head2 linker_flags

The same as returned as the Module::Build C<extra_linker_flags>.

Added in 0.13.

=head2 iostream_fname

Returns the filename to C<#include> to get iostream capability.

This can be used a bit creatively to be portable in one's XS files,
as the tests for this module need to be:

  # in Makefile.PL:
  $guess->add_extra_compiler_flags(
    '-DINCLUDE_DOT=' .
    ($guess->iostream_fname =~ /\./ ? 1 : 0)
  );

  // in your .xs file:
  #if INCLUDE_DOT
  #include <string.h>
  #else
  #include <string>
  #endif

Added in 0.15.

=head2 cpp_flavor_defs

Returns the text for a header that C<#define>s
C<__INLINE_CPP_STANDARD_HEADERS> and C<__INLINE_CPP_NAMESPACE_STD> if
the standard headers and namespace are available. This is determined by
trying to compile C++ with C<< #define <iostream> >> - if it succeeds,
the symbols will be defined, else commented.

Added in 0.15.

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

Steffen Mueller <smueller@cpan.org>

Tobias Leich <froggs@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2010, 2011 by Mattia Barbon.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use Config ();
use File::Basename qw();
use Capture::Tiny 'capture_merged';
use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir);

our $VERSION = '0.19';

sub new {
    my( $class, %args ) = @_;
    my $self = bless { %args }, $class;

    # Allow override of default %Config::Config; useful in testing.
    if( ! exists $self->{config} || ! defined $self->{config} ) {
      if ($ExtUtils::MakeMaker::Config::VERSION) {
        # tricksy hobbitses are overriding Config, go with it
        $self->{config} = \%ExtUtils::MakeMaker::Config::Config;
      } else {
        $self->{config} = \%Config::Config;
      }
    }

    # Allow a 'cc' %args.  If not supplied, pull from {config}, or $Config{cc}.
    if( ! exists $self->{cc} || ! defined $self->{cc} ) {
      $self->{cc}
        = exists $self->{config}{cc} && defined $self->{config}{cc}
        ? $self->{config}{cc}
        : $Config::Config{cc};
    }

    # Set up osname.
    if( ! exists $self->{os} || ! defined $self->{os} ) {
      $self->{os}
        = exists $self->{config}{osname} && defined $self->{config}{osname}
        ? $self->{config}{osname}
        : $^O;
    }

    # Set up osvers.
    if( ! exists $self->{osvers} || ! defined $self->{osvers} ) {
      $self->{osvers}
        = exists $self->{config}{osvers} && defined $self->{config}{osvers}
        ? $self->{config}{osvers}
        : '';
    }

    return $self;
}

# Thus saith the law: All references to %Config::Config shall come through
# $self->_config.  Accessors shall provide access to key components thereof.
# Testing shall thus grow stronger, verifying performance for platforms diverse
# to which access we have not.

sub _config { shift->{config} }
sub _cc     { shift->{cc}     }
sub _os     { shift->{os}     }
sub _osvers { shift->{osvers} }

# This is IBM's "how to compile on" list with lots of compilers:
# https://www.ibm.com/support/knowledgecenter/en/SS4PJT_5.2.0/com.ibm.help.cd52.unix.doc/com.ibm.help.cdunix_user.doc/CDU_Compiling_Custom_Programs.html
sub guess_compiler {
  my $self = shift;
  return $self->{guess} if $self->{guess};
  my $c_compiler = $self->_cc;
#  $c_compiler = $Config::Config{cc} if not defined $c_compiler;
  my %guess;
  if ($self->{os} eq 'freebsd' && $self->{osvers} =~ /^(\d+)/ && $1 >= 10) {
    $self->{is_clang} = 1; # special-case override
    %guess = (
      compiler_command => 'clang++',
      extra_lflags => '-lc++',
    );
  } elsif( $self->_cc_is_sunstudio( $c_compiler ) ) {
    %guess = (
      compiler_command => 'CC',
      extra_cflags => '',
      extra_lflags => '',
    );
  } elsif( $self->_cc_is_clang( $c_compiler ) ) {
    %guess = (
      compiler_command => 'clang++',
      extra_cflags => '-xc++',
      extra_lflags => '-lstdc++',
    );
  } elsif( $self->_cc_is_gcc( $c_compiler ) ) {
    %guess = (
      compiler_command => 'g++',
      extra_cflags => '-xc++',
      extra_lflags => '-lstdc++',
    );
  } elsif ( $self->_cc_is_msvc( $c_compiler ) ) {
    %guess = (
      compiler_command => 'cl',
      extra_cflags => '-TP -EHsc',
      extra_lflags => 'msvcprt.lib',
    );
  } else {
    my $v1 = `$c_compiler -v`;
    my $v2 = `$c_compiler -V`;
    my $v3 = `$c_compiler --version`;
    my $os = $self->_os;
    die <<EOF;
Unable to determine a C++ compiler for '$c_compiler' on $os
Version attempts:
-v: '$v1'
-V: '$v2'
--version: '$v3'
EOF
  }
  $guess{extra_lflags} .= ' -lgcc_s'
    if $self->_os eq 'netbsd' and
    $guess{compiler_command} =~ /g\+\+/i and
    $guess{extra_lflags} !~ /-lgcc_s/;
  $self->{guess} = \%guess;
}

sub _get_cflags {
  my $self = shift;
  $self->guess_compiler or die;
  join ' ', '', map _trim_whitespace($_), grep defined && length,
    $self->_config->{ccflags},
    $self->{guess}{extra_cflags},
    $self->{extra_compiler_flags},
    ($self->is_clang ? '-Wno-reserved-user-defined-literal' : ()),
    ;
}

sub _get_lflags {
  my $self = shift;
  $self->guess_compiler || die;
  join ' ', '', map _trim_whitespace($_), grep defined && length,
    $self->{guess}{extra_lflags},
    $self->{extra_linker_flags},
    ;
}

sub makemaker_options {
    my $self = shift;

    my $lflags = $self->_get_lflags;
    my $cflags = $self->_get_cflags;

    return (
      CCFLAGS      => $cflags,
      dynamic_lib  => { OTHERLDFLAGS => $lflags },
      CC => $self->{guess}{compiler_command},
    );
}


sub module_build_options {
    my $self = shift;

    my $lflags = $self->_get_lflags;
    my $cflags = $self->_get_cflags;

    return (
      extra_compiler_flags => $cflags,
      extra_linker_flags   => $lflags,
      config => { cc => $self->{guess}{compiler_command} },
    );
}

# originally from Alien::wxWidgets::Utility
# Why was this hanging around outside of all functions, and without any other
# use of $quotes?
# my $quotes = $self->_os =~ /MSWin32/ ? '"' : "'";

sub _capture {
    my @cmd = @_;
    my $out = capture_merged { system(@cmd) };
    $out = '' if not defined $out;
    return $out;
}

# capture the output of a command that is run with piping
# to stdin of the command. We immediately close the pipe.
sub _capture_empty_stdin {
    my $cmd = shift;
    my $out = capture_merged {
        if ( open my $fh, '|-', $cmd ) {
          close $fh;
        }
    };
    $out = '' if not defined $out;
    return $out;
}


sub _cc_is_msvc {
    my( $self, $cc ) = @_;
    $self->{is_msvc}
      = ($self->_os =~ /MSWin32/ and File::Basename::basename($cc) =~ /^cl/i);
    return $self->{is_msvc};
}

sub _cc_is_gcc {
    my( $self, $cc ) = @_;
    $self->{is_gcc} = 0;
    my $cc_version = _capture( "$cc --version" );
    if (
         $cc_version =~ m/\bg(?:cc|\+\+)/i # 3.x, some 4.x
      || scalar( _capture( "$cc" ) =~ m/\bgcc\b/i ) # 2.95
      || scalar(_capture_empty_stdin("$cc -dM -E -") =~ /__GNUC__/) # more or less universal?
      || scalar($cc_version =~ m/\bcc\b.*Free Software Foundation/si) # some 4.x?
      || $cc eq 'gcc' # because why would they lie?
    ) {
      $self->{is_gcc} = 1;
    }
    return $self->{is_gcc};
}

sub _cc_is_clang {
    my( $self, $cc ) = @_;
    $self->{is_clang} = 0;
    my $cc_version = _capture( "$cc --version" );
    if (
         $cc_version =~ m/\Aclang/i
      || $cc eq 'clang' # because why would they lie?
      || (($self->_config->{gccversion} || '') =~ /Clang/),
    ) {
      $self->{is_clang} = 1;
    }
    return $self->{is_clang};
}

sub _cc_is_sunstudio {
    my( $self, $cc ) = @_;
    $self->{is_sunstudio} = 0;
    my $cc_version = _capture( "$cc -V" );
    if (
         $cc_version =~ m/Sun C/i
      || $cc =~ /SUNWspro/ # because why would they lie?
    ) {
      $self->{is_sunstudio} = 1;
    }
    return $self->{is_sunstudio};
}

sub is_gcc {
    my $self = shift;
    $self->guess_compiler || die;
    return $self->{is_gcc};
}

sub is_msvc {
    my $self = shift;
    $self->guess_compiler || die;
    return $self->{is_msvc};
}

sub is_clang {
    my $self = shift;
    $self->guess_compiler || die;
    return $self->{is_clang};
}

sub is_sunstudio {
    my $self = shift;
    $self->guess_compiler || die;
    return $self->{is_sunstudio};
}

sub add_extra_compiler_flags {
    my( $self, $string ) = @_;

    $self->{extra_compiler_flags}
      = join ' ', map _trim_whitespace($_), grep defined && length,
        $self->{extra_compiler_flags}, $string;
}

sub add_extra_linker_flags {
    my( $self, $string ) = @_;
    $self->{extra_linker_flags}
      = join ' ', map _trim_whitespace($_), grep defined && length,
        $self->{extra_linker_flags}, $string;
}

sub compiler_command {
    my( $self ) = @_;
    $self->guess_compiler || die;
    my $cc = $self->{guess}{compiler_command};
    my $cflags = $self->_get_cflags;
    join ' ', map _trim_whitespace($_), grep defined && length, $cc, $cflags;
}

sub _trim_whitespace {
  my $string = shift;
  $string =~ s/^\s+|\s+$//g;
  return $string;
}

sub linker_flags {
    my( $self ) = @_;
    _trim_whitespace($self->_get_lflags);
}

sub _to_file {
  my ($file, @data) = @_;
  open my $fh, '>', $file
    or die "open $file: $!\n";
  print $fh @data or die "write $file: $!\n";
  close $fh or die "close $file: $!\n";
}

my $test_cpp_filename = 'ilcpptest';        # '.cpp' appended via open.
my $test_cpp          = <<'END_TEST_CPP';
#include <iostream>
int main(){ return 0; }
END_TEST_CPP

# returns true if compile succeeded, false if failed
sub _compile_no_h {
  my( $self ) = @_;
  return $self->{no_h_status} if defined $self->{no_h_status};
  $self->guess_compiler || die;
  my $dir = tempdir( CLEANUP => 1 );
  my $file = catfile( $dir, qq{$test_cpp_filename.cpp} );
  my $exe = catfile( $dir, qq{$test_cpp_filename.exe} );
  _to_file $file, $test_cpp;
  my $command = join ' ',
    $self->compiler_command,
    ($self->is_msvc ? qq{-Fe:} : qq{-o }) . $exe,
    $file,
    ;
  my $result = system $command;
  $self->{no_h_status} = ($result == 0);
}

sub iostream_fname {
  my( $self ) = @_;
  'iostream' . ($self->_compile_no_h ? '' : '.h');
}

sub cpp_flavor_defs {
  my( $self ) = @_;
  my $comment = ($self->_compile_no_h ? '' : '//');
  sprintf <<'END_FLAVOR_DEFINITIONS', $comment, $comment;

%s#define __INLINE_CPP_STANDARD_HEADERS 1
%s#define __INLINE_CPP_NAMESPACE_STD 1

END_FLAVOR_DEFINITIONS
}

1;
