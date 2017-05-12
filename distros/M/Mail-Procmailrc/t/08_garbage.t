use Test;
BEGIN { $| = 1; plan(tests => 10); chdir 't' if -d 't'; }
use blib;

## garbage testing

use Mail::Procmailrc;

my $rcfile;
my @rcfile;
my $pmrc = new Mail::Procmailrc;

$rcfile =<<'_RCFILE_';
## nice recipe
:0B:

## some conditions here
* foo
* bar

## file away
/dev/foobar
_RCFILE_

ok( $pmrc->parse( $rcfile ) );
ok( $pmrc->dump, <<'_RCFILE_' );
## nice recipe
:0B:
## some conditions here
* foo
* bar
/dev/foobar
_RCFILE_

ok( $pmrc->rc->[1]->action, '/dev/foobar' );

$rcfile =<<'_RCFILE_';
this won't parse!
at all!
not in a million years
this is garbage
 sdlfkja sdf:0 sldkjaf sdf
_RCFILE_

ok( $pmrc->parse( $rcfile ) );
ok( $pmrc->dump, '' );

$rcfile =<<'_RCFILE_';
this won't parse!
at all!
not in a million years
this is garbage
 sdlfkja sdf:0 sldkjaf sdf
:0
## nothing happens
* my name is larry
/dev/null
more garbage is here!
 sdlfkjas dfliua sdf; 

_RCFILE_

ok( $pmrc->parse( $rcfile ) );
ok( $pmrc->dump, <<'_RCFILE_' );
:0
## nothing happens
* my name is larry
/dev/null
_RCFILE_


###########################
## test for undefs in object

$rcfile =<<'_RCFILE_';
:0
## test
* testing
testing

## just a comment
## another comment
_RCFILE_

ok( $pmrc->parse($rcfile) );
ok( $pmrc->dump, $rcfile );
for my $o ( @{$pmrc->rc} ) {
    next unless $o->stringify =~ /^\#\# just a comment/;
    undef $o;
}

ok( $pmrc->dump, <<'_RCFILE_' );
:0
## test
* testing
testing

## another comment
_RCFILE_


###########################
## 

exit;
