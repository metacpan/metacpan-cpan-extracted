#
# This file is part of HTML-FormFu-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package HTML::FormFu::ExtJS::Element::ExtJS::Panel;
BEGIN {
  $HTML::FormFu::ExtJS::Element::ExtJS::Panel::VERSION = '0.090';
}

use strict;
use warnings;
use utf8;

use HTML::FormFu::Util qw(
    xml_escape
);


sub render {
	my $class  = shift;
	my $self   = shift;

	my $parent = $self->can("_get_attributes") ? $self : $self->form;
    my $title = $self->title || $self->label;

	return {
        xtype => $self->xtype,
		$title ? (title => xml_escape( $title )) : (),
		(scalar $self->id) ? (id => scalar $self->id) : (),
        items => $self->form->_render_items( $self ),
		$parent->_get_attributes( $self )
	};
}

1;

__END__
=pod

=head1 NAME

HTML::FormFu::ExtJS::Element::ExtJS::Panel

=head1 VERSION

version 0.090

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

