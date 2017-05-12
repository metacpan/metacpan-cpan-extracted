# test the logger -*- perl -*-

use Getopt::Std;
my $opt;
BEGIN {
    $opt={};
    getopts('d:',$opt) or die<<EOPTS
      Usage: $0 [-d<option letters from AutoCategorize>]
	  -d <> : exposes AutoCategorize options for easy testing
EOPTS
}

use Log::Log4perl::AutoCategorize (alias => 'Logger', 
				   debug => $opt->{d}, #'mrijDs',
				   );

package Foo;
use Log::Log4perl::AutoCategorize (alias => 'Logger');
sub bar { my $pkg = shift; print "in $pkg->bar(@_)\n" }

sub uselogger {
    Logger->debug("logging from Foo", @_);
    Logger->debug("logging from Foo", @_, 'extra');
    Logger->debug("logging from Foo", \@_);
}

package main;

# DONT ADD ANY LINES - ABOVE OR BELOW - EVEN COMMENTS
# THE TESTS RELY ON LINE NUMBERS - THATS A FEATURE

# blank lines to allow subsequent insert of fixes

for (1..2) {
    
    Logger->debug($_);
    Logger->info("one arg");
    Logger->warn("2", "args");
    Logger->debug(["arrayref"]);
    Logger->info({hash=>'ref'});
    Logger->info([[qw/nested arrayref and/], {hash=>'also'}]);
    
    # 2 of same call on same line !
    Logger->info( Logger->info({inner=>'call to same fn'}) );

    # nested call, but different method
    Logger->info ( Logger->debug({inner=>'call to diff fn'}),
		   'nested', {hash=>'ref'} );
    usersub($_);
    Foo->uselogger($_);
}

sub usersub {
    Logger->info ( "logging from main function", \@_);
    Logger->info ( "logging from main function", @_);
    Logger->info ( "logging from main function", 'arg1', @_);
}

Logger->bar(); # should evoke warning

if ($false) {
    Logger->info("2", "args");
    Logger->debug("suppressed", "dueto level");
}

# these should not be munged
Foo->bar();
Foo->bar(1);


# OK MY TESTS ARE DONE. YOU CAN ADD NOW.

# exit 1; # would fail basic test 3

__END__





# this works
# Log::Log4perl->init('log-conf');

# so do these
# Log::Log4perl::AutoCategorize->init('log-conf');
# Logger->init('log-conf');

# these were simple tests to use with -MO=Concise,-exec
# so I could see the op-chains I was after
# then they got used to test that optimizer wasnt munging where it shouldnt

