package HTML::WidgetValidator::Widget::TsukumoRanking;
use strict;
use warnings;
use base qw(HTML::WidgetValidator::Widget);

__PACKAGE__->name('TSUKUMO Ranking');
__PACKAGE__->url('http://labs.tsukumo.co.jp/2007/08/post_3.html');
__PACKAGE__->models([
   [
      {
         "name" => "script",
         "type" => "start",
         "attr" => {
            "src"  => "http://shop.tsukumo.co.jp/blogparts/ranking/runner.js",
            "type" => "text/javascript"
         }
      },
      {
         "name" => "script",
         "type" => "end"
      }
   ]
]);

1;

__END__

=head1 NAME

HTML::WidgetValidator::Widget::TsukumoRanking


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'TsukumoRanking' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate TSUKUMO Ranking Widget.


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://labs.tsukumo.co.jp/2007/08/post_3.html>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
