package Kephra::EventTable;
our $VERSION = '0.16';

use strict;
use warnings;

# get pointer to the event list
my %timer;
my %table;
my %group = (
	edit       =>  [qw(document.text.change document.text.select caret.move)],
	doc_change =>  [qw(document.current.number.changed
	                   document.savepoint document.text.select)],
);
sub _table { \%table }

sub start_timer {
	# set or update timer events
	my $win = Kephra::App::Window::_ref();
	my $config = Kephra::API::settings()->{file};   

	stop_timer();
	if ($config->{open}{notify_change}) {
		$timer{file_notify} = Wx::Timer->new( $win, 2 );
		$timer{file_notify}->Start( $config->{open}{notify_change} * 1000 );
		Wx::Event::EVT_TIMER( $win, 2, sub { Kephra::File::changed_notify_check() } );
	}
	if ($config->{save}{auto_save}) {
		$timer{file_save} = Wx::Timer->new( $win, 1 );
		$timer{file_save}->Start( $config->{save}{auto_save} * 1000 );
		Wx::Event::EVT_TIMER( $win, 1, sub { Kephra::File::save_all_named() } );
	}
}

sub stop_timer {
	my $win = Kephra::App::Window::_ref();
	$timer{file_save}->Stop if ref $timer{file_save} eq 'Wx::Timer';
	delete $timer{file_save};
	$timer{file_notify}->Stop if ref $timer{file_notify} eq 'Wx::Timer';
	delete $timer{file_notify};
}
sub delete_all_timer {}
#######################################################################
sub add_call {
	return until ref $_[2] eq 'CODE';
	my $list = _table();
	$list->{active}{ $_[0] }{ $_[1] } = $_[2];
	$list->{owner}{ $_[3] }{ $_[0] }{ $_[1] } = 1 if $_[3];
}

sub add_frozen_call {
	return until ref $_[2] eq 'CODE';
	my $list = _table();
	$list->{frozen}{ $_[0] }{ $_[1] } = $_[2];
	$list->{owner}{ $_[3] }{ $_[0] }{ $_[1] } = 1 if $_[3];
}

sub trigger {
	my $active = _table()->{active};
	for my $event (@_){
		if (ref $active->{$event} eq 'HASH'){
			$_->() for values %{ $active->{$event} }
		}
	}
}

sub trigger_group {
	my $group_name = shift;
	return unless $group_name and ref $group{$group_name} eq 'ARRAY';
	trigger( @{$group{$group_name}} );
}

sub freeze {
	my $list = _table();
	for my $event (@_){
		if (ref $list->{active}{$event} eq 'HASH'){
			$list->{frozen}{$event}{$_} = $list->{active}{$event}{$_}
				for keys %{$list->{active}{$event}};
			delete $list->{active}{$event};
		}
	}
}

sub freeze_group {
	my $group_name = shift;
	return unless $group_name and ref $group{$group_name} eq 'ARRAY';
	freeze( @{$group{$group_name}} );
}
sub freeze_all { freeze($_) for keys %{_table()->{active}} }


sub thaw {
	my $list = _table();
	for my $event (@_){
		if (ref $list->{frozen}{$event} eq 'HASH'){
			$list->{active}{$event}{$_} = $list->{frozen}{$event}{$_}
				for keys %{$list->{frozen}{$event}};
			delete $list->{frozen}{$event};
		}
	}
}
sub thaw_group {
	my $group_name = shift;
	return unless $group_name and ref $group{$group_name} eq 'ARRAY';
	thaw( @{$group{$group_name}} );
}
sub thaw_all   { thaw($_) for keys %{_table()->{frozen}} }

sub del_call {
	return until $_[1];
	my $list = _table()->{active};
	delete $list->{ $_[0] }{ $_[1] } if exists $list->{ $_[0] }{ $_[1] };
	$list = _table()->{frozen};
	delete $list->{ $_[0] }{ $_[1] } if exists $list->{ $_[0] }{ $_[1] };
}
sub del_subscription {
	my $subID = shift;
	my $list = _table()->{active};
	for my $event (keys %$list){
		delete $list->{$event}->{$subID} if exists $list->{$event}->{$subID};
	}
	$list = _table()->{frozen};
	for my $event (keys %$list){
		delete $list->{$event}->{$subID} if exists $list->{$event}->{$subID};
	}
}
sub del_own_subscriptions {
	my $owner = shift;
	my $list = _table();
	return unless ref $list->{owner}{ $owner } eq 'HASH';
	my $lista = $list->{active};
	my $listf = $list->{frozen};
	my $own_ev = $list->{owner}{ $owner };
	for my $ev (keys %$own_ev) {
		for (keys %{$own_ev->{$ev}}) {
			delete $lista->{ $ev  }{ $_ } if exists $lista->{ $ev  }{ $_ };
			delete $listf->{ $ev  }{ $_ } if exists $listf->{ $ev  }{ $_ };
		}
	}
	delete $list->{owner}{ $owner };
}
sub del_all_active { $table{active} = () }
sub del_all_frozen { $table{frozen} = () }
sub del_all        { %table         = () }


1;

__END__

=head1 NAME

Kephra::API::EventTable - API to internal events

=head1 DESCRIPTION

Every routine can subscribe a callback to any event that will than triggered
when that event takes place. Also extentions (plugins) can do that. 
Event ID can also be triggered to simulate application events. 
Some function do freeze events to speed up certain repeating actions 
(don't forget to thaw after that). Callbacks can also sanely removed,
if no longer needed.

Names of Events contain dots as separator of of namespaces.

=head1 SPECIFICATION

=head2 add_call

=over

=item * EvenID

=item * CallbackID

for removing that callback. Must be unique in for this event.

=item * Callback

a Coderef.

=item * Owner

for removing all callbacks of that owner.

=back

=head1 List of all Events

=over 4

=item * menu.open

=item * editpanel.focus
   
=item * document.text.select

=item * document.text.change

=item * document.savepoint

=item * document.list

=item * caret.move

=item * app.close

=back

=cut
