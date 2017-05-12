package Jaipo::Notify::MacGrowl;

use warnings;
use strict;
use base 'Mac::Growl';

=encoding utf8

=head1 NAME

Jaipo::Notify::MacGrowl - A easy-to-use interface to show desktop notifications with Growl on Mac OSX.


=head1 SYNOPSIS

Jaipo::Notify::MacGrowl is a easy-to-use interface to show desktop notifications with Grwol on Mac OSX.


	use Jaipo::Notify::MacGrowl;

	my $notify = Jaipo::Notify::MacGrowl->new();
	
	# yell for Service Notify.
	$notify->yell('Cannot connect to M$-Mi$roBlo$: $!');
	# display for message displaying.
	$notify->display("From Mr.Right: Hello Darling. How are you today?");
	
	# get current timeout setting
	print Data::Dumper $notify->timeout;
	# set yell timeout to 10 seconds. default is 5.
	$notify->timeout("yell" => 10);
	# set display timeout to 5 seconds.  default is 3.
	$notify->timeout("yell" => 5);

=head1 FUNCTIONS

=head2 new

Return a object which talks to Growl.

=cut

sub new {
    my $class = shift;
    my %args  = @_;
    print "Mac::Growl Notifier Initialized\n";
    my $self = {};
    bless $self, $class;
    Mac::Growl::RegisterNotifications( 'Jaipo', [ 'Updates' ], [ 'Updates' ], "" );
    return $self;
}

=head2 yell

yell for Service Notify.
Pops a notification with title "Jaipo Service Notify" and the given message content from you.

=cut

sub yell {
	my ($self, $msg) = @_;
    Mac::Growl::PostNotification( 'Jaipo',  'Updates'  , 'Jaipo', $msg );
}

=head2 display

display for message displaying.
Pops a notification with title "You've Got Message!" and the given message content from you.

=cut

sub display { 
    my ($self, $msg) = @_;
    Mac::Growl::PostNotification( 'Jaipo',  'Updates'  , 'Jaipo', $msg );
}

=head2 timeout

timeout for changing/getting the current timeout value.
Not implemented.

=cut

sub timeout {
	my $self = shift;
}

=head1 AUTHOR

BlueT - Matthew Lien - 練喆明, C<< <BlueT at BlueT.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-jaipo-notify-macgrowl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Jaipo-Notify-MacGrowl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Jaipo::Notify::MacGrowl


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Jaipo-Notify-MacGrowl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Jaipo-Notify-MacGrowl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Jaipo-Notify-MacGrowl>

=item * Search CPAN

L<http://search.cpan.org/dist/Jaipo-Notify-MacGrowl>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 BlueT - Matthew Lien - 練喆明, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Jaipo::Notify::MacGrowl
