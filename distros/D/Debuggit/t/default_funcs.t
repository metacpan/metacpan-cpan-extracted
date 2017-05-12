use strict;
use warnings;

use lib 't/lib';
use TestCmd;

use Test::More      0.88                            ;
use Test::Output    0.16    qw<:tests :functions>   ;
use Test::Exception 0.31                            ;

use Debuggit(DEBUG => 2);


open(IN, "t/data/hash_for_dumping") or die("# cannot read test data");
my $struct = eval do { local $/; <IN> };
close(IN);

my $cmd = <<'END';
    use strict;
    use warnings;
    use Data::Dumper;
    $Data::Dumper::Sortkeys = 1;

    open(IN, "t/data/hash_for_dumping") or die("# cannot read test data");
    my $struct = eval do { local $/; <IN> };
    close(IN);

    print Dumper($struct);
END

# get Dumper output without actually loading Data::Dumper
my $dump = cmd_stdout({ perl => $cmd });
# make sure we actually _got_ some output
isnt $dump, '', "test dump returned some output";
# and make sure we didn't actually load Data::Dumper
throws_ok { print Data::Dumper::Dumper() } qr/^Undefined subroutine &Data::Dumper::Dumper called/,
        'Data::Dumper not loaded';

my $output = 'test is';
stderr_is { debuggit(2 => $output, DUMP => $struct); } "$output $dump\n", "got DUMP output";


# okay, now we're going to build ourselves a hash
# and we're going to keep adding single-letter keys to it until we find a hash that returns its keys
# in unsorted order
# probably this won't take very many keys
# but, in the (extremely) unlikely event that we run out of letters before we find one, we'll bail
# we go to this trouble in order to verify that our use of DD is producing sorted keys
# and we do _that_ because, if we don't, we're bound to get random failures from our installers

SKIP:
{
    my %hash = ( a => 1, b => 1 );
    my $letter = "b";
    while ( join('', keys %hash) eq join('', sort keys %hash) )
    {
        skip "can't generate unsorted hash", 1 if $letter eq 'z';
        $hash{ ++$letter } = 1;
    }

    my $regex = join("\n", map { '^\s*' . "'$_'" . '.*?$' } sort keys %hash);
    stderr_like { debuggit(2 => DUMP => \%hash); } qr/$regex/m, "Data::Dumper is sorting its keys";
}

# also, make sure we're not leaving hashkeys in DD sorted for everyone else, whether they like it
# or not ...
isnt $Data::Dumper::Sortkeys, 1, "properly cleaning up after ourselves with DD";


# test removal
# (this has to be done last, obviously)

ok Debuggit::remove_func('DUMP'), "remove func successful";
stderr_is { debuggit(2 => $output, DUMP => $struct); } "$output DUMP $struct\n", "removed default func";


done_testing;
