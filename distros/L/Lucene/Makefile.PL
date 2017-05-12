use strict;
use warnings;
use ExtUtils::MakeMaker;

my $author = 'Thomas Busch <tbusch at cpan dot org>';
my $MIN_CLUCENE_VERSION = '0.9.17';

## Hash that specifies for each OS all possible directories to look
## for CLucene/clucene-config.h
my $rh_include_dirs = {
  "linux"   => ["/usr/include",       "/usr/lib"], 
  "freebsd" => ["/usr/local/include", "/usr/local/lib"], 
  "darwin"  => ["/usr/local/include", "/usr/local/lib"],
};

my $config_file;
my $include_dir;

foreach my $dir(@{$rh_include_dirs->{$^O}}) {
  my $file = "$dir/CLucene/clucene-config.h";
  if (-e $file) {
    if (defined $config_file) {
       die "You appear to have 2 clucene config files.\n".
           "  1) $config_file\n".
           "  2) $file\n".
           "Please remove one of the two.\n";
    }
    $config_file = $file;
    $include_dir = $dir;
  }
}

if (!defined $config_file) {
  die "couldn't find clucene config file";
}

print "Using clucene config file $config_file to build Makefile\n";

my $clucene_version = find_clucene_version($config_file);

if (!defined $clucene_version) {
  print "\nCouldn't find clucene version in $config_file\n";
  exit(0);
}

if ($clucene_version lt $MIN_CLUCENE_VERSION) {
  print "\nThis CPAN module requires clucene-core-$MIN_CLUCENE_VERSION or above to be installed.\n";
  exit(0);
}

print "Building using clucene-core $clucene_version\n";

my $define = $clucene_version;
$define =~ s/-svn//;
$define =~ s/[\.]/_/g;
$define =~ s/[a-z]//g;
$define = "-DCLUCENE_$define";


WriteMakefile(
    NAME                => 'Lucene',
    AUTHOR              => $author,
    VERSION_FROM        => 'lib/Lucene.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    CC                  => 'g++',
    LD                  => 'g++',
    LIBS                => ['-lstdc++ -lclucene'],
    DEFINE              => $define,
 
    ## 
    INC                 => "-I$include_dir",
    OBJECT              => '$(O_FILES)',

    OPTIMIZE            => ' ',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lucene-*' },
);


## find clucene version by looking through C/C++ define statements
sub find_clucene_version {
  my $file = shift;

  local $/ = undef;
  open FILE, "<$file";
  my $whole_file = <FILE>;
  close FILE;

  my $version;
  if ($whole_file =~ m/_CL_VERSION\s+"([^"]+)"/) {
    $version = $1;
  }
}

