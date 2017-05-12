use Test;
BEGIN { $| = 1; plan(tests => 7); chdir 't' if -d 't'; }
use blib;

##
## copying objects
##

use Mail::Procmailrc;

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

my $rcfile2 =  <<'_RCFILE_';
## my name is Larry
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

##
## copy test (does not support deep copies)
##

my $pmrc = new Mail::Procmailrc({'data' => $rcfile });
my $pmrc2 = new Mail::Procmailrc;

## copies a reference to each object
$pmrc2->push(@{$pmrc->rc});
ok( $pmrc2->dump, $rcfile );

## make alterations
for my $lit ( @{$pmrc->literals} ) {
    next unless $lit->literal =~ /my procmailrc file/i;
    $lit->literal('## my name is Larry');
    last;
}

ok( $pmrc->dump, $rcfile2 );
ok( $pmrc2->dump, $rcfile2 );


##
## reference test: hard to manipulate, but you can do it this way
##

ok( $pmrc = new Mail::Procmailrc( { 'data' => $rcfile } ) );
ok( $pmrc->dump, $rcfile );

undef $pmrc2;
$pmrc2 = new Mail::Procmailrc;

$pmrc2->push($pmrc);
ok( $pmrc2->dump, $rcfile );

for my $lit ( @{$pmrc->literals} ) {
    next unless $lit->literal =~ /my procmailrc file/i;
    $lit->literal('## my name is Larry');
    last;
}

ok( $pmrc2->dump, $rcfile2 );

exit;
