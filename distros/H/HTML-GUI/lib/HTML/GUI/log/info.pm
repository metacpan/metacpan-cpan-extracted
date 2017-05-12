package HTML::GUI::log::info;

use warnings;
use strict;

=head1 NAME

HTML::GUI::info::info - Create and control a info input for webapp

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 INFO

The info module to log all information messages

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
		$params->{type} = "info";
		my $this = $class->SUPER::new($params);
		if (!$this){
				return undef;
		}
		$this->{options} = [];

    bless($this, $class);
		if (exists $params->{options}){
				$this->setOptions($params->{options});
		}
		return $this;
}

=pod

=pod 

=head3 getHtml

   Description : 
      Return the html of the info for the public infos who should be presented to the user.

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
	$tagProp{name} = $tagProp{id} = $self->{id};
	$tagProp{size} = '1';

	my $optionHtml = '';
	my $currentValue = $self->getValue();
	foreach my $option (@{$self->{options}}){
			my $optionProp = {};

			if (defined $currentValue
					&& ($currentValue eq $option->{value})){
				$optionProp->{infoed} = 'infoed';
			}
			$optionProp->{value} = $option->{value};

			$optionHtml .= $self->getHtmlTag("option",
																		$optionProp,
																		$self->escapeHtml($option->{label}));
																										
	}
  
  return $self->getHtmlTag("p",{class=>("float")},
														$self->getLabelHtml() 
														.$self->getHtmlTag("info",
																						\%tagProp,$optionHtml)
												  );
}


=head1 AUTHOR

Jean-Christian Hassler, C<< <jhassler at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gui-libhtml-info at rt.cpan.org>, or through the web interface at
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

1; # End of HTML::GUI::info::info
