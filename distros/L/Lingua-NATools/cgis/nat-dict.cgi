#!/usr/bin/perl

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
use URI::Escape;

setlocale(LC_CTYPE, "pt_PT");

use warnings;

use locale;
use Data::Dumper;

use Lingua::NATools::Client;
use Lingua::NATools::CGI;
use CGI qw/:standard :cgi-lib/;


my $server = Lingua::NATools::Client->new();
my $corpora = $server->list();


my $crp = undef;
my $name;

if (param("crp")) {
  $crp = $corpora->{param("crp")}{id} || undef;
  $name = param("crp");
}
if (param("corpus")) {
  $crp = param("corpus");
  for (keys %$corpora) {
    $name = $_ if $corpora->{$_}{id} == $crp;
  }
}

($name) = keys %$corpora unless $name;

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
   window.open('nat-dict.cgi?HELP=1','NAT-QI Quick Help',
               'menubar=no,height=600,width=800,resizable=yes,toolbar=no,location=no,status=no');
}
EOS




print Lingua::NATools::CGI::my_header(jscript => $JSCRIPT);

print <<'EOH';
  <style>
   div.right { text-align: right }
   td.color  { font-weight: bold; text-align: right; width: 10%; border: solid 1px #000; padding: 2px }
   td.oc     { text-align: right; width: 10%; border: solid 1px #000; padding: 2px; }
   a         { font-weight: bold; text-decoration: none; }
   a:visited { color: #009; }
   a:hover   { text-decoration: underline; }
   .body { margin-left: 10%; margin-right: 10%; }
   .form { background-color: #efe;
           margin-bottom: 10px;
           margin-left: 10%;
           margin-right: 10%;
           border: solid 1px #000;
           text-align: center;
   }
  </style>
EOH


if (param("HELP")) {
  print Lingua::NATools::CGI::close_window();
  print_help();
  print Lingua::NATools::CGI::my_footer();
  exit;
}



print div({-class=>"hlpbt",
           -onclick=>"help()"}, "Help");

print h1("NATools Probabilistic Dictionaries Browsing Interface");

print start_form({-class=>"main"});;
print "<table>";
print Tr(td({-rowspan=>'2'},submit("Search")),
	 td({-rowspan=>'2'},"&nbsp;&nbsp;&nbsp"),
	 td({-style=>"text-align: left"},"corpus",popup_menu(-onchange=>"changeLanguages();",
                                                             -name=>'crp',
                                                             -id => 'crp',
									      -default => $name,
									      -values=>[keys %$corpora]) ),
	 td({-rowspan=>'2'},"&nbsp;&nbsp;&nbsp"),
       td(["search ".span({id=>"source"}, $corpora->{$name}{source})." language: ", textfield("l1")]));

print Tr(td({-align=>'left'},label(checkbox(-name=>'compact', -checked=>1,
					    -value=>'ON', -label=>' compact mode'))),
        td([
            "search ".span({id=>"target"}, $corpora->{$name}{target})." language: ",
	     textfield("l2"),
	    ]));


print "</table>";
print end_form;

if ($crp) {
  if (param("compact")) {
    if ((param("l1") || param("l2"))) {
      my $results;
      my $word;
      my $dir;

      if (param("l1")) {
	$dir = "~>";
	$word = param("l1");
      }
      if (param("l2")) {
	$word = param("l2");
	$dir = "<~";
      }

      $word = lc($word);
      $results = $server->ptd({crp=>$crp,direction => $dir},$word);

      # FIXME
      exit if (!$results);

      print h1($name);
      print div({-style=>"text-align: center"},
                a({-style=>"font-size: small;", -href=>"nat-about.cgi?corpus=$crp"},"meta-information")).br;

      print h2({-style=>"text-align: center"},"$word ($results->[0])");
      print div({-style=>"text-align: center"},
                "[", a({-href=>"nat-ngrams.cgi?corpus=$crp&".(($dir eq "~>")?"l1":"l2")."=$word"},"n-grams"), "]");
      print "<div style=\"text-align: center\"><table class='results' cellspacing='0'>\n";

      print Tr(th({-class=>'first'},"Level 1"), th({colspan => 8},"Level 2"));
      for (sort {$results->[1]{$b} <=> $results->[1]{$a}} keys %{$results->[1]}) {
	my $od = $dir eq "~>"?"<~":"~>";
	my $l1 = $dir eq "~>"?"l2":"l1";
	my $l2 = $l1  eq "l1"?"l2":"l1";
	my $or = $server->ptd({crp=>$crp,direction => $od}, $_);

	print "<tr>\n";
	print td({style=>'background-color: #eeeeee; border-bottom: dotted 1px #999999; border-right: dotted 1px #999999'},
		 [table(Tr(td(small(sprintf("%.2f %%",
					    defined($results->[1]{$_})?100*$results->[1]{$_}:0)))),
			Tr(td(a({href=>"?compact=1&corpus=$crp&$l1=".uri_escape($_)},$_),"  ",
                              defined($or->[0])?"(".$or->[0].")":"-")))]);

        my $ncells = 0;
	for my $y (sort {$or->[1]{$b} <=> $or->[1]{$a}} keys %{$or->[1]}) {
	  my $style = "";
	  $style = "background-color: #ffffee;" if ($y eq $word);
	  print td({style=>"$style border-right: dotted 1px #999999; border-bottom: dotted 1px #999999;"},
		   table(Tr(td(a({href=>"?compact=1&corpus=$crp&$l2=".uri_escape($y)},$y))),
			 Tr(td(small(sprintf("%.2f %%",100*$or->[1]{$y}))))));
          ++$ncells;
	}
        for ($ncells .. 7) {
	  print td({style=>"border-right: dotted 1px #999999; border-bottom: dotted 1px #999999;"},
		   "&nbsp;");
        }
	print "</tr>\n";
      }
      print "</table></div>";
    } else {
      print_help();
    }
  } else {

    my %args = Vars();

    if ($args{l1}) {
      my $word_to_search = lc($args{l1});
      $results = $server->ptd({crp=>$crp,direction => "~>"},  $word_to_search);
      print entry($word_to_search, "<~",$results,$crp,$name);

    } elsif ($args{l2}) {
      my $word_to_search = lc($args{l2});
      $results = $server->ptd({crp=>$crp,direction => "<~"},  $word_to_search);
      print entry($word_to_search, "~>",$results,$crp,$name);

    } else {
      print_help();
    }
  }
} else {
  print_help();
}


print Lingua::NATools::CGI::my_footer();

sub print_help {
  while(<DATA>) {
    print
  }
}

sub entry {
  my ($word, $dir, $results, $crp, $name) = @_;

  my $yellow = 33;
  my $green = 66;

  my %color = (
	       blue => '#bbffff',
	       red => '#fbb',
	       green => '#bfb',
	       yellow => '#ffb',
	      );


  my $ret = h1($name);
  $ret .= "<center>".a({-style=>"font-size: small;", -href=>"nat-about.cgi?corpus=$crp"},"about")."</center>".br;

  $ret .= h2({-style=>"text-align: center"},"$word ($results->[0])");

  $ret .= "<table style=\"margin-left: 100px;\" width=\"50%\"><tr>";

  my %hash;

  if ($results->[1]) {
    %hash = %{$results->[1]}
  } else {
    %hash = ();
  }

  for my $y (sort {$hash{$b} <=> $hash{$a}} keys %hash) {

      my $calc = $hash{$y}*100;
      my $bclass="background-color: $color{red};";
      $bclass = "background-color: $color{yellow};" if ($calc >= $yellow);
      $bclass = "background-color: $color{green};" if ($calc >= $green);
      $ret .= sprintf("<td class='color' rowspan=\"2\" style=\"padding: 4px; $bclass\"> %.2f%%</td>",$calc);

      my $class = "";

      my $results2 = $server->ptd({direction => $dir, crp=>$crp}, $y);

      my %trans2;

      if ($results2->[1]) {
	%trans2 = %{$results2->[1]}
      } else {
	%trans2 = ()
      }
      $class = "background-color: $color{blue}" if (exists($trans2{$word}));

      $ret .= "<td style=\"border: solid 1px #000; padding: 2px; $class\">";

      if ($dir eq "<~") {
	$ret .= "<a href=\"$ENV{SCRIPT_NAME}?corpus=$crp&l2=".uri_escape($y)."\">$y</a></td>\n";
      } else {
	$ret .= "<a href=\"$ENV{SCRIPT_NAME}?corpus=$crp&l1=".uri_escape($y)."\">$y</a></td>\n";
      }

      if ($y eq "(none)") {
	$ret .= "<td colspan=\"2\">&nbsp;</td>";
      } else {
	$ret .= "<td class=\"oc\">".$results2->[0]."</td>\n";
	$ret .= "<td class=\"oc\">";

	if ($dir eq "<~") {
	  $ret .= "<a href=\"nat-search.cgi?corpus=$crp&l1=".uri_escape($word)."&l2=".uri_escape($y)."&sequence=OFF&count=20\">>></a>";
	} else {
	  $ret .= "<a href=\"nat-search.cgi?corpus=$crp&l2=".uri_escape($word)."&l1=".uri_escape($y)."&sequence=OFF&count=20\">>></a>";
	}
	$ret .= "</td>\n";
      }

      $ret .= "</tr><tr>";
      $ret .= "<td colspan=\"3\" style=\"padding: 0px\; border: 0\">";

      $ret .= "<table width='100%'>";
      for my $x (sort {($trans2{$b} <=> $trans2{$a})||0} keys %trans2) {

	my $bclass="background-color: $color{red};";
	my $calc = defined($trans2{$x})?$trans2{$x}*100:0;
	$bclass = "background-color: $color{yellow};" if ($calc >= $yellow);
	$bclass = "background-color: $color{green};" if ($calc >= $green);

	$ret .= sprintf("<tr><td class='color' style=\"padding: 2px; $bclass\">%.2f%%</td>\n",$calc);
	$ret .= "<td style='border: solid 1px; padding: 2px;' width=\"80%\" colspan='2'>";

	if ($dir eq "<~") {
	  $ret .= "<a href=\"$ENV{SCRIPT_NAME}?corpus=$crp&l1=".uri_escape($x)."\">$x</a></td>\n";
	} else {
	  $ret .= "<a href=\"$ENV{SCRIPT_NAME}?corpus=$crp&l2=".uri_escape($x)."\">$x</a></td>\n";
	}
	$ret .= "</tr>";
      }
      $ret .= "</table>";
      $ret .= "</td></tr>";
    }
    $ret .= "</table>";
    return $ret;

}

sub count {
  my $hash = shift;
  my $word = shift;
  return (defined($hash->{$word}{count}))?$hash->{$word}{count}:"&nbsp;";
}


__DATA__
<div style="margin: 20px; border: solid 1px #000000; background-color: #ffffdd;">

    <h2 style="padding: 5px; border-bottom: solid 1px #000000; margin: 0px; background-color: #ddddbb">Help</h2>

     <div style="padding-left: 20px; padding-right: 20px">

     <p>NAT-QI (NATools Query Interface) is a web frontend to query and
     browse Parallel Corpora. For details about its architecture and
     associated tools see <a href="">this page</a>.</p>

     <p>This interface is querying a server (NATServer) with a
     specific parallel corpora, and a specific pair of
     languages. </p>

     <p><b>Toolbar Usage:</b></p>

     <p>Enter a word in the <i>search on source language</i> or
     <i>search on target language</i> entries (not in both, or the source language will be used) to search
     for the word entry in the probabilistic dictionary.</p>

     <p>This dictionary was obtained by word-aligning the associated
     parallel corpus.</p>

     <p>You can as well change from the normal mode to the compact
     mode. This will change the way the dictionary is shown, as well
     as some tools which are just available on some modes.</p>

     <p><b>Standard mode Output Description:</b></p>

     <p>A word search will return the word entry in the probabilistic
     dictionary, presented as a table. This table will show two levels
     of the dictionary. The first level include the direct
     translations from the word you searched with their respective
     translation probability and occurrence count in the corpus.</p>

     <p>For each of these words, their probable translations and
     respective probability are shown as well.</p>

     <p>Colors make it easier to distinguish between high or lower
     translation probabilities. Red for probabilities lower than 33%,
     yellow for those up to 66% and green for the other ones. Also, if
     a translation includes as a probable translation the word you
     searched for, its word entry is shown in blue.</p>

     <p>At the right of the occurrence count for the translation there
     is a link to search examples of sentence pairs where those two
     words co-occurr.</p>

     <p><b>Compact mode Output Description:</b></p>

     <p>A word search will return the word entry in the probabilistic
     dictionary, presented as a table.  The table title is the word you
     searched for and the occurrence count of that word on the aligned
     corpus.  As this number increases dictionary results should be
     better.</p>

     <p>The first column of the table (Level 1 output) contains the
     most probable translations for the searched word. for each one of
     the possible translation its occurrence number is shown, as well
     as its translation probability (related to the word you searched
     for).</p>

     <p>The remaining row contains the translations for the word in
     the first column, with its translation probability. If the cell
     is shaded it means that translation translation includes the word
     you searched for.</p>

     <p>Each word has a link to its dictionary entry. That way you can
     navigate through all the dictionary.</p>
   </div>
  </div>
