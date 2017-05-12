package HTML::WidgetValidator::Widget::GoogleMaps;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;
use Carp;

our $VERSION = '0.01';

__PACKAGE__->name('Google Maps');
__PACKAGE__->url('http://maps.google.com/');
__PACKAGE__->models(
    [
        [
            {
                name => 'iframe',
                type => 'start',
                attr => {
                    src          => qr{http://maps[.]google[.](?:com|co[.]jp)/(?:maps(?:/ms)?)?[?][A-Za-z0-9%=&\-_\.\+,:\;]+},
                    width        => qr{\d{2,3}},
                    height       => qr{\d{2,3}},
                    scrolling    => 'no',
                    frameborder  => qr{no|0},
                    marginwidth  => '0',
                    marginheight => '0',
                },
            },
            {
                'name' => 'iframe',
                'type' => 'end',
            },
        ],
    ]
);

=head1 NAME

HTML::WidgetValidator::Widget::GoogleMaps


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'GoogleMaps' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate widget "Google Maps"


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://maps.google.com/>


=head1 AUTHOR

Yasuhiro Onishi, E<lt>onishi@hatena.ne.jpE<gt>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
