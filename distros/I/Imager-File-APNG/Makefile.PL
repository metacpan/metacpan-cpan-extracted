#!perl -w
use strict;
use ExtUtils::MakeMaker;

my %opts = 
  (
   NAME => 'Imager::File::APNG',
   VERSION_FROM => 'lib/Imager/File/APNG.pm',
   clean => { FILES => 'testout' },
  );

if (eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 }) {
  $opts{LICENSE} = "perl_5";
  $opts{AUTHOR} = 'Tony Cook <tonyc@cpan.org>';
  $opts{ABSTRACT} = 'APNG image file support for Imager';
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
       url => "https://github.com/tonycoz/imager-file-apng.git",
       web => "https://github.com/tonycoz/imager-file-apng",
      },
      bugtracker =>
      {
       web => "https://github.com/tonycoz/imager-file-apng/issues",
      },
     },
    };
}

# Imager required configure through use
my @req =
  (
    Imager => "1.013",
    "Imager::File::PNG" => "0.99",
  );
if (eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 }) {
  $opts{META_MERGE}{prereqs} =
    {
      configure =>
      {
	requires =>
	{
	  @req,
	},
      },
      build =>
      {
	requires =>
	{
	  @req,
	  "Test::More" => "0.47",
	}
      },
      runtime =>
      {
	requires =>
	{
	  @req,
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
      @req,
    };
}

WriteMakefile(%opts);
