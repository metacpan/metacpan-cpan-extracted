use strict;
use warnings;
use Test::More;

use Git::Wrapper;

my @data = (
  # input , #output
  [
    [ 'status' ] ,
    'git status'
  ] ,
  [
    [ 'status' , { init => 1 } ] ,
    'git status --init'
  ] ,
  [
    [ 'status' , { init => 1 , -STDIN => 'foo bar baz' } ] ,
    'git status --init' ,
    'foo bar baz'
  ] ,
  [ [ 'status' , { init => 1 , -pre => 'bar' } ] ,
    'git --pre=bar status --init'
  ] ,
  [
    [ 'status' , { init => 1 } , 'file' , { -pre => 'bar' } ] ,
    'git --pre=bar status --init file'
  ] ,
  [
    [ 'status' , { init => 1 } , 'file' , { -pre => 'bar' , -STDIN => 'foo bar baz' } ] ,
    'git --pre=bar status --init file' ,
    'foo bar baz'
  ] ,
  [
    [ 'status' , { init => 1 } , 'file' , { -pre => 'bar' , post => 1 } ] ,
    'git --pre=bar status --init file --post'
  ] ,
  [
    [ 'status' , { arg => 'barg' , -pre => 'bar' } , 'file' , { post => 1 } ] ,
    'git --pre=bar status --arg=barg file --post'
  ] ,
  [
    [ 'status' , { init => 1 , -pre => 'bar' } , qw/ file1 file2 file3 / , { post => 1 } ] ,
    'git --pre=bar status --init file1 file2 file3 --post'
  ] ,
  [
    [ 'status' , { -a => 1, -b => 'foo', -cd => 1, -ef => 'foo', g => 1, h => 'bar', ij => 1, jk => 'baz' } ] ,
    'git -a -b foo --cd --ef=foo status -g -h bar --ij --jk=baz',
  ] ,
  [
    [ 'rev-list' , qw/ --all --not master / , { remotes => '*trunk*' } , qw/ -- filename / ] ,
    'git rev-list --all --not master --remotes=*trunk* -- filename'
  ],
  [
    [ 'submodule' , 'update' , { init => 1 } ] ,
    'git submodule update --init'
  ],
  [
    [ 'submodule' , { -STDIN => 'foo bar baz' } , 'update' , { init => 1 } ] ,
    'git submodule update --init',
    'foo bar baz'
  ],
);

my $test_case = 1;
foreach ( @data ) {
  my( $input , $expected_cli , $expected_stdin ) = @$_;

  my( $parts , $stdin ) = Git::Wrapper::_parse_args( @$input );

  my $output = join ' ' , ( 'git' , @$parts );

  is( $output , $expected_cli , "Expected for '$expected_cli' (CASE:$test_case)" );
  is( $stdin  , $expected_stdin , "Expected STDIN (CASE:$test_case)" );
  $test_case++;
}

done_testing();
