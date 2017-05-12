use strict;
use warnings;
use Carp;
use Gtk2::Ex::Simple::List;
use Glib qw(TRUE FALSE);
use Gtk2 qw/-init -threads-init/;
use Data::Dumper;
use Gtk2::Ex::Threads::DBI;
use Gtk2::Ex::DBITableFilter;

# This line is required on win32. I don't know why...
Gtk2::Gdk::Threads->enter if $^O =~ /Win32/;

my $datadir = '.';
writedatafile($datadir);

my $slist = Gtk2::Ex::Simple::List->new (
	 undef			=> 'bool',
	'ID'			=> 'text',
	'Name'			=> 'text',
	'Description'	=> 'text',
	'Quantity'		=> 'int',
	 ''				=> 'text',
);

my $mythread = Gtk2::Ex::Threads::DBI->new( {
	dsn		=> "DBI:CSV:f_dir=$datadir;csv_eol=\n;csv_sep_char=,",
	user	=> '',
	passwd	=> '',
	attr	=> { RaiseError => 1, AutoCommit => 1 }
});

# ----------------------- #
my $pagedlist = Gtk2::Ex::DBITableFilter->new($slist);
$pagedlist->make_checkable;
$pagedlist->add_filter(2, 
	[[0,'cat'], [1,'rat'], [1,'dog'], [0,'elephant'], [0,'lion'], [0,'tiger']]
);
$pagedlist->add_search_box(3);
$pagedlist->add_filter(4, 
	[[1,' >= 0 '], [0, ' >= 10 '], [0, ' >= 80 ']]
);
$pagedlist->count_using(\&count_records);
$pagedlist->fetch_using(\&fetch_records);
$pagedlist->set_thread($mythread);
# ----------------------- #

$mythread->start;

my $window = Gtk2::Window->new;
$window->signal_connect('destroy' => \&terminate);

my $refreshbutton = Gtk2::Button->new_from_stock('gtk-refresh');
$refreshbutton->signal_connect (clicked => 
	sub { 
		$pagedlist->refresh;
	}
);
my $quitbutton = Gtk2::Button->new_from_stock('gtk-quit');
$quitbutton->signal_connect (clicked => \&terminate);

my $hbox = Gtk2::HBox->new (TRUE, 0);
$hbox->pack_start ($refreshbutton, FALSE, TRUE, 0);    
$hbox->pack_start ($quitbutton, FALSE, TRUE, 0);    
my $vbox = Gtk2::VBox->new (FALSE, 0);
$vbox->pack_start ($hbox, FALSE, TRUE, 0);    
$vbox->pack_start ($pagedlist->get_widget, TRUE, TRUE, 0);
$window->add ($vbox);
$window->set_default_size(300, 400);
$window->show_all;
Gtk2->main;

sub terminate {
	$mythread->stop;
	print "Wait for child thread to die...\n";
	sleep 1;
	erasedatafile($datadir);
	Gtk2->main_quit;
}

sub fetch_records {
	my ($dbh, $params) = @_;
	my $names 		= $params->{params}->{columnfilter}->{2};
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

sub count_records {
	my ($dbh, $params) = @_;
	my $names 		= $params->{params}->{columnfilter}->{2};
	my $descpattern	= $params->{params}->{columnfilter}->{3} || '';
	my $valuelimit	= $params->{params}->{columnfilter}->{4}->[0];
	my $names_str = combine(@$names);
	my $sth = $dbh->prepare(qq{
		select 
			count(*)
		from 
			table1
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

sub combine {
	my (@list) = @_;
	my $str = join '\',\'', @list;
	$str = '(\''.$str.'\')';
	return $str;
}

sub writedatafile {
	my $datadir = shift;
	my $datafile = $datadir.'/table1';
	open (FILE, ">$datafile") or croak "Cannot open $datafile\n"
		."I am trying to write to a temp datafile $datafile\n"
		."Make sure the folder $datadir exists and you have write permission ino the folder\n";
	print FILE "selected,id,name,description,quantity\n";
	my @names = qw /cat rat dog elephant lion tiger/;
	my @descs = qw /furry big small herbivore/;
	my $count = 0;
	for my $i (0..100) {
		for my $j (0..110) {
			my $selected = int rand(2);
			my $name = $names[int rand(6)];
			my $desc = $descs[int rand(4)];				
			my $qty = int rand(100);
			print FILE "$selected,$count,$name,$desc,$qty\n";
			$count++;
		}
	}
	close FILE;
}

sub erasedatafile {
	my $datadir = shift;
	my $datafile = $datadir.'/table1';
	open (FILE, ">$datafile") or croak "Cannot open $datafile\n";
	print FILE "";
	close FILE;
}