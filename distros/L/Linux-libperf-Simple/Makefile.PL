#!perl -w
use strict;
use ExtUtils::MakeMaker 6.46;
use Getopt::Long;
use List::Util "first";
use Config;

$^O eq "linux"
  or die "OS unsupported: Linux::libperf::Simple requires linux\n";

my $pkgname = first { system("pkg-config --exists $_") == 0 } qw( libperf );

die <<'DIE' unless $pkgname;
OS unsupported: Can't find pkg-config for libperf.
  pkg-config --exists libperf
failed.
DIE

print "Found $pkgname\n";

my $cflags = `pkg-config --cflags $pkgname`;
my $ldflags = `pkg-config --libs $pkgname`;
my $version = `pkg-config --modversion $pkgname`;

unless ($cflags && $ldflags && $cflags =~ /\S/ && $ldflags =~ /\S/) {
  die <<'DIE'
OS unsupported: libperf libraries or headers not found

  pkg-config --cflags libperf
or
  pkg-config --libs libperf

didn't return a useful result.
DIE
}
tr/\n /  /s for $cflags, $ldflags;

my %opts = 
  (
   NAME => 'Linux::libperf::Simple',
   VERSION_FROM => 'lib/Linux/libperf/Simple.pm',
   OBJECT => 'Simple.o',
   #DEFINE => $define,
   #clean => { FILES => 'testout' },
   LICENSE => "perl_5",
   AUTHOR => 'Tony Cook <tony@develop-help.com>',
   ABSTRACT => 'Simple interface to Linux libperf',
   META_MERGE =>
   {
     'meta-spec' =>
     {
       version => "2",
       url => "https://metacpan.org/pod/CPAN::Meta::Spec",
     },
     resources =>
     {
       homepage => "http://github.com/tonycoz/perl5-linux-libperf-simple/",
       repository =>
       {
         type => "git",
         url => "https://github.com/tonycoz/perl5-linux-libperf-simple.git",
         web => "https://github.com/tonycoz/perl5-linux-libperf-simple/",
       },
       bugtracker =>
       {
         web => "https://github.com/tonycoz/perl5-linux-libperf-simple/",
       },
     },
   },
  );


$opts{META_MERGE}{prereqs} =
  {
    configure =>
    {
      requires =>
      {
        "ExtUtils::MakeMaker" => "6.46",
      },
    },
    build =>
    {
      requires =>
      {
        "Test::More" => "0.47",
      }
    },
    runtime =>
    {
      requires =>
      {
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
    XSLoader => 0,
  };

WriteMakefile
  (
    %opts,
    DEFINE => $cflags,
    LIBS => $ldflags,
   );
