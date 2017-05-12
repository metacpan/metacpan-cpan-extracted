# -*- perl -*-

use strict;

$^W = 1;
$| = 1;


eval {
    require HTML::EP::Shop;
    require DBD::CSV;
    require DBI;
};
if ($@) {
    print "1..0\n";
    exit 0;
}

print "1..5\n";



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


unlink "prefs";

my $input = q{
<ep-package name="HTML::EP::Shop">
<ep-database dsn="DBI:CSV:">
<ep-shop-prefs-read var="prefs" write=1>
$prefs->company$,$prefs->street$,$prefs->zip$,$prefs->city$,$prefs->country$
$prefs->vat$,$prefs->creditcards$,$prefs->nachnahme$,$prefs->rechnung$
$prefs->lastschrift$
};
my $output = q{



,,,,
,,,

};

my $parser = HTML::EP->new();
$parser->{'env'} = { 'PATH_TRANSLATED' => 't/shop.t'};
Test2($parser->Run($input), $output, "Reading the prefs (initially).\n");


$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING} = 'prefs_company=ISPsoft&prefs_street=Am+Eisteich+9'
    . '&prefs_zip=72555&prefs_city=Metzingen&prefs_country=Deutschland'
    . '&prefs_vat=16.0&prefs_creditcards=Mastercard,Eurocard,VISA'
    . '&prefs_nachnahme=1&prefs_rechnung=1&prefs_lastschrift=1';

$input = q{
<ep-package name="HTML::EP::Shop">
<ep-database dsn="DBI:CSV:">
<ep-shop-prefs-read var="prefs" write=1>
$prefs->company$,$prefs->street$,$prefs->zip$,$prefs->city$,$prefs->country$
$prefs->vat$,$prefs->creditcards$,$prefs->nachnahme$,$prefs->rechnung$
$prefs->lastschrift$
};
$output = q{



ISPsoft,Am Eisteich 9,72555,Metzingen,Deutschland
16.0,Mastercard,Eurocard,VISA,1,1
1
};
$parser = HTML::EP->new();
$parser->{'env'} = { 'PATH_TRANSLATED' => 't/shop.t'};
Test2($parser->Run($input), $output, "Writing the prefs (initially).\n");


$input = q{
<ep-package name="HTML::EP::Shop">
<ep-database dsn="DBI:CSV:">
<ep-shop-prefs-read var="prefs">
$prefs->company$,$prefs->street$,$prefs->zip$,$prefs->city$,$prefs->country$
$prefs->vat$,$prefs->creditcards$,$prefs->nachnahme$,$prefs->rechnung$
$prefs->lastschrift$
};
$output = q{



ISPsoft,Am Eisteich 9,72555,Metzingen,Deutschland
16.0,Mastercard,Eurocard,VISA,1,1
1
};
$parser = HTML::EP->new();
$parser->{'env'} = { 'PATH_TRANSLATED' => 't/shop.t'};
Test2($parser->Run($input), $output, "Reading the prefs again.\n");


$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING} = 'prefs_company=ISPsoft&prefs_street=Am+Eisteich+9'
    . '&prefs_zip=72555&prefs_city=Metzingen&prefs_country=Deutschland'
    . '&prefs_vat=17.0'
    . '&prefs_creditcards=Mastercard,Eurocard,VISA,American+Express'
    . '&prefs_nachnahme=1&prefs_rechnung=1&prefs_lastschrift=1';
# Prevent CGI module from caching
undef @CGI::QUERY_PARAM;
undef @CGI::QUERY_PARAM; # -w

$input = q{
<ep-package name="HTML::EP::Shop">
<ep-database dsn="DBI:CSV:">
<ep-shop-prefs-read var="prefs" write=1>
$prefs->company$,$prefs->street$,$prefs->zip$,$prefs->city$,$prefs->country$
$prefs->vat$,$prefs->creditcards$,$prefs->nachnahme$,$prefs->rechnung$
$prefs->lastschrift$
};
$output = q{



ISPsoft,Am Eisteich 9,72555,Metzingen,Deutschland
17.0,Mastercard,Eurocard,VISA,American Express,1,1
1
};
$parser = HTML::EP->new();
$parser->{'env'} = { 'PATH_TRANSLATED' => 't/shop.t'};
Test2($parser->Run($input), $output, "Updating the prefs.\n");


$input = q{
<ep-package name="HTML::EP::Shop">
<ep-database dsn="DBI:CSV:">
<ep-shop-prefs-read var="prefs">
$prefs->company$,$prefs->street$,$prefs->zip$,$prefs->city$,$prefs->country$
$prefs->vat$,$prefs->creditcards$,$prefs->nachnahme$,$prefs->rechnung$
$prefs->lastschrift$
};
$output = q{



ISPsoft,Am Eisteich 9,72555,Metzingen,Deutschland
17.0,Mastercard,Eurocard,VISA,American Express,1,1
1
};
$parser = HTML::EP->new();
$parser->{'env'} = { 'PATH_TRANSLATED' => 't/shop.t'};
Test2($parser->Run($input), $output, "Reading the prefs (finally).\n");


unlink 'prefs';




