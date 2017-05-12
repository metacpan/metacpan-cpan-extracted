package HTML::WidgetValidator::Widget::ShockwaveBloggames;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;

__PACKAGE__->name('Shockwave Bloggames');
__PACKAGE__->url('http://www.shockwave.co.jp/bloggames/');
__PACKAGE__->models([
    [ { type => 'start', name => 'script',
    attr => {
        type     => 'text/javascript',
        charset  => 'UTF-8',
	language => 'javascript',
        src      => qr{http://www[.]shockwave[.]co[.]jp/bloggame/blogame[.]php[?]idu=[A-Za-z0-9+/=]+&dtreg=[A-Za-z0-9+/=]+&typ=(?:s|e)&nmgb=[A-Za-z0-9+/=]+},
    }},
      { type => 'end', name=>'script' } ],
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::ShockwaveBloggames


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'ShockwaveBloggames' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate ShockeWave's Bloggames widgets.


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.shockwave.co.jp/bloggames/>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
