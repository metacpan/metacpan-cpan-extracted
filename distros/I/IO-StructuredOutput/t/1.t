# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test; # (tests => 37);

my @types = ('csv','html','xls');
plan tests => (7 + (scalar(@types) * 10));

my $html_output = '<HR><B>test1</B><BR>
<TABLE BORDER=1>
<TR>
<TD >test</TD>
<TD >blah</TD>
<TD >bob</TD>
</TR>
<TR>
<TD >test</TD>
<TD >blah</TD>
<TD >bob</TD>
</TR>
</TABLE>
<BR>
<HR><B>test2</B><BR>
<TABLE BORDER=1>
</TABLE>
<BR>
';

use IO::StructuredOutput;
ok(1);	# made it this far, we're ok.
use IO::StructuredOutput::Sheets;
ok(1);	# made it this far, we're ok.
my $io_so = IO::StructuredOutput->new;
ok( defined $io_so, 1, 'new() did not return anything' );
ok($io_so->isa('IO::StructuredOutput'));

# formats
$io_so->format('xls');
ok( $io_so->format(), 'xls', "couldn't set format to xls" );
$io_so->format('csv');
ok( $io_so->format(),'csv', "couldn't set format to csv" );
$io_so->format('html');
ok( $io_so->format(),'html', "couldn't set format to html" );
# now try creating one of each type of output w/ sheets
print "testing different formats making output\n";
foreach my $type (@types)
{
	my %io_so;
	$io_so{$type} = IO::StructuredOutput->new;
	$io_so{$type}->format($type);
	my $ws = $io_so{$type}->addsheet('test1');
	ok( sub { return 1 if ref($ws); }, 1, "  $type: got something back from addsheet('test1')");
#	ok( $ws->isa("IO::StructuredOutput::Sheets"), "  $type: sheet added is a 'Sheets' object");
	ok( sub{ return 1 if $ws->isa("IO::StructuredOutput::Sheets"); }, 1, "  $type: sheet added is not a 'Sheets' object");

	ok($ws->name(), 'test1', "  $type: couldn't set name correctly");
	ok( $io_so{$type}->sheetcount(), 1, "  $type: incorrect sheetcount");
	my $ws2 = $io_so{$type}->addsheet('test2');

	ok( sub{ return 1 if ref($ws); }, 1, "  $type: didn't get anything back from addsheet('test2')");

	ok($ws2->name(), 'test2', "  $type: couldn't set name correctly");
	ok( $io_so{$type}->sheetcount(), 2, "  $type: incorrect sheetcount");
	$ws->addrow(['test','blah','bob']);
	ok( $ws->rowcount(), 1, "  $type: added row, got incorrect rowcount (1)");
	$ws->addrow(['test','blah','bob']);
	ok( $ws->rowcount(), 2, "  $type: added row, got incorrect rowcount (2)");

	my $output = $io_so{$type}->output();
	if ($type eq 'html')
	{
		ok( $$output, $html_output, "$type testing output");
	} else {
		ok( sub{ return 1 if ref($output); }, 1, "  $type: didn't get any output");
	}
#	TODO: {
#		local $TODO = 'output() not yet implemented';
#		my $output = $io_so{$type}->output();
#		if ($type eq 'csv')
#		{
#			ok( $output, "test,blah,bob\ntest,blah,bob\n", "  $type: got good output back");
#		} elsif ($type eq 'html') {
#			ok( $output, /^\<TABLE.+?test.+?blah.+?bob.+?test.+?blah.+?bob.+\<\/TABLE\>/i, "  $type: got good output back");
#		} elsif ($type eq 'xls') {
#			ok( $output, /test.+blah.+bob.+test.+blah.+bob/i, "  $type: output contains what we put in it, assuming good xls file");
#		}
#	}
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

