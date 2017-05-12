use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 qw/-init/;
use Data::Dumper;
use Gtk2::Ex::Threads::DBI;
use Gtk2 qw/-init -threads-init/;
# This line is required on win32. I dont know why
Gtk2::Gdk::Threads->enter if $^O =~ /Win32/;

use Gtk2::TestHelper tests => 10;

my $datadir = './t/data';
writedatafile($datadir);

my $mythread = Gtk2::Ex::Threads::DBI->new( {
	dsn		=> "DBI:CSV:f_dir=$datadir;csv_eol=\n;csv_sep_char=,",
	user	=> '',
	passwd	=> '',
	attr	=> { RaiseError => 1, AutoCommit => 1 }
});


isa_ok($mythread, "Gtk2::Ex::Threads::DBI");

my $query1 = $mythread->register_query(undef, \&call_sql_1, \&call_back_1);
isa_ok($query1, "Gtk2::Ex::Threads::DBI::Query");

my $query2 = $mythread->register_query(undef, \&call_sql_2, \&call_back_2);
isa_ok($query2, "Gtk2::Ex::Threads::DBI::Query");

ok($mythread->start);
print "..this'll take 2 seconds\n";
sleep 2;

$query1->execute;
$query2->execute(['rat']);

Gtk2->main;

sub call_sql_1 {
	my ($dbh, $params) = @_;
	my $sth = $dbh->prepare(qq{
		select * from table1
	});
	$sth->execute();
	my @result_array;
	while (my @ary = $sth->fetchrow_array()) {
		push @result_array, \@ary;
	}
	return \@result_array;
}

sub call_back_1 {
	my ($self, $result_array) = @_;
	is($#{@$result_array}, 362);
	my $x = [
          'name0',
          'desc0',
          'cat'
        ];
	is(Dumper($result_array->[0]), Dumper($x));
}

sub call_sql_2 {
	my ($dbh, $params) = @_;
	my $x = ['rat'];
	is(Dumper($params), Dumper($x));
	my $sth = $dbh->prepare(qq{
		select * from table1
		where animal like ?
		order by name desc, description desc
	});
	$sth->execute('%'.$params->[0].'%');
	my @result_array;
	while (my @ary = $sth->fetchrow_array()) {
		push @result_array, \@ary;
	}
	return \@result_array;
}

sub call_back_2 {
	my ($self, $result_array) = @_;
	is($#{@$result_array}, 120);
	my $x = [
          'name9',
          'desc9',
          'rat'
        ];
	is(Dumper($result_array->[0]), Dumper($x));
	terminate();
}

sub terminate {
	ok($mythread->stop);
	print "..this'll take 2 seconds\n";
	sleep 2;
	erasedatafile($datadir);
	Gtk2->main_quit;
}

sub writedatafile {
	my $datadir = shift;
	my $datafile = $datadir.'/table1';
	open (FILE, ">$datafile") or die "Cannot open $datafile\n";
	print FILE "name,description,animal\n";
	for my $i (0..10) {
		for my $j (0..10) {
			for my $k (qw /cat rat dog/) {
				print FILE "name$i,desc$j,$k\n";
			}
		}
	}
	close FILE;
}

sub erasedatafile {
	my $datadir = shift;
	my $datafile = $datadir.'/table1';
	open (FILE, ">$datafile") or die "Cannot open $datafile\n";
	print FILE "";
	close FILE;
}


