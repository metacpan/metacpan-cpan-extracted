# Test file which can be run like so: `
#     perl 01-extract-doctrings-elisp.t
#
#   doom@kzsu.stanford.edu     2008/02/29 04:41:17

#########################

use Test::More;
my $DEBUG = 0;

use warnings;
use strict;
$|=1;
use Data::Dumper;

use File::Path     qw( mkpath );
use File::Basename qw( fileparse basename dirname );
use File::Copy     qw( copy move );
use Fatal          qw( open close mkpath copy move );
use Cwd            qw( cwd abs_path );
use Env qw(HOME);

my $prog = basename($0);

my $emacs_found = `emacs --version 2>/dev/null`;

if( not( $emacs_found ) ) {
  plan skip_all => 'emacs was not found in PATH';
} else {
  plan tests => 10;
}

use FindBin qw($Bin);

my $elisp_lib = "$Bin/../lisp/";
my $elisp_file = "$elisp_lib/extract-doctrings.el";

my $temp_dir = "$Bin/lisp-dat/tmp";
mkpath( $temp_dir ) unless -d $temp_dir;
my $temp_file = "$temp_dir/emacs_output.txt";

unless (-e $elisp_file) {
  die "Could not find elisp file: $elisp_file";
}
ok( 1, "Okay so far...");

# ========
my $string = q{ Hello, perl };
my $elisp = qq{ (message "$string") };
my $emacs_cmd = "emacs --batch -eval '$elisp' 2>&1";
chomp(
      my $return = qx{ $emacs_cmd }
);
print STDERR "return: >>>$return<<<\n" if $DEBUG;

is( $return, $string, "Testing basic shelling out to emacs.");

# ========

$emacs_cmd = "emacs --batch -l $elisp_file -eval '$elisp' 2>&1";
chomp(
       $return = qx{ $emacs_cmd }
);
is( $return, $string, "Testing that emacs could load library file: $elisp_file");

# ========
# extract-doctrings-fixdir

my %cases =
  (
   '/tmp'              => '/tmp/',
   '$HOME/tmp'         => "$HOME/tmp/",
   '$HOME/nada'        => "$HOME/nada/",
   '~/nada'            => "$HOME/nada/",

   '/tmp/bogo/../nada' => '/tmp/nada/',
   '/home/whocares/~/nada'
                       => "$HOME/nada/",
);

foreach my $dir (keys %cases) {
  my $expected = $cases{ $dir };

  my $return = run_extract_docs_fixdir( $dir );

  if ($DEBUG) {
    print "return: $return\n";
    print "expected: $expected\n";
  }

  is( $return, $expected, "Testing extract-doctrings-fixdir function on case: $dir");
}

### using default dir to expand a relative path
{
  my $default_dir = "$temp_dir/random_dir";
  mkdir( $default_dir ) unless -d $default_dir;

  chdir $default_dir;

  my $dir      = "some/location";
  my $expected = "$default_dir/some/location/";

  $return = run_extract_docs_fixdir( $dir );

  if ($DEBUG) {
    print "return: $return\n";
    print "expected: $expected\n";
  }

  is( $return, $expected, "Testing extract-doctrings-fixdir function on default dir case: $dir");
}


# ======
# end main, into the subs

sub run_extract_docs_fixdir {
  my $dir = shift;

  my $elisp_test = qq{ (message "%s" (extract-doctrings-fixdir "$dir")) };

  my $emacs_cmd = "emacs --batch --no-splash -l '$elisp_file' -eval '$elisp_test' 2>&1";
  ($DEBUG) && print "emacs_cmd: $emacs_cmd\n";
  chomp(
        $return = qx{ $emacs_cmd }
       );

  return $return;
}




# ========

#      "emacs -q --batch  -eval '$elisp' -f $func_name >& $log";
