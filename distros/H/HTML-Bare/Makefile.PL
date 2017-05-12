#!/usr/bin/perl
use ExtUtils::MakeMaker;
require 5.006;
my @basics = ( 
    AUTHOR       => 'David Helkowski <cpan@codechild.com>',
    ABSTRACT     => 'A minimal HTML parser / schema checker / pretty-printer using C internally.',
    NAME         => 'HTML::Bare',
    VERSION_FROM => 'Bare.pm',
    XSOPT        => '-nolinenumbers', # line number defines were causing issues on some platforms
    BUILD_REQUIRES => {
        'Data::Dumper' => 0,
        'English' => 0,
        'File::Find' => 0,
        'File::Temp' => 0,
        'Scalar::Util' => 0,
        'Test::Harness' => 0,
        'Test::More' => '0.94'
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.30'
    },
    PREREQ_PM => {
        Carp => 0,
        DynaLoader => 0,
        Exporter => 0
    },
);

my $cc = getcc();
if( $cc ) {
  push( @basics, CC => $cc );
}
if( $ExtUtils::MakeMaker::VERSION >= 6.31 ) {
  push( @basics, LICENSE => 'perl' );
}

if( $^O eq 'MSWin32' && !$cc ) {
  gen_msvc(); # special case for msvc
}
elsif( $^O eq 'darwin' ) {
  gen_darwin();
}
elsif( $^O eq 'solaris' ) {
  gen_solaris();
}
else {
  gen_cc(); # all others
}
sub gen_msvc {
  require Config;
  my $libpath = Config->{'archlibexp'};
  my $ver = $]*1000000;
  my $sub = $ver % 1000;
  $ver -= $sub;
  $ver /= 1000;
  my $minor = $ver % 1000;
  $ver -= $minor;
  my $major = $ver / 1000;
  WriteMakefile( @basics,
    CCFLAGS   => "/MT /DWIN32 /TP /DNOSTRING",
    LIBS      => ["$libpath\\core\\perl$major$minor.lib"],
    OBJECT    => 'Bare.o parser.o',
    LDDLFLAGS => '/DLL /NODEFAULTLIB:libcmt',
    #OPTIMIZE  => '-Zl -DNDEBUG -O1', # Because -MD is included by default BLEH
  );
}
sub gen_cc {
  WriteMakefile( @basics,
    LIBS      => ['-lm'],
    OBJECT    => 'Bare.o parser.o',
    LDDLFLAGS => '-shared -L/usr/local/lib',
  );
}
sub gen_solaris {
  WriteMakefile( @basics,
    LIBS      => ['-lm'],
    OBJECT    => 'Bare.o parser.o',
    LDDLFLAGS => '-G -L/usr/local/lib', # -G is equiv of -shared
  );
}
sub gen_darwin {
  if( substr(`which gcc`,0,2) eq 'no' ) {
    print "XCode must be installed.\n";
    exit 1;
  }
  WriteMakefile( @basics,
    LIBS      => ['-lm'],
    OBJECT    => 'Bare.o parser.o',
    CCFLAGS   => "-dynamiclib -DDARWIN -fno-common",
    LDDLFLAGS => '',
  );
}
sub getcc {
  my $div = (substr($ENV{'PATH'},0,1) eq '/') ? ':' : ';';
  my @path = split($div,$ENV{'PATH'});
  foreach my $dir ( @path ) {
    return 'gcc' if( -e "$dir/gcc" || -e "$dir/gcc.exe" ); # prefer gcc
    return 'cc'  if( -e "$dir/cc"  || -e "$dir/cc.exe"  );
  }               
  return 0;
}

# The following are hacks to force static linking and so remove need for msvcr## dll
package MY;

sub cflags {
  my $res = shift->SUPER::cflags( @_ );
  if( $^O eq 'MSWin32' ) {
    $res =~ s/-O1/-O2/g;
    $res =~ s/-MD/-MT/g;
  }
  return $res;
}

sub const_loadlibs {
  my $res = shift->SUPER::const_loadlibs( @_ );
  if( $^O eq 'MSWin32' ) {
    $res =~ s/msvcrt\.lib/libcmt\.lib/gi;
  }
  return $res;
}

