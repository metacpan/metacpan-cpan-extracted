package HTML::WidgetValidator::Widget::AlexaTrafficRankButton;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;

__PACKAGE__->name('Alexa Traffic Rank Button');
__PACKAGE__->url('http://www.alexa.com/site/site_stats/signup');
__PACKAGE__->models([
    [
        {
            type =>'start',
            name =>'script',
            attr => { type     => 'text/javascript',
                      language => 'JavaScript',
                      src      => qr{http://xslt\.alexa\.com/site_stats/js/t/(?:a|b|c)\?url=[\w\.%\-\/:\s]+} },
        },
        { type => 'end', name=>'script' }
    ],
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::AlexaTrafficRankButton


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'AlexaTrafficRankButton' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate widget "Alexa Traffic Rank Button".


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.alexa.com/site/site_stats/signup>


=head1 AUTHOR

Taro Minowa  C<< <higepon@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
