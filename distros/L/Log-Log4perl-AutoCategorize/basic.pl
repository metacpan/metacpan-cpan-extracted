
# test the logger

package Foo;
sub bar { print "in bar()\n" }

package main;

use Log::Log4perl::AutoCategorize (alias => 'Logger', 
				   debug => 'mrijDs',
				   debug => 'zjm',
				   ); 

# this works
# Log::Log4perl->init('log-conf');

# so do these
# Log::Log4perl::AutoCategorize->init('log-conf');
# Logger->init('log-conf');

# these were simple tests to use with -MO=Concise,-exec
# so I could see the op-chains I was after
# then they got used to test that optimizer wasnt munging where it shouldnt

Foo->bar();
Foo->bar(1);
Foo->bar("one arg");
Foo->bar("2", "args");
Foo->bar(["arrayref"]);
Foo->bar({hash=>'ref'});

Foo->bar([[qw/nested arrayref and/], {hash=>'also'}]);
Foo->bar(Foo->bar({hash=>'ref'}),{hash=>'ref'});

Logger->bar();

for (1..2) {
    # 2 of same call on same line !
    Logger->info( Logger->info({inner=>'call to same fn'}) );
    
    Logger->info(1);
    Logger->info("one arg");
    Logger->info("2", "args");
    Logger->info(["arrayref"]);
    Logger->info({hash=>'ref'});
    Logger->info([[qw/nested arrayref and/], {hash=>'also'}]);
    
    # illegit nested call
    Logger->info( Logger->baz({inner=>'call to diff fn'}),{hash=>'ref'} );
}

if ($false) {
    Logger->info("2", "args");
    Logger->debug("suppressed", "dueto level");
}

printf "used %d bytes\n", Logger->sizeUsed;
printf "used %d bytes\n", Log::Log4perl::AutoCategorize->sizeUsed;

Logger->debug("used ", Logger->sizeUsed);
