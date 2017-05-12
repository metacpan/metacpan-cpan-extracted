package HTML::WidgetValidator::Widget::YahooWeatherJP;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;
use Carp;

__PACKAGE__->name('Yahoo! Weather');
__PACKAGE__->url('http://weather.yahoo.co.jp/weather/promo/blogparts/');
__PACKAGE__->models([
    [ { type=>'start', name=>'script' },
      { type=>'text',  text=> qr{\s*var\s+CFLwidth\s*=\s*"150";\s*var\s+CFLheight\s*=\s*"322";\s*var\s+CFLswfuri\s*=\s*"http:\/\/i\.yimg\.jp\/images\/weather\/blogparts\/yj_weather\.swf\?mapc=[0-9a-z]+";\s*} },
      { type => 'end', name=>'script' } ],
    [ { type => 'start', name=>'script', 
	attr => {
	    type    => 'text/javascript',
	    charset => 'euc-jp',
	    src     => 'http://weather.yahoo.co.jp/weather/promo/js/weather.js',
	}},
      { type => 'end', name=>'script' } ],

]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::YahooWeatherJP


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'YahooWeatherJP' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate widget "Yahoo! Weather".


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://weather.yahoo.co.jp/weather/promo/blogparts/>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
