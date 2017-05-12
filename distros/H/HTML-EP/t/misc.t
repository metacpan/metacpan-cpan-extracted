# -*- perl -*-
#
# $Id: misc.t,v 1.1.1.1 1999/11/18 22:48:12 joe Exp $
#

use strict;

$^W = 1;
$| = 1;


print "1..82\n";

use HTML::EP ();

my $have_dbd_csv = eval { require DBD::CSV };
my $have_dbi = eval { require DBI };


my $numTests = 0;
sub Test($;@) {
    my $result = shift;
    if (@_ > 0) { printf(@_); }
    ++$numTests;
    if (!$result) { print "not " };
    print "ok $numTests\n";
    $result;
}

sub Test2($$;@) {
    my $a = shift;
    my $b = shift;
    my $c = ($a eq $b);
    if (!Test($c, @_)) {
	print("Expected $b, got $a\n");
    }
    $c;
}


$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING} = '';
$ENV{DOCUMENT_ROOT} = '';


my $parser = HTML::EP->new();
Test($parser, "Creating the parser.\n");

my $input = <<'END_OF_HTML';
<HTML><!-- This is a comment; it will stay -->
      <ep-comment>This is another comment. It will be removed.</ep-comment>.
</HTML>
END_OF_HTML

my $output = <<'END_OF_HTML';
<HTML><!-- This is a comment; it will stay -->
      .
</HTML>
END_OF_HTML
Test2($parser->Run($input), $output, "Multi-line comment.\n");

$parser = HTML::EP->new();
Test2($parser->Run('<ep-set var="a" val="b">'), '', "Setting a variable\n");
Test($parser->{'a'} eq 'b');

$parser = HTML::EP->new();
Test2($parser->Run('<ep-set var="a">c</ep-set>'), '',
		   "Setting a multi-line variable\n");
Test($parser->{'a'} eq 'c');

$parser = HTML::EP->new();
$parser->{'a'} = {};
Test2($parser->Run('<ep-set var="a->b">c</ep-set>'), '',
		   "Setting a structured variable\n");
Test($parser->{'a'}->{'b'} eq 'c');

$parser = HTML::EP->new();
$parser->{'a'} = [];
Test2($parser->Run('<ep-set var="a->0">d</ep-set>'), '',
		   "Setting an array variable\n");
Test($parser->{'a'}->[0] eq 'd');

$parser = HTML::EP->new();
$input = <<'END_OF_HTML';
<HTML><!-- This is a comment; it will stay -->
      <ep-comment comment="This is another comment. It will be removed.">.
</HTML>
END_OF_HTML
Test2($parser->Run($input), $output, "Single-line comment.\n");


$input = "<HTML>We'll see this</HTML><ep-exit>But not this!";
$output = "<HTML>We'll see this</HTML>";
$parser = HTML::EP->new();
eval { $parser->Run($input) }; 
Test2($parser->{'_ep_output'}, $output, "Exit\n");

$input = q{<HTML>We'll see this</HTML><ep-if eval="$a$"><ep-exit></ep-if>}
     . "And this!";
$output = "<HTML>We'll see this</HTML>And this!";
$parser = HTML::EP->new();
$parser->{'a'} = 0;
Test2($parser->Run($input), $output, "Exit 2\n");

$input = q{<HTML>We'll see this</HTML><ep-if eval="$a$"><ep-exit></ep-if>}
     . "But not this!";
$output = "<HTML>We'll see this</HTML>";
$parser = HTML::EP->new();
$parser->{'a'} = 1;
eval { $parser->Run($input) }; 
Test2($parser->{'_ep_output'}, $output, "Exit 3\n");

$input = q{<HTML>We'll see this</HTML><ep-if eval="$a$">And this!}
     . q{<ep-if eval="$a$"><ep-exit></ep-if></ep-if>}
     . "But not this!";
$output = "<HTML>We'll see this</HTML>And this!";
$parser = HTML::EP->new();
$parser->{'a'} = 1;
eval { $parser->Run($input) }; 
Test2($parser->{'_ep_output'}, $output, "Exit 4\n");

print "Testing conditions: neval, ==, !=, <, >, <=, >=, eq, ne\n";
$input = q{<ep-if neval="$a$">a is not set<ep-else>a is set</ep-if>};
$parser = HTML::EP->new();
$parser->{'a'} = 1;
eval { $parser->Run($input) };
Test2($parser->{'_ep_output'}, "a is set");
$parser = HTML::EP->new();
$parser->{'a'} = 0;
eval { $parser->Run($input) };
Test2($parser->{'_ep_output'}, "a is not set");

foreach my $ref (["==", 0, 1, 0],
		 ["!=", 1, 0, 1],
		 ["<", 1, 0, 0],
		 [">", 0, 0, 1],
		 ["<=", 1, 1, 0],
		 [">=", 0, 1, 1]) {
    $input = q{<ep-if cnd="$a$} . $ref->[0] . q{$b$">1<ep-else>0</ep-if>};
    $parser = HTML::EP->new();
    $parser->{'a'} = 1;
    $parser->{'b'} = 2;
    eval { $parser->Run($input) };
    Test2($parser->{'_ep_output'}, $ref->[1]);
    $parser = HTML::EP->new();
    $parser->{'a'} = 1;
    $parser->{'b'} = 1;
    eval { $parser->Run($input) };
    Test2($parser->{'_ep_output'}, $ref->[2]);
    $parser = HTML::EP->new();
    $parser->{'a'} = 2;
    $parser->{'b'} = 1;
    eval { $parser->Run($input) };
    Test2($parser->{'_ep_output'}, $ref->[3]);
}

foreach my $ref (["eq", 0, 1],
		 ["ne", 1, 0]) {
    $input = q{<ep-if cnd="'$a$'} . $ref->[0] . q{'$b$'">1<ep-else>0</ep-if>};
    $parser = HTML::EP->new();
    $parser->{'a'} = 1;
    $parser->{'b'} = 2;
    eval { $parser->Run($input) };
    Test2($parser->{'_ep_output'}, $ref->[1]);
    $parser = HTML::EP->new();
    $parser->{'a'} = 1;
    $parser->{'b'} = 1;
    eval { $parser->Run($input) };
    Test2($parser->{'_ep_output'}, $ref->[2]);
}

if ((-f "foo"  &&  !unlink("foo"))  ||
    !open(FOO, ">foo")  ||  !(print FOO "b")  ||  !close(FOO)) {
    die "Error while writing 'foo': $!";
}
$parser = HTML::EP->new();
Test2($parser->Run('a<ep-include file="foo">c'), "abc", "Include.\n");

$parser = HTML::EP->new();
$parser->{'list'} = [1,2,3,4];
$input = 'a<ep-list items=list item=l>$l$<ep-include file="foo"></ep-list>c';
Test2($parser->Run($input), "a1b2b3b4bc", "Repeated include.\n");

$parser = HTML::EP->new();
$parser->{'session'}->{'list'} = [[1,2,3,4]];
$input = 'a<ep-list items="session->list->0" item=l>$l$<ep-include file="foo"></ep-list>c';
Test2($parser->Run($input), "a1b2b3b4bc", "Repeated include.\n");


$parser = HTML::EP->new();
$input = '<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">';
Test2($parser->Run($input), $input, "DOCTYPE\n");


$parser = HTML::EP->new();
$input = '<HTML><ep-perl code="3+4"></HTML>';
$output = '<HTML>7</HTML>';
Test2($parser->Run($input), $output, "Single-line Perl expression.\n");


$parser = HTML::EP->new();
$input = <<'_END_OF_HTML';
<HTML><ep-perl>
'ab' . 'ce'
</ep-perl>
</HTML>
_END_OF_HTML
$output = <<'_END_OF_HTML';
<HTML>abce
</HTML>
_END_OF_HTML
Test2($parser->Run($input), $output, "Multi-line Perl expression.\n");


if (!$have_dbi  ||  !$have_dbd_csv) {
    ++$numTests;
    print "ok $numTests # Skip\n";
} else {
    $parser = HTML::EP->new();
    $input = <<'_END_OF_HTML';
<HTML><ep-database dsn="DBI:CSV:"></HTML>
_END_OF_HTML
    $output = <<'_END_OF_HTML';
<HTML></HTML>
_END_OF_HTML
    my $got = eval { $parser->Run($input); };
    Test2($got, $output, "Making a Database connection.\n");
}
my $dbh = $parser->{dbh};


if (!$have_dbi  ||  !$have_dbd_csv) {
    ++$numTests;
    print "ok $numTests # Skip\n";
} else {
    if (-f 'foo') { unlink 'foo'; }
    $parser = HTML::EP->new();
    $input = <<'_END_OF_HTML';
<HTML>
<ep-database dsn="DBI:CSV:">
<ep-query statement="CREATE TABLE foo (id INTEGER, name VARCHAR(64))">
<ep-query statement="INSERT INTO foo VALUES (1, 'joe')">
<ep-query statement="INSERT INTO foo VALUES (2, 'amar')">
<ep-query statement="INSERT INTO foo VALUES (3, 'gerald')">
<ep-query statement="SELECT * FROM foo" result="people">
$people_rows$
<TABLE>
<ep-list items="people" item="p">
  <TR><TD>$p->id$</TD><TD>$p->name$</TD>
</ep-list>
</TABLE>
<ep-query statement="SELECT * FROM foo" result="people2" limit=1 startat=1>
$people2_rows$
<ep-list items="people2" item="p">$p->id$,$p->name$</ep-list>
</HTML>
_END_OF_HTML
    $output = <<'_END_OF_HTML';
<HTML>






3
<TABLE>

  <TR><TD>1</TD><TD>joe</TD>

  <TR><TD>2</TD><TD>amar</TD>

  <TR><TD>3</TD><TD>gerald</TD>

</TABLE>

1
2,amar
</HTML>
_END_OF_HTML
    Test2($parser->Run($input), $output, "SQL queries.\n");
}


$parser = HTML::EP->new();
$input = '<ep-select range="1..5" name="foo" selected=3 item=y>'
    . '<OPTION $selected$>$y$</ep-select>';
$output= '<SELECT name="foo"><OPTION >1<OPTION >2<OPTION SELECTED>3<OPTION >4'
    . '<OPTION >5</SELECT>';
Test2($parser->Run($input), $output, "Select lists.\n");


$ENV{QUERY_STRING} = 'address_t_name=joe&address_t_street=Am+Eisteich+9'
    . '&address_n_zip=72555&address_t_city=Metzingen'
    . '&address_dy_date1=1998&address_dm_date1=7&address_dd_date1=2'
    . '&address_dy_date2=98&address_dm_date2=7&address_dd_date2=2'
    . '&address_dy_date3=8&address_dm_date3=7&address_dd_date3=2';
$input = <<'_END_OF_HTML';
<ep-input prefix="address_" dest=address>
<HTML>
<P>Name = $address->name->val$</P>
<P>Street = $address->street->val$</P>
<P>Zip = $address->zip->val$</P>
<P>City = $address->city->val$</P>
<P>Date1 = $address->date1->val$</P>
<P>Date2 = $address->date2->val$</P>
<P>Date3 = $address->date3->val$</P>
</HTML>
_END_OF_HTML
$output = <<'_END_OF_HTML';

<HTML>
<P>Name = joe</P>
<P>Street = Am Eisteich 9</P>
<P>Zip = 72555</P>
<P>City = Metzingen</P>
<P>Date1 = 1998-07-02</P>
<P>Date2 = 1998-07-02</P>
<P>Date3 = 2008-07-02</P>
</HTML>
_END_OF_HTML
$parser = HTML::EP->new();
Test2($parser->Run($input), $output, "Object input.\n");

if (!$have_dbi  ||  !$have_dbd_csv) {
    ++$numTests;
    print "ok $numTests # Skip\n";
} else {
    $input = '<ep-database dsn="DBI:CSV:">'.$input;
    $input =~ s/(dest=address)/$1 sqlquery=1/;
    $input .= <<'END_OF_HTML';
<P>Names = $address->names$
<P>Values = $address->values$
<P>Update = $address->update$
END_OF_HTML
    $output .= <<'END_OF_HTML';
<P>Names = date2,date3,city,name,zip,date1,street
<P>Values = '1998-07-02','2008-07-02','Metzingen','joe',72555,'1998-07-02','Am Eisteich 9'
<P>Update = date2='1998-07-02',date3='2008-07-02',city='Metzingen',name='joe',zip=72555,date1='1998-07-02',street='Am Eisteich 9'
END_OF_HTML
    $parser = HTML::EP->new();
    Test2($parser->Run($input), $output,
	  "Object input with 'sqlquery' set.\n");
}


$ENV{QUERY_STRING} = 'art_0_t_name=Book&art_0_n_price=5.00'
    . '&art_1_t_name=Donut&art_1_n_price=1.00';
$input = <<'_END_OF_HTML';
<ep-input prefix="art_" dest=art list=1>
<ep-list items=art item=a>
  Name = $a->name->val$, Price = $a->price->val$, Item = $a->i$
</ep-list>
_END_OF_HTML
$output = <<'_END_OF_HTML';


  Name = Book, Price = 5.00, Item = 0

  Name = Donut, Price = 1.00, Item = 1

_END_OF_HTML
undef @CGI::QUERY_PARAM; # Arrgh! CGI caches :-(
$parser = HTML::EP->new();
Test2($parser->Run($input), $output, "Object list input.\n");


$input = <<'_END_OF_HTML';
<HTML>
<ep-if eval="$_->{i}==0">0<ep-elseif eval="$_->{i}==1">1<ep-elseif eval="$_->{i}==2">2<ep-else>3</ep-if>
</HTML>
_END_OF_HTML

for (my $i = 0;  $i < 4;  $i++) {
$output = <<"_END_OF_HTML";
<HTML>
$i
</HTML>
_END_OF_HTML
    $parser = HTML::EP->new();
    $parser->{i} = $i;
    Test2($parser->Run($input), $output, "If: $i.\n");
}


$input = <<'_END_OF_HTML';
<HTML>
<ep-if eval="$_->{i}<0">
    i is < 0.
<ep-elseif eval="$_->{i}==0">
    i equals 0.
<ep-elseif eval="$_->{j}<0">
    j is < 0.
<ep-elseif eval="$_->{j}==0">
    j equals 0.
<ep-else>
    Both numbers are > 0.
</ep-if>
</HTML>
_END_OF_HTML

my $ref;
my @conditionals = (
    [ -1, -1, "i is < 0." ],
    [ -1, 0,  "i is < 0." ],
    [ -1, 1,  "i is < 0." ],
    [ 0, -1,  "i equals 0." ],
    [ 0, 0,   "i equals 0." ],
    [ 0, 1,   "i equals 0." ],
    [ 1, -1,  "j is < 0." ],
    [ 1, 0,   "j equals 0." ],
    [ 1, 1,   "Both numbers are > 0." ]
);
foreach $ref (@conditionals) {
    $parser = HTML::EP->new();
    $parser->{i} = $ref->[0];
    $parser->{j} = $ref->[1];
    my $result = $ref->[2];    
    $output = <<"_END_OF_HTML";
<HTML>

    $result

</HTML>
_END_OF_HTML
    Test2($parser->Run($input), $output);
}


$input = <<'_END_OF_HTML';
<HTML>
<ep-if eval="$_->{i}<0">
    i is < 0.
<ep-elseif eval="$_->{i}==0">
    i equals 0.
<ep-else><ep-if eval="$_->{j}<0">
    j is < 0.
<ep-elseif eval="$_->{j}==0">
    j equals 0.
<ep-else>
    Both numbers are > 0.
</ep-if></ep-if>
</HTML>
_END_OF_HTML

foreach $ref (@conditionals) {
    $parser = HTML::EP->new();
    $parser->{i} = $ref->[0];
    $parser->{j} = $ref->[1];
    my $result = $ref->[2];    
    $output = <<"_END_OF_HTML";
<HTML>

    $result

</HTML>
_END_OF_HTML
    Test2($parser->Run($input), $output);
}


my $cfg;
if (-f "lib/HTML/EP/Config.pm") {
    $cfg = do "lib/HTML/EP/Config.pm";
}
if (!$cfg->{email}  ||  $cfg->{email} eq 'none'  ||  !$cfg->{mailhost}) {
    Test(1);
} else {
    print("Sending mail to ", $cfg->{email}, " via mail server ",
          $cfg->{mailhost}, "\n");
    $input = <<'_END_OF_HTML';
<HTML>
<ep-mail from="joe@ispsoft.de" to="$cgi->email$" subject="Testmail">

Hello,

this is a testmail from the script t/misc.t in the HTML::EP distribution.
You may safely ignore it. It was sent to $cgi->email$ by using the mailserver
$cgi->mailhost$.

You should be alarmed, though, if it doesn't reach you. :-)


Yours sincerely,

Jochen Wiedmann
</ep-mail>
</HTML>
_END_OF_HTML
    $output = <<'_END_OF_HTML';
<HTML>

</HTML>
_END_OF_HTML
    $ENV{QUERY_STRING} = 'email=' . CGI->escape($cfg->{email}) .
        '&mailhost=' . CGI->escape($cfg->{mailhost});
    undef @CGI::QUERY_PARAM; # Arrgh! CGI caches :-(
    $parser = HTML::EP->new();
    Test2($parser->Run($input), $output);
}


print "Checking nested loops.\n";
$input = q{
<ep-list range="1..3" item=j
 ><ep-list range="4..6" item=k
   ><ep-list range="7..9" item=l>j$j$k$k$l$l$</ep-list></ep-list></ep-list>};
$output = "\n";
for (my $j = 1;  $j < 4;  $j++) {
    for (my $k = 4;  $k < 7;  $k++) {
	for (my $l = 7;  $l < 10;  $l++) {
	    $output .= "j${j}k${k}l$l";
	}
    }
}
$parser = HTML::EP->new();
Test2($parser->Run($input), $output);


print "Checking nested loop/if.\n";
$input = q{
<ep-list range="1..4" item=j>a<ep-if cnd="$j$<3">ok$j$</ep-if>b</ep-list>};
$output = "\naok1baok2babab";
$parser = HTML::EP->new();
Test2($parser->Run($input), $output);


print "Checking nested if/loop.\n";
$input = q{<ep-if eval="$a$"><ep-list range="1..4" item=j>a$j$</ep-list></ep-if>};
$output = "a1a2a3a4";
$parser = HTML::EP->new();
$parser->{'a'} = 1;
Test2($parser->Run($input), $output);
$parser = HTML::EP->new();
$parser->{'a'} = 0;
Test2($parser->Run($input), "");


print "Checking repeated ep-package\n";
$input = q{
<ep-package name="HTML::EP::Locale">
<ep-package name="HTML::EP::EditTable">
};
$parser = HTML::EP->new();
Test2($parser->Run($input), "\n\n\n");
Test(ref($parser) eq "HTML::EP::PACK2")
    or print "$parser is a ", ref($parser), "\n";
Test(@HTML::EP::PACK2::ISA == 2  &&
     $HTML::EP::PACK2::ISA[0] eq 'HTML::EP::EditTable'  &&
     $HTML::EP::PACK2::ISA[1] eq 'HTML::EP::Locale')
    or print "Wrong ISA, got\n", map { "  $_\n " } @HTML::EP::PACK2::ISA;

print "Checking ep-set nested with ep-list.\n";
$parser = HTML::EP->new();
$parser->{'list'} = [1,2,3,4];
$input = '<ep-list items=list item=l><ep-set var=Foo>$l$</ep-set>$Foo$</ep-list>';
Test2($parser->Run($input), "1234");

END { unlink 'foo' }
