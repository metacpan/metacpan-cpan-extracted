package HTML::WidgetValidator::Widget::Natalie;
use strict;
use warnings;
use base qw(HTML::WidgetValidator::Widget);

our $VERSION = '0.01';

__PACKAGE__->name('Natalie');
__PACKAGE__->url('http://natalie.mu/news/list');
__PACKAGE__->models([
   [
      {
         "name" => "script",
         "type" => "start",
         "attr" => {
            "src" => qr{http://natalie\.mu/widget/(?:news\?|hotnews\?|news\?category_id=[0-9]+|news\?artist_id=[0-9]+)},
            "charset" => "UTF-8",
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

HTML::WidgetValidator::Widget::Natalie

=head1 SYNOPSIS

  my $validator = HTML::WidgetValidator->new(widgets => [ 'Natalie' ]);
  my $result = $validator->validate($html);

=head1 DESCRIPTION

Validate widget "Natalie"

=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://natalie.mu/>

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentaro@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See perlartistic.

=cut
