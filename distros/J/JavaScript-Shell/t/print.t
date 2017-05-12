##print and putstr spidermonkey should be disabled
## and must not be available to be used

use JavaScript::Shell;
use Data::Dumper;
use Test::More;
use strict;

my $js = JavaScript::Shell->new();

sub testThrows {
    my $js = shift;
    my $desc = shift->[0];
    ok(1, $desc);
}

$js->Set('testThrows' => \&testThrows);

$js->eval(qq!
    try {
        //should thow
        print("something");
    } catch (e){
        testThrows('print throws');
    }
    
    //put str too
    try {
        //should thow
        putstr("something");
    } catch (e){
        testThrows('putstr throws');
    }
    
!);

##with context too
my $ctx = $js->createContext({});
$ctx->Set('testThrows' => \&testThrows);

$ctx->eval(qq!
    try {
        //should thow
        print("something");
    } catch (e){
        testThrows('context print throws');
    }
    
    //put str too
    try {
        //should thow
        putstr("something");
    } catch (e){
        testThrows('context putstr throws');
    }
    
!);

$js->destroy();
done_testing(4);
