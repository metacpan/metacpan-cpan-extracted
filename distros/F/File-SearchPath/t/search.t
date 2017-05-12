# -*-perl-*-

use Test::More tests => 16;
use File::Spec;
use Config;

require_ok( "File::SearchPath" );

# Look for the test file

my $test = 'search.t';

setpath( "MYPATH", qw/ blib t / );

my $fullpath = File::SearchPath::searchpath( $test, env => 'MYPATH' );

is( $fullpath, File::Spec->catfile( "t", $test), "Find $test");


$fullpath = File::SearchPath::searchpath( $test, env => 'MYPATH', exe => 1 );
ok( !$fullpath, "$test not executable");

# Now look for perl itself
my ($vol,$dir,$f) = File::Spec->splitpath( $^X );
if ($dir) {
  setpath( "MYPATH", File::Spec->catpath($vol,$dir,""), "t" );
  $fullpath = File::SearchPath::searchpath( $f, exe => 1, env => "MYPATH" );
  is( $fullpath, $^X, "Looking for perl in $ENV{MYPATH}");
} else {
  # test invoked with perl that did not include a path
  # test instead that perl is in our PATH (which it must be else
  # this script would not run)
  $fullpath = File::SearchPath::searchpath( $^X );
  ok($fullpath, "Found perl in PATH");
}

# Now look in the test directories
setpath( "MYPATH" ,map { File::Spec->catdir( "t", $_) } qw/ a b c /);

$fullpath = File::SearchPath::searchpath( "file2", env => 'MYPATH' );
is($fullpath, File::Spec->catfile("t","a","file2"),"found file2");

@full = File::SearchPath::searchpath( "file2", env => 'MYPATH' );
is(@full,2, "Number of files found");

is($full[0], File::Spec->catfile("t","a","file2"),"found file2");
is($full[1], File::Spec->catfile("t","b","file2"),"found file2");

# Now for backwards compatibility
@full = File::SearchPath::searchpath( "file2", $ENV{MYPATH} );
is(@full, 2, "Number of files found in backcompat mode" );
is($full[0], File::Spec->catfile("t","a","file2"),"found file2 [backcompat]");
is($full[1], File::Spec->catfile("t","b","file2"),"found file2 [backcompat]");

# Backwards compatibility equivalency
@compat = File::SearchPath::searchpath( "file2", env => "MYPATH", exe => 0 );
is($full[0], $compat[0], "backcompat matches normal file2");
is($full[1], $compat[1], "backcompat matches normal file2");

# Search for a directory
setpath( "MYPATH", File::Spec->catdir(File::Spec->curdir, "blib"), File::Spec->curdir );
$fullpath = File::SearchPath::searchpath( "t", dir => 1, env => "MYPATH");
is( $fullpath, File::Spec->catdir(File::Spec->curdir, "t"), "Found directory");

$fullpath = File::SearchPath::searchpath( "t", env => "MYPATH" );
ok(!$fullpath, "Do not find dir when not looking for dir");

# absolute dir
my $tmpdir = File::Spec->tmpdir;
$tmpdir = File::Spec->rel2abs( $tmpdir ) if !File::Spec->file_name_is_absolute($tmpdir);
$fullpath = File::SearchPath::searchpath( $tmpdir, dir => 1);
ok($fullpath, "Find absolute path");

exit;

# Given an environment variable name and an array of variables
# set the path.
# Will use Env::Path if available
sub setpath {
  my ($env, @dirs) = @_;
  eval { require Env::Path };
  if ($@) {
    # use colons
    my $ps = $Config{path_sep};
    $ENV{$env} = join($ps, @dirs);
  } else {
    my $path = Env::Path->$env;
    $path->Assign( @dirs );
  }
}
