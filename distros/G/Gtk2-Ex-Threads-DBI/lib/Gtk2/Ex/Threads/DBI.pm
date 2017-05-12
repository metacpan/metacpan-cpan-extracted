package Gtk2::Ex::Threads::DBI;

our $VERSION = '0.06';

use strict;
use warnings;
use threads;
use threads::shared;
use DBI;
use Data::Dumper;
use Storable qw(freeze thaw);
use Glib;
use Gtk2::Ex::Threads::DBI::Query;

sub new {
	my ($class, $connectionparams) = @_;
	my $self  = {};
	bless ($self, $class);
	$self->{connectionparams} = $connectionparams;
	$self->{queryid} = 0;
	$self->{sharedhash} = undef;
	$self->{pollinginterval} = 500; # Default in milliseconds
	return $self;
}

sub set_polling_interval {
	my ($self, $pollinginterval) = @_;
	$self->{pollinginterval} = $pollinginterval;
}

sub execute {
	my ($self, $queryid, $sqlparams) = @_;
	$self->{sharedhash}->{$queryid.'_executesql'} = 1;
	$self->{sharedhash}->{$queryid.'_sqlparams'} 
		= freeze $sqlparams if $sqlparams;
}

sub register_query {
	my ($self, $object, $runsql, $callback) = @_;
	my $queryid = $self->{queryid}++;
	# Cannot 'share' nested hashes. Hence generate a key
	# by concatenation
	$self->{sharedhash}->{$queryid.'_executesql'} = 0;
	$self->{sharedhash}->{$queryid.'_sqlreturn'} = undef;
	$self->{sharedhash}->{$queryid.'_sqlparams'} = undef;
	$self->{$queryid}->{runsql} = $runsql;
	$self->{$queryid}->{callback} = $callback;
	$self->{$queryid}->{object} = $object;
	my $query = Gtk2::Ex::Threads::DBI::Query->new($queryid, $self);
	return $query;
}

sub start {
	my ($self) = @_;
	my $dsn  = $self->{connectionparams}->{dsn};
	my $user = $self->{connectionparams}->{user};
	my $pwd  = $self->{connectionparams}->{passwd};
	my $attr = $self->{connectionparams}->{attr};
	$self->{sharedhash}->{deathflag} = 0;
	my %sharedhash : shared;
	foreach my $key (keys %{$self->{sharedhash}}) {
		$sharedhash{$key} = $self->{sharedhash}->{$key};
	}
	$self->{sharedhash} = \%sharedhash;
	
	my $thread = threads->create (
		sub {
			my $dbh = DBI->connect($dsn, $user, $pwd, $attr) or warn "Connection failed !";
			while (! $self->{sharedhash}->{deathflag}) {
				foreach my $key (keys %{$self->{sharedhash}}) {
					if ($key =~ /executesql$/ and $self->{sharedhash}->{$key}) {
						my $queryid = $key;
						$queryid =~ s/_executesql$//;
						my $getresults = sub {
							my $sqlparams = $self->{sharedhash}->{$queryid.'_sqlparams'};
							my $thawed_params = thaw $sqlparams;
							return &{ $self->{$queryid}->{runsql} }($dbh, $thawed_params);
						};
						my $result = &$getresults;
						$self->{sharedhash}->{$queryid.'_sqlreturn'} 
							= freeze $result if $result;
						$self->{sharedhash}->{$queryid.'_executesql'} = 0;
					} else {
						threads->yield;
					}
				}
				select(undef, undef, undef, $self->{pollinginterval}/1000);
			}
			$dbh->disconnect if $self->{sharedhash}->{deathflag};
		}
	);
	Glib::Timeout->add ($self->{pollinginterval}, sub {
		if ($self->{sharedhash}->{deathflag}) {
			$thread->join;
			return 0;
		}
		foreach my $queryid (keys %$self) {
			if ($self->{sharedhash}->{$queryid.'_sqlreturn'}) {
				my $do_callback = sub {
					my $sqlreturn = $self->{sharedhash}->{$queryid.'_sqlreturn'};
					my $thawed_sqlreturn = thaw $sqlreturn;
					&{ $self->{$queryid}->{callback} }(
						$self->{$queryid}->{object}, $thawed_sqlreturn
					);
				};
				&$do_callback;
				$self->{sharedhash}->{$queryid.'_sqlreturn'} = undef;
			}
		}
		return 1;
	});	
}

sub stop {
	my ($self) = @_;
	$self->{sharedhash}->{deathflag} = 1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::Threads::DBI - Achieving I<asynchronous DBI like> functionality for
gtk2-perl applications using perl ithreads.

=head1 DESCRIPTION

I want to have my perl-gtk app query a database using DBI and display
the query results.  Some of the queries can take minutes to run and a
naive implementation would mean all GUI interaction was blocked until
the $dbh->execute returned.

This seems to be a fairly common problem.

	http://mail.gnome.org/archives/gtk-perl-list/2004-November/msg00055.html
	http://mail.gnome.org/archives/gtk-perl-list/2005-August/msg00140.html

This package will help you achieve this functionality through the use of 
perl ithreads. An asynchronous DBI like functionality is achieved through
using callbacks from a separate thread.

=head1 SYNOPSIS

	use Glib qw(TRUE FALSE);
	use Gtk2 qw/-init -threads-init/;
	use Gtk2::Ex::Threads::DBI;
	use Storable qw(freeze thaw);

	my $mythread = Gtk2::Ex::Threads::DBI->new( {
		dsn		=> 'DBI:mysql:test:localhost',
		user	=> 'root',
		passwd	=> 'test',
		attr	=> { RaiseError => 1, AutoCommit => 0 }
	});

	my $query = $mythread->register_query(undef, \&call_sql, \&call_back);
	$mythread->start();
	
	my $button = Gtk2::Button->new('fetch data from table using pattern');
	$button->signal_connect (clicked => 
		sub {
			my $pattern = $entry->get_text(); #Get the pattern
			$query->execute([$pattern]);
		}
	);

	# This function gets called from inside the thread
	sub call_sql {
		my ($dbh, $sqlparams) = @_;
		my $params = thaw $sqlparams;
		my $sth = $dbh->prepare(qq{
			# my complicated long query that takes a long time to complete
			select * from xxx
			where yyy like ?
			limit 1000
		});
		$sth->execute('%'.$params->[0].'%');
		my @result_array;
		while (my @ary = $sth->fetchrow_array()) {
			push @result_array, \@ary;
		}
		return \@result_array;
	}

	# This function gets called from inside the thread after sql execution
	sub call_back {
		my ($self, $result_array) = @_;
		@{$slist->{data}} = (); #We'll populate a SimpleList with the data
		foreach my $x (thaw $result_array) {
			push @{$slist->{data}}, @$x;
		}
	}


=head1 METHODS

=head2 new($connectionparams);

Accepts a hash containing the DBI connection params.

	my $mythread = Gtk2::Ex::Threads::DBI->new( {
		dsn		=> 'DBI:mysql:test:localhost',
		user	=> 'root',
		passwd	=> 'test',
		attr	=> { RaiseError => 1, AutoCommit => 0 }
	});

=head2 register_query($caller_ref, $call_sql, $call_back);

All the SQLs that you want to execute should be registered through here

	my $threaded_query = $mythread->register_query(undef, \&call_sql, \&call_back);

The first parameter is a reference to the caller itself. If you are calling this
from a simple script, you can pass C<undef> along.

If you are calling this from another package, it is a good idea to pass the C<$self> as
C<$caller_ref>

	my $threaded_query = $mythread->register_query($self, \&call_sql, \&call_back);

This argument will be passed back to you when the C<\&call_back> get executed.

The C<register_query> API returns a handle to the the C<threaded_query> object. You can 
later on call execute the C<\&call_sql> by specifying.
	
	$threaded_query->execute()

=head2 $threaded_query->execute([$sqlparams]);

This is where the actual sql query gets executed. The C<[$sqlparams]> arrayref 
that you send here will be available as an argument to the C<\&call_sql> 
callback function.

The callback functions themselves should be of the following form

	# This function gets called from inside the thread
	sub call_sql {
		# $dbh is of course the database handle
		# $sqlparams is the same arrayref that you had passed along
		# while calling $threaded_query->execute([$sqlparams]);
		my ($dbh, $sqlparams) = @_;
		
		# Remember, it is very important to thaw the $sqlparams
		my $params = thaw $sqlparams;
		
		# Plain old DBI stuff
		my $sth = $dbh->prepare(qq{
			# my complicated long query that takes a long time to complete
			select * from xxx
			where yyy like ?
		});
		$sth->execute('%'.$params->[0].'%');
		my @result_array;
		while (my @ary = $sth->fetchrow_array()) {
			push @result_array, \@ary;
		}
		
		# Since we are using two threads and since objects such as
		# statement handles cannot be 'shared' between the two threads, 
		# we have to shuttle these pieces of data back and forth.
		# Here the result set has to be loaded into an array and sent back
		return \@result_array;
	}

	# This function gets called from inside the thread after sql execution
	sub call_back {
		# $self is the first argument that you had passed while
		# calling $mythread->register_query($self, \&call_sql, \&call_back);
		# Like I told you before, this'll be of use if you are calling this
		# from within another class. For example, you need this to get a
		# reference to the $self->{slist} if this were oo code.
		#
		# $result_array is the same array_ref that you just passed back
		# as the return value from $call_sql
		# Remember, you need to thaw this once again
		my ($self, $result_array) = @_;
		@{$slist->{data}} = (); #We'll populate a SimpleList with the data
		foreach my $x (thaw $result_array) {
			push @{$slist->{data}}, @$x;
		}
	}

=head2 start();

The actual thread execution starts here. I prefer using a single thread to handle
all of my database queries. So I'll instantiate one C<$thread> in my main program 
and then pass that along to all other child objects. All the child objects will
register their sqls here and get new query handles. They will call these query
handles as required. But there will be only one single thread that handles
all the DBI calls.

The C<start()> function has to be called very early in the main program. Preferrably
before any widget is created.

	http://mail.gnome.org/archives/gtk-perl-list/2003-November/msg00028.html

	$mythread->start();

=head2 stop();

Call this to do all clean up actions. Since we are using polling, it can take as
long as the polling_interval to actually C<join> the child thread.

	$mythread->stop;
	print "Wait for child thread to die...\n";
	sleep 1;
	Gtk2->main_quit;

=head2 set_polling_interval($polling_interval);

Sets the polling interval. By default it is set to 500ms. Keeping it too short will
cost too many CPU cycles. Keeping it too large will cause delays between events.

	$mythread->set_polling_interval(300);

=head1 AUTHOR

Ofey Aikon, C<< <ofey.aikon at gmail dot com> >>

=head1 ACKNOWLEDGEMENTS

To the wonderful gtk-perl-list.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Ofey Aikon, All Rights Reserved.

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 59
Temple Place - Suite 330, Boston, MA  02111-1307  USA.

=cut
