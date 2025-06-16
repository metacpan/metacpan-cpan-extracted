#!perl -w
use strict;
use ExtUtils::MakeMaker 6.46;
use ExtUtils::CppGuess;
use Getopt::Long;
use List::Util "first";
use Config;
use Imager::ExtUtils;

# Imager required configure through use
# need 1.015 for C++ compatibility
my @Imager_req = ( Imager => "1.015" );

my %opts = 
  (
   NAME => 'Imager::zxing',
   VERSION_FROM => 'lib/Imager/zxing.pm',
   OBJECT => 'zxing.o',
   #DEFINE => $define,
   #clean => { FILES => 'testout' },
   LICENSE => "perl_5",
   AUTHOR => 'Tony Cook <tony@develop-help.com>',
   XSOPT => '-C++',
   ABSTRACT => 'Barcode scanning with libzxing-cpp',
   TYPEMAPS => [ Imager::ExtUtils->typemap ],
   #PREREQ_PM =>
   #{
   #  @Imager_req,
   #  XSLoader => 0,
   #},
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
     prereqs =>
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
     },
   },
  );

my $pkgname = first { system("pkg-config --exists $_") == 0 } qw( zxing zxing-cpp );

die <<'DIE' unless $pkgname;
OS unsupported: Can't find pkg-config for zxing or zxing-cpp.
Make sure you have the devel package installed
DIE

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

print "Found $pkgname $version\n";

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
    $cflags . " " . Imager::ExtUtils->includes . " $std -DMY_ZXVERSION=$v"
   );
$guess->add_extra_linker_flags
  (
    $ldflags
   );

WriteMakefile(%opts, $guess->makemaker_options);
