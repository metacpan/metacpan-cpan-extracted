package HTML::GUI::log::eventList;

use warnings;
use strict;
use UNIVERSAL qw(isa);
use HTML::GUI::tag;

=head1 NAME

HTML::GUI::log::eventList - Create and control a eventList input for webapp

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
#TODO : creer un objet htmlTag pour ne plus boucler a l'infini sur l'objet widget
our @ISA = qw(HTML::GUI::tag);

my $SProcessEventList = HTML::GUI::log::eventList->new();

=head1 EVENTLIST

The eventList module to store all the events we need.

=cut


=head1 PUBLIC METHODS

=pod 

=head3 new

 create a new eventList

=cut

sub new
{
  my($class,
    ) = @_;
		my $this = {};
		if (!$this){
			return undef;
		}
		$this->{eventList} = [];

    bless($this, $class);
}


=pod 

=head3 addEvent

   Description : 
      Add $event to the EventList object
   Parameters :
		  $event : a HTML::GUI::log::event
   returns :
				1 if the event is effectively added
				0 if there was a problem

=cut
sub addEvent
{
  my($self,$event) = @_;

	if (!isa($event,'HTML::GUI::log::event')){
		return 0;
  }
	push @{$self->{eventList}},$event;
	return 1;
}

=pod 

=head3 forget

   Description : 
      Erase all events of the eventList

=cut

sub forget
{
  my($self) = @_;

	$self->{eventList}=[];
}

=pod 

=head3 getCurrentEventList

   Description : 
      Return the EventList object of the proces

=cut

sub getCurrentEventList
{
  return $SProcessEventList;
}

=pod 

=head3 getHtml

   Description : 
      Return the html of the eventList. The HTML is like this one :
		<div class="errorList">
 		 <h2 class="errorList">Some errors occured.</h2>
		 <dl class="errorList">
		   <dt>Object label</dt>
			 <dd>Event label.</dd>
		 ...other events...
		</div>

   Parameters :
		  $type :
				'error' : render error events
				'info' : render info events
				'debug' : render debug events
				'all' : render all events
	    $visibility : 
				'pub'  for public, only public events are rendered
				'all' for private, all events (private and public) are rendered


=cut

sub getHtml
{
  my($self,$type,$visibility) = @_;
	my @displayList = ();

	$type ||= 'all'; 
	$visibility ||= 'pub';

	if (!scalar @{$self->{eventList}}){
		#no error to display !!
		return '';
	}
	@displayList = grep {$type eq 'all' || $type eq $_->getType()}
														@{$self->{eventList}};
  
  
  #generate HTML for each event !!!
	my $listHtml = '';
	my $lastDomainHtml = '';
  foreach my $event (@displayList){
		my $domainHtml = $event->getDtHtml();
		if ($lastDomainHtml ne $domainHtml){
			$listHtml .= $domainHtml;
		}
		$lastDomainHtml = $domainHtml;
		$listHtml .= $event->getDdHtml();
	}


  $listHtml =  $self->getHtmlTag("h2",{class=>("errorList")},$self->escapeHtml('Some errors occured.') )
		.$self->getHtmlTag("dl",{class=>("errorList")},$listHtml );
  $listHtml =  $self->getHtmlTag("div",{class=>("errorList")},
								$listHtml );
  return $listHtml;
}

sub DESTROY
{
  my($self) = @_;
		
	delete $self->{eventList} ;

}

=head1 AUTHOR

Jean-Christian Hassler, C<< <jhassler at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gui-libhtml-eventList at rt.cpan.org>, or through the web interface at
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

1; # End of HTML::GUI::event::eventList
