# ------------------------------------------- #
# This example requires a mysql database up and running
# Try thread-dbi-csv.pl if you don't want to set up your own mysql database
# ------------------------------------------- #
use strict;
use warnings;
use Gtk2::Ex::Simple::List;
use Glib qw(TRUE FALSE);
use Gtk2 qw/-init -threads-init/;

# This line is required on win32. I don't know why
Gtk2::Gdk::Threads->enter if $^O =~ /Win32/;

use Data::Dumper;
use Gtk2::Ex::Threads::DBI;
use Storable qw(freeze thaw);

my $mythread = Gtk2::Ex::Threads::DBI->new( {
	dsn		=> 'DBI:mysql:threadtest:localhost',
	user	=> 'threaduser',
	passwd	=> 'parrot',
	attr	=> { RaiseError => 1, AutoCommit => 0 }
});

my $query_1 = $mythread->register_query(undef, \&call_sql_1, \&call_back_1);
my $query_2 = $mythread->register_query(undef, \&call_sql_2, \&call_back_2);
$mythread->start();

# ------------------------------------------- #
# All widget packing code below               #
# ------------------------------------------- #
my $slist = Gtk2::Ex::Simple::List->new (
	'field1'			=> 'text',
	'field2'			=> 'text',
	'field3'			=> 'text',
	'field4'			=> 'text',
	'field5'			=> 'text',
);
my $entry = Gtk2::Entry->new;
my $fetchpatternbutton = Gtk2::Button->new('fetch data by pattern');
my $fetchallbutton = Gtk2::Button->new('fetch all data');
my $hbox = Gtk2::HBox->new (FALSE, 0);
$hbox->pack_start ($entry, TRUE, TRUE, 0);    
$hbox->pack_start ($fetchpatternbutton, FALSE, TRUE, 0); 
$hbox->pack_start ($fetchallbutton, FALSE, TRUE, 0); 
my $scrolledwindow= Gtk2::ScrolledWindow->new (undef, undef);
$scrolledwindow->add($slist);	
my $vbox = Gtk2::VBox->new (FALSE, 0);
$vbox->pack_start ($hbox, FALSE, TRUE, 0);    
$vbox->pack_start ($scrolledwindow, TRUE, TRUE, 0);
my $window = Gtk2::Window->new;
$window->add ($vbox);
$window->set_default_size(300, 400);
# ------------------------------------------- #
# Add all signals handlers                    #
# ------------------------------------------- #
$fetchpatternbutton->signal_connect (clicked => 
	sub {
		my $pattern = $entry->get_text();
		$query_1->execute([$pattern]);
	}
);
$fetchallbutton->signal_connect (clicked => 
	sub {
		$query_2->execute;
	}
);
$window->signal_connect('destroy', 
	sub {
		$mythread->stop;
		print "Wait for child thread to die...\n";
		sleep 1;
		Gtk2->main_quit;
	}
);
$window->show_all;
Gtk2->main;
# ------------------------------------------- #

sub call_sql_1 {
	my ($dbh, $params) = @_;
	my $sth = $dbh->prepare(qq{
		select * from table1 
		where description like ?
		limit 1000
	});
	$sth->execute('%'.$params->[0].'%');
	my @result_array;
	while (my @ary = $sth->fetchrow_array()) {
		push @result_array, \@ary;
	}
	return \@result_array;
}

sub call_back_1 {
	my ($self, $result_array) = @_;
	@{$slist->{data}} = ();
	foreach my $x (@$result_array) {
		push @{$slist->{data}}, $x;
	}
}

sub call_sql_2 {
	my ($dbh) = @_;
	my $sth = $dbh->prepare(qq{
		select * from table1
		limit 1000
	});
	$sth->execute();
	my @result_array;
	while (my @ary = $sth->fetchrow_array()) {
		push @result_array, \@ary;
	}
	return \@result_array;
}

sub call_back_2 {
	my ($self, $result_array) = @_;
	@{$slist->{data}} = ();
	foreach my $x (@$result_array) {
		push @{$slist->{data}}, $x;
	}
}
