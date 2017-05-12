=head1 NAME

Konstrukt::PrintRedirector - Catches the print statements and fires an event on each print.

=head1 SYNOPSIS

	#activate
	$Konstrukt::PrintRedirector->activate();
	
	#print some stuff that should be catched and put into the parsing tree
	print 'stuff';
	
	#deactivate
	$Konstrukt::PrintRedirector->deactivate();

=head1 DESCRIPTION

If activated, all print()'s will be intercepted and an event
C<Konstrukt::PrintRedirector::print> with the arguments that were printed will be fired.
So you have to register an object method for this event (see L<Konstrukt::Event>
for more information).

=cut

package Konstrukt::PrintRedirector;

use strict;
use warnings;

use Konstrukt::Event;

=head1 METHODS

=head2 new

Constructor of this class

=cut
sub new {
	my ($class) = @_;
	tie(*PRINTREDIRECTOR, 'Konstrukt::PrintRedirector');
	return bless {}, $class;
}
#= /new

=head2 init

Initialization of this class.

=cut
sub init {
	my ($self) = @_;
	#deactivate the print redirector
	$self->deactivate();
	return 1;
}
#= /init

=head2 activate

Activates the print catcher.

=cut
sub activate {
	my ($self) = @_;
	
	#only select file handle if not already selected
	if (!exists($self->{old_fh})) {
		$self->{old_fh} = select(PRINTREDIRECTOR);
	}
	
	return 1;
}
#= /activate

=head2 deactivate

Deactivates the print catcher.

=cut
sub deactivate {
	my ($self) = @_;
	
	#only select old file handle if it exists
	if (defined($self->{old_fh})) {
		select($self->{old_fh});
		delete($self->{old_fh});
		return 1;
	}
}
#= /deactivate

sub TIEHANDLE {
	my ($class) = @_;
	return bless {}, $class;
}

sub PRINT {
	my ($self, @data) = @_;
	
	$Konstrukt::Event->trigger("Konstrukt::PrintRedirector::print", @data);
	
	return 1;
}

#create global object
sub BEGIN { $Konstrukt::PrintRedirector = __PACKAGE__->new() unless defined $Konstrukt::PrintRedirector; }

return 1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::perl>, L<Konstrukt>

=cut
