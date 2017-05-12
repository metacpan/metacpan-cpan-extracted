#!/usr/bin/perl -w

use Data::Dumper;
use CGI qw/:standard/;
use Lingua::NATools::NATDict;

print header;
print while(<DATA>);

our $url = url();
our $dict;
our $lang;

if (param("dict") && (-f param("dict"))) {
  $dict = param("dict");

  $lang = 0;
  my $id = 250;
  my @togo;

  my $NTD = Lingua::NATools::NATDict->open($dict);

  print "<div class=\"header\">\n";
  print "Browsing file '",i($dict),"'",br;

  my ($lsource, $ltarget) = $NTD->languages;
  print "Languages: '",i($lsource),"', '",i($ltarget),"'",br;

  if (param("search")) {
    my $word = param("search");
    my $language = param("language");
    if ($language eq "Both") {

      my $x;
      $x = $NTD->id_from_word($lsource,param("search"));
      push @togo, [$x, 0] if ($x);

      $x = 0;
      $x = $NTD->id_from_word($ltarget,param("search"));
      push @togo, [$x, 1] if ($x);


    } elsif ($language eq "$ltarget") {

      my $x = $NTD->id_from_word($ltarget,param("search"));
      push @togo, [$x, 1] if ($x);

    } else {

      my $x = $NTD->id_from_word($lsource,param("search"));
      push @togo, [$x, 0] if ($x);

    }
  } else {
    $id = param("word") if (param("word"));
    $lang = param("lang") if (param("lang"));
    @togo = ([$id, $lang]);
  }



  print "</div>\n";
  print form($lsource,$ltarget);

  if (@togo) {
    for (@togo) {
      $lang = $_->[1];
      my ($dic1, $dic2);
      if ($_->[1] == 0) {
	($dic1, $dic2) = ($lsource, $ltarget);
      } else {
	($dic2, $dic1) = ($lsource, $ltarget);
      }
      print show_table($NTD, $_->[0], $dic1, $dic2);
    }
  } else {
    print "Words not found!\n";
  }

} else {
  print "File '",i(param("dict")),"' not found!" if param("dict");
  print start_form;
  print "Enter dictionary path/name: ", textfield("dict"), submit("Browse");
  print end_form;
}

print "</body></html>\n";

sub printDebug {
  my $str =shift;
  print "<span style=\"color: #f00; font-weight: bold\">$str</span><br/>\n";
}


sub show_table {
  my ($NTD, $id, $dic1, $dic2) = @_;

  my $output;
  my $word = $NTD->word_from_id($dic1, $id);
  my $wcount = $NTD->word_count_by_id($dic1, $id);
  my $data = $NTD->word_vals_by_id($dic1, $id);
  my %data = (@$data);


  $output .= h3("$word ($wcount)");

  $output .= "<table>\n";

  for (sort {$data{$b} <=> $data{$a}} keys %data) {
    $output .= Tr(td({-class=>"box",
		      -style=>style_from_percent($data{$_})},
		     percent($data{$_})),
		  td({-style=>"width: 300px; padding: 0px"},
		     show_table_2($NTD, $_, $dic2, $dic1)));
  }

  $output .= "</table>\n";
  return $output;
}

sub show_table_2 {
  my ($NTD, $id, $dic1, $dic2) = @_;

  my $output = "<table style=\"margin: 0px; width: 100%\">\n";
  my $word = $NTD->word_from_id($dic1, $id);
  my $wcount = $NTD->word_count_by_id($dic1, $id);
  my $data = $NTD->word_vals_by_id($dic1, $id);
  my %data = (@$data);
  my $lang1 = $lang == 0?1:0;

  $output .= Tr(td({-colspan=>2,-class=>"box"},
		   b(a({-href=>"$url?word=$id&dict=$dict&lang=$lang1"},$word)),
		   "($wcount)"));

  for (sort {$data{$b} <=> $data{$a}} keys %data) {
    $output .= Tr(td({-class=>"box",-style=>style_from_percent($data{$_})},percent($data{$_})),
		  td({-class=>"box",-style=>"width: 75%"},
		     a({-href=>"$url?word=$_&dict=$dict&lang=$lang"},
		       $NTD->word_from_id($dic2, $_))));
  }

  $output .= "</table>\n";
  return $output;
}

sub percent {
  my $x = shift;
  $x *= 100;
  return sprintf("%.2f%%", $x);
}

sub style_from_percent {
  my $x = shift;
  if ($x > .75) { return "background-color: #afa" }
  if ($x > .35) { return "background-color: #ffa" }
  return "background-color: #faa"
}

sub form {
  my ($l1,$l2) = @_;
  return start_form .
    p("Search ", textfield('search'), " on ",
      popup_menu(-name    => 'language',
		 -values  => ["Both",$l1,$l2],
		 -default => "Both"), " language(s)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;",
      hidden("dict", $dict),
      submit(" Go! ")) . end_form;
}

__DATA__
<html>
 <head>
  <title>NATools Dictionary Browse</title>
  <style type="text/css">
   a:visited { color: #009; }
   body { font-family: helvetica }
   a { text-decoration: none; }
   a:hover { text-decoration: underline; }
   .box { border: solid 1px #000; padding: 2px; }
   div.header { font-size: small; padding: 2px; border: dotted 1px #999; }
   form {  padding: 3px; background-color: #eee; border: solid 1px #000; margin-top: 4px;}
   input { border: solid 1px #000 }
  </style>
 </head>

 <body>
