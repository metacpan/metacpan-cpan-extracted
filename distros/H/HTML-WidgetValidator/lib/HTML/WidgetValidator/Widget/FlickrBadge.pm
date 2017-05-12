package HTML::WidgetValidator::Widget::FlickrBadge;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;

__PACKAGE__->name('Flickr Bagde');
__PACKAGE__->url('http://www.flickr.com/badge.gne');
__PACKAGE__->models([
    [
	{ type => 'start', name=>'style', 
	  attr => {
	      type => 'text/css',
	  },
      },
	{ type => 'text',
	  text => qr{\s*(?:(?:\.zg_div\s+\{margin:\d+px\s+\d+px\s+\d+px\s+\d+px;\s+width:\d+px;\}\s*)|(?:\.zg_div_inner\s+\{(?:border:\s*solid\s+\d+px\s+#[0-9A-Fa-f]{6};)?\s*(?:background\-color:\s*#[0-9A-Fa-f]{6};)?\s*color:\s*\#[0-9A-Fa-f]{6};\s+text\-align:\s*center;\s+font\-family:[0-9A-Za-z\,\s]+;\s+font\-size:\s*\d+px;\}\s*)|(?:\.zg_div\s+a,\s+\.zg_div\s+a:hover,\s+\.zg_div\s+a:visited\s+\{color:#[0-9A-Fa-f]{6};\s+background:\s*inherit\s+\!important;\s+text-decoration:\s*none\s+\!important;\}\s*))+},},
	{ type => 'end', name=>'style' }
    ],
    [
	{ type => 'start', name=>'script', 
	  attr => {
	      type => 'text/javascript',
	  },},
	{ type => 'text',
	  text => qr{\s*\s*zg_insert_badge\s+=\s+function\(\)\s+\{\s+var\s+zg_bg_color\s+=\s+'[0-9A-Fa-f]{6}';\s+var\s+zgi_url\s+=\s+'http:\/\/www\.flickr\.com\/apps\/badge\/badge_iframe\.gne\?zg_bg_color='\+zg_bg_color\+'(?:&zg_person_id=[^'&\?<>]+)?(?:&zg_tags=[^<>&]+&zg_tag_mode=[a-z]+)?(?:&zg_set_id=\d+&zg_context=in%2Fset\-\d+%2F)?&?';\s+document\.write\('<iframe\s+style="background\-color:#'\+zg_bg_color\+';\s+border\-color:#'\+zg_bg_color\+';\s+border:none;"\s+width="\d+"\s+height="\d+"\s+frameborder="\d+"\s+scrolling="no"\s+src="'\+zgi_url\+'"\s+title="[A-Za-z0-9\s]+"><\\\/iframe>'\);\s+if\s+\(document\.getElementById\)\s+document\.write\('<div\s+id="zg_whatlink"><a\s+href="http:\/\/www\.flickr\.com\/badge\.gne"\s+style="color:#[0-9A-Fa-f]{6};"\s+onclick="zg_toggleWhat\(\);\s+return\s+false;">[A-Za-z0-9_\-\s\%\?]+<\\\/a><\\\/div>'\);\s+\}\s+zg_toggleWhat\s+=\s+function\(\)\s+\{\s+document\.getElementById\('zg_whatdiv'\)\.style\.display\s+=\s+\(document\.getElementById\('zg_whatdiv'\)\.style\.display\s+\!=\s+'none'\)\s+\?\s+'none'\s+:\s+'block';\s+document\.getElementById\('zg_whatlink'\)\.style\.display\s+=\s+\(document\.getElementById\('zg_whatdiv'\)\.style\.display\s+\!=\s+'none'\)\s+\?\s+'none'\s+:\s+'block';\s+return\s+false;\s+\}\s*},},
	{ type => 'end', name=>'script' },
    ],
    [
	{ type => 'start', name=>'script', 
	  attr => {
	      type => 'text/javascript',
	  },},
	{ type => 'text',text => qr{\s*zg_insert_badge\(\);\s*},},
	{ type => 'end', name=>'script' },
    ],
    [
	{ type => 'start', name=>'script', 
	  attr => {
	      type => 'text/javascript',
	  },},
	{ type => 'text', text => qr{\s*if\s*\(document\.getElementById\)\s*document\.getElementById\('zg_whatdiv'\)\.style\.display\s*=\s*'none';\s*} ,},
	{ type => 'end', name=>'script' },
    ],
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::FlickrBadge


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'FlickrBadge' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate Flickr Badge.


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.flickr.com/badge.gne>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

