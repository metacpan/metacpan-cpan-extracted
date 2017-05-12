use Test;
BEGIN { $| = 1; plan(tests => 4); chdir 't' if -d 't'; }
use blib;

##
## editing a new recipe file programmatically
##

use Mail::Procmailrc;

my $pmrc = new Mail::Procmailrc;

$rcfile =<<'_RCFILE_';
## this is my procmailrc file
LOGABSTRACT=yes

PMDIR=$HOME/.procmail

:0H:
## deliver stuff from home
* 1^0 From: dad
* 1^0 From: mom
* 1^0 From: babycakes
$DEFAULT

:0B:
## block indecent emails
* 1^0 people talking dirty
* 1^0 dirty persian poetry
* 1^0 dirty pictures
* 1^0 xxx
/dev/null
_RCFILE_

ok( $pmrc = new Mail::Procmailrc( { 'data' => $rcfile } ) );
ok( $pmrc->dump, $rcfile );

## alter a literal
for my $literal ( @{$pmrc->literals} ) {
    next unless $literal->literal =~ /my procmailrc file/i;
    $literal->literal('## this is a borrowed procmailrc file');
    last;
}

## alter a variable
for my $variable ( @{$pmrc->variables} ) {
    next unless $variable->lval() eq 'LOGABSTRACT';
    $variable->rval('no');
    last;
}

## add a new condition or two to a recipe
my $conditions;
for my $recipe (@{$pmrc->recipes}) {
    next unless $recipe->info()->[0] =~ /^\s*\#\# block indecent emails/i;
    $conditions = $recipe->conditions();
    last;
}

ok( scalar(@$conditions) );

push @$conditions, '* 1^0 my name is not important';
push @$conditions, '* 1^0 I have a very low IQ';

## check out the results
ok( $pmrc->dump, <<'_RCFILE_' );
## this is a borrowed procmailrc file
LOGABSTRACT=no

PMDIR=$HOME/.procmail

:0H:
## deliver stuff from home
* 1^0 From: dad
* 1^0 From: mom
* 1^0 From: babycakes
$DEFAULT

:0B:
## block indecent emails
* 1^0 people talking dirty
* 1^0 dirty persian poetry
* 1^0 dirty pictures
* 1^0 xxx
* 1^0 my name is not important
* 1^0 I have a very low IQ
/dev/null
_RCFILE_

exit;
