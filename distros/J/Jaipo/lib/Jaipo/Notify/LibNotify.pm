package Jaipo::Notify::LibNotify;

use warnings;
use strict;
#~ use Smart::Comments;
use Data::Dumper;
use base qw(Desktop::Notify);

=encoding utf8

=head1 NAME

Jaipo::Notify::LibNotify - A easy-to-use interface to show desktop notifications with libnotify.


=head1 SYNOPSIS

Jaipo::Notify::LibNotify is a easy-to-use interface to show desktop notifications with libnotify.
It doesn't use libnotify directly, but talking to libnotify via dbus.


	use Jaipo::Notify::LibNotify;

	my $notify = Jaipo::Notify::LibNotify->new();
	
	# yell for Service Notify.
	$notify->yell('Cannot connect to M$-Mi$roBlo$: $!');

	# display for message displaying.
	$notify->display("From Mr.Right: Hello Darling. How are you today?");
	
	# pop_box for message displaying.
	$notify->pop_box("Are you using M$ windows without buying license?");
	
	# get current timeout setting
	print Data::Dumper $notify->timeout;

	# set yell timeout to 10 seconds. default is 5.
	$notify->timeout("yell" => 10);

	# set display timeout to 5 seconds.  default is 3.
	$notify->timeout("yell" => 5);

=head1 FUNCTIONS

=head2 new

Return a object which talks to libnotify via dbus.

=cut

sub new {
	my $class = shift;
	#~ print Dumper $class;
	my $self = Desktop::Notify->new(@_); 
	bless $self, $class;
	$self->{timeout_yell} = 5000;
	$self->{timeout_display} = 3000;
	return $self;
}

=head2 yell

yell for Service Notify.
Pops a notification with title "Jaipo Service Notify" and the given message content from you.

=cut

sub yell {
	my ($self, $msg) = @_;
	$self->create(
		"summary" => 'Jaipo Service Notify',
		"body" => $msg,
		"timeout" => $self->{timeout_yell},
	)->show();
}

=head2 display

display for message displaying.
Pops a notification with title "You've Got Message!" and the given message content from you.

=cut

sub display { 
        my ($self, $msg) = @_;
        #~ $self->SUPER::display("Name", @args);
	$self->create(
		"summary" => "Jaipo: You've Got Message!",
		"body" => $msg,
		"timeout" => $self->{timeout_display},
	)->show();
}

=head2 pop_box

pop_box for special message displaying.
Pops a window box with title "Pop!" and the given message content from you.

=cut

sub pop_box { 
        my ($self, $msg) = @_;
        #~ $self->SUPER::display("Name", @args);
	$self->create(
		"summary" => "Jaipo: Pop!",
		"body" => $msg,
		#~ "timeout" => $self->{timeout_display},
	)->show();
}

=head2 timeout

timeout for changing/getting the current timeout value.


=cut

sub timeout {
	my $self = shift;
	my %timeout = (
		"timeout_yell" => $self->{timeout_yell} / 1000,
		"timeout_display" => $self->{timeout_display} / 1000,
	);
	
	if (not @_) {
		# do nothing
	}elsif ( $_[0] eq "yell" ) {
		$self->{timeout_yell} = $_[1] * 1000;
	} elsif ( $_[0] eq "display" ) {
		$self->{timeout_display} = $_[1] * 1000;
	}
	return \%timeout;
}

=head1 AUTHOR

BlueT - Matthew Lien - 練喆明, C<< <BlueT at BlueT.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-jaipo-notify-libnotify at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Jaipo-Notify-LibNotify>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Jaipo::Notify::LibNotify


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Jaipo-Notify-LibNotify>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Jaipo-Notify-LibNotify>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Jaipo-Notify-LibNotify>

=item * Search CPAN

L<http://search.cpan.org/dist/Jaipo-Notify-LibNotify>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 BlueT - Matthew Lien - 練喆明, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Jaipo::Notify::LibNotify
