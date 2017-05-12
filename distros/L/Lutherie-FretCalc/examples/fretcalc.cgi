#!/usr/bin/perl -w
use strict;
use CGI qw/:standard/;
use Lutherie::FretCalc;

# Limit number of frets
my $MAX_FRETS = 50;

my %calc_method_labels = (t=>'12th root of 2', ec=>17.817, es=>17.835);

print header,
      start_html(-title=>'FretCalc'),
      h1('Fret Placement Calculator'),
      startform,
      table(TR,
             td('Scale Length:'),
             td(textfield(-name=>'scale_length')),
             td(radio_group(-name=>'in_units',
                            -values=>['inches','millimeters'],
                            -default=>'inches')),
           TR,
             td('Number of Frets:'), 
             td(textfield(-name=>'num_frets')),
             td(radio_group(-name=>'out_units',
                            -values=>['inches','millimeters'],
                            -default=>'inches')),
           TR,
             td('Calc Method:'), 
             td(radio_group(-name=>'calc_method',
                            -values=>['t','ec', 'es'],
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
  if( param('scale_length') =~ /^\d+\.?\d+$/ &&
      param('num_frets') =~ /^\d+$/) {

      # Get params
      my $scale_length = param('scale_length');
      my $num_frets = param('num_frets');
      my $in_units = param('in_units');
      my $out_units = param('out_units');
      my $calc_method = param('calc_method');

      # Check $num_frets
      $num_frets = $MAX_FRETS unless $num_frets =~ /^\d+$/;
      $num_frets = $MAX_FRETS if $num_frets > $MAX_FRETS;

      $in_units = 'in' if $in_units eq 'inches';
      $in_units = 'mm' if $in_units eq 'millimeters';
      $out_units = 'in' if $out_units eq 'inches';
      $out_units = 'mm' if $out_units eq 'millimeters';

      my $fretcalc = Lutherie::FretCalc->new($scale_length);
      $fretcalc->num_frets($num_frets);
      $fretcalc->in_units($in_units);
      $fretcalc->out_units($out_units);
      $fretcalc->calc_method($calc_method);
      my @frets = $fretcalc->fretcalc();

      print hr,
            '<table border=1>',
            '<th>Fret</th>',
            '<th>Dist from Nut</th>';

      foreach my $i (1..$#frets) {
          my $fret = sprintf("%3d",$i);
          print '<tr>',
                qq!<td align="right">$fret</td>!,
                qq!<td align="right">$frets[$i]</td>!,
                '</tr>';
      }
      print '</table>';

  } else {

      print hr,
            "'Scale length' and 'number of frets' must be numeric";
   }
     
}

sub footer {
    print hr;
    print qq!Powered by <a href="http://search.cpan.org/search?dist=Lutherie-FretCalc">Lutherie::FretCalc</a><br>\n!;

}
