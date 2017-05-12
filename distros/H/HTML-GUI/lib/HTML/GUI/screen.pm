package HTML::GUI::screen;

use warnings;
use strict;

=head1 NAME

HTML::GUI::screen - Create and control a whole screen for web application

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use HTML::Template;
use HTML::GUI::container;
use HTML::GUI::hidden;
use HTML::GUI::log::eventList;
use UNIVERSAL qw(isa);
our @ISA = qw(HTML::GUI::container);
use JSON;
use Log::Log4perl qw(:easy);



=head1 SCREEN

Manage a screen : it loads its definition with a YAML file and create all the widgets it contains.
It can generate javascript code to check constraints on the web page.
It can test if constraints of each widget are OK.
It can generate the HTML of each widget for use with HTML::Template.


=cut

# array of string : list of all public properties specific to a screen
my @publicPropList = qw/ path actionUrl nextScreen nextScreenParams 
												nextScreenType nextScreenValues session hsession 
												counter lastCounter parentScreenDesc loadNextScreen
												dialogCallBack openCallBack/;


=head1 PUBLIC METHODS

=pod 

=head3 new

  create a new screen

=cut

sub new
{
  my($class,$params,$path) = @_;

	my $this = $class->SUPER::new($params);
  return undef unless defined $this;

  $this->{type} = "screen";
  $this->{dialogCallBackFunc} = undef;
  $this->{openCallBackFunc} = undef;
	#default path to a screen is '/' (root directory)
  $this->setProp({	'path'=> defined $path ? $path : '/',
                    'nextScreen' => '',
                    'nextScreenParams' => {},
                    'nextScreenValues' => {},
										'parentScreenDesc' => $params->{parentScreenDesc} || '',
                    'session' => {}, 
                    'hsession' => {}, 
										'loadNextScreen' => 0,
										'dialogCallBack' => $params->{dialogCallBack} || '',
										'openCallBack' => $params->{openCallBack} || '',
								});
  if (!$this->getProp('actionUrl')){
		#default form action
		$this->setProp({'actionUrl'=>'/'})
	}

  bless($this, $class);
}


=pod 

=head3 setProp

   Description :
      specialized version of widget::setProp for managing
			functions associated with the screen

=cut
sub setProp
{
  my($self,
     $params, # hash ref : defines params value
    ) = @_;

		if (exists $params->{dialogCallBack}){
				$self->{dialogCallBackFunc} = $self->getFunctionFromName($params->{dialogCallBack});
		}
		if (exists $params->{openCallBack}){
				$self->{openCallBackFunc} = $self->getFunctionFromName($params->{openCallBack});
		}
		$self->SUPER::setProp($params);
}

=pod 

=head3 getJscript

   Parameters :

   Return : 
      string

   Description : 
      Return the javascript code to enforce the constraints of the widgets (describe each constraint for each widget); this code must be inserted in the header of the HTML page.

=cut

sub getJscript
{
  my($self    ) = @_;
#UML_MODELER_BEGIN_PERSONAL_CODE_getJscript
#UML_MODELER_END_PERSONAL_CODE_getJscript
}

=head3 getDescriptionDataFromParams

	 Description:
			Retrieve from the http form data the data describing the current screen

   Parameters :
      params : the hash containing the params retrieve from the HTTP form submit

   Return : 
      a hash ref containing the description data (screen name...)

=cut

sub getDescriptionDataFromParams
{
  my ($self,$params)=@_;

	my $descDataString = exists $params->{'GHW:screenDescription'} ? 
												$params->{'GHW:screenDescription'} : '{}';

	return  JSON::decode_json($descDataString);
}

=head3 getDescriptionFieldsHtml

   Return : 
      a string containing the html of the hidden fields containing usefull 
			data for describing the screen (for example, the name of the screen)
			To generate a valid Html document, we insert the the hidden field into
			an invisible div.

=cut

sub getDescriptionFieldsHtml
{
	my ($self)=@_;

	#we create a JSON string that contain all the usefull data we need for this screen
	my $descDataString = JSON::encode_json({screenName => $self->getProp('path'),
																		  counter		 => $self->getProp('counter')||'0'});

	my $descField = HTML::GUI::hidden->new({id		=> 'GHW:screenDescription',
																						value	=> $descDataString  });
	if (!$descField){
		return '';
	}else{
		return $self->getHtmlTag("div",{style=>'display:none'},
								$descField->getHtml());								
	}
}

=head3 getHtml

   Return : 
      a string containing the html of the webpage for the screen.

=cut

sub getHtml
{
  my($self    ) = @_;
	my $filename = $self->getPath()."templates/main.html";
	my $template = HTML::Template->new(filename => $filename);
  my $eventList = HTML::GUI::log::eventList::getCurrentEventList();
  my $screenHtml = $eventList->getHtml()
					.$self->SUPER::getHtml()
					.$self->getDescriptionFieldsHtml();
  $template->param( screen => $self->getHtmlTag('form',
										{action=> $self->getProp('actionUrl'),
										 method=>'post'},
										$screenHtml),
		css_path => [{url =>"/static/css/base.css"}]	);

	return $template->output;

}

=pod 

=head3 validate
   Description :
				Validate all the fields of a screen and store the result of 
				the validation

   Return : 
				return 1 if no field of the screen break no constraint
				return 0 if one or more field break constraint

=cut

sub validate
{
  my($self) = @_;
  my $eventList = HTML::GUI::log::eventList::getCurrentEventList();
	$eventList->forget();
	return $self->SUPER::validate();
}

=pod 

=head3 getPubPropHash

   Returns :
      propHash : hash : a hash containing the value '1' pour each public propertie

=cut

my $pubPropHash = undef;
sub getPubPropHash{
 my($self    ) = @_; 

 return $pubPropHash if (defined $pubPropHash);
 foreach my $propName(@publicPropList){
			$pubPropHash->{$propName} = 1;
 }
 return $pubPropHash;
}

=pod 

=head3 executeAction

   Parameters :
		- $actionFunction : the function to execute
		- $session : a hash ref to the session

   Description :
				Execute the function $actionFunction with the values of the screen

   Returns :
				
      

=cut
sub executeAction{
 my($self,$actionFunction) = @_;


 if (defined $actionFunction){
		&$actionFunction($self);
 }
 return $self;
}



=pod 

=head3 processHttpRequest

   Parameters :
		- $params : hash ref containing the POST data

   Description :
		- do all the stuff when a user press a buton

   Returns :
	 - the screen to display to the user ; it can be a new one if needed
      

=cut
sub processHttpRequest{
 my($self,$params) = @_;

		$self->setValueFromParams($params);

		my $btnFired = $self->getFiredBtn($params);
		if ($btnFired){
				my $nextScreenName = $btnFired->getProp('nextScreen');
				if ($nextScreenName){
						$self->setNextScreen($nextScreenName,undef,undef);
				}
				
				if ($btnFired->getProp('btnAction')){
						#We want to process data => we first validate it
						if ($self->validate()){
								#Data are OK for the GUI => call the controller
								#defined by the action button
								my $actionFunction = $btnFired->getProp('btnActionFunc');
								if ($actionFunction){
									$self->executeAction($actionFunction);
								}
								
						}
				}
		}
		return $self;
}

=pod

=head3 executeCallBackHandler

		Description
		 - execute the handler whose name is $handlerName on
		 the $newScreen object if the handle is defined.
		 When the handler is called, it is called with $params as parameters

=cut
sub executeCallBackHandler{
 my($self,$newScreen,$handlerName,$params) = @_;

 if ($newScreen->{$handlerName}){
		#activate the callback if it's defined
		$newScreen->{$handlerName}($newScreen,$params);
 }
}

=pod 

=head3 getNextScreen

   Description :
		- determine what is the next screen to display to the user and populate it with the messages and user data

   Returns :
	 - the screen to display to the user ; it can be a new one if needed
      

=cut
sub getNextScreen{
 my($self) = @_;

 my $newScreen = undef;
 my $nextScreenPath = $self->getProp('nextScreen');
 my $nextScreenValues = $self->getProp('nextScreenValues');

 if ( ! $self->getProp('loadNextScreen') ){
		#we want to stay on the same screen
		return $self;
 }
 $DB::single = 1;
 if ($self->getProp('nextScreenType') eq 'closeDialog'){
		$newScreen = HTML::GUI::widget->instantiateFromYAML( $self->getProp('parentScreenDesc'));
		$self->executeCallBackHandler($newScreen,'dialogCallBackFunc',$self->getProp('nextScreenParams'));
 }else{
		$newScreen = HTML::GUI::widget->instantiateFromFile($nextScreenPath);
		$self->executeCallBackHandler($newScreen,'openCallBackFunc',$self->getProp('nextScreenParams'));
 }
 if (!$newScreen){
		$self->error("Sorry, a technical problem occured : impossible to load the next screen. Please report this issue to the support.");
		return $self;
 }
 $newScreen->setProp({counter => $self->getProp('counter')});
 if ($nextScreenValues){
		$newScreen->setValue($nextScreenValues);
 }
 if ($self->getProp('nextScreenType') eq 'openDialog'){
		$newScreen->setProp({parentScreenDesc=>$self->serializeToYAML()});
 }

 return $newScreen;
}

=pod 

=head3 setNextScreen

   Parameters :
	  - $path	  : the path of the next screen
		- $params : hash ref containing the optional params to call the next screen (for example imagine the next screen is customer_info and the param is {customer_id => 254412}
		- $values : you can specify all the values you want to feed your screen (in the way you get the values from getValueHash() )

   Description :
		- determine what is the next screen to display to the user and populate it with the messages and user data

   Returns :
	 - the screen to display to the user ; it can be a new one if needed
      

=cut
sub setNextScreen{
 my($self,$path,$params,$values,$screenType) = @_;

  $screenType ||= 'screen';
  $self->setProp({nextScreen => $path,
								  nextScreenType => $screenType,
                  nextScreenParams => $params || {},
                  nextScreenValues => $values || {},
								  loadNextScreen		=> 1,
								});
}


=pod 

=head3 openDialog
   
	 Description :
		- define the next dialog to show to the end user. The difference between a dialog and a screen is that a dialog can be closed (like a popup window).

   Parameters :
	  - $path	  : the path of the next screen
		- $params : hash ref containing the optional params to call the next screen (for example imagine the next screen is customer_info and the param is {customer_id => 254412}
		- $values : you can specify all the values you want to feed your screen (in the way you get the values from getValueHash() )
=cut

sub openDialog(){
 my($self,$path,$params,$values) = @_;

 $self->setNextScreen($path,$params,$values,'openDialog');
}

=pod 

=head3 closeDialog
   
	 Description :
		- close the current dialog. MUST only be called on an dialog screen.

   Parameters :
		- $params : hash ref containing the optional params that will be used as parameters for the dialogCallBack function.

=cut
sub closeDialog(){
 my($self,$params) = @_;
 
 $self->setNextScreen(undef,$params,undef,'closeDialog');

}

=pod

=head3 error

   Description :
		- Specialization of the error function for all generic messages for the end user

   parameters :
		- $message : the message to display to the end user

   Returns :
	 - nothing

=cut
sub error($){
  my ($self,$message) = @_;
  $self->SUPER::error({
							  visibility => 'pub',
								'error-type' => 'business',
								'message' => $message,
								});
}

#array of properties that must be serialized
my @GHW_publicPropList = qw/parentScreenDesc dialogCallBack/;

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
=head1 AUTHOR

Jean-Christian Hassler, C<< <jhassler at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gui-libhtml-screen at rt.cpan.org>, or through the web interface at
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

1; # End of HTML::GUI::screen
