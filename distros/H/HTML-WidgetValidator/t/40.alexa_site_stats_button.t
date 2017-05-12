use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'AlexaSiteStatsButton' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Alexa Site Stats Button 1
--- input
<SCRIPT type='text/javascript' language='JavaScript' src='http://xslt.alexa.com/site_stats/js/s/a?url=hatena.com'></SCRIPT>
--- expected
Alexa Site Stats Button

=== Alexa Site Stats Button 2
--- input
<SCRIPT type='text/javascript' language='JavaScript' src='http://xslt.alexa.com/site_stats/js/s/b?url=hatena.com'></SCRIPT>
--- expected
Alexa Site Stats Button

=== Alexa Site Stats Button 3
--- input
<SCRIPT type='text/javascript' language='JavaScript' src='http://xslt.alexa.com/site_stats/js/s/c?url=hatena.ne.jp'></SCRIPT>
--- expected
Alexa Site Stats Button

=== Alexa Site Stats Button 4
--- input
<SCRIPT type='text/javascript' language='JavaScript' src='http://xslt.alexa.com/site_stats/js/s/a?url=http%3A%2F%2Fwww.hatena.ne.jp%2F'></SCRIPT>
--- expected
Alexa Site Stats Button
