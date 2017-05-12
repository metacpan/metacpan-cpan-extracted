package HTML::GUI::log::error;

use warnings;
use strict;

use HTML::GUI::constraint;
use HTML::GUI::log::event;

=head1 NAME

HTML::GUI::log::error - Create and control a error input for webapp

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our @ISA = qw(HTML::GUI::log::event);


=head1 ERROR

The error module to log all errors events

=cut


=head1 PUBLIC METHODS

=pod 

=head3 new

=cut

sub new
{
  my($class,
     $params, # widget : 
    ) = @_;
		foreach my $mandatory qw/visibility error-type/{
				if (!defined $params->{$mandatory}){
						return undef;
				}
		}
		my $this = $class->SUPER::new($params);
		if (!$this){
				return undef;
		}
		$this->{type} = 'error';
		foreach my $paramName qw/message visibility error-type value/{
				if (exists $params->{$paramName}){
						$this->{$paramName} = $params->{$paramName} ;
				}else{
						$this->{$paramName} = '' ;
				}
		}
		if (exists $params->{'constraint-info'}){
			$this->{'constraint-info'} = $params->{'constraint-info'} ;
		}else{
			$this->{'constraint-info'} = {} ;
		}
		$this->{widgetSrc} =  $params->{widgetSrc} ?$params->{widgetSrc}:undef;
    bless($this, $class);
		return $this;
}

=pod

=head3 getMessage

   Description :
		  returns the message corresponding for the current error

=cut

sub getMessage
{
  my ($self)=@_;
	my $message = '';
	if ($self->{'error-type'} eq 'constraint'){
			$message = HTML::GUI::constraint::getMessage($self->{'constraint-info'});
	}
  if ($message ne ''){
		return $message;
	}
	if ($self->{message} ne ''){
			return $self->{message};
	}
	return 'no message found for this error';
}

=pod 

=head3 getDtHtml

   Description : 
      Return the html usefull for localize the error (name of the input, or 'General' for internal errors). This Html is meant to be integrated into a definition list. Example :  <dt>Date of Birth :</dt>

=cut

sub getDtHtml
{
  my($self) = @_;

	my $domain = "General";

	my $widgetSrc = exists $self->{widgetSrc} ? $self->{widgetSrc} : undef;
	if ($widgetSrc && ($self->{'error-type'} eq 'constraint')){
		  #we add the informations of a particular widget
			$domain = $widgetSrc->getLabel();
	}

	return $self->getHtmlTag("dt",{},$domain);
}

=pod 

=head3 getDdHtml

   Description : 
      Return the html of the error for the public errors who should be presented to the user. This Html is meant to be integrated into a definition list (ex :  <dd> This field is mandatory <a href="#dateOfBirth">Fix it.</a> </dd>).

=cut

sub getDdHtml
{
  my($self) = @_;

	my $explanation = $self->escapeHtml( $self->getMessage());
	my $correctionLink = '';

	my $widgetSrc = exists $self->{widgetSrc} ? $self->{widgetSrc} : undef;
	if ($widgetSrc && ($self->{'error-type'} eq 'constraint')){
		  #we add the informations of a particular widget
		  my %tagProp=(href => '#'.$widgetSrc->getId());
			$correctionLink = $self->getHtmlTag('a',\%tagProp,
																$self->escapeHtml('Fix it.'));
	}

  return $self->getHtmlTag("dd",{},$explanation.$correctionLink); 
}

sub DESTROY{
  my($self) = @_;

  delete $self->{widgetSrc};
}

=head1 AUTHOR

Jean-Christian Hassler, C<< <jhassler at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gui-libhtml-error at rt.cpan.org>, or through the web interface at
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

1; # End of HTML::GUI::error::error
