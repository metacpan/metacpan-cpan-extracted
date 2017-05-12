package HTML::WidgetValidator::Widget::Playlog;
use base qw(HTML::WidgetValidator::Widget);
use strict;
use warnings;

__PACKAGE__->name('Playlog');
__PACKAGE__->url('http://playlog.jp/bp/showEntryForm?siteType=outside');
__PACKAGE__->models([
    [
	{ type => 'start', name => 'script',
	  attr => {
	      language => 'JavaScript',
	      src      => qr{http://playlog[.]jp/bp/js/\d+/[0-9A-Za-z]{32}.js},
	  }},
	{ type => 'end', name=>'script' }
    ],
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::Playlog


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'Playlog' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate "Playlog" Widget.


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://playlog.jp/bp/showEntryForm?siteType=outside>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
