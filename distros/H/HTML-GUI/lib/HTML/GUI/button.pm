package HTML::GUI::button;

use warnings;
use strict;

=head1 NAME

HTML::GUI::button - Create and control a button input for webapp

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


use HTML::GUI::input;
our @ISA = qw(HTML::GUI::input);

=head1 BUTTON

The button widget is the specialisation of the input 

=cut


=head1 PUBLIC ATTRIBUTES

=pod 

=cut
#array of string : list of all specifric public properties of the widget
my @GHW_publicPropList = qw/nextScreen btnAction/;


=head1 PUBLIC METHODS

=pod 

=head3 new

   Parameters :
      params : widget : 

=cut

sub new
{
  my($class,
     $params, # widget : 
    ) = @_;
		$params->{type} = "button";
		my $this = $class->SUPER::new($params);
		if (!$this){
				return undef;
		}
		#default value, means we stay on the
		#same screen
		$this->{nextScreen} = '';
		#by default, no work to do
		$this->{btnAction} = '';
		$this->{btnActionFunc} = undef;
 bless($this, $class);
 if (exists $params->{nextScreen}){
		$this->setProp({'nextScreen',$params->{nextScreen}});
 }
 if (exists $params->{btnAction}){
		$this->setProp({'btnAction',$params->{btnAction}});
 }
 return $this;
}



=pod 

=head3 setProp

   Description :
      specialized version of widget::setProp for managing
			functions associated qith the button

=cut
sub setProp
{
  my($self,
     $params, # hash ref : defines params value
    ) = @_;

		if (exists $params->{btnAction} 
				&& $params->{btnAction}){
				my $functionRef = $self->getFunctionFromName($params->{btnAction});
				if ($functionRef){
						$self->{btnActionFunc} = $functionRef;
				}
		}
		$self->SUPER::setProp($params);
}

=head3 getPubPropHash

   Returns :
      propHash : hash : a hash containing the value '1' pour each public propertie


=cut

my $pubPropHash = undef;
sub getPubPropHash
{
 my($self) = @_;

 return $pubPropHash if (defined $pubPropHash);
 my $widgetPropRef = $self->SUPER::getPubPropHash();

 #we want a deep copy of the hash
 my %btnProp = %$widgetPropRef;
 $btnProp{nextScreen} = 1;
 $btnProp{btnAction}  = 1;
 $btnProp{btnActionFunc}  = 1;
 
 $pubPropHash = \%btnProp;
 return $pubPropHash;
}

=pod 

=head3 getDefinitionData
  
  This method is the specialisation of the widget.pm method, refer to the widget.pm manual for more information.

=cut

sub getDefinitionData($)
{
  my ($self) = @_;

		my $publicProperties = $self->SUPER::getDefinitionData();
		 
		return $self->SUPER::getDefinitionData($publicProperties,
														undef,\@GHW_publicPropList);
}

=pod 

=head3 setLabel

   Parameters :
		 The new label of the button 

   Return : 
     nothing 

   Description : 
      The label of a button is also it's value

=cut

sub setLabel
{
  my($self,$newValue) = @_;
	$self->setValue($newValue);
}

=pod 

=head3 getHtml

   Description : 
      Return the html of the widget.

=cut

sub getHtml
{
  my($self) = @_;
	my %tagProp=();
	my %styleProp=();
  

	if (exists $self->{display} && 0==$self->{display}){
		$styleProp{display} = 'none';
	}

	$tagProp{style} = $self->getStyleContent(\%styleProp);
	$tagProp{type} = 'submit';
	$tagProp{name} = $tagProp{id} = $self->{id};
  $tagProp{value} = $self->getValue();
  $tagProp{class} = 'btn';

  return $self->getHtmlTag("input", \%tagProp) ;
}

=head3 fired
   
	 Parameters :
		 $params : the hash ref containing the POST key-value pairs.

   Decription :
		 Return TRUE if the current button was fired by the user

   Returns :
      - 1 if the current button was fired
			- 0 otherwise

=cut
sub fired
{
  my($self,$params) = @_;

	my $id = $self->getId();

	if (exists $params->{$id} && defined $params->{$id}){
		return 1;
	}
	return 0;
}

=head1 AUTHOR

Jean-Christian Hassler, C<< <jhassler at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gui-libhtml-button at rt.cpan.org>, or through the web interface at
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

1; # End of HTML::GUI::button
