package HTML::WidgetValidator::Widget::Alpslab;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;

__PACKAGE__->name('ALPSLAB');
__PACKAGE__->url('http://www.alpslab.jp/');
__PACKAGE__->models([
    [ { type => 'start', name => 'object', 
	attr => {
	    codebase => qr{http://fpdownload\.macromedia\.com/pub/shockwave/cabs/flash/swflash\.cab\#version=[0-9,]+},
	    width    => qr{\d+},
	    height   => qr{\d+},
	}},
      { type => 'start', name => 'param', 
	attr => {
	    name  => 'movie',
	    value => 'http://video.alpslab.jp/svideoslide.swf',
	}},
      { type => 'end', name=>'param' },
      { type => 'start', name => 'param', 
	attr => {
	    name  => 'flashvars',
	    value => qr{lapid=[A-Fa-f0-9]+},
	}},
      { type => 'end', name=>'param' },
      { type => 'start', name => 'embed', 
	attr => {
	    src       => 'http://video.alpslab.jp/svideoslide.swf',
	    width     => qr{\d+},
	    height    => qr{\d+},
	    type      => 'application/x-shockwave-flash',
	    flashvars => qr{lapid=[A-Fa-f0-9]+},
	}},
      { type => 'end', name=>'embed'},
      { type => 'end', name=>'object' } ],

    [ { type => 'start', name => 'object', 
	attr => {
	    codebase => qr{http://fpdownload\.macromedia\.com/pub/shockwave/cabs/flash/swflash\.cab\#version=[\d\,]+},
	    width    => qr{\d+},
	    height   => qr{\d+},
	}},
      { type => 'start', name => 'param', 
	attr => {
	    name  => 'movie',
	    value => 'http://route.alpslab.jp/fslide.swf',
	}},
      { type => 'end', name=>'param' },
      { type => 'start', name => 'param', 
	attr => {
	    name  => 'flashvars',
	    value => qr{routeid=[A-Fa-f0-9]+},
	}},
      { type => 'end', name=>'param' },
      { type => 'start', name => 'embed', 
	attr => {
	    src       => 'http://route.alpslab.jp/fslide.swf',
	    width     => qr{\d+},
	    height    => qr{\d+},
	    type      => 'application/x-shockwave-flash',
	    flashvars => qr{routeid=[A-Fa-f0-9]+},
	}},
      { type => 'end', name=>'embed' },
      { type => 'end', name=>'object' } ],

    [ { type => 'start', name => 'script', 
	attr => {
	    type => 'text/javascript',
	    src  => 'http://mybase.alpslab.jp/mybase.js',
	}},
      { type => 'end', name=>'script' } ],

    [ { type => 'start', name => 'script', 
	attr => {
	    type => 'text/javascript',
	    src  => 'http://slide.alpslab.jp/scrollmap.js',
	}},
      { type => 'end', name=>'script' } ],

]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::Alpslab


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'Alpslab' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate "Alpslab" widgets.


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.alpslab.jp/>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
