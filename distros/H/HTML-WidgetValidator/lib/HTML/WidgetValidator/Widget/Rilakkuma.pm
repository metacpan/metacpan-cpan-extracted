package HTML::WidgetValidator::Widget::Rilakkuma;
use base qw(HTML::WidgetValidator::Widget);
use strict;
use warnings;

__PACKAGE__->name('Rilakkuma');
__PACKAGE__->url('http://www.san-xchara.jp/setting_tag.php');
__PACKAGE__->models([
    [
	{ type => 'start', name => 'script',
	  attr => {
	      language => 'JavaScript',
	      type     => 'text/javascript',
	      src      => qr{http://www[.]san-xchara[.]jp/js/[0-9a-zA-Z]{32}.js},
	  }},
	{ type => 'end', name=>'script' }
    ],
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::Rilakkuma


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'Rilakkuma' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate San-X "Rilakkuma" widget.


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.san-xchara.jp/setting_tag.php>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
