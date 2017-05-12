package HTML::WidgetValidator::Widget::Paolo;
use strict;
use warnings;
use base qw(HTML::WidgetValidator::Widget);

our $VERSION = '0.01';

__PACKAGE__->name('Paolo');
__PACKAGE__->url('http://www.blogdeco.jp/paolo/tag.php');
__PACKAGE__->models([
   [
      {
         "name" => "script",
         "type" => "start",
         "attr" => {
            "src" => qr{http://paolo\.blogdeco\.jp/js/paolo\.js#\d+},
            "charset" => "utf-8",
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

HTML::WidgetValidator::Widget::Paolo

=head1 SYNOPSIS

  my $validator = HTML::WidgetValidator->new(widgets => [ 'Paolo' ]);
  my $result = $validator->validate($html);

=head1 DESCRIPTION

Validate widget "Paolo"

=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.blogdeco.jp/paolo/tag.php>

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentaro@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See perlartistic.

=cut
