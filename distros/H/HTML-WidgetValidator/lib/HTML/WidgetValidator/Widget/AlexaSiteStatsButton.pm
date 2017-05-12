package HTML::WidgetValidator::Widget::AlexaSiteStatsButton;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;

__PACKAGE__->name('Alexa Site Stats Button');
__PACKAGE__->url('http://www.alexa.com/site/site_stats/signup');
__PACKAGE__->models([
    [
        {
            type =>'start',
            name =>'script',
            attr => { type     => 'text/javascript',
                      language => 'JavaScript',
                      src      => qr{http://xslt\.alexa\.com/site_stats/js/s/(?:a|b|c)\?url=[\w\.%\-\/:\s]+} },
        },
        { type => 'end', name=>'script' }
    ],
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::AlexaSiteStatsButton


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'AlexaSiteStatsButton' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate widget "Alexa Site Stats Button".


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.alexa.com/site/site_stats/signup>


=head1 AUTHOR

Taro Minowa  C<< <higepon@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
