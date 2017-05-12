#!/usr/bin/perl -w

# NATools - Package with parallel corpora tools
# Copyright (C) 2002-2012  Alberto Simões
#
# This package is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

use POSIX qw(locale_h);

setlocale(LC_CTYPE, "pt_PT");

use locale;

use URI::Escape;
use Lingua::NATools::Client;
use Lingua::NATools::CGI;
use CGI qw/:standard/;

# Create a new client
my $server = Lingua::NATools::Client->new();

# Get the list of available corpora
my $corpora = $server->list();

# Current corpus if undefined, without a name
my $crp = undef;
my $name;

# Check if we got a corpus identifier
if (param("crp")) {
  $crp = $corpora->{param("crp")}{id} || undef;
  $name = param("crp");
}

# Ok, we didn't get a corpus identifier, just a corpus name
if (param("corpus") && !param("crp")) {
  $crp = param("corpus");
  for (keys %$corpora) {
    $name = $_ if $corpora->{$_}{id} == $crp;
  }
}

# We didn't get a corpus identifier nor a corpus name, so get randomly one.
($name) = keys %$corpora unless $name;


# Create JavaScript combo-box to change corpus being queried
my $s = join("\n",
	     join("\n", map {
	       "source[\"$_\"]=\"$corpora->{$_}{source}\";"} keys %$corpora),
	     join("\n", map {
	       "target[\"$_\"]=\"$corpora->{$_}{target}\";"} keys %$corpora));

my $JSCRIPT = <<"EOS";

var source = new Array();
var target = new Array();

$s

function changeLanguages() {
  var corpus = document.getElementById('crp').value;
  document.getElementById('source').innerHTML = source[corpus];
  document.getElementById('target').innerHTML = target[corpus];
}

function go(l,c) {
  if (parseInt(navigator.appVersion)>=4)
    if (navigator.userAgent.indexOf("MSIE")>0) { //IE 4+
      var sel=document.selection.createRange();
      sel.expand("word");
      window.location="nat-dict.cgi?corpus=" + c + "&" + l + "=" + escape(sel.text)
    } else // NS4+
      window.location="nat-dict.cgi?corpus=" + c + "&" + l + "=" + escape(document.getSelection())
}

function help() {
   window.open('nat-search.cgi?HELP=1','NAT-QI Quick Help',
               'menubar=no,height=600,width=800,resizable=yes,toolbar=no,location=no,status=no');
}
EOS


print Lingua::NATools::CGI::my_header(jscript => $JSCRIPT);

# Check if we were asked for help
if (param("HELP")) {
  print Lingua::NATools::CGI::close_window();
  print_help();
  print Lingua::NATools::CGI::my_footer();
  exit;
}

# Print form HTML
print div({-class=>"hlpbt",
           -onclick=>"help()"}, "Help  ");

print h1("NAT-QI: NATools Corpora Query Interface");

print start_form({-class=>"main"});
print "<table>\n";
print Tr(td({-rowspan=>'1'},submit("Search")),
	 td({-colspan=>'2', -style=>"text-align: left"},
	    "Corpus: ",popup_menu(-onchange=>"changeLanguages();",
				  -name=>'crp',
				  -id => 'crp',
				  -default=>$name,
				  -values=>[keys %$corpora])));
print Tr(td(["",
             "Search on ".
	     span({id=>"source"}, $corpora->{$name}{source}). " language: ",
             textfield("l1")
	    ]));
print Tr(td(["",
             "Search on ".
	     span({id=>"target"}, $corpora->{$name}{target}). " language: ",
             textfield("l2"),
            ]));
print "</table>";
print end_form;

# If we have a corpus, and at least one word in one of the two
# languages, then query the server
if ($crp && (param("l1") || param("l2"))) {

  # print the corpus name and a link to the information page
  print h1($name);
  print "<center>",
    a({-style=>"font-size: small;", -href=>"nat-about.cgi?corpus=$crp"},
      "meta-information"), "</center>",br;

  $server->set_corpus($crp);

  if (param("l1")) {
    ngrams(param("l1"),"l1",$crp)
  }
  if (param("l2")) {
    ngrams(param("l2"),"l2",$crp)
  }

} else {
  # if no corpus is selected, and/or no word was passed as parameter,
  # print help usage and go out.
  print_help();
}

print Lingua::NATools::CGI::my_footer();


sub ngrams {
  my ($word, $field, $crp) = @_;

  my %r = ();
  my $ws =scalar(split(/\s+/,$word));

  print "<div style=\"margin-left: 25px; margin-right: 25px;\">";

  print h2($word);

  my %dir = ();
  if ($field eq "l1") {
    $dir{direction} = ':>';
  } else {
    $dir{direction} = '<:';
  }

  if ($ws == 3){

    print "<table>\n";
    for (sngrams({%dir,max=>10},"$word *")){
      next unless $_;
      print "<tr>\n";
      print td({-class=>"entry2", -style=>'border: solid 1px #995500'}, $_->[-1]);
      print td({-class=>"entry2", -style=>'border: solid 1px #995500'},
	       a({-href=>create_link("$word $_->[-2]", $field, $crp)},
		 $_->[-2]));
      print "</tr>\n";
    }
    print "</table>\n";

  } elsif($ws == 2){

    print "<table>\n";
    for (sngrams({%dir,max=>10},"$word *")){
      next unless $_;
      print "<tr>\n";
      print td({-class=>"entry2", -style=>'border: solid 1px #995500'}, $_->[-1]);
      print td({-class=>"entry2", -style=>'border: solid 1px #995500'},
	       a({-href=>create_link("$word $_->[-2]", $field, $crp)},
		 $_->[-2]));
      my $pw = $_->[-2];
      for (sngrams({%dir,max=>10},"$word $_->[2] *")){
        next unless $_;
        print td({-style=>"border: solid 1px #995500"},
		 a({-href=>create_link("$word $pw $_->[3]", $field, $crp)},
		   $_->[3]));
      }
      print "\n</tr>\n";
    }
    print "</table>\n";

  } else {

    print "<table>\n";
    for (sngrams({%dir,max=>10},"$word *")){
        next unless $_;
	print "<tr>\n";
	print td({-class=>"entry2", -style=>'border: solid 1px #995500'}, $_->[-1]);
	print td({-class=>"entry2", -style=>'border: solid 1px #995500'},
		 a({-href=>create_link("$word $_->[-2]",$field,$crp)},
		   $_->[-2]));
	my $pw = $_->[-2];
        for (sngrams({%dir,max=>10},"$word $_->[1] * *")){
          next unless $_;
          print td({-style=>"border: solid 1px #995500"},
		   a({-href=>create_link("$word $pw $_->[2] $_->[3]", $field, $crp)},
		     "$_->[2] $_->[3]"));
        }
        print "\n";
	print "</tr>\n";
    }
    print "</table>\n";
  }
  print "</div>\n";
}


sub create_link {
  my ($words,$field,$crp) = @_;

  return "nat-search.cgi?$field=".uri_escape($words)."&sequence=ON&corpus=$crp";
}

sub sngrams{
 my %opt =(max => 50);
 if(ref($_[0]) eq "HASH") {%opt = (%opt , %{shift(@_)}) } ;
 my $exp = shift;
 my $ng =scalar(split(/\s+/,$exp));

 if($opt{max}){  # grep {$_} 
    ((sort {$b->[$ng]<=>$a->[$ng]} @{$server->ngrams(\%opt,$exp)})[0..$opt{max}-1])
 }
 else { (sort {$b->[$ng]<=>$a->[$ng]} @{$server->ngrams(\%opt,$exp)}) }
}


# This is the help code
sub print_help {
  while(<DATA>) {
    print
  }
}

__DATA__
  <div style="margin: 20px; border: solid 1px #000000; background-color: #ffffdd;">
     <h2 style="padding: 5px; border-bottom: solid 1px #000000; margin: 0px; background-color: #ddddbb">NAT-QI Help</h2>

     <div style="padding-left: 20px; padding-right: 20px">

     <p>NAT-QI (NATools Query Interface) is a web frontend to query and
     browse Parallel Corpora. For details about its architecture and
     associated tools see <a href="http://natools.sf.net">this page</a>.</p>

     <p>This interface is querying a server (NATServer) with a
     specific parallel corpora, and a specific pair of
     languages. </p>

     <p><b>Toolbar Usage:</b></p>

     <dl>

     </dl>


     <p><b>Related Tools Integration:</b></p>


    </div>

  </div>

