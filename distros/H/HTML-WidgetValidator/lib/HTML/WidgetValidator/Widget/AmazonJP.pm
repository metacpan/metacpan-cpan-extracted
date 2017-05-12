package HTML::WidgetValidator::Widget::AmazonJP;
use base qw(HTML::WidgetValidator::Widget);
use strict;
use warnings;

__PACKAGE__->name('AmazonJP');
__PACKAGE__->url('http://www.amazon.com/');
__PACKAGE__->models([
    [
        { type => 'start', name => 'iframe',
          attr => {
              src          => qr{http://rcm-jp\.amazon\.co\.jp/e/cm\?t=[A-Za-z0-9\-]+?&o=9&p=\d{1,2}?&l=(?:st1|bn1)&mode=[a-z\-]+?(?:&search=[A-Za-z0-9\-\.\_%]+?|&browse=\d+?)(?:&nou=1)?&fc1=[A-F0-9]{6}&lt1=(?:|_blank|_top)&lc1=[A-F0-9]{6}&bg1=[A-F0-9]{6}(?:&npa=1)?&f=ifr},
              marginwidth  => '0',
              marginheight => '0',
              width        => qr{\d{2,3}},
              height       => qr{\d{2,3}},
              border       => '0',
              frameborder  => '0',
              style        => 'border:none;',
              scrolling    => 'no',
          }},
        { type => 'end', name => 'iframe' }
    ],
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::AmazonJP


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'AmazonJP' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate widget "Amazon Live Link"


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.amazon.com/>


=head1 AUTHOR

Tetsuya Toyoda, E<lt>aql@hatena.ne.jpE<gt>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
