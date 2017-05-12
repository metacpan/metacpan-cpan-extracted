#
# This file is part of HTML-FormFu-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package HTML::FormFu::ExtJS::Element::Date;
BEGIN {
  $HTML::FormFu::ExtJS::Element::Date::VERSION = '0.090';
}

use base "HTML::FormFu::ExtJS::Element::_Field";

use strict;
use warnings;
use utf8;

sub render {
	my $class = shift;
	my $self = shift;
	$self->_date_defaults;
	$self->strftime('%Y-%m-%d');
	$self->default(sprintf("%04s-%02s-%02s", $self->year->{default},$self->month->{default},$self->day->{default}))
	if((defined $self->default || defined $self->default_natural) && $self->year->{default} && $self->month->{default} && $self->day->{default});
	my $super = $class->SUPER::render($self);
	return { %{$super}, xtype => "datefield" };
	
	
}

sub record {
	my $class = shift;
	my $self = shift;
	use Data::Dumper; $Data::Dumper::Indent = 1; warn Dumper $self unless($self->name);
	my $super = $class->SUPER::record($self, @_);
	return {%{$super}, type => "date", dateFormat => 'Y-m-d'}
}

sub column_model {
	my $class = shift;
	my $self = shift;
	my $super = $class->SUPER::column_model($self, @_);
	my $format = $super->{dateFormat} || 'Y-m-d';
	return {%{$super}, renderer => \('Ext.util.Format.dateRenderer("'.$format.'")') }
}


1;


__END__
=pod

=head1 NAME

HTML::FormFu::ExtJS::Element::Date

=head1 VERSION

version 0.090

=head1 DESCRIPTION

C<dateFormat> (L<http://extjs.com/deploy/dev/docs/?class=Ext.form.DateField>) is set to C<Y-m-d>.
This is the internal representation of a date and this value will be send to the server on submit.

C<strftime> is set to C<%Y-%m-%d>, which is C<%F> the ISO 8601 date format. This is the format for default values.

By default the localozation of ExtJS will do the job and transform this internal value
to a more readable version depending on your locale.

=head2 column_model

To change the format of the date object specify C<< $element->attrs->{dateFormat} >>.
The date parsing and format syntax is a subset of PHP's date() function.
See L<http://extjs.com/deploy/dev/docs/?class=Date> for details.
It defaults to C<Y-m-d> (which is the same as Perl's C<%Y-%m-%d>).

=head1 NAME

HTML::FormFu::ExtJS::Element::Date - Date element

=head1 SEE ALSO

L<HTML::FormFu::Element::Date>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Moritz Onken, all rights reserved.

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

