#!perl -w
use strict;
use ExtUtils::MakeMaker;
use Getopt::Long;
use Config;

my $verbose = $ENV{IM_VERBOSE};
my @libpaths;
my @incpaths;

GetOptions("incpath=s", \@incpaths,
           "libpath=s" => \@libpaths,
           "verbose|v" => \$verbose);

our $BUILDING_IMAGER;
our %IMAGER_LIBS;

my %opts =
  (
   NAME => 'Imager::File::AVIF',
   VERSION_FROM => 'AVIF.pm',
   OBJECT => 'AVIF.o imavif.o',
   #DEFINE => $define,
   clean => { FILES => 'testout' },
  );

if (eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 }) {
  $opts{LICENSE} = "perl_5";
  $opts{AUTHOR} = 'Tony Cook <tonyc@cpan.org>';
  $opts{ABSTRACT} = 'AVIF image file support for Imager';
  $opts{META_MERGE} =
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
       url => "https://github.com/tonycoz/imager-file-avif.git",
       web => "https://github.com/tonycoz/imager-file-avif",
      },
      bugtracker =>
      {
       web => "https://github.com/tonycoz/imager-file-avif/issues",
      },
     },
    };
}

my @inc;
unshift @INC, "inc";
require Imager::ExtUtils;
push @inc, Imager::ExtUtils->includes;
$opts{TYPEMAPS} = [ Imager::ExtUtils->typemap ];

# Imager required configure through use
my @Imager_req = ( Imager => "0.94" );
if (eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 }) {
  $opts{META_MERGE}{prereqs} =
    {
     configure =>
     {
      requires =>
      {
       @Imager_req,
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
}

require Imager::Probe;

my %probe =
  (
   name => "AVIF",
   inccheck => sub { -e File::Spec->catfile($_[0], "avif/avif.h") },
   libbase => [ "avif" ],
   libopts => "-lavif",
   incpath => \@incpaths,
   libpath => \@libpaths,
   verbose => $verbose,
   pkg => [ "libavif" ],
  );

my $probe_res = Imager::Probe->probe(\%probe);
if ($probe_res) {
  push @inc, $probe_res->{INC};
  $opts{LIBS} = $probe_res->{LIBS};
  $opts{DEFINE} .= " $probe_res->{DEFINE}";
  $opts{INC} = "@inc";

  if ($Config{d_snprintf}) {
    $opts{DEFINE} .= " -DHAVE_SNPRINTF";
  }

  WriteMakefile(%opts);
}
else {
  die "OS unsupported: AVIF libraries or headers not found\n";
}

