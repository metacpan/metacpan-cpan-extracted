#
# This file is part of HTML-FormFu-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package HTML::FormFu::ExtJS::Element::_Group;
BEGIN {
  $HTML::FormFu::ExtJS::Element::_Group::VERSION = '0.090';
}

use base "HTML::FormFu::ExtJS::Element::_Field";

use strict;
use warnings;
use utf8;

use HTML::FormFu::ExtJS::Util qw(
    _camel_case
    _css_case
);


sub _items {
	my $class = shift;
	my $self = shift;
	
	my $data = [];
	foreach my $option ( @{ $self->render_data->{options} } ) {

		#push( @{$data}, [ $option->{value}, $option->{label} ] );
		if ( $option->{group} && (my @items = @{ $option->{group} }) ) {
			my $subgroup = {
				%{$option->{attributes}},
				items => [{
				xtype  => 'label',
				text   => $option->{label},
				cls    => 'x-form-check-group-label',
				anchor => '-15',
				$option->{attributes}->{label} ? %{$option->{attributes}->{label}} : ()
				}
			]};
			foreach my $item ( @items ) {
				push(
					@{ $subgroup->{items} },
					{
						boxLabel   => $item->{label},
						name       => $self->name,
						inputValue => $item->{value},
						%{$item->{attributes}},
					}
				);
			}
			push( @{ $data }, $subgroup );
		} else {
					push(@{ $data },
					{
						boxLabel   => $option->{label},
						name       => $self->name,
						inputValue => $option->{value},
						%{$option->{attributes}}
					}
				);
		}
	}
	#use Data::Dumper; print Dumper $self->_options;
	return $data;
}

sub column_model {
	my $class = shift;
	my $self = shift;
	my $super = $class->SUPER::column_model($self);
	my $name = $self->nested_name;
	
    return ({%{$super}, id => _css_case($name)."-value", dataIndex => _camel_case($name).'Value', hidden => \1 },
            {%{$super}, id => _css_case($name), dataIndex => _camel_case($name) });
	
}

sub record {
	my $class = shift;
	my $self = shift;
	my $super = $class->SUPER::record($self);
	my $name = $self->nested_name;
	return ({%{$super}, name => _camel_case($name)."Value", mapping => $self->nested_name.'.value' },
			{%{$super}, name => _camel_case($name), mapping => $self->nested_name.'.label' });
	
}




1;
__END__
=pod

=head1 NAME

HTML::FormFu::ExtJS::Element::_Group

=head1 VERSION

version 0.090

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

