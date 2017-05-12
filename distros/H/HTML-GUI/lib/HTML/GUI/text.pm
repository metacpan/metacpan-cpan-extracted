package HTML::GUI::text;

use warnings;
use strict;

=head1 NAME

HTML::GUI::text - Create and control a text input for webapp

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


use HTML::GUI::input;
our @ISA = qw(HTML::GUI::input);

=head1 TEXT

The text widget is the specialisation of the widget class for classical values ("enter your name").

=cut


#array of string : list of all specifric public properties of the widget
my @GHW_publicPropList = qw/size/;

=pod

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

		my $this = $class->SUPER::new($params);
	  $this->{type} = "text";

		if (exists $params->{size}){
				$this->{size} = $params->{size};
		}
 bless($this, $class);
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
	$tagProp{type} = $self->{type};
	$tagProp{value} = $self->getValue();
	$tagProp{name} = $tagProp{id} = $self->{id};
	if (exists $self->{size}){
   $tagProp{size} = $self->{size};
	}
  
  return $self->getHtmlTag("input", \%tagProp);
}


=head1 AUTHOR

Jean-Christian Hassler, C<< <jhassler at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gui-libhtml-text at rt.cpan.org>, or through the web interface at
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

1; # End of HTML::GUI::text
