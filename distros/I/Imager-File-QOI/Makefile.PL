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
   NAME => 'Imager::File::QOI',
   VERSION_FROM => 'QOI.pm',
   OBJECT => 'QOI.o imqoi.o',
   #DEFINE => $define,
   clean => { FILES => 'testout' },
  );

if (eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 }) {
  $opts{LICENSE} = "perl_5";
  $opts{AUTHOR} = 'Tony Cook <tonyc@cpan.org>';
  $opts{ABSTRACT} = 'QOI image file support for Imager';
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
       url => "https://github.com/tonycoz/imager-file-qoi.git",
       web => "https://github.com/tonycoz/imager-file-qoi",
      },
      bugtracker =>
      {
       web => "https://github.com/tonycoz/imager-file-qoi/issues",
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
my @Imager_req = ( Imager => "1.013" );
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
	  "File::Spec" => 0,
	}
      },
    };
  $opts{PREREQ_PM} =
    {
      @Imager_req,
      XSLoader => 0,
    };
}

$opts{INC} = "@inc";

WriteMakefile(%opts);
