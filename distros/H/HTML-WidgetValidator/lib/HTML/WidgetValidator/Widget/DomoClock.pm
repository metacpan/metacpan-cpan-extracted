package HTML::WidgetValidator::Widget::DomoClock;
use strict;
use warnings;
use base qw(HTML::WidgetValidator::Widget);

our $VERSION = '0.01';

__PACKAGE__->name('Domo Clock');
__PACKAGE__->url('http://www.domomode.com/japan.html');
__PACKAGE__->models([
   [
      {
         "name" => "script",
         "type" => "start",
         "attr" => {
            "src" => qr|http://www\.domomode\.com/blogparts/domo_clock\d{2}\.js|,
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

HTML::WidgetValidator::Widget::DomoClock

=head1 SYNOPSIS

  my $validator = HTML::WidgetValidator->new(widgets => [ 'DomoClock' ]);
  my $result = $validator->validate($html);

=head1 DESCRIPTION

Validate widget "Domo Clock"

=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.domomode.com/japan.html>

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentaro@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See perlartistic.

=cut
