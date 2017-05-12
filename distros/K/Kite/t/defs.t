#!/usr/bin/perl -w

use strict;
use lib qw( ./lib ../lib);
use Kite::PScript::Defs qw( :all );

print "1..7\n";
my $n = 0;

sub ok {
    shift or print "not ";
    print "ok ", ++$n, "\n";
}

# test access directly via package
ok( $Kite::PScript::Defs::mm   =~ /mm/ );
ok(  Kite::PScript::Defs::mm() =~ /mm/ );
ok(  Kite::PScript::Defs->mm() =~ /mm/ );

# test class methods indirectly via a "factory" variable
my $ps = 'Kite::PScript::Defs';
ok( $ps->mm() =~ /mm/ );
ok( $ps->mm =~ /mm/ );

# test subs got imported ok
ok( mm() =~ /mm/ );
ok( mm =~ /mm/ );

