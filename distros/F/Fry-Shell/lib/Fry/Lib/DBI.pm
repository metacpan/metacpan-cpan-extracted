package Fry::Lib::DBI;
use strict;
use DBI;
our ($dbh);
sub _default_data {
	return {
		vars=>{user=>'bozo',pwd=>'bozo',db=>'pg',dbname=>'useful',
			dsn=>{qw/mysql dbi:mysql: pg dbi:Pg:dbname= sqlite dbi:SQLite:dbname=/}, 
			attr=>{},
		},
		objs=>{
			dbh=>{}
		},
		methods=>[qw/available_drivers trace data_sources/],
		#all obj: err errstr set_err state func
		class=>'DBI',
	}
}
sub _initLib {
	my ($cls,%arg) = @_;
	my ($dsn,$db,$dbname,$user,$pwd,$attr) = $cls->varMany(qw/dsn db dbname user pwd attr/);
	my $methods = [qw/selectall_arrayref selectall_hashref selectrow_arrayref selectrow_hashref
		get_info table_info column_info primary_key_info
		tables type_info_all do err errstr set_err begin_work commit rollback/],
	#print join(',',$o->varMany(qw/dsn db dbname user pwd attr/));
	$dbh = DBI->connect($dsn->{$db}.$dbname,$user,$pwd,$attr);
	$cls->obj->set('dbh','obj',$dbh);
	$cls->obj->set('dbh','methods',$methods);	
	#$o->lib->obj('Fry::Lib::DBI')->{obj}{dbh} = $dbh = DBI->connect($dsn->{$db}.$dbname,$user,$pwd,$attr);
	#$o->{obj}{dbh}{class} = "Fry::Lib::DBI";
}
1;

__END__	

#unused
sub create_dbh {
	my $cls = shift;
	my ($dsn,$db,$dbname,$user,$pwd,$attr) = $cls->varMany(qw/dsn db dbname user pwd attr/);
	my $dbh = DBI->connect($dsn->{$db}.$dbname,$user,$pwd,$attr);
	$cls->obj->set('dbh','obj',$dbh);
}

=head1 NAME

Fry::Lib::DBI - Autoloaded library for DBI's object methods. 

=head1 Example Command

-p=e objectAct dbh selectall_arrayref,,'select * from perlfn'

=head1 AUTHOR

Me. Gabriel that is.  I welcome feedback and bug reports to cldwalker AT chwhat DOT com .  If you
like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.


=head1 COPYRIGHT & LICENSE

Copyright (c) 2004, Gabriel Horner. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
