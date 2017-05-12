#
# This file is part of HTML-FormFu-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package HTML::FormFu::ExtJS::Element::DateTime;
BEGIN {
  $HTML::FormFu::ExtJS::Element::DateTime::VERSION = '0.090';
}
use base "HTML::FormFu::ExtJS::Element::_Field";

use HTML::FormFu::ExtJS::Element::Select;
use HTML::FormFu::ExtJS::Element::Date;

use strict;
use warnings;
use utf8;


sub render {
	my $class = shift;
	my $self  = shift;
	$self->process;
	$self->deflator({ type => 'Strftime', strftime => '%FT%T%Z'});
	$self->strftime('%FT%T%Z');
	my @value;
	for(1..3) {
		push(@value, sprintf("%02d", $self->get_element->default));
		$self->remove_element( $self->get_element );
	}
	my $date = $self->form->element({type => "Date", value => join('-', @value) });
	my $data = [HTML::FormFu::ExtJS::Element::Date->render($date)];
	for(1..2) {
	    my $element = $self->get_element;
    	$element->attrs->{width} = 50;
    	push(@$data, HTML::FormFu::ExtJS::Element::Select->render( $element ));
    	$self->remove_element( $element );
    }
    
    unshift(@$data, { fieldLabel => $self->label, xtype => "textfield", hidden => \1})
        if($self->label);
    $data = [map { { layout => 'form', items => $_ } } @$data];
    
	
    return { layout => "form", items => [ { layout => "column", items => $data } ] };
}

sub record {
	my $class = shift;
	my $self = shift;
	my $super = $class->SUPER::record($self, @_);
	return {%{$super}, type => "date", dateFormat => 'c'}
}

sub column_model {
	my $class = shift;
	my $self = shift;
	my $super = $class->SUPER::column_model($self, @_);
	my $format = $self->attrs->{dateFormat} || $self->attrs_xml->{dateFormat} || 'c';
	return {%{$super}, renderer => \('Ext.util.Format.dateRenderer("'.$format.'")') }
}

1; 



=pod

=head1 NAME

HTML::FormFu::ExtJS::Element::DateTime

=head1 VERSION

version 0.090

=head1 DESCRIPTION

You cannot put this element in a multi element because it is one itself.

=head2 column_model

To change the format of the date object specify C<< $element->attrs->{dateFormat} >>.
The date parsing and format syntax is a subset of PHP's date() function.
See L<http://extjs.com/deploy/dev/docs/?class=Date> for details.
It defaults to C<Y-m-d G:i> (which is the same as Perl's C<%Y-%m-%d %R>).

=head1 NAME

HTML::FormFu::ExtJS::Element::DateTime - DateTime element

=head1 SEE ALSO

L<HTML::FormFu::Element::DateTime>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Moritz Onken, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

