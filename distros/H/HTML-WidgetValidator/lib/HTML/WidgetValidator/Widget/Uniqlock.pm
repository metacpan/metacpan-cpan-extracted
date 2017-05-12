package HTML::WidgetValidator::Widget::Uniqlock;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;

__PACKAGE__->name('UNIQLOCK');
__PACKAGE__->url('http://www.uniqlo.jp/uniqlock/');
__PACKAGE__->models([
    [
        { type => 'start', name => 'script',
          attr => {
              src  => qr{http://www[.]uniqlo[.]jp/uniqlock/user/js/[0-9A-Za-z]{16}[.]js},
              type => 'text/javascript',
          }
        },
        { type => 'end', name => 'script' }
    ]
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::Uniqlock


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'Uniqlock' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate "Uniqlock" widgets.


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.uniqlo.jp/uniqlock/>


=head1 AUTHOR

Tetsuya Toyoda  C<< <aql@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
