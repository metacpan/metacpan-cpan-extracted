package HTML::WidgetValidator::Widget::TegakiBlog;
use base qw(HTML::WidgetValidator::Widget);
use strict;
use warnings;

our $VERSION = 0.01;

__PACKAGE__->name('TegakiBlog');
__PACKAGE__->url('http://pipa.jp/tegaki/');
__PACKAGE__->models([
	[
		{ type => 'start', name => 'object',
			attr => {
				width => qr{\d+},
				height => qr{\d+},
			},
		},

		{ type => 'start', name => 'param',
			attr => {
				name => 'movie',
				value => 'http://pipa.jp/tegaki/OBlogParts.swf',
			},
		},
		{ type => 'end', name => 'param' },

		{ type => 'start', name => 'param',
			attr => {
				name => 'FlashVars',
				value => qr{ID=\d+},
			},
		},
		{ type => 'end', name => 'param' },

		{ type => 'start', name => 'embed',
			attr => {
				src => 'http://pipa.jp/tegaki/OBlogParts.swf',
				width => qr{\d+},
				height => qr{\d+},
				flashvars => qr{ID=\d+},
			},
		},
		{ type => 'end', name => 'embed' },

		{ type => 'end', name => 'object' },
	],

	[
		{ type => 'start', name => 'script',
			attr => {
				type => 'text/javascript',
				src => qr{http://pipa\.jp/tegaki/js/tag\.js(?:#userID=\d+)?},
			},
		},
		{ type => 'end', name => 'script' },
	],
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::TegakiBlog - Perl extension for validate "Tegaki blog"(handwriting blog) blog parts.


=head1 SYNOPSIS

    my $validator = HTML::WidgetValidator->new(widgets => ['TegakiBlog']);
    my $result  = $validator->validate(UNTRUSTED_TEXT_WHICH_INCLUDE_TEGAKIBLOG_CODE);
    if ($result){
        CODE_FOR_VALIDATED_HTML
    }


=head1 DESCRIPTION

Validate "Tegaki blog"(handwriting blog) blog parts.


=head1 SEE ALSO

L<HTML::WidgetValidator>,

Tegaki blog
L<http://pipa.jp/tegaki/VTop_en.jsp> (English)
L<http://pipa.jp/tegaki/> (Japanese)


=head1 AUTHOR

pmint, C<< <pmint@cpan.org> >>


=head1 LICENSE

Copyright (C) 2008 pmint Some Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.


=cut
