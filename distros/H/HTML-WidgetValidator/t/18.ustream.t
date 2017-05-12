use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'Ustream' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Ustream 1
--- input
<embed width="416" height="340" flashvars="autoplay=false" src="http://www.ustream.tv/h8qRgbdFEPJDAVtPRXWqwrF2pLttiKm7.usc" type="application/x-shockwave-flash" wmode="transparent"/>
--- expected
Ustream

=== Ustream 2
--- input
<embed width="563" height="266" type="application/x-shockwave-flash" flashvars="channel=#otsune" pluginspage="http://www.adobe.com/go/getflashplayer" src="http://ustream.tv/IrcClient.swf"/>
--- expected
Ustream

=== Ustream 3
--- input
<embed width="416" height="340" flashvars="autoplay=false" src="http://ustream.tv/54sTBo3wLQF0Ge1Jg4ZarQ.usc" type="application/x-shockwave-flash" wmode="transparent" />
--- expected
Ustream
