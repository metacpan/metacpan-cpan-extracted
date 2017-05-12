package HTML::WidgetValidator::Widget::Twitter;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;
use Carp;

__PACKAGE__->name('Twitter');
__PACKAGE__->url('http://twitter.com/badges');
__PACKAGE__->models([
    [ { type => 'start', name => 'embed',
	attr => {
	    src               => 'http://static.twitter.com/flash/twitter_timeline_badge.swf',
	    flashvars         => qr{user_id=\d+&color1=0x[0-9A-Fa-f]{6}&color2=0x[0-9A-Fa-f]{6}&textColor1=0x[0-9A-Fa-f]{6}&textColor2=0x[0-9A-Fa-f]{6}&backgroundColor=0x[0-9A-Fa-f]{6}&textSize=\d+},
	    quality           => 'high',
	    width             => qr{\d{1,3}},
	    height            => qr{\d{1,3}},
	    name              => 'twitter_timeline_badge',
	    align             => 'middle',
	    allowscriptaccess => 'always',
	    type              => 'application/x-shockwave-flash',
	    pluginspage       => 'http://www.adobe.com/go/getflashplayer',
	}},
      { type => 'end', name=>'embed'} ],

    [ { type => 'start', name => 'embed',
	attr => {
	    src               => 'http://twitter.com/flash/twitter_badge.swf',
	    flashvars         => qr{color1=\d+&type=[a-z]+&id=\d+},
	    quality           => 'high',
	    width             => qr{\d{1,3}},
	    height            => qr{\d{1,3}},
	    name              => 'twitter_badge',
	    align             => 'middle',
	    allowscriptaccess => 'always',
	    wmode             => 'transparent',
	    type              => 'application/x-shockwave-flash',
	    pluginspage       => 'http://www.macromedia.com/go/getflashplayer',
	}},
      { type => 'end', name=>'embed'} ],

    [ { type => 'start', name => 'script', 
	attr => {
	    type => 'text/javascript',
	    src  => 'http://twitter.com/javascripts/blogger.js',
	}},
      { type => 'end', name=>'script' } ],
    [ { type => 'start', name => 'script', 
	attr => {
	    type => 'text/javascript',
	    src  => qr{http://twitter\.com/statuses/user_timeline/[0-9A-Za-z\-_]+\.json\?callback=twitterCallback2&count=\d+},
	}},
      { type => 'end', name=>'script' } ],

    [ { type => 'start', name => 'script', 
	attr => {
	    text => 'text/javascript',
	    src  => qr{http://twitter\.com/statuses/user_timeline/[0-9A-Za-z\-_]+\.json\?callback=twitterCallback2&count=\d+},
	}},
      { type => 'end', name=>'script' } ],


]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::Twitter


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'Twitter' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate Twitter badge.


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://twitter.com/badges>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

