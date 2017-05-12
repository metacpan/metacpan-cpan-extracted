package HTML::WidgetValidator::Widget::PixivEmbedFeature;
use base qw(HTML::WidgetValidator::Widget);
use strict;
use warnings;

our $VERSION = 0.03;

__PACKAGE__->name('PixivEmbedFeature');
__PACKAGE__->url('http://www.pixiv.net/');
__PACKAGE__->models([
	[
	{ type => 'start', name => 'iframe',
		attr => {
			style => qr{(?:background:(?:transparent);\s*)*},
			width => qr{.*},
			height => qr{.*},
			frameborder => qr{.*},
			marginheight => qr{.*},
			marginwidth => qr{.*},
			scrolling => qr{.*},
			src => qr{http://embed\.pixiv\.net/code\.php\??.*},
		}},
	{ type => 'end', name => 'iframe' }
	],
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::PixivEmbedFeature - Perl extension for validate "pixiv Embed"


=head1 SYNOPSIS

    my $validator = HTML::WidgetValidator->new(widgets => ['PixivEmbedFeature']);
    my $result  = $validator->validate($html);
    $result->code;


=head1 DESCRIPTION

Validate "pixiv Embed".


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.pixiv.net/>


=head1 AUTHOR

pmint, C<< <pmint@cpan.org> >>


=head1 LICENSE

Copyright (C) 2008 pmint Some Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.


=cut
