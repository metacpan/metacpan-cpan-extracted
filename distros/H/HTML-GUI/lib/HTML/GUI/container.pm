package HTML::GUI::container;

use warnings;
use strict;

=head1 NAME

HTML::GUI::container - Create and control a whole container for web application

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use HTML::GUI::widget;
use UNIVERSAL qw(isa);
our @ISA = qw(HTML::GUI::widget);
use Log::Log4perl qw(:easy);



=head1 CONTAINER

Manage a container : it loads its definition with a YAML file and create all the widgets it contains.
It can generate javascript code to check constraints on the web page.
It can test if constraints of each widget are OK.
It can generate the HTML of each widget for use with HTML::Template.


=cut



=head1 PUBLIC METHODS

=pod 

=head3 new

  create a new container

=cut

sub new
{
  my($class, $params) = @_;

	 my $this = $class->SUPER::new($params);
	 return undef unless defined $this;

   $this->{widgets} = [];
   $this->{index} = {$this->getId() => $this};# an index of all widget ids
   
	 bless($this, $class);
	 if (exists $params->{childs} && ref $params->{childs} eq 'ARRAY'){
		 foreach my $widgetDefinition (@{$params->{childs}}){
				$this->addChild($widgetDefinition);
		 }
	 }
	 return $this;
}

=head3 addChild

   Parameters :
      widget_def : hash ref : Parameters to define the widget inside the container.
The same parameters as to create a a widget but you can specify the cloneID (the id of the widget you want to clone from).

   Return : 
      

   Description : 
      Create and add a widget to the container

=cut

sub addChild
{
  my($self,
     $widget_def, # hash ref : Parameters to define the widget inside the container.
								 #The same parameters as to create a widget object 
								 # but you can specify the cloneID 
								 # (the id of the widget you want to clone from).
								 # $widget_def can also a widget object
    ) = @_;

		my $widget = undef;
		SWITCH:	{
		  if (isa($widget_def,'HTML::GUI::widget')){
				$widget = $widget_def;
				last SWITCH;
			}
			$widget = HTML::GUI::widget->instantiate($widget_def);
			last SWITCH;
		}
		if (!defined $widget){
				die "Impossible to define the widget";
		}

		#get the list of the ids existing in the new widget
		my @ids_list = $widget->getIds();

		foreach my $id (@ids_list){
			if ($id ne '' && exists $self->{index}{$id} ){
				$self->error({visibility => 'pub',
						'error-type' => 'internal',
						'message' => "An internal error occured while generating the screen."
												  ." Report your problem to the technical support."	,
		    		});
				ERROR "Impossible to add the child [$id]. Each widget id MUST be unique.";
				return;
			}
		}
	  push @{$self->{widgets}} , $widget;

		foreach my $id (@ids_list){
		  #the widget with a void id are ignored
			$self->setIndex($widget->getElementById($id)) unless $id eq '';
		}
		$widget->setParent($self);
		
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
	foreach my $widget (@{$self->{widgets}}){
	  push @widgetsDefinitionList, $widget->getDefinitionData();	
	}
	$publicProp->{childs} = \@widgetsDefinitionList;

	return $publicProp;
}

=pod 

=head3 getIds

   Return : 
				array

   Description : 
      return an array of the ids of the widgets which belong
			to the container. 

=cut

sub getIds
{
  my($self) = @_;
	if (!defined $self->{parent}){
	 return (keys %{$self->{index}});
	}else{
    my @idList = ();
		foreach my $widget (@{$self->{widgets}}){
				push @idList, $widget->getIds();
		}
	}
  
}

=pod 

=head3 setIndex

   Parameters :
      $widget : widget objet : the object to add to the index.

   Description : 
		  update the index of the container and all of its parents in order to have all indexes "up-to-date"


=cut

sub setIndex
{

  my($self,$newWidget) = @_;

	my $id = $newWidget->getId();
	$self->{index}{$id} = $newWidget;

	if (defined $self->{parent}){
		$self->{parent}->setIndex($newWidget);
	}
}

=pod 

=head3 getElementById

   Parameters :
      id : string : id of the object to find.

   Description : 
				return the objet widget whose id is $id or undef if no object has this id


=cut

sub getElementById
{

  my($self,$id) = @_;

	return undef unless (exists $self->{index}{$id});
	return $self->{index}{$id};
}


=pod 

=head3 setDefaultField

   Parameters :
      widgetObj : widget : The widget objet you want to use as a default widget.

   Return : 
      

   Description : 
			The default widget defined with this function will be used anytime your create a new widget without specifiing options.
      

=cut

sub setDefaultField
{
  my($self,
     $widgetObj, # widget : The widget objet you want to use as a default widget.
    ) = @_;
#UML_MODELER_BEGIN_PERSONAL_CODE_setDefaultField
#UML_MODELER_END_PERSONAL_CODE_setDefaultField
}


=pod 


=pod 

=head3 ListError

   Return : 
      string

   Description : 
      Return a string describing all the public errors that occured in all the widget objects in order to explain to the user why his input cannot be recorded.

=cut

sub ListError
{
  my($self    ) = @_;
#UML_MODELER_BEGIN_PERSONAL_CODE_ListError
#UML_MODELER_END_PERSONAL_CODE_ListError
}


=pod 

=head3 validate

   Return : 
				return 1 if no field of the container break no constraint
				return 0 if one or more field break constraint

=cut

sub validate
{
  my($self) = @_;
	my $OK = 1;
	foreach my $widget (@{$self->{widgets}}){
		 if ( !$widget->validate()){
				$OK = 0;
		 }
	}
	return $OK;
}

=head3 getFiredBtn
   
	 Parameters :
		 $params : the hash ref containing the POST key-value pairs.

   Description :
			Find the button the user clic (if one button was fired)

   Returns :
      - The button object which was fired
			- undef if no button was fired

=cut
sub getFiredBtn
{
  my($self,$params) = @_;
	foreach my $key (keys %{$self->{index}}){

			my $widget = $self->{index}{$key};
			if ($widget->fired($params)){
				return $widget;
			}
	}
	return undef;
}

=pod 

=head3 getValueHash

		Description : 
				get all the values stored in the container
		Return : 
				a ref to a hash containing the value associated to each input id

=cut

sub getValueHash
{
  my($self) = @_;
	my %values=();
	foreach my $widget (@{$self->{widgets}}){
		 my $widgetValues = $widget->getValueHash();
		 if ($widgetValues){
				 foreach my $key (keys %$widgetValues){
						$values{$key} =$widgetValues->{$key};
				 }
		 }
	}
	return \%values;
}

=pod 

=head3 setValueFromParams

		Description : 
				set the value of the widgets of the container for which a value fits in $params hash;
		Return : 
				nothing

=cut

sub setValueFromParams
{
  my($self,$params) = @_;
	foreach my $widget (@{$self->{widgets}}){
		if (isa($widget,'HTML::GUI::input')
				||isa($widget,'HTML::GUI::container')){
		 $widget->setValueFromParams($params);
 }
	}
}

=pod 

=head3 setValue

		Description : 
				set the value of the widgets of the container for which a value fits in $params hash; 
		
		Parameters :
				$valueHash : a hash ref of the same form as the function getValueHash returns

		Return : 
				nothing

=cut

sub setValue
{
  my($self,$valueHash) = @_;
	foreach my $key (keys %{$valueHash}){
		if (exists $self->{index}{$key}){
				my $widget = $self->{index}{$key};	
				$widget->setValue($valueHash->{$key});
		}
	}
}


=head3 getHtml

   Return : 
      a string containing the html of the widget contained in the container.

=cut

sub getHtml
{
  my($self    ) = @_;
	my $html = "";
	foreach my $widget (@{$self->{widgets}}){
			$html .= $widget->getHtml();
	}
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
C<bug-gui-libhtml-container at rt.cpan.org>, or through the web interface at
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

1; # End of HTML::GUI::container
