#!perl -w
use strict;
require 5.006;
use ExtUtils::MakeMaker;
my %opts;
# eval to prevent warnings about versions with _ in them
my $MM_ver = eval $ExtUtils::MakeMaker::VERSION;
if ($MM_ver > 6.06) {
  $opts{AUTHOR} = 'Tony Cook <tony@develop-help.com>';
  $opts{ABSTRACT} = 'Draws good looking charts';
}
if ($MM_ver >= 6.31) {
  $opts{LICENSE} = 'perl';
}
if ($MM_ver >= 6.46) {
  $opts{META_MERGE} =
    {
     license => "perl",
     resources =>
     {
      homepage => "http://imager.perl.org/",
      repository => "git://git.imager.perl.org/imager-graph.git",
      bugtracker => "http://rt.cpan.org/NoAuth/Bugs.html?Dist=Imager-Graph",
     },
    };
}

if ($MM_ver >= 6.48) {
  $opts{MIN_PERL_VERSION} = "5.006";
}

WriteMakefile(
              %opts,
              'NAME'          => 'Imager::Graph',
              'VERSION_FROM'  => 'Graph.pm', # finds $VERSION
              PREREQ_PM       => 
	      { 
	       Imager=>'0.75',
	       'Test::More' => 0.47
	      },
              clean => { FILES=>'testout' },
);
