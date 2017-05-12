package HTML::WidgetValidator::Widget::Rimo;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;

__PACKAGE__->name('Rimo');
__PACKAGE__->url('http://rimo.tv/');
__PACKAGE__->models([
    [ { type=>'start', name=>'object',
	attr => { height  => qr{\d{1,3}},
		  width   => qr{\d{1,3}},
	          classid => 'clsid:D27CDB6E-AE6D-11cf-96B8-444553540000', },
      },
      { type=>'start', name=>'param',
	attr => { name  => 'movie',
		  value => 'http://rimo.tv/tools/mini.swf?v1.1', }, },
      { type => 'end',  name=>'param' },
      { type =>'start', name=>'param',
	attr => { name  => 'FlashVars',
		  value => qr{channelId=\d+&serverRoot=http%3A%2F%2Frimo.tv%2F&lang=\w+&autoPlay=0}, }, },
      { type => 'end', name=>'param' },
      { type=>'start', name=>'embed',
	attr => { src       => 'http://rimo.tv/tools/mini.swf?v1.1',
		  type      => 'application/x-shockwave-flash',
		  height    => qr{\d{1,3}},
		  width     => qr{\d{1,3}},
		  flashvars => qr{channelId=\d+&serverRoot=http%3A%2F%2Frimo.tv%2F&lang=\w+&autoPlay=0},},},
      { type => 'end', name=>'embed' },
      { type => 'start', name=>'noembed' },
      { type => 'start', name=>'a', attr => { href => qr{http:\/\/rimo\.tv\/.+?},},},
      { type => 'text', text => 'Rimo' },
      { type => 'end', name=>'a' },
      { type => 'end', name=>'noembed' },
      { type => 'end', name=>'object' } ],
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::Rimo


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'Rimo' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate widget "mini Rimo"


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://rimo.tv/>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
