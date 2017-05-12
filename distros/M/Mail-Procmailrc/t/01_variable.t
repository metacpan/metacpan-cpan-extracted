use Test;
BEGIN { $| = 1; plan(tests => 20); chdir 't' if -d 't'; }
use blib;

use Mail::Procmailrc;

my $variable = <<'_VARIABLE_';
PMDIR=$HOME/.procmail
VERBOSE=off
LOGABSTRACT=on
HOSTNAME=`uname -a |\
          awk '{print $2}'`
NL="
"
_VARIABLE_
my @variable = split(/\n/, $variable);

## constructor
ok( my $v1 = new Mail::Procmailrc::Variable(\@variable) );
ok( $v1->variable(), "PMDIR=\$HOME/.procmail");

ok( my $v2 = new Mail::Procmailrc::Variable(\@variable) );
ok( $v2->variable(), "VERBOSE=off");

ok( my $v3 = new Mail::Procmailrc::Variable(\@variable) );
ok( $v3->variable(), "LOGABSTRACT=on");

ok( $v3->rval("off") );
ok( $v3->variable(), "LOGABSTRACT=off");

ok( ! $v3->rval('') );
ok( $v3->variable(), "LOGABSTRACT=");

## test multiline
ok( my $v4 = new Mail::Procmailrc::Variable(\@variable) );
ok( $v4->variable(), "HOSTNAME=`uname -a |\\\n          awk '{print \$2}'`" );

ok( $v4->rval(), "`uname -a |\\\n          awk '{print \$2}'`" );

ok( my $v5 = new Mail::Procmailrc::Variable(\@variable) );
ok( $v5->variable(), qq(NL="\n") );

$variable = <<'_VARIABLE_';
HOSTNAME=`uname -a |\
          awk '{print $2}'`
_VARIABLE_
@variable = split(/\n/, $variable);

ok( $v4 = new Mail::Procmailrc::Variable(\@variable, {'level' => 2} ) );
ok( $v4->variable(), "HOSTNAME=`uname -a |\\\n          awk '{print \$2}'`" );
ok( $v4->dump(), "    HOSTNAME=`uname -a |\\\n          awk '{print \$2}'`\n" );

$v1 = $v2 = $v3 = $v4 = $v5 = undef;

$variable =<<'_VARIABLE_';
NL="
"
_VARIABLE_
$v1 = new Mail::Procmailrc::Variable([$variable]);
ok( $v1->dump, <<_DUMP_ );
NL="
"
_DUMP_
ok( $v1->rval, qq("\n") );
exit;
