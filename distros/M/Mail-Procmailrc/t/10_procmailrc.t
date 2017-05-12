use Test;
BEGIN { $| = 1; plan(tests => 5); chdir 't' if -d 't'; }
use blib;

##
## creating a new recipe file programmatically
##

use Mail::Procmailrc;

my $pmrc = new Mail::Procmailrc;

## push a variable assignment
my $v1 = new Mail::Procmailrc::Variable();
$v1->lval('FOO'); $v1->rval('bar');

## make an entire recipe
my $rec = new Mail::Procmailrc::Recipe;
$rec->flags(':0B:');
$rec->info('## put spam away');
$rec->conditions([ q(* 1^0 this is not spam),
		   q(* 1^0 please read this),
		   q(* 1^0 urgent assistance),
		 ]);
$rec->action('$PMDIR/spam');

## push things
$pmrc->push( $v1, 
	     new Mail::Procmailrc::Variable(['PMDIR=$HOME/.procmail']),
	     new Mail::Procmailrc::Literal(),
	     $rec,
	   );

## test that what we created matches what we imagined
ok( $pmrc->dump(), <<'_RECIPE_' );
FOO=bar
PMDIR=$HOME/.procmail

:0B:
## put spam away
* 1^0 this is not spam
* 1^0 please read this
* 1^0 urgent assistance
$PMDIR/spam
_RECIPE_

## now muck with some things...
$rec->info('## banish the bad spam far away');
push @{$rec->conditions}, q(* 1^0 stinky cheese);

## ... and test again
ok( $pmrc->dump(), <<'_RECIPE_' );
FOO=bar
PMDIR=$HOME/.procmail

:0B:
## banish the bad spam far away
* 1^0 this is not spam
* 1^0 please read this
* 1^0 urgent assistance
* 1^0 stinky cheese
$PMDIR/spam
_RECIPE_


## The pmrc->conditions method should always return an empty list
## reference when there are no conditions. It should never return
## undef unless the recipe fails, etc.

$rec = new Mail::Procmailrc::Recipe;
$rec->flags(':0 c:');
$rec->info('## empty recipe');
$rec->action('$DEFAULT');

$pmrc->rc([$rec]); ## clobber existing recipes

ok( $pmrc->dump, <<'_RECIPE_' );
:0 c:
## empty recipe
$DEFAULT
_RECIPE_

ok( defined $rec->conditions );
ok( scalar(@{$rec->conditions}), 0 );

exit;
