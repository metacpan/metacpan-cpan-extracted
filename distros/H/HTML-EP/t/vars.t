# -*- perl -*-

use strict;


print "1..20\n";

require HTML::EP::Locale;

{
    my $numTests = 0;
    sub Test($;@) {
	my $result = shift;
	if (@_ > 0) { printf(@_); }
	++$numTests;
	if (!$result) { print "not " };
	print "ok $numTests\n";
	$result;
    }

    sub SkipTest() {
	++$numTests;
	print "ok $numTests # Skip\n";
    }
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

my $dbh;
eval { require DBI; $dbh = DBI->connect("DBI:CSV:") };


$ENV{'REQUEST_METHOD'} = 'GET';
my $self = HTML::EP::Locale->new();
$self->{'env'} = {'PATH_TRANSLATED' => ''};
$self->init();
$self->{'a'} = 1;
$self->{'b'} = "Obelix GmbH & Co KG";
$self->{'t_hash_ref'} = { f => 'foo', g => 'bar' };
$self->{'t_array_ref'} = [ 1, 1.5, 'i' ];
$self->{'dbh'} = $dbh;
$self->{'empty'} = '';
$self->{'sum'} = 1234567.89;
$self->{'path'} = "file:/mosaic/..";

Test2($self->ParseVars('$a$'), '1', "Simple strings (HTML encoded)\n");
Test2($self->ParseVars('$%a$'), '1', "Simple strings (HTML encoded)\n");
Test2($self->ParseVars('$@a$'), '1', "Simple strings (Raw)\n");
Test2($self->ParseVars('$#a$'), '1', "Simple strings (URL encoded)\n");
if (!$dbh) {
    SkipTest();
} else {
    Test2($self->ParseVars('$~a$'), "'1'", "Simple strings (DBI quoted)\n");
}

Test2($self->ParseVars('$b$'), 'Obelix GmbH &amp; Co KG',
     "HTML strings (HTML encoded)\n");
Test2($self->ParseVars('$%b$'), 'Obelix GmbH &amp; Co KG',
     "HTML strings (HTML encoded)\n");
Test2($self->ParseVars('$@b$'), 'Obelix GmbH & Co KG',
    "HTML strings (Raw)\n");
Test2($self->ParseVars('$#b$'), 'Obelix%20GmbH%20%26%20Co%20KG',
     "HTML strings (URL encoded)\n");
if (!$dbh) {
    SkipTest();
} else {
    Test2($self->ParseVars('$~b$'), "'Obelix GmbH \& Co KG'",
          "HTML strings (DBI quoted)\n");
}

Test2($self->ParseVars('$t_hash_ref->f$'), 'foo', "Hash dereferencing\n");
Test2($self->ParseVars('$t_hash_ref->g$'), 'bar', "Hash dereferencing\n");

Test2($self->ParseVars('$t_array_ref->0$'), '1', "Array dereferencing\n");
Test2($self->ParseVars('$t_array_ref->1$'), '1.5', "Array dereferencing\n");
Test2($self->ParseVars('$t_array_ref->2$'), 'i', "Array dereferencing\n");
Test2($self->ParseVars('$&NBSP->empty$'), '&nbsp;', "Custom format: NBSP\n");
Test2($self->ParseVars('$&NBSP->b$'), 'Obelix GmbH & Co KG',
                       "Custom format: NBSP\n");

Test2($self->ParseVars('$@_ep_language$'),
      $HTML::EP::Config::CONFIGURATION->{'default_language'} =
      $HTML::EP::Config::CONFIGURATION->{'default_language'}, # -w
      "Default language\n");
Test2($self->ParseVars('$&DM->sum$'), '1 234 567,89 DM',
                       "Custom format: DM\n");
Test2($self->ParseVars('$#path$'), 'file%3A%2Fmosaic%2F..');


