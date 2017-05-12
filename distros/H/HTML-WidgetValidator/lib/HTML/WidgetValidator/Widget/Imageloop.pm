package HTML::WidgetValidator::Widget::Imageloop;
use base qw(HTML::WidgetValidator::Widget);
use strict;
use warnings;

__PACKAGE__->name('imageloop');
__PACKAGE__->url('http://www.imageloop.com/');
__PACKAGE__->models([
    [
	{ type => 'start', name => 'embed',
	  attr => {
	      src     => qr{http://www[.]imageloop[.]com/looopSlider[.]swf[?]id=[0-9A-Fa-f\-]+&c=[0-9,]+},
	      type    => 'application/x-shockwave-flash',
	      quality => 'high',
	      scale   => 'noscale',
	      salign  => 'l',
	      wmode   => 'transparent',
	      width   => qr{\d{2,3}},
	      height  => qr{\d{2,3}},
	      style   => qr{width:\d{2,3}px;height:\d{2,3}px;},
	      align   => 'middle',
	  }},
	{ type => 'end', name=>'embed' }
    ],
    [
	{ type => 'start', name => 'embed',
	  attr => {
	      src     => qr{http://www[.]imageloop[.]com/looopSlider[.]swf[?]id=[0-9A-Fa-f\-]+&c=[0-9,]+},
	      type    => 'application/x-shockwave-flash',
	      quality => 'high',
	      scale   => 'noscale',
	      salign  => 'l',
	      name    => 'imageloop',
	      wmode   => 'transparent',
	      width   => qr{\d{2,3}},
	      height  => qr{\d{2,3}},
	      style   => qr{width:\d{2,3}px;height:\d{2,3}px;},
	      align   => 'middle',
	  }},
	{ type => 'end', name=>'embed' }
    ],

]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::Imageloop


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'Imageloop' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate imageloop slideshow embed code.


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.imageloop.com/>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
