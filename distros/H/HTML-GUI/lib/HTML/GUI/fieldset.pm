package HTML::GUI::fieldset;

use warnings;
use strict;

=head1 NAME

HTML::GUI::fieldset - Create and control a whole fieldset for web application

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use HTML::GUI::container;
use UNIVERSAL qw(isa);
our @ISA = qw(HTML::GUI::container);



=head1 FIELDSET

A fieldset widget can contain input widgets (i.e. text input).
A fieldset cannot contains a fieldset nor a screen (because the screen MUST be the top element of the widget tree)

=cut

=head1 PUBLIC ATTRIBUTES

=pod 



=cut


=head1 PUBLIC METHODS

=pod 

=head3 new

  create a new fieldset

=cut

sub new
{
  my($class,$params) = @_;

	my $this = $class->SUPER::new($params);
	$this->{type} = "fieldset";

  return undef unless defined $this;

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
	my %styleProp=();
  

	if (exists $self->{display} && 0==$self->{display}){
		$styleProp{display} = 'none';
	}

	$tagProp{style} = $self->getStyleContent(\%styleProp);
	$tagProp{id} = $self->{id};
	my $legendHtml = '';
	if (exists $self->{label}){
			$legendHtml = $self->getHtmlTag("legend",
																		undef,
																		$self->escapeHtml($self->{label}));
	}
	return $self->getHtmlTag( "fieldset",
														\%tagProp,
														$legendHtml
														.$self->SUPER::getHtml()) ;
}



=head1 AUTHOR

Jean-Christian Hassler, C<< <jhassler at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gui-libhtml-fieldset at rt.cpan.org>, or through the web interface at
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

1; # End of HTML::GUI::fieldset
