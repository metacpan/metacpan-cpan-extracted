#!/bin/echo This is a perl module and should not be run

package Meta::Db::Dbi;

use strict qw(vars refs subs);
use DBI qw();
use Meta::Utils::System qw();
use Meta::Db::Connections qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.30";
@ISA=qw();

#sub new($);
#sub error($$);
#sub connect_dsn($$$);
#sub connect_xml($$$$);
#sub connect($$);
#sub connect_def($$$);
#sub connect_name($$$$);
#sub connect_info($$$$);
#sub execute_single($$);
#sub execute_arrayref($$);
#sub execute($$$$);
#sub prepare($$);
#sub begin_work($);
#sub commit($);
#sub quote_simple($$);
#sub quote($$$);
#sub disconnect($);
#sub table_info($);
#sub full_table_info($);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)={};
	bless($self,$class);
	$self->{HANDLE}=defined;
	return($self);
}

sub error($$) {
	my($one,$two)=@_;
	throw Meta::Error::Simple("dbi error with text [".$one."] on handle [".$two."]");
}

sub connect_dsn($$$) {
	my($self,$conn,$dsnx)=@_;
	my($user)=undef;
	if($conn->get_use_user()) {
		$user=$conn->get_user();
	}
	my($password)=undef;
	if($conn->get_use_password()) {
		$password=$conn->get_password();
	}
#	Meta::Utils::Output::print("dsnx is [".$dsnx."]\n");
#	Meta::Utils::Output::print("user is [".$user."]\n");
#	Meta::Utils::Output::print("password is [".$password."]\n");
	my($dbxx)=DBI->connect($dsnx,$user,$password,{ HandleError=>\&error });
#	if(!$dbxx) {
#		throw Meta::Error::Simple("error in connect was [".$DBI::errstr."]");
#	}
	# I don't think the next line is needed
#	$dbxx->{RaiseError}=0;
	$dbxx->{AutoCommit}=1;
#	$dbxx->{HandleError}=\&error;
	$self->{HANDLE}=$dbxx;
}

sub connect_xml($$$$) {
	my($self,$file,$conn,$name)=@_;
	my($connections)=Meta::Db::Connections->new_file($file);
	my($connection)=$connections->get_con_null($conn);
	return($self->connect_name($connection,$name));
}

sub connect($$) {
	my($self,$conn)=@_;
	my($dsnx)=$conn->get_dsn_nodb();
	$self->connect_dsn($conn,$dsnx);
}

sub connect_def($$$) {
	my($self,$conn,$defx)=@_;
	my($dsnx)=$conn->get_dsn($defx->get_name());
	$self->connect_dsn($conn,$dsnx);
}

sub connect_name($$$) {
	my($self,$conn,$name)=@_;
	my($dsnx)=$conn->get_dsn($name);
	$self->connect_dsn($conn,$dsnx);
}

sub connect_info($$$) {
	my($self,$conn,$info)=@_;
	my($dsnx)=$conn->get_dsn($info->get_name());
	$self->connect_dsn($conn,$dsnx);
}

sub execute_single($$) {
	my($self,$stat)=@_;
	$self->{HANDLE}->do($stat);
}

sub execute_arrayref($$) {
	my($self,$stat)=@_;
	$self->{HANDLE}->selectall_arrayref($stat);
}

sub execute($$$$) {
	my($self,$stats,$conn,$info)=@_;
	for(my($i)=0;$i<$stats->size();$i++) {
		my($stat)=$stats->getx($i);
		if($stat->is_sql()) {
			my($curr)=$stat->get_text();
			$self->execute_single($curr.";");
		}
		if($stat->is_reconnect()) {
			$self->disconnect();
			$self->connect_name($conn,$stat->get_reconnect_name());
		}
	}
}

sub prepare($$) {
	my($self,$stat)=@_;
	my($sth)=$self->{HANDLE}->prepare($stat);
	return($sth);
}

sub begin_work($) {
	my($self)=@_;
	my($sth)=$self->{HANDLE}->begin_work();
	return($sth);
}

sub commit($) {
	my($self)=@_;
	my($sth)=$self->{HANDLE}->commit();
	return($sth);
}

sub quote_simple($$) {
	my($self,$string)=@_;
	return($self->{HANDLE}->quote($string));
}

sub quote($$$) {
	my($self,$string,$type)=@_;
	return($self->{HANDLE}->quote($string,$type));
}

sub disconnect($) {
	my($self)=@_;
	$self->{HANDLE}->disconnect();
}

sub table_info($) {
	my($self)=@_;
	my($sth)=$self->{HANDLE}->table_info();
	return($sth);
}

sub full_table_info($$$$$) {
	my($self,$o1,$o2,$o3,$o4)=@_;
	my($sth)=$self->{HANDLE}->table_info($o1,$o2,$o3,$o4);
	return($sth);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Db::Dbi - an extension of the regular DBI module.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: Dbi.pm
	PROJECT: meta
	VERSION: 0.30

=head1 SYNOPSIS

	package foo;
	use Meta::Db::Dbi qw();
	my($object)=Meta::Db::Dbi->new();
	my($result)=$object->do("CREATE DATABASE foo");

=head1 DESCRIPTION

This is my extension of the Dbi module.
The reason that there is no inheritance here is that DBI is hard to inherit
from since the object which is the database handle (which is returned from
connect) is not clear (I mean which object is it). And all the internals
of the other objects (statement handles and others) are not well documented.
This is the reason that this object just stores a handle and not IS a handle.

=head1 FUNCTIONS

	new($)
	error($$)
	connect_dsn($$$)
	connect_xml($$$$)
	connect($$)
	connect_def($$$)
	connect_name($$$)
	connect_info($$$)
	execute_single($$)
	execute_arrayref($$)
	execute($$$$)
	prepare($$)
	begin_work($)
	commit($)
	quote_simple($$)
	quote($$$)
	disconnect($)
	table_info($)
	full_table_info($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This is a constructor which gives you a new Dbi object.

=item B<error($$)>

This class method will handle error for us by raising an exception with the
relevant errors data.

=item B<connect_dsn($$$)>

This will connect the Dbi to the specified connection data if you spply the DSN.
Input:
0. object to connect.
1. connection object.
2. DSN used for connection.

=item B<connect_xml($$$$)>

This method will receive:
0. A Meta::Db::Dbi object to connect.
1. A file name of XML data for connection.
2. A name of a connection to connect with.
3. A name of a database to connect to.
The method will connect the Dbi object.

=item B<connect($$)>

This will connect the Dbi to the specified connection data.
The connection will NOT be to a specific database.
Parameters:
0. Dbi object - handle of the object to connect.
1. Meta::Db::Connection object - used to get the connection information.

=item B<connect_def($$$)>

This will connect to a server and a specific db within the server.

=item B<connect_name($$$)>

This will connect to a server and a specific db name within the server.

=item B<connect_info($$$)>

This method will connect the Dbi handle to a specific db name take from an info object.

=item B<execute_single($$)>

This method will execute a single sql statement and will return the result. 

=item B<execute_arrayref($$)>

This method will execute a select_arrayref dbi.

=item B<execute($$$$)>

This method will execute a list of statements on the Dbi connection.

=item B<prepare($$)>

This method will prepare a statement for execution.
This method returns the handle to the prepared statement.

=item B<begin_work($)>

This methos is exactly like the DBI::begin_work method except it
raises exceptions in the case of errors.

=item B<commit($)>

This method is exactly like the DBI::commit method except it
raises exceptions in the case of errors.

=item B<quote_simple($$)>

This is the most basic quoting mechanism without type specification.

=item B<quote($$$)>

This is the two argument Dbi quote function.

=item B<disconnect($)>

This method will disconnect the Dbi object according to the specified
connection data.

=item B<table_info($)>

This method will give you the list of tables in the database.

=item B<full_table_info($$$$$)>

This method will give you the list of tables in the database.

=item B<TEST($)>

Test suite for this object.

=back

=head1 SUPER CLASSES

None.

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV get graph stuff going
	0.01 MV more perl quality
	0.02 MV perl qulity code
	0.03 MV more perl code quality
	0.04 MV revision change
	0.05 MV languages.pl test online
	0.06 MV db stuff
	0.07 MV advance the contacts project
	0.08 MV xml data sets
	0.09 MV more data sets
	0.10 MV perl packaging
	0.11 MV data sets
	0.12 MV PDMT
	0.13 MV some chess work
	0.14 MV more movies
	0.15 MV fix database problems
	0.16 MV md5 project
	0.17 MV database
	0.18 MV perl module versions in files
	0.19 MV movies and small fixes
	0.20 MV more thumbnail stuff
	0.21 MV thumbnail user interface
	0.22 MV more thumbnail issues
	0.23 MV website construction
	0.24 MV improve the movie db xml
	0.25 MV web site development
	0.26 MV web site automation
	0.27 MV SEE ALSO section fix
	0.28 MV download scripts
	0.29 MV teachers project
	0.30 MV md5 issues

=head1 SEE ALSO

DBI(3), Error(3), Meta::Db::Connections(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-use Meta::Class::MethodMaker so that inheritance and code will be cleaner.

-use the connect_cached method of the DBI instead of straight connect.

-add convenience method of auto_commit on and off.
