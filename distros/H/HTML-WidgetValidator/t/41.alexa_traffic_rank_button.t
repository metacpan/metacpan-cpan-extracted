use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'AlexaTrafficRankButton' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Alexa Traffic Rank Button 1
--- input
<SCRIPT type='text/javascript' language='JavaScript' src='http://xslt.alexa.com/site_stats/js/t/a?url=rimo.tv'></SCRIPT>
--- expected
Alexa Traffic Rank Button

=== Alexa Traffic Rank Button 2
--- input
<SCRIPT type='text/javascript' language='JavaScript' src='http://xslt.alexa.com/site_stats/js/t/b?url=rimo.tv'></SCRIPT>
--- expected
Alexa Traffic Rank Button

=== Alexa Traffic Rank Button 3
--- input
<SCRIPT type='text/javascript' language='JavaScript' src='http://xslt.alexa.com/site_stats/js/t/c?url=rimo.tv'></SCRIPT>
--- expected
Alexa Traffic Rank Button

=== Alexa Traffic Rank Button 4
--- input
<SCRIPT type='text/javascript' language='JavaScript' src='http://xslt.alexa.com/site_stats/js/t/a?url=http%3A%2F%2Fwww.hatena.ne.jp%2F'></SCRIPT>
--- expected
Alexa Traffic Rank Button
