#
# This file is part of HTML-FormFu-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package HTML::FormFu::ExtJS::Element::SimpleTable;
BEGIN {
  $HTML::FormFu::ExtJS::Element::SimpleTable::VERSION = '0.090';
}

use strict;
use warnings;
use utf8;

sub render {
	my $class = shift;
	my $self  = shift;
	my @header;
	my @rows;
	my $columns = 0;
	foreach my $element ( @{ $self->get_elements } ) {
		$columns = 0;
		foreach my $row ( @{ $element->get_elements } ) {
			if ( $row->tag eq "th" ) {
				push(
					@header,
					{
						xtype  => 'label',
						text   => scalar $row->{content},
						cls    => 'x-form-check-group-label',
						anchor => '-15',
					}
				);
			} elsif ( $row->tag eq "td" ) {
				push( @rows, @{ $self->form->_render_items($row) } );
				$columns++;
			}
		}
	}
	my $data;
	my $width = 1 / $columns;
	foreach my $i ( 0 .. $columns ) {
		my $column = { columnWidth => $width, layout => "form", items => [ ] };
		push( @{ $column->{items} }, $header[$i] ) if($header[$i]);
		foreach my $j ( 0 .. @rows - 1 ) {
			next unless ( $j % $columns == $i );
			push( @{ $column->{items} }, $rows[$j] );
		}
		push( @{$data}, $column );
	}
	pop( @{$data} );
	return { layout => "column", items => $data };
}
1;



__END__
=pod

=head1 NAME

HTML::FormFu::ExtJS::Element::SimpleTable

=head1 VERSION

version 0.090

=head1 DESCRIPTION

This element renders a simple table using ExtJS column layout. There is no
way to influence the width etc. of each column. They get distributed equally.

To create layouts with individual width and styles see L<HTML::FormFu::ExtJS::Element::Multi>.

=head1 NAME

HTML::FormFu::ExtJS::Element::SimpleTable - Simple table layout

=head1 SEE ALSO

L<HTML::FormFu::Element::Multi>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Moritz Onken, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

