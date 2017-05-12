package Gtk2::Ex::DBITableFilter;

our $VERSION = '0.03';

use strict;
use warnings;
use Carp;
use Gtk2::Ex::Simple::List;
use Glib qw(TRUE FALSE);
use Data::Dumper;
use Gtk2::Ex::ComboBox;
use Gtk2::Ex::Simple::Menu;
use Gtk2::Ex::DBITableFilter::BrowserBar;
use Gtk2::Ex::DBITableFilter::FilterWidget;

sub new {
	my ($class, $slist) = @_;
	my $self  = {};
	bless ($self, $class);
	$self->set_increment(500);
	$self->{slist} = $slist;
	$self->{dumpedcachedparams} = undef;
	$self->{params} = undef;
	$self->{browserbar} = undef;
	$self->{filterwidget} = Gtk2::Ex::DBITableFilter::FilterWidget->new($self);
	return $self;
}

sub process_dates {
	my ($self, $fieldname, $list) = @_;
	return $self->{filterwidget}->process_dates($fieldname, $list);
}

sub set_simple_sql {
	my ($self, $callback) = @_;
	$self->{methods}->{count} = sub {
		my ($dbh, $params) = @_;
		my $sql = &$callback($params);
		my $countsql = $sql;
		$countsql = 'select count(*) from ('.$sql.') DBITableFilterTemp';
		print Dumper $countsql;
		my $sth = $dbh->prepare($countsql);
		$sth->execute();
		my @result_array;
		while (my @ary = $sth->fetchrow_array()) {
			push @result_array, $ary[0];
		}
		return \@result_array;	
	};
	$self->{methods}->{fetch} = sub {
		my ($dbh, $params) = @_;
		my $sql = &$callback($params);
		my $fetchsql = $sql;
		$fetchsql = 'select * from ('.$sql.') DBITableFilterTemp limit '
			.$params->{limit}->{start}
			.' , '
			.$params->{limit}->{step};
		print Dumper $fetchsql;
		my $sth = $dbh->prepare($fetchsql);
		$sth->execute();
		my @result_array;
		while (my @ary = $sth->fetchrow_array()) {
			push @result_array, \@ary;
		}
		return \@result_array;	
	};
}

sub set_increment {
	my ($self, $increment) = @_;
	my $limit = $self->{limit};
	$limit->{increment} = $increment;
	$limit->{start} = 0;
	$limit->{end}   = $limit->{increment};
	$limit->{total} = $limit->{increment};
	$self->{limit} = $limit;
}

sub count_using {
	my ($self, $method) = @_;
	$self->{methods}->{count} = $method;
}

sub fetch_using {
	my ($self, $method) = @_;
	$self->{methods}->{fetch} = $method;
}

sub set_thread {
	my ($self, $thread) = @_;
	$self->{thread} = $thread;
	my $fetch_records_query = $thread->register_query (
		$self, $self->{methods}->{fetch}, \&_post_fetch_records 
	);
	$self->{fetch_records_query} = $fetch_records_query;
	my $count_records_query = $thread->register_query (
		$self, $self->{methods}->{count}, \&_post_count_records 
	);
	$self->{count_records_query} = $count_records_query;
}

sub get_widget {
	my ($self) = @_;
	my $scrolledwindow= Gtk2::ScrolledWindow->new (undef, undef);
	$scrolledwindow->set_policy ('automatic', 'automatic');
	$scrolledwindow->add($self->{slist});	
	my $bbar = Gtk2::Ex::DBITableFilter::BrowserBar->new($self);
	$self->{browserbar} = $bbar;
	my $hboxbottom = $bbar->get_widget;
	my $vbox = Gtk2::VBox->new (FALSE, 0);
	$vbox->pack_start ($scrolledwindow, TRUE, TRUE, 0);
	$vbox->pack_start ($hboxbottom, FALSE, TRUE, 0);    
	return $vbox;
}

sub _update_count {
	my ($self, $params) = @_;
	$self->{browserbar}->update_progress_label('Counting');
	$self->{browserbar}->start_progress(0, 0.4);
	$self->{count_records_query}->execute($params);
}

sub refresh {
	my ($self) = @_;
	my $str1 = $self->{dumpedcachedparams} || '';
	my $str2 = Dumper $self->{params};
	if ($str1 eq $str2) {
		# No need to update the count
		print "No need to count\n";
		$self->{browserbar}->end_progress(0.4);
		$self->{browserbar}->start_progress(0.5, 1.0);
		$self->{browserbar}->update_progress_label('Fetching');
		$self->{fetch_records_query}->execute(
			{params => $self->{params}, limit => $self->{limit}}
		);		
	} else {
		# Must update the count
		print "Must re-count\n";
		$self->{dumpedcachedparams} = Dumper $self->{params};
		$self->_update_count({params => $self->{params}});
	}	
}

sub _post_count_records {
	my ($self, $result_array) = @_;
	my $count = $result_array->[0];
	$self->{limit}->{total} = $count;
	$self->{browserbar}->_go_to_first;
}

sub _post_fetch_records {
	my ($self, $result_array) = @_;
	$self->{browserbar}->update_progress_label('Rendering');
	@{$self->{slist}->{data}} = ();
	foreach my $x (@$result_array) {
		push @{$self->{slist}->{data}}, $x;
	}
	$self->{browserbar}->update_progress_label('Showing');
		$self->{browserbar}->end_progress(1);
	$self->{browserbar}->end_progress(0);		
}

sub make_checkable {
	my ($self) = @_;
	my ($slist) = $self->{slist};
	# Add a checkbutton to select all
	$slist->set_headers_clickable(TRUE);
	my $col = $slist->get_column(0);
	my $check = Gtk2::CheckButton->new;
	$col->set_widget($check);
	$check->set_active(TRUE);
	$check->show;  # very important, show_all doesn't get this widget!
	my $button = $col->get_widget; # not a button
	do {
		$button = $button->get_parent;
	} until ($button->isa ('Gtk2::Button'));
	
	$button->signal_connect (button_release_event => 
		sub {
			if ($check->get_active()) {
				$check->set_active(FALSE);
			} else {
				$check->set_active(TRUE);
			}
		}
	);
	$check->signal_connect (toggled => 
		sub {
			my $flag = 0;
			$flag = 1 if $check->get_active();
			foreach my $line (@{$slist->{data}}) {
				$line->[0] = $flag;
			}
		}
	);
}

sub add_choice {
	my ($self, $columnnumber, $list) = @_;
	$self->{filterwidget}->add_choice($columnnumber, $list);
}

sub add_search_box {
	my ($self, $columnnumber) = @_;
	$self->{filterwidget}->add_search_box($columnnumber);
}

sub add_date_filter {
	my ($self, $columnnumber, $preselected) = @_;
	$self->{filterwidget}->add_date_filter($columnnumber, $preselected);
}

1;

__END__

=head1 NAME

Gtk2::Ex::DBITableFilter - A high level widget to present large amounts of data 
fetched using DBI. Also provides data filtering capabilities.


=head1 DESCRIPTION

May be you are dealing with tons of relational data, safely tucked away in an RDBMS, 
accessible using DBI, and may be you would like  to view them in a Gtk2 widget. 
The ideal widget (in most cases) is the Gtk2::TreeView or its younger cousin, 
the Gtk2::Ex::Simple::List.

But then you start worrying about questions like,

- How do I prevent the UI from hanging while reading all the data ?

- How do I present all the data in the TreeView without causing it to explode ?

Gtk2::Ex::DBITableFilter comes to rescue !!

Gtk2::Ex::DBITableFilter is a higher level widget built using Gtk2::Ex::Simple::List 
to achieve the following.

1. Ensure that arbitrary SQLs can be executed to fetch the data.

2. Ensure that UI does not hang while SQL is being executed.

3. Provide some kind of I<paging> functionality. Do not display all fetched data in one
shot, instead spread it into multiple I<pages> with buttons to navigate between pages.

4. Provide some kind of data filtering capability. (Spreadsheets for example allow the
user to filter the data by column using a dropdown box).

=head1 SYNOPSIS

	use Gtk2::Ex::DBITableFilter;
	
	# Either define a new thread or using an existing thread
	my $mythread = Gtk2::Ex::Threads::DBI->new( {
		dsn	=> "dbi:SQLite2:data.dbl",
		user	=> undef,
		passwd	=> undef,
		attr	=> { RaiseError => 1, AutoCommit => 0 }
	});
	
	# Define a list
	my $slist = Gtk2::Ex::Simple::List->new (
		 undef		=> 'bool',
		'ID'		=> 'text',
		'Name'		=> 'text',
		'Description'	=> 'text',
		'Quantity'	=> 'int',
	);

	my $pagedlist = Gtk2::Ex::DBITableFilter->new($slist);
	$pagedlist->add_choice(2, 
		[[0,'cat'], [1,'rat'], [1,'dog'], [0,'elephant'], [0,'lion'], [0,'tiger']]
	);
	$pagedlist->set_simple_sql(\&fetch_easy);
	$pagedlist->set_thread($mythread);

	sub fetch_easy {
		my ($params) = @_;
		my $names 	= $params->{params}->{columnfilter}->{2};
		my $descpattern	= $params->{params}->{columnfilter}->{3} || '';
		my $valuelimit	= $params->{params}->{columnfilter}->{4}->[0];
		my $names_str = combine(@$names);
		return (qq{
			select 
				marked, id, name, description, quantity
			from 
				animals
			where 
				name in $names_str and 
				description like '%$descpattern%'
		});
	}

=head1 SCREENSHOTS

http://ofey.blogspot.com/2005/09/gtk2exdbitablefilter.html

=head1 METHODS

=head2 new($slist);

Constructor accepts a Gtk2::Ex::Simple::List as the argument.

	my $pagedlist = Gtk2::Ex::DBITableFilter->new($slist);

=head2 set_simple_sql(\&call_back);

This method can be used to simplify things to a great extent. If you are using this
method, then you don't need to explicitly define C<count_using(\&call_back)> and
C<fetch_using(\&call_back)>.

Instead you just need to define C<set_simple_sql(\&call_back)>.

The callback in this case will return the SQL query to be executed. Note that you 
don't need to specify C<limit> information in the SQL. Also, the count is obtained
by modifying this SQL internally and executing it against the RDBMS.

Internally, this method will use a subquery C<select count(*) from ($sql) temp>.
Therefore, this method will work only if your underlying RDBMS supports subselects.

Fortunately, most of the RDBMS do (SQLite, MySQL, Oracle, DB2).

	sub fetch_easy {
		my ($params) = @_;
		my $names 	= $params->{params}->{columnfilter}->{2};
		my $descpattern	= $params->{params}->{columnfilter}->{3} || '';
		my $valuelimit	= $params->{params}->{columnfilter}->{4}->[0];
		my $names_str = combine(@$names);
		return (qq{
			select 
				selected, id, name, description, quantity
			from 
				animals
			where 
				name in $names_str and 
				description like '%$descpattern%'
		});
	}

Look at C<examples/filtered-table-sqlite.pl> for an example usage of this function.

=head2 count_using(\&call_back);

Define a callback function to count the records. This call back function will
be called with certain parameters. Look at the example ...

	sub count_records {
		my ($dbh, $params) = @_;
		my $names 	= $params->{params}->{columnfilter}->{2};
		my $descpattern	= $params->{params}->{columnfilter}->{3} || '';
		my $valuelimit	= $params->{params}->{columnfilter}->{4}->[0];
		my $names_str = combine(@$names);
		my $sth = $dbh->prepare(qq{
			select 
				count(*)
			from 
				animals
			where
				name in $names_str and 
				description like '%$descpattern%' and
				quantity $valuelimit
		});
		$sth->execute();
		my @result_array;
		while (my @ary = $sth->fetchrow_array()) {
			push @result_array, $ary[0];
		}
		return \@result_array;	
	}

This function will give you full flexibility in defining and executing your SQL
and meddling with the resultset if you like.

If your RDBMS does not support subselects, then you have to use this route.

=head2 fetch_using(\&call_back);

Define a callback function to fetch the records. This call back function will
be called with certain parameters. Look at the example ...

	sub fetch_records {
		my ($dbh, $params) = @_;
		my $names 	= $params->{params}->{columnfilter}->{2};
		my $descpattern	= $params->{params}->{columnfilter}->{3} || '';
		my $valuelimit	= $params->{params}->{columnfilter}->{4}->[0];
		my $names_str = combine(@$names);
		my $sth = $dbh->prepare(qq{
			select 
				selected, id, name, description, quantity
			from 
				table1
			where 
				name in $names_str and 
				description like '%$descpattern%' and
				quantity $valuelimit
			limit  
				$params->{limit}->{start}, $params->{limit}->{step}
		});
		$sth->execute();
		my @result_array;
		while (my @ary = $sth->fetchrow_array()) {
			push @result_array, \@ary;
		}
		return \@result_array;	
	}

This function will give you full flexibility in defining and executing your SQL
and meddling with the resultset if you like.

=head2 set_thread($mythread);

The C<$mythread> object here is an instance of Gtk2::Ex::Threads::DBI

	$pagedlist->set_thread($mythread);

=head1 SEE ALSO

Gtk2::Ex::Threads::DBI
Gtk2::Ex::ComboBox
Gtk2::Ex::Simple::List

=head1 AUTHOR

Ofey Aikon, C<< <ofey.aikon at cpan dot org> >>

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
