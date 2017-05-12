package HTML::GUI::input;

use warnings;
use strict;

=head1 NAME

HTML::GUI::input - Create and control a input input for webapp

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


use HTML::GUI::widget;
our @ISA = qw(HTML::GUI::widget);
use HTML::GUI::log::eventList;
use HTML::GUI::log::error;
use Log::Log4perl qw(:easy);

=head1 INPUT

The input widget is the specialisation of the widget class for all user inputs (text, checkbox, combo ...).
It enforces all the specific functions of the use input (for example : implement the validate() function to check id the submitted value is OK).

=cut


=head1 PUBLIC ATTRIBUTES

=pod 



=cut


=head1 PUBLIC METHODS

=pod 

=head3 new

   Parameters :
      params : widget definition 

=cut

sub new
{
  my($class,
     $params, # widget : 
    ) = @_;
		#each input MUST have an id
		return undef unless defined $params->{id};

		my $this = $class->SUPER::new($params);

 bless($this, $class);
}


=pod 

=head3 setValue

   Parameters :
		 The new value of the widget value

   Return : 
     nothing 

   Description : 
      set the value of the widget with $newvalue.

=cut

sub setValue
{
  my($self,$newValue) = @_;
	$self->{value}=$newValue;
}

=pod 

=head3 getValue

   Parameters :

   Return : 
      

   Description : 
      return the current value of the widget.

=cut

sub getValue
{
  my($self) = @_;
	return $self->{value};
}

=pod 

=head3 getValueHash

		Description : 
				return a hash containing the input id and value 
		Return : 
				a ref to a hash containing ( widgetId => widgetValue) 

=cut

sub getValueHash
{
  my($self) = @_;
	return {$self->getId() => $self->getValue()};
}

=pod 

=head3 setValueFromParams

   Parameters :
	   -params : a hash ref 

   Description : 
      look for a value coresponding to the widget in $params hash;
			if it is the case,set the objet value with this one
			 For more elaborate objects, the functions is specialised.

=cut

sub setValueFromParams
{
  my($self,$params) = @_;
	if (defined $params->{$self->{id}} ){
		$self->setValue($params->{$self->{id}});
  }
}


=pod 

=head3 validate

   Return : 
      1 if all constraints are OK;
			0 if one or more constraint are broken

=cut

sub validate
{
  my($self) = @_;
	my $value = $self->getValue();
	my $failedName = '';
  my $status=1;

	foreach my $constraint (@{$self->{constraints}}){
		$failedName='';
		SWITCH:	{
		  if ($constraint =~ /required/ && $value =~ /^\s*\t*$/){
				$failedName = 'required';
				last SWITCH;
			}
		  if ($constraint =~ /integer/ && $value ne '' && $value !~ /^\d*$/){
				$failedName = 'integer';
				last SWITCH;
			}
		}
		if ($failedName){
		  $status =0;
		  my $constrInfo = {widgetLabel => $self->getLabel(),
												 'constraint-name' => $failedName};
		  $self->error({                                visibility => 'pub',
								'error-type'=>'constraint',
								'constraint-info' => $constrInfo,
								});
		}
	}
	return $status;
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

	my %errorParams = ();
	foreach my $paramName qw/visibility error-type constraint-info message/{
		if (exists $params->{$paramName}){
			$errorParams{$paramName} = $params->{$paramName};
		}
	}
	$errorParams{widgetSrc} = $self;
	my $errorEvent =  HTML::GUI::log::error->new(\%errorParams);
	if (!$errorEvent){
			$self->SUPER::error({
										visibility => 'pub',
										'error-type' => 'business',
										'message' => $params->{message},
										});
			return ;
	}
	my $eventList = HTML::GUI::log::eventList::getCurrentEventList();
	$eventList->addEvent($errorEvent);
}

=pod

=head3 getHtml
   
	 Description : 
      Return the html of the widget. It can be directly inserted into a screen

=cut

sub getHtml{
  my ($self)= @_;
  
	return $self->getHtmlTag("p",{class=>("float")},
														$self->getLabelHtml() 
														.$self->getNudeHtml()
												  );
}

=head1 AUTHOR

Jean-Christian Hassler, C<< <jhassler at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gui-libhtml-input at rt.cpan.org>, or through the web interface at
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

1; # End of HTML::GUI::input
