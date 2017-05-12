package HTML::GUI::widget;

use warnings;
use strict;

=head1 NAME

HTML::GUI::widget - Create and control GUI for web application

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.04';

use Locale::TextDomain qw (GUI::HTML);
use POSIX qw(strftime);
use Data::Compare;
use YAML::Syck;
use HTML::GUI::tag;
use HTML::GUI::log::eventList;

use Log::Log4perl qw(:easy);

our @ISA = qw(HTML::GUI::tag);

=head1 WIDGET

base class for HTML widgets

=cut

#the root directory to look after the screen definition
our $rootDirectory = '/' ;

# Define the default values for the new widget
my %GHW_defaultValue = (display =>1 , constraints => []);

# array of string : list of all public properties of the widget
my @publicPropList = qw/type value id display 
						constraints label title class disabled/;


=head1 PUBLIC METHODS

=pod 

=head3 new

   Parameters :
      params : hash ref : Contains the properties of the widget :
				-type : text, select, checkbox
				-value : the value of the widget
				-id : the id of the widget (mandatory)
				-display : if false, the fied has the propertie style="display:none"
				-constraints : array ref of contraints names
				-label : text associated with the fiel
				-title : title to display when the mouse cursor is over the widget
				-class : css class to associate with the widget
				-disabled : the widget is disabled or not

   Return : 
      

   Description : 
      create a new html widget.
      It can be feed with data manually or automatically with a hash.

=cut

sub new
{
  my($class,
     $params) = @_;
  my $this = $class->SUPER::new($params);

 foreach my $propName(@publicPropList){
   if (exists $params->{$propName}){
     $this->{$propName} = $params->{$propName};
		 #we don't like undef as property value
		 $this->{$propName} = '' unless defined $this->{$propName};
	 }else{
		 $this->{$propName} = 
						$GHW_defaultValue{$propName} ||"";
	 }
 }
 $this->{alert} = [];
 $this->{debug} = [];

 $this->{style} = [];
 $this->{class} = [];
 
 $this->{parent} = undef; #a ref to the parent widget

 bless($this, $class);
}


=head1 FACTORY

 instantiante any widget previously serialized

=cut

=pod 

=head3 instantiate

  Create widgets from the data structure $data
	This is a class method so it should be use like this :
				HTML::GUI::widget->instantiate($myString)

  Parameters :
	  -$data : the data structure which describe the widgets 
		-$path : the path (used to name the screen objects)

	Return :
		a widget or undef if the $data is not correct

=cut

sub instantiate {
  my ($class,$data,$path) = @_;

	if (!$data || !exists $data->{type}){
		return undef;
	}
	my $wtype = $data->{type}.'::' ;
	if (!exists $HTML::GUI::{$wtype}){
		my $moduleFilename = $data->{type}.'.pm';
		if ($moduleFilename !~ '::'){
				#no namespace specified => this is a HTML::GUI native
				#widget
				$moduleFilename = 'HTML::GUI::'.$moduleFilename;
		}
		#convert module name to fileName
		$moduleFilename =~ s/::/\//g;

		require $moduleFilename;
  }

# Rastafarian code inside !!
# Automatic instantation of widgets
# We explore the available packages to instantiate 
# 	the good objects (see perlmod and perlobj for more explanation 
# 	about this particular notation).

		my $package = $HTML::GUI::{$wtype};
		my $constructor = $package->{new};
	  return &$constructor('HTML::GUI::'.$data->{type},$data,$path);

}

=pod

=head3 instantiateFromYAML

  Instantiante a widget from a yaml string
	This is a class method so it should be use like this :
				HTML::GUI::widget->instantiateFromYAML($myString)

	parameters :
	- $class : the className
	- $yamlString : the yaml string describing the widget
	- $path : the path (used to name the screen objects)

	returns :
	-the new widget or undef if the yaml does not describe a widget

=cut

sub instantiateFromYAML{
  my ($class,$yamlString,$path) = @_;

	$YAML::Syck::ImplicitTyping =1 ;
	$YAML::Syck::ImplicitUnicode=1; #try to get correct utf8 handling
	my $descriptionData  = YAML::Syck::Load($yamlString);
  return HTML::GUI::widget->instantiate($descriptionData,$path);

}
=pod 

=head3 setParent

   Return : 
				nothing

   Description : 
				set the reference to the parent of the widget in the widget tree

=cut

sub setParent
{
  my($self,$parent) = @_;
	$self->{parent} = $parent;

}

=pod 

=head3 top

   Return : 
     the root of the widget tree or itself if the widget doesn't belong to 
		 any container

=cut
sub top {
  my($self) = @_;
	if (defined $self->{parent}){
		return $self->{parent}->top();
	}else{
		return $self;
	}
}


=pod 

=head3 setRootDirectory

   Description : 
				Define the root Directory of the screen definitions

=cut

sub setRootDirectory
{
  my ($class,$rootDir)=@_;
	$HTML::GUI::widget::rootDirectory = $rootDir;
}

=pod 

=head3 getRootAncestor

   Description : 
      search the root of the current widget tree.

   Return : 
      The root object of the current tree 

=cut
sub getRootAncestor
{
  my($self) = @_;
	if (defined $self->{parent}){
		return $self->{parent}->getRootAncestor();
	}else{
		return $self;
	}
}

=pod 

=head3 getHtml

   Parameters :

   Return : 
      string

   Description : 
      Return the html of the widget.

=cut

sub getHtml
{
  my($self    ) = @_;
#UML_MODELER_BEGIN_PERSONAL_CODE_getHtml
#UML_MODELER_END_PERSONAL_CODE_getHtml
}


=pod 

=head3 getId

   Return : 
				string  

   Description : 
      return the id of the widget.

=cut

sub getId
{
  my($self) = @_;
	return $self->{id};
}

=pod 

=head3 getIds

   Return : 
				array

   Description : 
      return an array of the ids of the widget. 
			For simple widget, it's the same thing as getId
			but it's different for container which can have many widgets.

=cut

sub getIds
{
  my($self) = @_;
	return ($self->{id});
}

=pod

=head3 getTempId

  Return a new widget id who is unique for the current screen.

=cut
my $idCounter = 0;
sub getTempId{
  my($self) = @_;
	$idCounter++;
	return 'GHW::tmpId::'.$idCounter;
}

=pod 

=head3 getElementById

   Parameters :
      id : string : id of the object to find.

   Description : 
				return the widget whose id is $id or undef if no object has this id


=cut

sub getElementById
{

  my($self,$id) = @_;

	return undef unless ($id eq $self->getId());

	return $self;
}


=pod 


=head3 getStyleContent

   Description : 
     return the content of the html 'style' attribute
   Parameters :
      style : hashref : reference to a hash containing all styles attributs ; if not defined, the function use $self->style to generate a html content

=cut
sub getStyleContent($$){
		my ($self,$style)=@_;
		my @styleList = ();
		my $styleData = $style;
		my @propNames = ();
		@propNames = keys %$styleData;
		@propNames = sort {$a cmp $b} @propNames; #always the same order

		foreach my $styleProp (@propNames){
				push @styleList, $styleProp.":".$style->{$styleProp};
		}
		
		return join ";",@styleList;
}



=pod 

=head3 setProp

   Parameters :
      params : hash ref : defines params value

   Return : 
      

   Description : 
      

=cut

sub setProp
{
  my($self,
     $params, # hash ref : defines params value
    ) = @_;
  my $pubPropHash = $self->getPubPropHash();
 foreach my $propName(keys %$params){
		if (!$pubPropHash->{$propName}){
				$self->alert( __x("Propertie [{propName}] doesn't exists !!"
										."Can't set value [{value}] ",
										propName		=> $propName,
										value				=> $params->{$propName}));
		}else{
				$self->{$propName} = $params->{$propName} || "";
		}
 }
}


=pod 

=head3 getProp

   Parameters :
      $propName : the name of the property we want to read

   Return : 
		   - the value of the property if it exists
			 - undef if the property doesn't exists

=cut

sub getProp
{
  my($self,
     $propName, 
    ) = @_;
  my $pubPropHash = $self->getPubPropHash();
		if (!$pubPropHash->{$propName}){
				$self->alert( __x("Propertie [{propName}] doesn't exists !!"
										."Can't get the value !!",
										propName		=> $propName,));
				return undef;
		}else{
				return $self->{$propName};
		}
}


=pod 

=head3 getDefinitionData
  
  This method is the miror of the "new" method it generate a data structure that defines the widget, calling the "new" function with this hash ref will create the same widget. It is usefull for serialing a widget.
  With no parameters it works for a generic widget, but it is possible to specify paramters in order to specialise the behavior for a particular class.
	The expression "definition data" means the data that are specified when calling the 'new' function. Exemple :

my $definitionData = {id	=> "textObject",
          				value=> '2'};

my $textInputWidget = HTML::GUI::text->new($definitionData);

  Parameters :
		- $paramPublicProp : the hash to feed with the public properties, if undef a new hash is created
		- $paramDefaultValue : an ARRAY ref containing a list of the default values (if a propertie is set to a default value, il is not specified as a "definition data"), if undef the default values of generic widgets is used
		- $paramPublicPropList : the list of properties that can be "definition data", if undef the list of public properties of a generic widget is used 

  Return :
		- a ref to the hash that define the public properties of the widget

=cut
sub getDefinitionData($;$$$)
{
  my ($self,$paramPublicProp,$paramDefaultValue, $paramPublicPropList) = @_;
  
  my $publicProp = $paramPublicProp || {};
	my $defaultValues = $paramDefaultValue ? 
						$paramDefaultValue : \%GHW_defaultValue;
  my $publicPropList = $paramPublicPropList ?
						$paramPublicPropList :\@publicPropList;

	foreach my $propName(@{$publicPropList}){
   if (exists $self->{$propName} ){
		 my $defaultValue = $defaultValues->{$propName};
		 if (defined $defaultValue 
				&& Data::Compare::Compare($self->{$propName}, $defaultValue)){
			  next;
		 }elsif(!ref $self->{$propName}
						&& $self->{$propName} eq ''){
				next;
		 }elsif('ARRAY' eq ref $self->{$propName}
						&& ! scalar @{$self->{$propName}}){
				next;
		 }
		$publicProp->{$propName} = $self->{$propName};
	 }
	}
	return $publicProp;
}

=pod

=head3 serializeToYAML

		return a string describing the current widget in YAML format

=cut

sub serializeToYAML
{
  my ($self)=@_;
	$YAML::Syck::ImplicitTyping =1 ;
	$YAML::Syck::ImplicitUnicode=1; #try to get correct utf8 handling
  my $dataString =YAML::Syck::Dump($self->getDefinitionData());
	#we want a utf-8 encoded string
	#so we convert the escape sequences (\x09...)
	$dataString =~ s/\\x([0-9A-Fa-f]{2})/chr(hex($1))/eg;
	return $dataString;
}


=pod

=head3 writeToFile

  write the seralization of the current objet into the file $fileName.
	Currently, only the YAML is available, so $fileName MUST be like "*.yaml"
	Parameters :
	 - $fileName : the name of the file to write into
  returns :
	 - 1 if the operation terminates normally
	 - 0 if a problem occurs

=cut

sub writeToFile
{
  my ($self,$fileName)=@_;
	if ($fileName !~ /\.yaml$/){
		#TODO : rise an error here
		return 0;
	}
	my $dataString = $self->serializeToYAML ();
	open(FH,'>:utf8',"$fileName") or return 0 ;

  print FH  $dataString;
  close FH;
	return 1;
}

=pod

=head3 instantiateFromFile

  Instantiate widgets from a file
	Currently, only the YAML format is available, so $fileName MUST be like "*.yaml"
	Parameters :
	 - $fileName : the name of the file to read
	 - $baseDir (optional) : the base Directory (this path is added befaor $fileName 
														to effectively locate the file on the filesystem)
  returns :
	 - the widgets object newly created if the operation terminates normally
	 - undef if a problem occurs

=cut
sub instantiateFromFile
{
  my ($class,$fileName,$baseDir)=@_;
	my $wholeName = '';


	if (defined $baseDir){
		$wholeName = $baseDir.$fileName;
	}else{
		$wholeName = $rootDirectory.$fileName;
  }

	if (!-e $wholeName){
		die "the file $wholeName doesn't exists";
	}
  undef $/; #we want to read the whole flie at once
	open DATAFILE ,'<:encoding(utf8)', $wholeName;
  my $whole_file = <DATAFILE>;  
	close DATAFILE;
	if ($fileName =~ /\.yaml$/){
	  return HTML::GUI::widget->instantiateFromYAML($whole_file,$fileName);
	}
	return undef;
}

=pod 

=head3 clone

   Parameters :
      params : hash ref : params to overload the params of the current objet (changing the id is a good idea)

   Return : 
      widget

   Description : 
      

=cut

sub clone
{
  my($self,
     $params, # hash ref : params to overload the params of the current objet (changing the id is a good idea)
    ) = @_;
#UML_MODELER_BEGIN_PERSONAL_CODE_clone
#UML_MODELER_END_PERSONAL_CODE_clone
}


=pod

=head3 error

   Parameters :
      type : string : Visibility of the error (pub/priv)
      params :  hashref : params of the error
   Description :
                 record one error in the current objet

=cut

sub error
{
		my($self,
				$params, # hashref : params of the error
		) = @_;
		my $eventList = HTML::GUI::log::eventList::getCurrentEventList();
		my %errorParams = ( visibility => 'pub',
                      	'error-type' => 'internal',);
		foreach my $paramName qw/visibility error-type constraint-info message/{
				if (exists $params->{$paramName}){
						$errorParams{$paramName} = $params->{$paramName};
				}
		}
		$errorParams{widgetSrc} = $self;
		my $errorEvent =  HTML::GUI::log::error->new(\%errorParams);
		DEBUG "ERREUR :".$errorEvent->getMessage();
		$eventList->addEvent($errorEvent);
}



=head3 printTime

   Parameters :
      $time : string : a value returned by the function time
   Description :
		  return a human readable string of the date $time

=cut
sub printTime($$)
{
  my ($self,$time)=@_;
  return  strftime "%a %b %e %H:%M:%S %Y", localtime($time);
}

=head3 dumpStack

   Parameters :
      stackName : string : name of the stack to convert to string
   Description :
		  return a human readable string of the stack $stackName

=cut
sub dumpStack
{
  my ($self,$stackName)=@_;
	my $dumpString="";
  my %stackNames = (
				error => 'error',
				debug => 'debug',
				alert => 'alert',
		);
  if (!exists $stackNames{$stackName}){
		return "bad stack name [".$stackName."]\n";
	}
  foreach my $event (@{$self->{$stackName}}){		
		$dumpString .= "[".$self->printTime($event->{time})."]";
		$dumpString .= $event->{message}."\n";
		foreach my $frame (@{$event->{stack}}){
				$dumpString .= "  ->".$frame->{subroutine}
										." line:".$frame->{line}
										." in:".$frame->{filename}."\n";
		}
		$dumpString .="\n";
	}
	return $dumpString;
}


=pod

=head3 getCurrentStack

   Description :
		  return a array of the current stack

=cut
sub getCurrentStack
{
  my ($self) = @_;
	my @stack  ;
	my $i=0;
  my ($package, $filename, $line,$subroutine) ;
	while ($i==0 || $filename){
	($package, $filename, $line,$subroutine) = caller($i);
			push @stack, {
					'package' => $package,
					filename => $filename,
					line			=> $line,
					subroutine=> $subroutine,
			} unless (!defined $filename);
			$i++;
	}
	return \@stack;
}

=head3 alert

   Description :
		  store an alert message in the current objet 

=cut
sub alert($$)
{
  my($self,
     $message, # string : alert message 
    ) = @_;
		push @{$self->{alert}},{
				'time'=>time,
				message => $message,
				stack		=> $self->getCurrentStack(),
				};
}

=head3 debug

   Parameters :
      message : string : message to debug
   Description :
		  record one debug in the current objet


=cut

sub debug($)
{
  my ($self,$message)=@_;
		push @{$self->{debug}},{
				'time'=>time,
				message => $message,
				};
}


=head3 getLabel

   Description :
		  return the label of the current obj


=cut
sub getLabel()
{
  my ($self) = @_;
	return $self->{label};
}

=head3 getLabelHtml

   Description :
		  return the html of the label of the current obj
			If the label is a void string, return ''


=cut

sub getLabelHtml
{
  my ($self)=@_;
  my %tagProp =();
	my $label = $self->{label};

	if ($label eq ''){
  	return '';
	}
	$tagProp{for} = $self->{id};

	return $self->getHtmlTag("label",\%tagProp, $self->escapeHtml($label));
}


=head1 METHODS FOR SUBCLASSING



=cut


=head1 PRIVATE METHODS



=cut



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

=head3 getPath

   Return : 
      a string containing the actual path of the module

=cut

sub getPath
{
  my($self    ) = @_;

  my $path = $INC{'HTML/GUI/container.pm'};
	$path =~ s/container.pm$//;
	return $path;
}


=pod 

=head3 validate

   Description :
		  All widgets are OK by default. The input widgets have custom 
			validate function to implements constraints.

   Return : 
      always 1 

=cut

sub validate
{
  my($self    ) = @_;
	return 1;
}


=pod 

=head3 getValueHash

		Description : 
				Default method for all non-input and non-container widgets
		Return : 
			undef

=cut

sub getValueHash
{
  my($self) = @_;
	return undef;
}


=head3 fired
   
	 Parameters :
		 $params : the hash ref containing the POST key-value pairs.

   Decription :
		this function aims to be specialized for buttons.

   Returns :
      - true if the current object was fired
			- false otherwise

=cut
sub fired
{
  my($self,$params) = @_;

	return 0;
}

=head3 getNodeSession

   Decription :
		 return a hash ref to the session. This is a low level API to
		 manage multiple user session in multiple windows.
		 This function MUST be refined by the choosen engine.

   Returns :
      - a hash ref to the session corresponding to the user agent cookie
			- a void hash ref if no session can be found

=cut
sub getNodeSession
{
  return {};
}

=head3 getSession

   Decription :
		 return a hash ref to the session corresponding to one window of the browser. If a user opens two windows of the same brower, he will need to connect two times, getSession will return two different sessions.
		 This method MUST be implemented by the engine

   Returns :
      - a hash ref to the session corresponding to the user agent cookie
			- a void hash ref if no session can be found

=cut
sub getSession
{
  return {};
}

=pod

=head3 getFunctionFromName

		Description :
				Find the function whose name is $functionName 
				If the module of the function not loaded, it will be loaded automatically.

		Returns :
				- a ref to the function whose name is $functionName if it exists
				- undef if no function of this name exists

=cut
sub getFunctionFromName{
 my ($self,$functionName) = @_;
 if (!$functionName){
		return undef; #nothing to do
 }
 my @funcPath = split '::',$functionName;
 my $funcName = pop @funcPath;
 my $moduleName = join '::',@funcPath;
 #for testing purpose
 $moduleName ||= 'main';
 $functionName = $moduleName.'::'.$funcName;
 if (!defined &{$functionName}){
		 my $status = undef;
			my $evalError = '';
		if ($moduleName ne ''){
			$status = eval "require $moduleName";
			$evalError = $@;
		}
	 if (!defined $status  && $moduleName ne ''){
			 my $msg = '['.$moduleName."] is not a valid module name : ".$evalError;
			 ERROR($msg);
			 $self->error({
						'message' =>$msg,
						});
				return undef;
	 }elsif(!defined &{$functionName}){
			 my $msg = '['.$moduleName.'] is not a valid module name';
			 ERROR($msg);
		 	 $self->error({
						'message' => $msg,
						});
				return undef
	 }
 }
 return \&{$functionName};
}
=head1 AUTHOR

Jean-Christian Hassler, C<< <jhassler at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gui-libhtml-screen at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-GUI>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::GUI::widget

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-GUI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-GUI>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-GUI>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-GUI>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jean-Christian Hassler, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of HTML::GUI::widget
