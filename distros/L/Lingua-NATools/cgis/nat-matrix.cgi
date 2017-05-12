#!/usr/bin/perl

use strict;
use POSIX qw(locale_h);

setlocale(LC_CTYPE, "pt_PT");

use warnings;

use locale;

use Lingua::NATools::Client;
use Lingua::NATools::CGI;
use Lingua::NATools::Matrix;

use CGI qw/:standard/;


my $JSCRIPT = <<"EOS";

function help() {
   window.open('nat-matrix.cgi?HELP=1','NAT-QI Quick Help',
               'menubar=no,height=600,width=800,resizable=yes,toolbar=no,location=no,status=no');
}
EOS


print Lingua::NATools::CGI::my_header(jscript => $JSCRIPT);

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

if (param("HELP")) {
  print Lingua::NATools::CGI::close_window();
  print help();
  print Lingua::NATools::CGI::my_footer();
  exit;
}


print div({-class=>"hlpbt",
           -onclick=>"help()"}, "Help");

print h1("NATools Simple Generalization Engine Interface");

print start_form({-class=>"main"});
print "<table>";
print Tr(td({-rowspan=>"3"},submit("Calculate Matrix")),
	 td({-rowspan=>"3"},"&nbsp;"),
	 td({-colspan=>2, -style=>"text-align: left"},
	    "Corpus: ",popup_menu(-name=>'crp',
				  -default => $name,
				  -values=>[keys %$corpora]) ));

print Tr(td(["Sentence in source language: ", textfield(-name=>"s1", -size=>"80")]));
print Tr(td(["Sentence in target language: ", textfield(-name=>"s2", -size=>"80")]));

print "</table>\n";
print end_form;



if ($crp && param("s1") && param("s2")) {
    my $s1 = param("s1");
    my $s2 = param("s2");

    print h1($name);

    print "<center>",a({-style=>"font-size: small;", -href=>"nat-about.cgi?corpus=$crp"},"about"),"</center>",br;

    align($crp,$s1,$s2);
} else {
  print help();
}

print Lingua::NATools::CGI::my_footer();

sub align {
  my ($crp, $s1, $s2) = @_;
  $server->set_corpus($crp);

  my $rules = Lingua::NATools::PatternRules->parseFile("/home/ambs/Natura/main/NATools/rules.test-case");
  my $matrix = Lingua::NATools::Matrix->new($server, $rules, $s1,$s2);

  $matrix->findDiagonal;

  my @s1 = @{$matrix->{s1}};
  my @s2 = @{$matrix->{s2}};

  my $blocks = $matrix->grep_blocks;

  my $MAT = $matrix->{matrix};
  my $RES = $matrix->{res};
  dump_html_mat(\@s1,\@s2,$MAT,$RES);

  print h3("Generalization");

  print "<table class=\"results\">\n";
  print Tr(td({-colspan=>2}, "Sub Blocks"));
  for my $b (@{$matrix->{patterns}}) {
    print Tr(td($matrix->dump_block($b)));
  }
  print "</table>\n";
  print "<br/>\n";
  print "<table class=\"results\">\n";
  # for (1..3) {
  for (1) {
    print Tr(td({-colspan=>2}, "Size $_"));
    my $bs = $matrix->combine_blocks($blocks, $_);
    for my $b (@$bs) {
      print Tr(td($matrix->dump_block($b)));
    }
  }
  print "</table>\n";
  # print "<pre>\n";
  # dump_latex_mat(\@s1,\@s2,$MAT,$RES);
  # print "</pre>\n";
}

sub combine {
  my ($s, $size, @sizes) = @_;

  for my $w (@sizes) {
    for my $i (0..$size-$w) {
      print Tr(td({-style=>"border: solid 1px #999999"},
		  join(" ",map { $s->[$_][0] } ($i..$i+$w-1))),
	       td({-style=>"border: solid 1px #999999"},
		  join(" ",map { $s->[$_][1] } ($i..$i+$w-1))));
    }
  }
  print "</table>\n";
}

sub findStart {
  my ($R,$S1,$S2) = @_;
  my ($i,$j) = (0,0);
  my $delta = 0;
  while($delta < $S1 && $delta < $S2) {
    return ($i+$delta, $j) if $R->[$i+$delta][$j];
    return ($i, $j+$delta) if $R->[$i][$j+$delta];
    $delta++;
  }
  return (0,0);
}




sub dump_html_mat {
  my ($S1,$S2,$MAT,$RES) = @_;

  print h3("Alignment Matrix");
  print "<table class=\"results\">\n";
  my ($i,$j) = (-1,-1);
  my ($x,$y);

  for $x ("\$", @$S1, "\$") {
    my $class = $i%2?"\"even\"":"\"odd\"";
    print "<tr>\n";
    $j = -1;
    for $y ("\$", @$S2, "\$") {
      if ($x eq "\$" && $y eq "\$") {
	print "<td></td>\n";
      } elsif ($x eq "\$") {
	print "<td>$y</td>\n"
      } elsif ($y eq "\$") {
	print "<td>$x</td>\n"
      } else {
	my $c = cor($MAT->[$i][$j]);
	my $x = $RES->[$i][$j]?"#ff0000":"#000000";
	printf "<td style=\"border: solid 1px $x; background-color: $c\">%.2f</td>\n",$MAT->[$i][$j];
      }
      $j++;
    }
    print "</tr>\n";
    $i++;
  }

  print "</table>\n";

}


sub dump_latex_mat {
  my ($S1,$S2,$M,$R) = @_;

  print <<'EOH';
\documentclass{book}
\usepackage[T1]{fontenc}
\usepackage[latin1]{inputenc}
\usepackage{aeguill}
\usepackage{a4wide}
\usepackage{rotating}
\usepackage{dcolumn}
\begin{document}


\newcolumntype{R}[1]{% 
>{\begin{turn}{90}\begin{minipage}{#1}% 
\raggedright\hspace{0pt}}c% 
<{\end{minipage}\end{turn}}% 
} 


{\footnotesize
\begin{turn}{90}
EOH

  my $h = join('@{\ \ }',map {"r"} (0..scalar(@$S2)));

  print '\begin{tabular}{',$h,"}\n";

  my ($i,$j) = (-1,-1);
  my ($x,$y);

  for $x ("\$", @$S1) {
    $j = -1;
    for $y ("\$", @$S2) {
      if ($x eq "\$" && $y eq "\$") {
	# nothing
      } elsif ($x eq "\$") {
	print ' & \multicolumn{1}{R{5em}}{',$y,'}'
      } elsif ($y eq "\$") {
	print "\\hline\n" if $i == 0;


	my ($ll,$rl) = latex_get_limits($i, scalar(@$S2), $R);
	$ll+=2;
	$rl+=2;
	print "\\cline{$ll-$rl}\n" if $ll <= $rl;


	print '\multicolumn{1}{r|}{',$x,'}'
      } else {

	if ($R->[$i][$j]) {
	  print " & \\multicolumn{1}{|r|}{", latex_number_format($M->[$i][$j]),"}"
	} else {
	  print " & ", latex_number_format($M->[$i][$j])
	}
      }
      $j++;
    }
    print "\\\\\n";
    $i++;
  }


  my ($ll,$rl) = latex_get_limits($i, scalar(@$S2), $R);
  $ll+=2;
  $rl+=2;
  print "\\cline{$ll-$rl}\n" if $ll <= $rl;

 print <<'EOF';
\end{tabular}
\end{turn}
}

\end{document}
EOF

}

sub latex_get_limits {
  my ($i,$size,$R) = @_;

  my ($min1,$max1,$min2,$max2) = ($size, 0, $size, 0);

  for (0..$size) {
    if ($R->[$i-1][$_]) {
      $min1 = $_ if $_ < $min1;
      $max1 = $_ if $_ > $max1;
    }
    if ($R->[$i][$_]) {
      $min1 = $_ if $_ < $min1;
      $max1 = $_ if $_ > $max1;
    }
  }

  return (min($min1,$min2),max($max1,$max2));
}

sub latex_number_format {
  my $n = shift;
  sprintf("%.1f",$n);
}

sub max {
  my ($a,$b) = @_;
  return ($a>$b)?$a:$b;
}

sub min {
  my ($a,$b) = @_;
  return ($a<$b)?$a:$b;
}



sub cor {
  my $x = shift;
  # my $y =  255 - $x*255/100;
  my $y = 255 - $x*2;

  sprintf("#%02x%02x%02x",$y, $y, $y);
}


sub help {
  return <<EOH;
  <div style="margin: 20px; border: solid 1px #000000; background-color: #ffffdd; ">
     <h2 style="padding: 5px; border-bottom: solid 1px #000000; margin: 0px; background-color: #ddddbb">Help</h2>

     <div style="padding-left: 20px; padding-right: 20px">

     <p>NAT-QI (NATools Query Interface) is a web frontend to query and
     browse Parallel Corpora. For details about its architecture and
     associated tools see <a href="">this page</a>.</p>

     <p>This interface is querying a server (NATServer) with a
     specific parallel corpora, and a specific pair of
     languages. <i>At the moment the source language is Portuguese and
     the target language is English. This will be generic in the
     future.</i></p>

     <p>The purpose of this application if to align sub-segments from
     a sentence, and use them to generalize translations.</p>

     <p><b>Toolbar Usage:</b></p>

     <p>To use this application you need two sentences (a sentence and
     its translation), and write them in the respective entries in the
     toolbar. Then, click <i>calculate matrix</i> to align them.</p>

     <p>Examples:
      <a href="nat-matrix.cgi?crp=EuroParl&s1=aplausos&s2=applause">aplausos / applause</a>,
      <a href="nat-matrix.cgi?crp=EuroParl&s1=sabe%20o%20que%20é%20um%20gato%20%3F&s2=do%20you%20know%20what%20a%20cat%20is%20%3F">Sabe o que é um gato? / do you know what a cat is?</a>

     <p><b>Output Description:</b></p>

     <p>You will be presented with two separate sections: the
     alignment matrix, and the generalization output section. The
     first shows a matrix where probability relation between words is
     presented and a diagonal is searched. The second part shows segments
     extracted from the matrix.</p>
   </div>
  </div>
EOH
}
