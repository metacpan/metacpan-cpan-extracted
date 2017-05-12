package HTML::GUI::checkbox;

use warnings;
use strict;

=head1 NAME

HTML::GUI::checkbox - Create and control a checkbox input for webapp

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


use HTML::GUI::input;
our @ISA = qw(HTML::GUI::input);

=head1 CHECKBOX

The checkbox widget is the specialisation of the input 

=cut


=head1 PUBLIC ATTRIBUTES

=pod 



=cut


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
		$params->{type} = "checkbox";
		my $this = $class->SUPER::new($params);
		if (!$this){
				return undef;
		}

 bless($this, $class);
}

=pod 

=head3 setValue

   Parameters :
		 The new value of the checkbox value

   Return : 
     nothing 

   Description : 
      a checkbox can only contain a boolean value 1 or 0.

=cut

sub setValue
{
  my($self,$newValue) = @_;
	$self->{value} = defined $newValue && $newValue? 1 : 0;
}

=pod 

=head3 getNudeHtml

   Description : 
      Return the html of the widget to be inserted in a <p> tag or a a table.

=cut

sub getNudeHtml
{
  my($self) = @_;
	my %tagProp=();
	my %styleProp=();
  

	if (exists $self->{display} && 0==$self->{display}){
		$styleProp{display} = 'none';
	}

	$tagProp{style} = $self->getStyleContent(\%styleProp);
	$tagProp{type} = 'checkbox';
	$tagProp{name} = $tagProp{id} = $self->{id};

  $tagProp{class} = 'ckbx';

	#the value is not really useful for combo
	#so we use an arbitrary value
	$tagProp{value} = 'on';
	#checked if the value is true
	if ($self->getValue()){
		$tagProp{checked} = 'checked';
	}
  
  return $self->getHtmlTag("input", \%tagProp);
}

=pod 

=head3 setValueFromParams

   Parameters :
	   -params : a hash ref 

   Description : 
      look for a value coresponding to the checkbox in $params hash;
			if no value is found, the widget value is 0
		  if a value is found, the widget value is 1

=cut

sub setValueFromParams
{
  my($self,$params) = @_;
	my $id = $self->getId();
	if (defined $params->{$id} 
		  && $params->{$id} eq 'on'){
		$self->setValue(1);
  }else{
		$self->setValue(0);
	}
}

=head1 AUTHOR

Jean-Christian Hassler, C<< <jhassler at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gui-libhtml-checkbox at rt.cpan.org>, or through the web interface at
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

1; # End of HTML::GUI::checkbox
