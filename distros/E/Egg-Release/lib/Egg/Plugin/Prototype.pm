package Egg::Plugin::Prototype;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Prototype.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use base 'Class::Data::Inheritable';
use HTML::Prototype;

our $VERSION = '3.00';

__PACKAGE__->mk_classdata('prototype');
eval { require HTML::Prototype::Useful; };

if ( $@ ) {
    __PACKAGE__->prototype( HTML::Prototype->new );
} else {
    __PACKAGE__->prototype( HTML::Prototype::Useful->new );
}

1;

__END__

=head1 NAME

Egg::Plugin::Prototype - Plugin for Prototype

=head1 SYNOPSIS

  # use it
  use Egg qw/ Prototype /;

  # ...add this to your mason template...
  <% $e->prototype->define_javascript_functions %>

  # ...and use the helper methods...
  <div id="view"></div>
  <textarea id="editor" cols="80" rows="24"></textarea>
  % my $uri = $e->config->{static_uri}. 'edit/'. $e->page_title;
  <% $e->prototype->observe_field( 'editor', $uri, { 'update' => 'view' } ) %>

=head1 DESCRIPTION

Some stuff to make Prototype fun.

This plugin replaces L<Egg::Helper::Plugin::Prototype>.

=head1 METHODS

=head2 prototype

Returns a ready to use L<HTML::Prototype> object.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Helper::Plugin::Prototype>,
L<Catalyst::Plugin::Prototype>,

=head1 AUTHOR

This code is a transplant of 'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>'
of the code of 'L<Catalyst::Plugin::Prototype>'.

Therefore, the copyright of this code is assumed to be the one that belongs
to 'Sebastian Riedel, C<sri@oook.de>'.

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

