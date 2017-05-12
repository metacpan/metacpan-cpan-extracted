package HTML::GUI::table::basic;

use warnings;
use strict;

=head1 NAME

HTML::GUI::table::basic - Create and control a whole table::basic for web application

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use HTML::GUI::widget;
use UNIVERSAL qw(isa);
our @ISA = qw(HTML::GUI::widget);
use Log::Log4perl qw(:easy);



=head1 TABLE::BASIC

A simple object to create tables

=cut



=head1 PUBLIC METHODS

=pod 

=head3 new

  create a new table::basic

=cut

sub new
{
  my($class, $params) = @_;

	 my $this = $class->SUPER::new($params);
	 return undef unless defined $this;

	 bless($this, $class);
	 return $this;
}



=pod

=head3 getDefinitionData

		Specialization of the widget.pm function

=cut
sub getDefinitionData($;$$$)
{
  my ($self,$paramPublicProp,$paramDefaultValue, $paramPublicPropList) = @_;
  
	my @widgetsDefinitionList = () ;

  my $publicProp = $self->SUPER::getDefinitionData($paramPublicProp,$paramDefaultValue, $paramPublicPropList);

	return $publicProp;
}


=pod 

=head3 validate

   Return : 
				return 1 if no field of the table::basic break no constraint
				return 0 if one or more field break constraint

=cut

sub validate
{
  my($self) = @_;
	my $OK = 1;
	return $OK;
}


=pod 

=head3 getValueHash

		Description : 
				get all the values stored in the table::basic
		Return : 
				a ref to a hash containing the value associated to each input id

=cut

sub getValueHash
{
  my($self) = @_;
	my %values=();
	return \%values;
}

=pod 

=head3 setValueFromParams

		Description : 
				set the value of the widgets of the table::basic for which a value fits in $params hash;
		Return : 
				nothing

=cut

sub setValueFromParams
{
  my($self,$params) = @_;
#	TODO !!
}

=pod 

=head3 setValue

		Description : 
				set the value of the widgets of the table::basic for which a value fits in $params hash; 
		
		Parameters :
				$valueHash : a hash ref of the same form as the function getValueHash returns

		Return : 
				nothing

=cut

sub setValue
{
  my($self,$valueHash) = @_;
#	TODO !!
}


=head3 getHtml

   Return : 
      a string containing the html of the widget contained in the table::basic.

=cut

sub getHtml
{
  my($self    ) = @_;
	my $html = "";
	return $html;
}

=pod

=head3 DESTROY
  The destructor to erase the ref to the parent 
	and avoid cycle references

=cut

sub DESTROY
{
  my($self    ) = @_;
  
	delete $self->{parent};
}

=head1 AUTHOR

Jean-Christian Hassler, C<< <jhassler at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gui-libhtml-table::basic at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-GUI-widget>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::GUI::widget

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-GUI-widget>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-GUI-widget>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-GUI-widget>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-GUI-widget>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jean-Christian Hassler, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of HTML::GUI::table::basic
