package HTML::WidgetValidator::Widget::Ustream;
use base qw(HTML::WidgetValidator::Widget);
use strict;
use warnings;

__PACKAGE__->name('Ustream');
__PACKAGE__->url('http://ustream.tv/mybroadcasts');
__PACKAGE__->models([
    [
        { type => 'start', name => 'embed',
          attr => {
              width        => qr{\d{2,3}},
              height       => qr{\d{2,3}},
              flashvars    => 'autoplay=false',
              src          => qr{http://(?:www\.)?ustream[.]tv/[a-zA-Z0-9,.]+[.]usc},
              type         => 'application/x-shockwave-flash',
              wmode        => 'transparent',
          }
        },
	{ type => 'end', name=>'embed' },
    ],
    [
        { type => 'start', name => 'embed',
          attr => {
              width        => qr{\d+},
              height       => qr{\d+},
              type         => 'application/x-shockwave-flash',
              flashvars    => qr{channel=#.+},
              pluginspage  => 'http://www.adobe.com/go/getflashplayer',
              src          => qr{http://(?:www\.)?ustream[.]tv/IrcClient[.]swf},
          }
        },
	{ type => 'end', name=>'embed' },
    ],
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::Ustream


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'Ustream' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate widget "ustream".


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://ustream.tv/mybroadcasts>


=head1 AUTHOR

motemen  C<< <motemen@gmail.com> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
