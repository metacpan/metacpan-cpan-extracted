package HTML::GUI::hidden;

use warnings;
use strict;

=head1 NAME

HTML::GUI::hidden - Create and control a hidden input for webapp

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


use HTML::GUI::input;
our @ISA = qw(HTML::GUI::input);

=head1 HIDDEN

The hidden widget is the specialisation of the widget class for classical values ("enter your name").

=cut



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
	  $this->{type} = "hidden";

 bless($this, $class);
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
  
	$tagProp{type} = 'hidden';
	$tagProp{value} = $self->getValue();
	$tagProp{name} = $tagProp{id} = $self->{id};
  
  return $self->getHtmlTag("input",\%tagProp) ;
}


=head1 AUTHOR

Jean-Christian Hassler, C<< <jhassler at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gui-libhtml-hidden at rt.cpan.org>, or through the web interface at
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

1; # End of HTML::GUI::hidden
