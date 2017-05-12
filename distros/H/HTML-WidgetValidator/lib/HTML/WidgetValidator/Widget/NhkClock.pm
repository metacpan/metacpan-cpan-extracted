package HTML::WidgetValidator::Widget::NhkClock;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;

__PACKAGE__->name('NHK CLOCK');
__PACKAGE__->url('http://www.nhk.or.jp/lab-blog/02/1066.html');
__PACKAGE__->models([
    [
        { type => 'start', name => 'script',
          attr => {
              src      => qr{http://www[.]nhk[.]or[.]jp/lab-blog/blogtools/script/clock(?:150|210)(?:wood)?.js},
              type     => 'text/javascript',
              language => 'javascript',
          }
        },
        { type => 'end', name => 'script' }
    ]
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::NhkClock


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'NhkClock' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate "NHK CLOCK" widgets.


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.nhk.or.jp/lab-blog/02/1066.html>


=head1 AUTHOR

Yasuhiro Onishi, E<lt>onishi@hatena.ne.jpE<gt>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
