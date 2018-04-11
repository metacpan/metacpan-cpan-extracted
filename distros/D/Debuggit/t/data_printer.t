use strict;
use warnings;

use lib 't/lib';
use TestCmd;

use Test::More      0.88                            ;
use Test::Output    0.16    qw<:tests :functions>   ;
use Test::Exception 0.31                            ;

BEGIN
{
    my $error = system("$^X -MData::Printer -le 1 2>/dev/null");
    plan skip_all => "Data::Printer required for testing pretty dumping" if $error;
}


# If we have Data::Printer, but the version is too old, just check to make sure
# we throw an appropriate error, then call it a day.
BEGIN
{
	# Remember: we can't actually _load_ Data::Printer here, or it will throw
	# off the later tests.
	my $error = cmd_stderr({ perl => 'use Data::Printer; Data::Printer->VERSION("0.36")' });
	if ($error)
	{
		my $cmd = q{
			use Debuggit(DataPrinter => 1, DEBUG => 2);
			debuggit(DUMP => "test");
		};
		cmd_stderr_like({ perl => $cmd }, qr/Data::Printer version 0.36 required--this is only version/,
				"correctly identified old (bad) version of Data::Printer");
		done_testing;
		exit;
	}
}


use Debuggit(DataPrinter => 1, DEBUG => 2);


open(IN, "t/data/hash_for_dumping") or die("# cannot read test data");
my $testhash = eval do { local $/; <IN> };
close(IN);

my $cmd = <<'END';
    use strict;
    use warnings;
    require Data::Printer;

    open(IN, "t/data/hash_for_dumping") or die("# cannot read test data");
    my $testhash = eval do { local $/; <IN> };
    close(IN);

    print Data::Printer::np($testhash, colored => 1, hash_separator => " => ", print_escapes => 1);
END

# get dumped output without actually loading Data::Printer
my $dump = cmd_stdout({ perl => $cmd });
# make sure we actually _got_ some output
isnt $dump, '', "test dump returned some output";
# and make sure we didn't actually load Data::Printer
throws_ok { print &Data::Printer::p() } qr/^Undefined subroutine &Data::Printer::p called/,
        'Data::Printer not loaded';

my $output = 'test is';
stderr_is { debuggit(2 => $output, DUMP => $testhash); } "$output $dump\n", "got DUMP output";


# if you call it twice for the same package, make sure the Data::Dumper version doesn't come back
eval 'use Debuggit DEBUG => 2';
stderr_is { debuggit(2 => $output, DUMP => $testhash); } "$output $dump\n", "still using Data::Printer after reimport";


# make sure it still works even after loading Data::Printer directly
$cmd = <<'END';
    use strict;
    use warnings;
    use Data::Printer;
    use Debuggit DEBUG => 2, DataPrinter => 1;

    debuggit(2 => DUMP => { this => 'hash' });
END
cmd_stderr_unlike({ perl => $cmd }, qr/type.*must be one of.*not/i, "successfully circumvented prototype");


done_testing;
