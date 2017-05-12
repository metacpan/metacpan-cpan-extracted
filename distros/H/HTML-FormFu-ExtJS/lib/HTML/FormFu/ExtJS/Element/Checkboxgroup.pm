#
# This file is part of HTML-FormFu-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package HTML::FormFu::ExtJS::Element::Checkboxgroup;
BEGIN {
  $HTML::FormFu::ExtJS::Element::Checkboxgroup::VERSION = '0.090';
}

use base "HTML::FormFu::ExtJS::Element::_Group";

use strict;
use warnings;
use utf8;

sub render {
	my $class = shift;
	my $self  = shift;
	
	my $data = $class->_items($self);
	my $super = $class->SUPER::render($self);
	return { %{$super}, xtype => "checkboxgroup", items => $data };
}
1;

__END__
=pod

=head1 NAME

HTML::FormFu::ExtJS::Element::Checkboxgroup

=head1 VERSION

version 0.090

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

