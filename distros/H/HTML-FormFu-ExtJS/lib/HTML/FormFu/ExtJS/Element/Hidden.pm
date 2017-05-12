#
# This file is part of HTML-FormFu-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package HTML::FormFu::ExtJS::Element::Hidden;
BEGIN {
  $HTML::FormFu::ExtJS::Element::Hidden::VERSION = '0.090';
}

use base "HTML::FormFu::ExtJS::Element::_Field";

use strict;
use warnings;
use utf8;


sub render {
	my $class = shift;
	my $self = shift;
	my $super = $class->SUPER::render($self);
	return { %{$super}, xtype => "hidden" };
	
	
}

sub column_model {
	my $class = shift;
	my $self = shift;
	my $super = $class->SUPER::column_model($self);
	return {%{$super}, hidden => \1 };
}

1;
__END__
=pod

=head1 NAME

HTML::FormFu::ExtJS::Element::Hidden

=head1 VERSION

version 0.090

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

