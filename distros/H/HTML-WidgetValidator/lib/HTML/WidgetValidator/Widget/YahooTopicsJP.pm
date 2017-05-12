package HTML::WidgetValidator::Widget::YahooTopicsJP;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;
use Carp;

__PACKAGE__->name('Yahoo! Topics');
__PACKAGE__->url('http://public.news.yahoo.co.jp/blogparts/fc/');
__PACKAGE__->models([
    [ { type=>'start', name=>'script' },
      { type=>'text',  text=> qr{\s*var\s+CFLwidth\s*=\s*"(?:150|222)";\s*var\s+CFLheight\s*=\s*"(?:208|240)";\s*var\s+CFLswfuri\s*=\s*"http:\/\/i\.yimg\.jp\/i\/topics\/blogparts\/topics(_s)?\.swf\?genre=[a-z]+&(?:amp;)?wakuFontColor=[0-9A-Za-z]{6}&(?:amp;)?wakuBGColor=[0-9A-Za-z]{6}&(?:amp;)?bodyFontColor=[0-9A-Za-z]{6}&(?:amp;)?bodyBGColor=[0-9A-Za-z]{6}";\s*} },
      { type => 'end', name => 'script' } ],
    [ { type => 'start', name => 'script', 
	attr => {
	    type    => 'text/javascript',
	    charset => 'euc-jp',
	    src     => 'http://public.news.yahoo.co.jp/blogparts/js/topics.js',
	}},
      { type => 'end', name=>'script' } ],
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::YahooTopicsJP


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'YahooTopicsJP' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate widget "Yahoo! Topics".


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://public.news.yahoo.co.jp/blogparts/fc/>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
