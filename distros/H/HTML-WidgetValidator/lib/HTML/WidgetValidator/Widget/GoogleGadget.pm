package HTML::WidgetValidator::Widget::GoogleGadget;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;
use Carp;

__PACKAGE__->name('Google Gadget');
__PACKAGE__->url('http://www.google.com/ig/directory?synd=open');
__PACKAGE__->models([
    [ { type => 'start', name=>'script', 
	attr => {
	    src => qr{http:\/\/gmodules\.com\/ig\/ifr\?url=http:\/\/[^"<>]+&(?:amp;)?synd=open&(?:amp;)?w=\d{1,3}&(?:amp;)?h=\d{1,3}&(?:amp;)?title=[^"&<>]*&(?:amp;)?(?:lang=\w+&(?:amp;)?)?(?:country=\w+&(?:amp;)?)?border=[^"&<>]+&(?:amp;)?output=js},
	}},
      { type => 'end', name=>'script' } ],

]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::GoogleGadget


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'GoogleGadget' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate Google Gadget.


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.google.com/ig/directory?synd=open>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
