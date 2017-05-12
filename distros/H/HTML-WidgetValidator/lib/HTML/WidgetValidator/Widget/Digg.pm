package HTML::WidgetValidator::Widget::Digg;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;
use Carp;

__PACKAGE__->name('Digg');
__PACKAGE__->url('http://digg.com/add-digg');
__PACKAGE__->models([
    [ { type=>'start', name=>'script', 
	attr => { type    => 'text/javascript', }, },
      { type=>'text',  
	text=> qr{\s*(?:digg_width\s*=\s*'\d+px';\s*|digg_height\s*=\s*'\d+px';\s*|digg_border\s*=\s*\d+;\s*|digg_count\s*=\s*\d+;\s*|digg_description\s*=\s*\d+;\s*|digg_target\s*=\s*\d+;\s*|digg_theme\s*=\s*'digg-widget-[a-z0-9]+';\s*|digg_custom_header\s*=\s*'#[0-9A-Fa-f]{3,6}';\s*|digg_custom_border\s*=\s*'#[0-9A-Fa-f]{3,6}';\s*|digg_custom_link\s*=\s*'#[0-9A-Fa-f]{3,6}';\s*|digg_custom_hoverlink\s*=\s*'#[0-9A-Fa-f]{3,6}';\s*|digg_custom_footer\s*=\s*'#[0-9A-Fa-f]{3,6}';\s*|digg_title\s*=\s*'[^'<>]+';\s*)+\s*} },
      { type => 'end', name=>'script' } ],
    [ { type => 'start', name=>'script', 
	attr => {
	    type    => 'text/javascript',
	    src     => 'http://digg.com/tools/widgetjs',
	}},
      { type => 'end', name=>'script' } ],
    [ { type => 'start', name=>'script', 
	attr => {
	    type    => 'text/javascript',
	    src     => qr{http://digg\.com/tools/services\?type=javascript&callback=diggwb&endPoint=[a-z0-9/]+(?:&domain=[A-Za-z0-9\-\.]+)?(?:&sort=[a-z\-_]+)?&count=\d{1,2}},
	}},
      { type => 'end', name=>'script' } ],

]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::Digg


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'Digg' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate Digg Widget.


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://digg.com/add-digg>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
