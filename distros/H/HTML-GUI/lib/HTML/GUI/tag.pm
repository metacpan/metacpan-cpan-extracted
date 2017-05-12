package HTML::GUI::tag;

use warnings;
use strict;

=head1 NAME

HTML::GUI::tag - generate html tags

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';



=head1 TAG

abstract class for generating html.

=cut



=pod

=head1 PUBLIC METHODS

=pod 

=head3 new


=cut

sub new
{
  my($class
    ) = @_;

	  my $this = {};

 bless($this, $class);
}



=head3 escapeHtml

   Description : 
     return the protected label with :
				- &quot; instead of "
				- &amp; insterad of &

=cut
sub escapeHtml($$){
		my ($self,$label)=@_;
		$label =~ s/&/&amp;/g;
		$label =~ s/"/&quot;/g;
		$label =~ s/</&lt;/g;
		$label =~ s/>/&gt;/g;
		return $label
}

=pod 


=head3 getHtmlTag

   Parameters :
      tagName : string : Name of the tag to generate
      @htmlProperties : array : Array of hash ref of properties for the tag  (propName => propValue)
      content : string : Content of the HTML tag. The content string is inserted "as is" in the tag, it should not contain special characters like '&' or '<' except for coding entities or inner tags.


   Return : 
      string

   Description : 
      

=cut

sub getHtmlTag
{
  my($self,
     $tagName, # string : Name of the tag to generate
     $tagProperties, # array : hash ref of properties for the tag  (propName => propValue)
     $content, # string : Content of the HTML tag.

    ) = @_;
		my @widgetProp = ();
		my @propNames = ();
		@propNames = keys %$tagProperties;
		@propNames = sort {$a cmp $b} @propNames; #always the same order
		foreach my $propName (@propNames){
		  if ($tagProperties->{$propName} ne ""){
				push @widgetProp, 
						$propName.'="'.$self->escapeHtml($tagProperties->{$propName}).'"';
				}

		}
		my $tagHtml = join ' ',$tagName,@widgetProp;
		if ($content){
			return '<'.$tagHtml.'>'
				.$content
				.'</'.$tagName.'>';
		}else{
			return '<'.$tagHtml.'/>';

		}
}

=head1 AUTHOR

Jean-Christian Hassler, C<< <jhassler at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gui-libhtml-tag at rt.cpan.org>, or through the web interface at
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

1; # End of HTML::GUI::tag
