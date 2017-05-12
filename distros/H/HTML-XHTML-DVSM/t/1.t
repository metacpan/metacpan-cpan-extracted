# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('HTML::XHTML::DVSM') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
use strict;
use HTML::XHTML::DVSM;
use IO::String;

my $sb = HTML::XHTML::DVSM->new();

my $buf = "";
$sb->sbSetStopOnError( 1 );
sub prepare {
    $sb->sbInit();
    $buf = "";
    $sb->{Stream} = IO::String->new(\$buf);
}
sub logit {
    my $msg = shift;
    print "$msg\n";
}
sub getSB { return $sb; }

testSet();
testRun();
testToggle();
testDelete();
testIf();
testWhile();

### TESTRUN
sub testRun {
    prepare();
    my $markup = '
<html><body>    
<span id="sid">hello world</span>
</body></html>
<!--DVSM
run "doRun()"
run "doRun()" where id = "sid"
-->
<!--DSUBS
my $count = 0;
sub doRun {
    ++$count;
    my $stream = getSB()->{Stream};
    print $stream "doRun called $count\n";
}
-->    
';
    my ( $instructions, $subs ) = "";
    my $markup_copy = $markup;
    $sb->sbAnalyseContents( ".", \$markup, \$instructions, \$subs );
    die ( "Markup [$markup] should not contain DVSM tags" ) if ( $markup =~ /DVSM/ );
    die ( "Subs should contain sayHello() function" ) if ( ! $subs );
    die ( "Instructions should contain set command" ) if ( ! $instructions );
    $sb->sbInitMarkup( ".", \$markup_copy );
    $sb->sbPrintDocument();
    ok( $buf =~ /doRun called 2\n<span/s, "Test Run" );
    #print "[$buf]\n";
}

###TESTSET
sub testSet {
    prepare();
    my $markup = <<EOF;
<html><body>    
<span id="sid">hello world</span>
</body></html>
<!--DVSM
set textnode to "sayHello()" where id = "sid"
set id to "return 'sidney'" where id = "sid"
-->
<!--DSUBS
sub sayHello {
    return "hello sid";
}
-->
EOF
    my ( $instructions, $subs ) = "";
    my $markup_copy = $markup;
    $sb->sbAnalyseContents( ".", \$markup, \$instructions, \$subs );
    die ( "Markup [$markup] should not contain DVSM tags" ) if ( $markup =~ /DVSM/ );
    die ( "Subs should contain sayHello() function" ) if ( ! $subs );
    die ( "Instructions should contain set command" ) if ( ! $instructions );
    $sb->sbInitMarkup( ".", \$markup_copy );
    $sb->sbPrintDocument();
    ok( $buf =~ />hello sid</, "Test Set" );
    #print "[$buf]\n";
    return 1;
}

###TESTTOGGLE
sub testToggle {
    prepare();
    my $markup = <<EOF;
<html><body>    
<select name="myselect">
<option value="1" select="myselect">Option 1</option>
<option value="2" select="myselect">Option 2</option>
<option value="3" select="myselect">Otpion 3</option>
</select>
</body></html>
<!--DVSM
toggle selected to "doToggle()" where select = "myselect"
-->
<!--DSUBS
my \$selected = 2;
sub doToggle {
    my \$sb = getSB();
    my \$value = \$sb->sbGetCurrentTagValue( "value" );
    return ( \$value == \$selected );
}
-->    
EOF
    my ( $instructions, $subs ) = "";
    my $markup_copy = $markup;
    $sb->sbAnalyseContents( ".", \$markup, \$instructions, \$subs );
    $sb->sbInitMarkup( ".", \$markup_copy );
    $sb->sbPrintDocument();
    #print "[$buf]\n";
    ok( $buf =~ /value="2" selected="true" select="myselect">Option 2</s, "Test Toggle" );
}

###TESTTOGGLE
sub testDelete {
    prepare();
    my $markup = <<EOF;
<html><body>    
<select name="myselect">
<option value="1" select="myselect">Option 1</option>
<option value="2" select="deleteme">Option 2</option>
<option value="3" select="deleteme">Otpion 3</option>
</select>
</body></html>
<!--DVSM
delete where select = "deleteme"
-->
EOF
    my ( $instructions, $subs ) = "";
    my $markup_copy = $markup;
    $sb->sbAnalyseContents( ".", \$markup, \$instructions, \$subs );
    $sb->sbInitMarkup( ".", \$markup_copy );
    $sb->sbPrintDocument();
    #print "[$buf]\n";
    ok( $buf !~ /<option value="3" select="myselect">Otpion 3<\/option>/s, "Test Delete" );
}

###TESTIF
sub testIf {
    prepare();
    my $markup = '<html><body>
<p>This paragraph always happens</p>
<p id="datepara_even">This paragraph only happens if the date of the month
(<span id="thedate"></span>) is an even number</p>
<p id="datepara_odd">This version of the paragraph only happens if the date of the month
(<span id="thedate"></span>) is an odd number</p>
</body></html>
<!--DVSM
if "dateiseven()" where id = "datepara_even"
   set textnode to "getdate()" where id = "thedate"
end if
if "dateisodd()" where id = "datepara_odd"
   set textnode to "getdate()" where id="thedate"
end if
-->
<!--DSUBS
sub dateisodd { return ( ! dateiseven() ); }
sub dateiseven {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
        localtime(time);
    return ( $mday % 2 == 0 );
}
sub getdate {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
        localtime(time);
    return sprintf( "%.2d/%.2d/%.4d", $mday, $mon + 1, 1900 + $year );
}
-->
';
    my ( $instructions, $subs ) = "";
    my $markup_copy = $markup;
    $sb->sbAnalyseContents( ".", \$markup, \$instructions, \$subs );
    $sb->sbInitMarkup( ".", \$markup_copy );
    $sb->sbPrintDocument();
    my @date = localtime(time);
    my $mday = $date[3];
    if ( $mday % 2 == 0 ) {
        ok( $buf =~ /is an even number/s, "Test If" );
    }
    else {
        ok( $buf =~ /is an odd number/s, "Test If" );
    }
    #print "[$buf]\n";
}

###TESTWHILE
sub testWhile {
    prepare();
    my $markup = <<EOF;
<html><body>
<table>
<tr><th>Customer Number</th><th>Customer Name</th></tr>
<tbody>
<tr name="customers"><td name="custid">12345</td><td name="custname">Mr Bloggs</td></tr>
<tr name="deleteme"><td>23456</td><td>Mrs Soap</td></tr>
<tr name="deleteme"><td>67890</td><td>Mr A N Other</td></tr>
</tbody>
</table>
</body></html>
<!--DVSM
delete where name = "deleteme"
while "moreCustomers()" where name = "customers"
   set textnode to "getCustid()" where name = "custid"
   set textnode to "getCustname()" where name = "custname"
end while
-->
<!--DSUBS
my %db = ( 148842 => "Mr J Smith", 848488 => "Ms S Jones", 484848 => "Mrs P Cook" );
my \$cursor = -1;
sub moreCustomers {
    \$cursor++;
    my \@keys = keys( %db );
    return ( \$cursor < \@keys );
}
sub getCustid {
    my \@keys = sort keys( %db );
    return \$keys[\$cursor];
}
sub getCustname {
    return \$db{getCustid()};
}
-->    
EOF
    my ( $instructions, $subs ) = "";
    my $markup_copy = $markup;
    $sb->sbAnalyseContents( ".", \$markup, \$instructions, \$subs );
    $sb->sbInitMarkup( ".", \$markup_copy );
    $sb->sbPrintDocument();
    ok( $buf =~ />Ms S Jones</s, "Test While" );
    #print "[$buf]\n";
}

