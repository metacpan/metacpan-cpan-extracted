#!/usr/bin/perl -w
use strict;
use CGI qw/:standard/;
use Lutherie::FretCalc;

my %calc_method_labels = (t=>'12th root of 2', ec=>17.817, es=>17.835); 

print header,
      start_html(-title=>'Dulcimer Fret Placement Calculator'),
      h1('Dulcimer Fret Placement Calculator'),
      startform,
      table(TR,
             td('Scale Length:'),
             td(textfield(-name=>'scale_length')),
           TR,
             td('Half Frets:'),
             td(checkbox_group(-name=>'half_frets',
                            -values=>[1,6,8,13],
                            -default=>[6,13])),
           TR,
             td('Calc Method:'),
             td(radio_group(-name=>'calc_method',
                            -values=>['t', 'ec', 'es'],
                            -default=>'t',
                            -labels=>\%calc_method_labels)),
      ),
      submit,
      endform;

display_results() if param();

footer();
print end_html;

################################################

sub display_results {

  # Display results if scale_length is numeric
  if( param('scale_length') =~ /^\d+\.?\d+$/ ) {

      # Get params
      my $scale_length = param('scale_length');
      my $calc_method = param('calc_method');
      my @half_frets = param('half_frets');

      my $fretcalc = Lutherie::FretCalc->new($scale_length);
      # Set calc method
          $fretcalc->calc_method($calc_method);
      # Set half frets
      foreach my $half_fret( @half_frets ) {
          $fretcalc->half_fret($half_fret);
      }
      my %chart = $fretcalc->dulc_calc();

      print hr,
            '<table border=1>',
            '<th>Fret</th>',
            '<th>Dist from Nut</th>';

      foreach my $fret (sort {$a <=> $b} keys %chart) {
          my $dist = $chart{$fret};
          $fret = sprintf("%4s",$fret);
          print '<tr>',
                qq!<td align="right">$fret</td>!,
                qq!<td align="right">$dist</td>!,
                '</tr>';
      }
      print '</table>';

  } else {

      print hr,
            "'Scale length' must be numeric";
   }
     
}

sub footer {
    print hr;
    print qq!Powered by <a href="http://search.cpan.org/search?dist=Lutherie-FretCalc">Lutherie::FretCalc</a><br>\n!;

}
