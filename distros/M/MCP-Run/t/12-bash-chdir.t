use strict;
use warnings;
use Test::More;
use Cwd          qw( getcwd realpath );
use Path::Tiny   qw( tempdir );

use MCP::Run::Bash;

# working_directory is applied by chdir in the child, not by prefixing the
# command with "cd DIR &&". The prefix binds only to the first command of a
# list, so everything after a ';', a newline or a '&' runs somewhere else
# than the caller asked for - and when the cd itself fails, the rest of the
# list runs anyway, in the caller's directory. Each subtest below samples one
# of those failure modes.

my $server = MCP::Run::Bash->new( name => 'TestServer' );
my $root   = tempdir;
$root->child('work')->mkpath;
my $dir    = realpath( "$root/work" );
my $gone   = "$root/does-not-exist";
my $caller = getcwd();

subtest 'missing directory: clear error, command not executed' => sub {
  my $marker = "$root/marker-plain";
  my $r = $server->execute( "touch '$marker'", $gone, 10 );
  isnt $r->{exit_code}, 0, 'non-zero exit';
  ok defined $r->{error}, 'error field set';
  like $r->{error}, qr/\Q$gone\E/, 'error names the directory';
  like $r->{error}, qr/No such file or directory/, 'error carries the reason';
  ok !-e $marker, 'command did not run';
};

subtest 'failing directory + ; chain: later members do not run' => sub {
  my $marker = "$root/marker-chain";
  my $r = $server->execute( "true; touch '$marker'; pwd", $gone, 10 );
  isnt $r->{exit_code}, 0, 'non-zero exit';
  ok !-e $marker, 'member after ; did not run in the caller directory';
  is $r->{stdout}, '', 'nothing printed';
};

subtest 'failing directory + newlines: later lines do not run' => sub {
  my $marker = "$root/marker-nl";
  my $r = $server->execute( "true\ntouch '$marker'\npwd\n", $gone, 10 );
  isnt $r->{exit_code}, 0, 'non-zero exit';
  ok !-e $marker, 'line after newline did not run';
};

subtest 'not a directory' => sub {
  my $file = $root->child('file');
  $file->spew('x');
  my $marker = "$root/marker-file";
  my $r = $server->execute( "touch '$marker'", "$file", 10 );
  isnt $r->{exit_code}, 0, 'non-zero exit';
  like $r->{error} // '', qr/Not a directory/, 'reason reported';
  ok !-e $marker, 'command did not run';
};

subtest 'background & does not take the directory change with it' => sub {
  my $r = $server->execute( 'true & pwd; wait', $dir, 10 );
  is $r->{exit_code}, 0, 'exit 0';
  is realpath( $r->{stdout} ), $dir, 'member after & runs in the working directory';
};

subtest 'every member of a chain sees the directory' => sub {
  my $r = $server->execute( "pwd; (pwd); pwd\npwd", $dir, 10 );
  is $r->{exit_code}, 0, 'exit 0';
  is_deeply [ map { realpath($_) } split /\n/, $r->{stdout} ], [ ($dir) x 4 ],
    'four members, one directory';
};

subtest 'apostrophe and other quoting in the path' => sub {
  for my $name ( "it's", 'a b', '$HOME', '"q"', '-dash', 'semi;colon', "new\nline" ) {
    my $odd = $root->child($name);
    $odd->mkpath;
    my $r = $server->execute( 'pwd', "$odd", 10 );
    my $label = $name =~ s/\n/\\n/r;
    is $r->{exit_code}, 0, 'exit 0 for ' . $label;
    is realpath( $r->{stdout} ), realpath("$odd"), 'ran in ' . $label;
  }
};

subtest 'no working directory: runs where the caller is, caller untouched' => sub {
  my $r = $server->execute( 'pwd', undef, 10 );
  is realpath( $r->{stdout} ), realpath($caller), 'caller cwd';
  $r = $server->execute( 'pwd', '', 10 );
  is realpath( $r->{stdout} ), realpath($caller), 'empty string counts as none';
  $server->execute( 'true', $dir, 10 );
  is getcwd(), $caller, 'the server process did not change directory';
};

subtest 'timeout and exit codes still work with a directory' => sub {
  is $server->execute( 'exit 7', $dir, 10 )->{exit_code}, 7, 'exit code passes through';
  my $r = $server->execute( 'sleep 60', $dir, 1 );
  is $r->{exit_code}, 124, 'timeout';
};

done_testing;
