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
setlocale(LC_CTYPE, "pt_PT");
use locale;

use warnings;

#use Data::Dumper;
use Lingua::NATools::Client;
use Lingua::NATools::CGI;
use CGI qw/:standard :cgi-lib/ ;

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
      window.location="nat-dict.cgi?compact=1&corpus=" + c + "&" + l + "=" + escape(sel.text)
    } else // NS4+
      window.location="nat-dict.cgi?compact=1&corpus=" + c + "&" + l + "=" + escape(document.getSelection())
}

function help() {
   window.open('nat-search.cgi?HELP=1','NAT-QI Quick Help',
               'menubar=no,height=600,width=800,resizable=yes,toolbar=no,location=no,status=no');
}
EOS

print Lingua::NATools::CGI::my_header(jscript => $JSCRIPT);

#my $x = Vars;
#print pre(Dumper($x));

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
print Tr(td({-rowspan=>'3'},submit("Search")),
	 td({-rowspan=>'3'}, "&nbsp;&nbsp;&nbsp;"),
	 td({-colspan=>6, -style=>"text-align: left"},
	    "Corpus: ",popup_menu(-onchange=>"changeLanguages();",
				  -name=>'crp',
				  -id => 'crp',
				  -default=>$name,
				  -values=>[keys %$corpora])));
print Tr(td(["Search on ",
	     span({id=>"source"}, $corpora->{$name}{source}), " language: ",
             textfield("l1"),
	     "&nbsp;&nbsp;&nbsp;&nbsp;",
	    ]),
	 td({-style=>"text-align: left"},label(checkbox(-name=>'sequence', -checked=>0,
							-value=>'ON', -label=>'Pattern Matching'))),
	 td(["&nbsp;&nbsp;&nbsp;&nbsp;",
	     "Result-set size",popup_menu(-name=>'count',
					  -values=>['20','50','100','500'])
	    ]));
print Tr(td(["Search on ",
	     span({id=>"target"}, $corpora->{$name}{target}), " language: ",
             textfield("l2"),
	     "&nbsp;&nbsp;&nbsp;&nbsp;"]),
	 td({-style=>"text-align: left"},
	    label(checkbox(-name=>'horiz', -checked=>0,
			    -value=>'ON', -label=>'Horizontal Mode')),
	   ));
print "</table>";
print end_form;

my $count = param("count") || 20;

# If we have a corpus, and at least one word in one of the two
# languages, then query the server
if ($crp && (param("l1") || param("l2"))) {

#  param("l1", lc(param("l1"))) if param("l1");
#  param("l2", lc(param("l2"))) if param("l2");

  # print the corpus name and a link to the information page
  print h1($name);
  print "<center>",
    a({-style=>"font-size: small;", -href=>"nat-about.cgi?corpus=$crp"},
      "meta-information"), "</center>",br;

  # variable to store the query results
  my $results;
  my $ptds;

  # Check if we are looking for a pattern or a set of words
  $mod = (param("sequence") && param("sequence") eq "ON") ? "=" : "-";

  if (param("l1") && !param("l2")) {
    # We have just source language...
    $results = $server->conc({count => $count,
			      crp => $crp,
			      direction => "$mod>"}, param("l1"));

    # get PTDs for all searched words
    $ptds = get_ptds($server, $crp, "~>", lc(param("l1")));

  } elsif (param("l2") && !param("l1")) {
    # We have just the target language
    $results = $server->conc({count => $count,
			      crp => $crp,
			      direction => "<$mod"}, param("l2"));

    # get PTDs for all searched words
    $ptds = get_ptds($server, $crp, "<~", lc(param("l2")));

  } else {
    # We have both languages
    $results = $server->conc({count => $count,
			      crp => $crp,
			      direction => "<$mod>"}, param("l1"), param("l2"));
    $ptds = [];
  }

  $_->[1]{'**KEYS**'} = [sort {$_->[1]{$b} <=> $_->[1]{$a}} keys %{$_->[1]} ] for @$ptds;

  # Start to print results
  print "<table class='results' cellspacing='0'>";

  # print table header accordingly with the horizontal vs vertical
  # user request
  unless (param("horiz")) {
    print Tr(th({-class=>'first'},"#"),
             th(["%","Source Language","Target Language","Tools"]))
  } else {
    print Tr(th({-class=>'first'},"#"),
             th(["%","Source/Target Language","Tools"]))
  }

  my $i = 0;

  # print the results
  for (@$results) {
    $i++;

    # Code backwards compatibility O:-)
    $_->[4]=$_->[2]?sprintf("%.1f%%", 100*$_->[2]):"";
    $_->[2]=$_->[0];
    $_->[3]=$_->[1];

    # Highlight l1 if defined
    if (param("l1")) {
      $_->[0] = highlite($_->[0], param("l1"), $mod eq '='?1:0);
      $_->[1] = highlite_translations($_->[1], $ptds) if ($ptds);
    }

    # Highlight l2 if defined
    if (param("l2")) {
      $_->[1] = highlite($_->[1], param("l2"), $mod eq "="?1:0);
      $_->[0] = highlite_translations($_->[0], $ptds) if ($ptds);
    }

    # Create the form to ask for the matrix diagonalization tool
    # my $FORM = start_form(-method => "POST",
    #     		  -action => "nat-matrix.cgi");
    # $FORM .= hidden("corpus", $crp);
    # $FORM .= hidden("s1", $_->[2]);
    # $FORM .= hidden("s2", $_->[3]);
    # $FORM .= submit("\\");
    # $FORM .= end_form;
    my $FORM = "n/a";

    # Print the data accordingly with the requested format (horizontal
    # vs vertical)
    if (param("horiz")) {
      print Tr(td({-class=>$i%2?"entry1":"entry2", -rowspan=>2},
                  $i),
	       td({-class=>$i%2?"entry1":"entry2", -rowspan=>2},
                  $_->[4]),
	       td({-class=>$i%2?"entry1":"entry2",
		   -ondblclick=>"go('l1','$crp')"},
		  $_->[0]),
	       td({-class=>$i%2?"entry1":"entry2", -rowspan=>2},
		  $FORM));
      print Tr(td({-class=>$i%2?"entry1":"entry2", -ondblclick=>"go('l2','$crp')"},
		  $_->[1]));
    } else {
      print Tr(td({-class=>$i%2?"entry1":"entry2"},
                  $i),
	       td({-class=>$i%2?"entry1":"entry2"},
                  $_->[4]),
	       td({-class=>$i%2?"entry1":"entry2", -ondblclick=>"go('l1','$crp')"},
                  $_->[0]),
	       td({-class=>$i%2?"entry1":"entry2", -ondblclick=>"go('l2','$crp')"},
                  $_->[1]),
	       td({-class=>$i%2?"entry1":"entry2"},
		  $FORM));
      print "\n";
    }
  }
  print "</table>";
} else {
  # if no corpus is selected, and/or no word was passed as parameter,
  # print help usage and go out.
  print_help();
}

print Lingua::NATools::CGI::my_footer();


# This is the help code
sub print_help {
  while(<DATA>) {
    print
  }
}

sub highlite {
  my ($text, $keywords, $seq) = @_;

  my $x = $keywords;
  $x =~ s/^\s*(.*?)\s*$/$1/;
  if ($seq) {
    $x =~ s/\*/\\S+/g;
    $text =~ s/\b($x)\b/<span class="searched">$1<\/span>/gi;
  } else {
    $x =~ s/\*//g;
    for my $y (split /\s+/, $x) {
      $text =~ s/\b($y)\b/<span class="searched">$1<\/span>/gi;
    }
  }
  return $text
}

sub highlite_translation {
  my ($changed, $text, $word, $perc) = (0, @_);

  my $class = class_from_perc($perc);
  $changed = $text =~ s/\b(\Q$word\E)\b/<span class="$class">$1<\/span>/gi;

  return ($text, $changed);
}

sub class_from_perc {
  my $perc = shift;
  if ($perc < .3) {
    return "guessed30"
  } elsif ($perc < .6) {
    return "guessed60"
  } else {
    return "guessed100"
  }
}

sub get_ptds {
  my ($server, $crp, $dir, $words) = @_;
  return [ map { $server->ptd({crp => $crp,
                               direction=>$dir},$_) }
           grep { $_ !~ m"\*" } split /\s+/, $words ];
}

sub highlite_translations {
  my ($text, $ptds) = @_;
  for my $word (@$ptds) {
    for my $t (@{$word->[1]{'**KEYS**'}}) {
      ($text, my $changed) = highlite_translation($text, $t, $word->[1]{$t});
      last if $changed;
    }
  }
  return $text
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

      <dt><i>Simple Search:</i></dt>
      <dd>Enter a word in the <i>search on source language</i> or
          <i>search on target language</i> entries (or in both) to
          search for concordancies in the parallel corpora. Words are
          searched with no specific order.<br/> </dd>

     <dt><i>Pattern Search:</i></dt>
     <dd>If you want to search for a specific sequence of words, click
         the <i>Pattern Matching</i> radio button. This option applies
         to both source and target language entries. It also has the
         feature of searching for patterns: enter some '*' in places
         you want any, not specific, word.<br/> </dd>

     <dt><i>Horizontal Mode:</i></dt>
     <dd>The <i>Horizontal Mode</i> radio button let you change the
         layout of the output. Instead of two columns, one for each
         language, you get two lines, one for each language.</dd>

     <dt><i>Result-set Size:</i></dt>

     <dd>The <i>Result-set size</i> combo-box let you specify how many
         results you want.</dd>

     </dl>

     <p><b>Output Description:</b></p>

     <p>The standard output is a five column table: </p>
     <ol>
       <li>number which corresponds to the order in the result-set. Not
     very useful.</li>
       <li>a quality measure of the sentence pair.</li>
       <li>sentence in the source language.</li>
       <li>sentence in the target language.</li>
       <li>links to tools you can apply to the sentence pair.</li>
     </ol>

     <p><b>Related Tools Integration:</b></p>

     <ul>
     <li>
     Double-click any word in the source or target language to
     access its probabilistic dictionary entry. This tool will let you
     navigate through the dictionary.
     </li>
     <li>Use the <tt>[/]</tt> button in the tools column to access a
     sub-segment aligner, and sentence generalization tool.
     </li>
     </ul>

    </div>

  </div>

