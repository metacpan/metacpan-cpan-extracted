#!perl -w
use strict;
use ExtUtils::MakeMaker 6.46;
use ExtUtils::CppGuess;
use Getopt::Long;
use List::Util "first";
use Config;

my $verbose = $ENV{IM_VERBOSE};
my @libpaths;
my @incpaths;

GetOptions("incpath=s", \@incpaths,
           "libpath=s" => \@libpaths,
           "verbose|v" => \$verbose);

my %opts = 
  (
   NAME => 'Imager::zxing',
   VERSION_FROM => 'lib/Imager/zxing.pm',
   OBJECT => 'zxing.o',
   #DEFINE => $define,
   #clean => { FILES => 'testout' },
   LICENSE => "perl_5",
   AUTHOR => 'Tony Cook <tonyc@cpan.org>',
   XSOPT => '-C++',
   ABSTRACT => 'Barcode scanning with libzxing-cpp',
   META_MERGE =>
   {
     'meta-spec' =>
     {
       version => "2",
       url => "https://metacpan.org/pod/CPAN::Meta::Spec",
     },
     resources =>
     {
       homepage => "http://imager.perl.org/",
       repository =>
       {
         type => "git",
         url => "https://github.com/tonycoz/imager-zxing.git",
         web => "https://github.com/tonycoz/imager-zxing/",
       },
       bugtracker =>
       {
         web => "https://github.com/tonycoz/imager-zxing/",
       },
     },
   },
  );


my @inc;
unshift @INC, "inc";
require Imager::ExtUtils;
push @inc, Imager::ExtUtils->includes;
$opts{TYPEMAPS} = [ Imager::ExtUtils->typemap ];

# Imager required configure through use
# need 1.015 for C++ compatibility
my @Imager_req = ( Imager => "1.015" );
$opts{META_MERGE}{prereqs} =
  {
    configure =>
    {
      requires =>
      {
        @Imager_req,
        "ExtUtils::CppGuess" => "0.22",
        "ExtUtils::MakeMaker" => "6.46",
        "ExtUtils::CppGuess" => 0,
        "List::Util" => "1.43",
      },
    },
    build =>
    {
      requires =>
      {
        @Imager_req,
        "Test::More" => "0.47",
      }
    },
    runtime =>
    {
      requires =>
      {
        @Imager_req,
      }
    },
    test =>
    {
      requires =>
      {
        "Test::More" => "0.47",
      }
    },
  };
$opts{PREREQ_PM} =
  {
    @Imager_req,
    XSLoader => 0,
  };


my $pkgname = first { system("pkg-config --exists $_") == 0 } qw( zxing zxing-cpp );

die <<'DIE' unless $pkgname;
OS unsupported: Can't find pkg-config for zxing or zxing-cpp.
Make sure you have the devel package installed
DIE

print "Found $pkgname\n";

my $cflags = `pkg-config --cflags $pkgname`;
my $ldflags = `pkg-config --libs $pkgname`;
my $version = `pkg-config --modversion $pkgname`;

unless ($cflags && $ldflags && $cflags =~ /\S/ && $ldflags =~ /\S/) {
  die <<'DIE'
OS unsupported: zxing libraries or headers not found

  pkg-config --cflags zxing
or
  pkg-config --libs zxing

didn't return a useful result.
DIE
}
my @v = split /\./, $version;
my $v = $v[0] * 10_000 + $v[1] * 100 + $v[2];
if ($v < 10400) {
  die <<DIE
OS unsupported: zxing $version too old, 1.4.0 or later required
DIE
}
tr/\n /  /s for $cflags, $ldflags;

my $guess = ExtUtils::CppGuess->new;
# prefer C++20, but accept C++17
my $std = '';
unless (eval { $std = $guess->cpp_standard_flag("C++20") }) {
  $std = $guess->cpp_standard_flag("C++17");
}
$guess->add_extra_compiler_flags
  (
    $cflags . " " . Imager::ExtUtils->includes . " $std"
   );
$guess->add_extra_linker_flags
  (
    $ldflags
   );

WriteMakefile(%opts, $guess->makemaker_options);
