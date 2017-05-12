# yes, these are commented out for a reason
# if we leave them in, they show up in the deparsed code
#use strict;
#use warnings;

use Test::More      0.88                            ;

use Test::More tests => 1;

use Debuggit(DEBUG => 0);


eval "use B::Deparse";
plan skip_all => "B::Deparse required for testing code deparsing" if $@;

my $deparse = B::Deparse->new('-sv"optimized away"');

my $code = $deparse->coderef2text(sub
{
    call_heinous_function() if DEBUG;
    #debuggit("some crazy output");
});
$code =~ s/^\s*"optimized away";\s*\n//m;
$code =~ s/^\s*0;\s*\n//m;

is($code, "{\n}", "use of DEBUG is optimized away");


done_testing;
