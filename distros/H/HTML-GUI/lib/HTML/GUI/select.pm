package HTML::GUI::select;

use warnings;
use strict;

=head1 NAME

HTML::GUI::select - Create and control a select input for webapp

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


use HTML::GUI::input;
our @ISA = qw(HTML::GUI::input);

=head1 SELECT

The select widget is made for choose an item in limited list.

=cut


# Define the specific default values for a select widget
my %GHW_defaultValue = (options => []);

#array of string : list of all specifric public properties of the widget
my @GHW_publicPropList = qw/options/;

=head1 PUBLIC ATTRIBUTES

=pod 



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
		$params->{type} = "select";
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

=head3 isNewValue
  Description :
		return 1 if the value already exist in the widget's options
		else return 0

  parameter :
	  the newValue (scalar) to test
=cut

sub isNewValue($$)
{
		my ($this,$newValue) = @_;

		foreach my $option (@{$this->{options}}){
				if ($newValue eq $option->{value}){
						return 0;
				}
		}

		return 1;
}

=pod 

=head3 setOptions

   Description : 
      Define the options of the select box.

		parameters :
				$options is a ref to an array of hash ref
				[{	value		=>	"myvalue",
						label		=>	"my label},
				 {	value		=>	"myvalue2",
						label		=>	"my second label}]
=cut

sub setOptions
{
		my ($this,$options) = @_;
		if (!$options || ref $options ne 'ARRAY'){
		  $this->error("priv",{
								type=>'incorrect use of API',
								'explanation' => '$option should be an ARRAY ref',
								option => $options});
				
		}
		foreach my $oneOption (@$options){
				if (ref $oneOption ne "HASH"
								|| !exists $oneOption->{value}
								|| !exists $oneOption->{label}){
						#wrong data structure !!
						$this->error("priv",{
							type=>'incorrect use of API',
							'explanation' => '$oneOption should be a hash ref '
																	.'with ˝value" and "label" keys',
							option => $oneOption});
						next;

				}
				$oneOption->{value} ||= '';
				$oneOption->{label} ||= '';
				if (!$this->isNewValue($oneOption->{value}) ){
						#value already used !!!
						$this->error("priv",{
									type=>'incorrect use of API',
									'explanation' => 'the value of $oneOption is already '
																			.'present in the widget',
									option => $oneOption});
						next;
				}
				push @{$this->{options}} , $oneOption; 
		}

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
														\%GHW_defaultValue,\@GHW_publicPropList);
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
	$tagProp{name} = $tagProp{id} = $self->{id};
	$tagProp{size} = '1';

	my $optionHtml = '';
	my $currentValue = $self->getValue();
	foreach my $option (@{$self->{options}}){
			my $optionProp = {};

			if (defined $currentValue
					&& ($currentValue eq $option->{value})){
				$optionProp->{selected} = 'selected';
			}
			$optionProp->{value} = $option->{value};

			$optionHtml .= $self->getHtmlTag("option",
																		$optionProp,
																		$self->escapeHtml($option->{label}));
																										
	}
  
  return $self->getHtmlTag("select", \%tagProp,$optionHtml);
}


=head1 AUTHOR

Jean-Christian Hassler, C<< <jhassler at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gui-libhtml-select at rt.cpan.org>, or through the web interface at
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

1; # End of HTML::GUI::select
