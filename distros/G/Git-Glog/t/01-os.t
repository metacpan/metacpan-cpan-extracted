#!perl -T

use Test::More tests => 1;

BEGIN {
  ok( $^O !~ /MSWin32/ , "OS isn't Windows") or BAIL_OUT("Right now this only works on Unix-like oses");
}

$ENV{'PATH'} = '/bin:/usr/bin:/usr/local/bin';
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

unless( `which less` ){
  diag( "Warning: less not found in " . $ENV{PATH} . " , git-glog works well with less." );
}
unless( `which tput` ){
  diag( "Warning: tput not found in " . $ENV{PATH} . " , git-glog requires tput to function." );
}
unless( `which git` ){
  diag( "Warning: git not found in " . $ENV{PATH} . " , git-glog requires git to function." );
}

