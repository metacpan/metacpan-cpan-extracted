# $Id: makeuri.t,v 1.4 2008-04-11 12:03:30 mike Exp $

use strict;
use Test;
use CGI;

use vars qw(%args @recipes);
BEGIN {
    %args = (
	     genre => "article",
	     sid => "mimas:zetoc",
	     title => "ACTA PALAEONTOLOGICA POLONICA",
	     issn => "0567-7920",
	     date => "2004",
	     volume => "49",
	     issue => "2",
	     spage => "197",
	     epage => "210",
	     atitle => "A new diplodocoid sauropod dinosaur from " .
	     "the Upper Jurassic Morrison Formation of Montana, USA",
	     aulast => "Harris",
	     auinit => "J. D.",
# There's no way to specify requestor in a v0.1 OpenURL such as this
# Use "opt_loglevel => 0xffff," for debugging output
	     );

    @recipes = (
		[ "constant string" => "constant string" ],
		[ "string with %% sign" => "string with % sign" ],
		[ "%{THIS}" => "/^http:\/\/.*rft.auinit=J\.%20D\./" ],
		( map { [ "%{$_}" => $args{$_} ] }
		  grep { !/^sid$/ } sort keys %args ),
		(map { [ "%{rft.$_}" => $args{$_} ] }
		 grep { !/^sid$/ } sort keys %args ),
		[ "%{rfr_id}" => "info:sid/mimas:zetoc" ],
		[ "%v" => "49" ],
		[ "%i" => "2" ],
		[ "%p" => "197" ],
		[ "%t" => $args{atitle} ],
		[ "%I" => "0567-7920" ],
		[ "%a" => "Harris" ],
		[ "%A" => "J. D." ],
		[ "%j" => undef ],
		[ "%x" => "{UNKNOWN-x}" ],
		[ "this%{spage}that" => "this197that" ],
		[ "this%vthat" => "this49that" ],
		[ "%*I" => "05677920" ],
		[ "%_I" => "0567-7920" ],
		[ "%*A" => "J. D." ],
		[ "%_A" => "J.D." ],
		[ "%_{title}" => "ACTAPALAEONTOLOGICAPOLONICA" ],
		[ "%{_title}" => undef ], # check that incorrect syntax fails
		[ "%1v" => "49" ],
		[ "%2v" => "49" ],
		[ "%3v" => " 49" ],
		[ "%4v" => "  49" ],
		[ "%01v" => "49" ],
		[ "%02v" => "49" ],
		[ "%03v" => "049" ],
		[ "%04v" => "0049" ],
		[ "%042v" => "000000000000000000000000000000000000000049" ],
		[ "%{title/btitle}" => "ACTA PALAEONTOLOGICA POLONICA" ],
		[ "%{btitle/title}" => "ACTA PALAEONTOLOGICA POLONICA" ],
		[ "%{abc/def/ghi/title}" => "ACTA PALAEONTOLOGICA POLONICA" ],
		[ "%{btitle/xtitle}" => undef ],
		[ "http://www.pnas.org/cgi/content/full/%v/%i/%p" =>
		  "http://www.pnas.org/cgi/content/full/49/2/197" ],
		[ "http://www.psjournals.org/paleoonline/?request=get-abstract&issn=%I&volume=%03v&issue=%02i&page=%04p" =>
		  "http://www.psjournals.org/paleoonline/?request=get-abstract&issn=0567-7920&volume=049&issue=02&page=0197" ],
		[ "http://search.epnet.com/Login.aspx?authtype=url%%2cip%%2cuid&profile=ehost&defaultdb=aph" =>
		  "http://search.epnet.com/Login.aspx?authtype=url%2cip%2cuid&profile=ehost&defaultdb=aph" ],
		[ "http://www.google.com/search?q=%%22%t%%22" =>
		  "http://www.google.com/search?q=%22A new diplodocoid sauropod dinosaur from the Upper Jurassic Morrison Formation of Montana, USA%22" ],
		[ "http://www.google.com/search?q=%%22%A %a%%22" =>
		  "http://www.google.com/search?q=%22J. D. Harris%22" ],
		[ "http://www.amazon.com/exec/obidos/ASIN/%*{isbn}/thedinosaurrea0a" =>
		  undef ], # no ISBN
		[ "http://www.bioone.org/bioone/?request=get-document&issn=%{issn}&volume=%03{volume}&issue=%02{issue}&page=%04{spage}" =>
		  "http://www.bioone.org/bioone/?request=get-document&issn=0567-7920&volume=049&issue=02&page=0197" ],
		[ "%{THIS}&svc_dat=indexdata:citation:Endnote" =>
		  "/^http://.*rft.auinit=J\.%20D\..*citation:Endnote/" ],
		[ "http://masterkey.indexdata.com/author=%{aulast}&title=%{atitle}&date=%{date}" =>
		  "http://masterkey.indexdata.com/author=Harris&title=A new diplodocoid sauropod dinosaur from the Upper Jurassic Morrison Formation of Montana, USA&date=2004" ],
		[ "http://www.reindex.org/%{req_id}/main/Hits.php?qe=lfo=%{aulast}+and+lti=%{title}" =>
		  undef ], # no req_id
		);

    plan tests => 1 + scalar(@recipes);
};

use Keystone::Resolver;
ok(1);

my $cgi = new CGI(\%args);
my $resolver = new Keystone::Resolver();
my $openURL = Keystone::Resolver::OpenURL->newFromCGI($resolver, $cgi);

foreach my $ref (@recipes) {
    my($recipe, $result) = @$ref;
    my $maybe = $openURL->_makeURI($recipe);
    ok($maybe, $result, "result for recipe '$recipe'");
}
