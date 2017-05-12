package HTML::WidgetValidator::Widget::RakugakiBoard;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;
use Carp;

our $VERSION = '0.01';

__PACKAGE__->name('Rakugaki Board');
__PACKAGE__->url('http://www.blogdeco.jp/rakugaki/');
__PACKAGE__->models(
    [
        [
            {
                type => 'start',
                name => 'script',
                attr => {
                    language => 'javascript',
                    src      => qr{http://rakugaki[.]kayac[.]com/rakugaki_tag[.]php[?]rid=\d+},
                },
            },
            { type => 'end', name => 'script' },
        ],
        [
            { type => 'start', name => 'noscript' },
            {
                type => 'start',
                name => 'a',
                attr => {
                    href   => 'http://www.blogdeco.jp/',
                    target => '_blank',
                },
            },
            {
                type => 'start',
                name=>'img',
                attr => {
                    src    => 'http://www.blogdeco.jp/img/jsWarning.gif',
                    width  => '140',
                    height => '140',
                    border => '0',
                    alt    => 'Blogdeco',
                },
            },
            { type => 'end', name=>'img' },
            { type => 'end', name=>'a' },
            { type => 'end', name=>'noscript' },
        ],
    ]
);

=head1 NAME

HTML::WidgetValidator::Widget::RakugakiBoard

=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'RakugakiBoard' ]);
    my $result  = $validateor->validate($html);

=head1 DESCRIPTION

Validate widget "Rakugaki Board" (BlogDeco)

=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.blogdeco.jp/rakugaki/>

=head1 AUTHOR

Yasuhiro Onishi, E<lt>onishi@hatena.ne.jpE<gt>

=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
