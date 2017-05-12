use strict;
use warnings;
use ExtUtils::MakeMaker;

my $author = 'Thomas Busch <tbusch at cpan dot org>';

## hash that specifies the directory to look for CLucene/clucene-config.h
## for each OS
my %h_config_dirs = (
  "linux" => "/usr/lib",
  "freebsd" => "/usr/local/lib",
  "darwin" => "/usr/local/lib",
);

my $config_dir = $h_config_dirs{$^O};

if (!$config_dir) {
  print "==========================================================\n";
  print "CLucene config directory for $^O unknown.\n";
  print "\n";
  print "Please modify Makefile.PL and send a mail to\n";
  print "$author with your modification.\n";
  print "\n";
  print "Thanks for your help.\n";
  print "==========================================================\n";
  exit(0);
}

WriteMakefile(
    NAME                => 'Lucene::Search::Highlight',
    AUTHOR              => $author,
    VERSION_FROM        => 'lib/Lucene/Search/Highlight.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Lucene'     => 0.07,
    },
    CC                  => 'g++',
    LD                  => 'g++',
    LIBS                => ['-lstdc++ -lclucene -lclucene-contrib'],
 
    ## 
    INC                 => "-I$config_dir",
    OBJECT              => '$(O_FILES)',

    OPTIMIZE            => ' ',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lucene-*' },
);

