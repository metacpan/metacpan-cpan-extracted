package HTML::WidgetValidator::Widget::GoogleAdSense;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;
use Carp;

__PACKAGE__->name('Google AdSense');
__PACKAGE__->url('https://www.google.com/adsense/');
__PACKAGE__->models([
    [ { type=>'start', name=>'script', 
	attr => { type    => 'text/javascript', }, },
      { type=>'text',  text=> qr{\s*<\!\-\-\s+(?:google_ad_client\s*=\s*"pub\-[\d]+";\s*|google_alternate_ad_url\s*=\s*"[^"<>]+";\s*|google_alternate_color\s*=\s*"[0-9A-Fa-f]{6}";\s*|google_ad_width\s*=\s*\d+;\s*|google_ad_height\s*=\s*\d+;\s*|google_ad_format\s*=\s*"\d+x\d+_(?:as|0ads_al|0ads_al_s)";\s*|google_ad_type\s*=\s*"(?:text|image|text_image)";\s*|google_ad_channel\s*=\s*"[\w\-\_]*";\s*|google_color_border\s*=\s*"[0-9A-Fa-f]{6}";\s*|google_color_bg\s*=\s*"[0-9A-Fa-f]{6}";\s*|google_color_link\s*=\s*"[0-9A-Fa-f]{6}";\s*|google_color_text\s*=\s*"[0-9A-Fa-f]{6}";\s*|google_color_url\s*=\s*"[0-9A-Fa-f]{6}";\s*|google_ui_features\s*=\s*"rc:\d+";\s*|google_cpa_choice\s*=\s*"[0-9A-Za-z]+";\s*|\/\/\d\d\d\d-\d\d-\d\d:\s+\w+\s+)+\s*\/\/-->\s*} },
      { type => 'end', name=>'script' } ],
    [ { type => 'start', name=>'script', 
	attr => {
	    type    => 'text/javascript',
	    src     => 'http://pagead2.googlesyndication.com/pagead/show_ads.js',
	}},
      { type => 'end', name=>'script' } ],
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::GoogleAdSense


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'GoogleAdSense' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate Google AdSense code.


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<https://www.google.com/adsense/>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
