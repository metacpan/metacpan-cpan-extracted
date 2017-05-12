#!/usr/bin/perl -w

use POSIX qw(locale_h);

setlocale(LC_CTYPE, "pt_PT");

use locale;

use Lingua::NATools::CGI;
use Lingua::NATools::Client;
use CGI qw/:standard/;

print Lingua::NATools::CGI::my_header();

my $server = Lingua::NATools::Client->new();
my $corpora = $server->list();


$crp = undef;
if (param("crp")) {
  $crp = $corpora->{param("crp")}{id} || undef;
}
if (param("corpus")) {
  $crp = param("corpus");
}

my @order = (
	     "Corpus Name: ",
	     "Source Language: ",
	     "Target Language: ",
	     "Corpus Description: ",
	     "Number of Translation Units: ",
	     "Source Language Tokens Count: ",
	     "Target Language Tokens Count: ",
             "Source Forms: ",
             "Target Forms: ",
	    );

print h1("NAT-QI: NATools Corpora Query Interface");

print start_form({-class=>"main"});
print "Get information about: &nbsp;", popup_menu(-name=>'crp',
						  -values=>[keys %$corpora]);
print "&nbsp;", submit(">>");
print end_form;

if ($crp) {
  my %data;
  $data{"Source Forms: "}    = $server->attribute({crp=>$crp}, "source-forms");
  $data{"Target Forms: "}    = $server->attribute({crp=>$crp}, "target-forms");
  $data{"Source Language: "}    = $server->attribute({crp=>$crp}, "source-language");
  $data{"Target Language: "}    = $server->attribute({crp=>$crp}, "target-language");
  $data{"Corpus Description: "} = $server->attribute({crp=>$crp}, "description");
  $data{"Corpus Name: "}        = $server->attribute({crp=>$crp}, "name");
  $data{"Number of Translation Units: "} = $server->attribute({crp=>$crp}, "nr-tus");
  $data{"Source Language Tokens Count: "} = $server->attribute({crp=>$crp}, "source-tokens-count");
  $data{"Target Language Tokens Count: "} = $server->attribute({crp=>$crp}, "target-tokens-count");

  print h1($data{"Corpus Name: "});
  print br,br,"<center>\n";
  print "<table width=\"50%\" style=\"border: solid 1px #000000; background-color: #ffffdd; padding: 20px; -moz-border-radius: 20px; \">\n";
  for (@order) {
    print Tr(td({-style=>"vertical-align: top; width: 50\%; text-align: right"},b($_)),
	     td({-style=>"width: 50\%;"}, $data{$_}))
  }
  print "</table>\n";
  print "</center>\n";
}

print Lingua::NATools::CGI::my_footer();

