package HTML::WidgetValidator::Widget::BlogPet;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;
use Carp;

__PACKAGE__->name('BlogPet');
__PACKAGE__->url('http://www.blogpet.net/');
__PACKAGE__->models([
    [ { type => 'start', name => 'script', 
	attr => {
	    language => 'JavaScript',
	    charset  => 'UTF-8',
	    type     => 'text/javascript',
	    src      => qr{http://www\.blogpet\.net/js/[0-9A-Fa-f]+\.js},
	}},
      { type => 'end', name=>'script' } ],

]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::BlogPet


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'BlogPet' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate widget "BlogPet".


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.blogpet.net/>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
