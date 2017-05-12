package LIMS::Controller;

use 5.006;

our $VERSION = '1.6';

{ package lims_controller;

	use LIMS::Database::Util;
	use LIMS::Web::Interface;
	
	# web methods come first in the inheritance tree
	our @ISA = qw( lims_interface lims_database );

	sub DESTROY {
		my $self = shift;
		$self->close_log;
		$self->disconnect_dbh;
		$self->SUPER::DESTROY;
	}
	sub finish {
		my $self = shift;
		$self->param_forward;
		$self->print_footer;
		$self->disconnect_dbh;
		$self->close_log;
	}
	### login/session methods ###
	
	sub check_login {
		my $self = shift;
		my $q = $self->get_cgi;
		if (my $db_user_name = $q->param('user_name')){
			if (my $db_user_pass = $q->param('password')){
				$self->check_user_pass;
			} elsif (my $personnel_id = $q->param('personnel_id')){
				$self->check_session;
			} else {
				$self->db_error('No password was entered');
			}
		} else {
			$self->db_error('No user name was entered');
		}
		if ($self->db_error){
			$self->print_errors;
			$self->print_footer;
			return undef;	# bad login
		} else {
			return 1;	# login OK
		}
	}
	sub check_session {
		my $self = shift;
		my $epoch_time = Date::EzDate->new()->{'epoch second'};
		my $sess_start_secs;
		my $session_length = $self->session_length;
		# get session information from db
		if (my $user_session = $self->get_user_session) {
			# check time since last session activity
	  		$sess_start_secs = Date::EzDate->new( $self->session_time )->{'epoch second'};
			my $session_duration = $epoch_time - $sess_start_secs;  			
			if ( $session_duration > $session_length ) {
				$self->db_error('session timed out');
			}
			#Êcheck the user's ip address matches that in the db
			if ( $self->session_ip ne $self->current_ip ) {
				$self->db_error('ip error');
			}	
		} else {
			$self->db_error('session closed');
		}
		# so long as there aren't any errors, update the session to NOW()
		unless( $self->db_error ){
			# compare session time in db with that from cgi
			if (( $sess_start_secs > Date::EzDate->new( $self->current_sess_time )->{'epoch second'}) &&
				( $self->back_sensitive)) {	# is an 'old' session
					$self->standard_error("Data from this page has already been entered into the database.","Please don't use the browser's 'back' button after submitting a form");
					$self->kill_pipeline;
			} else {
				$self->update_session;
			}
		}
	}
	sub update_session {
		my $self = shift;
		$self->alter_session_id(1);
	}
	sub close_session {
    	my $self = shift;		
    	$self->alter_session_id(0);
	}
	sub log_out {
		my $self = shift;
		$self->close_session;
		my $q = $self->get_cgi;
		$q->delete_all();
		$q->param(-name=>'logout',-value=>1);
	}
	sub alter_session_id {
   		my $self = shift;
   		if (@_) {
		   	my $state = shift;
	     	my $date = Date::EzDate->new();
	     	my $mysql_time = $date->{'{year}/{%m}/{%d} %T'};	# unix style %Y actually returns 2-digit year
		   	my $ip_address = $self->current_ip;
		   	my $usr_info_obj = $self->get_user_info;
	     	my $session_id = ($state) ? $ip_address.",".$mysql_time : '';
	     	$usr_info_obj->session_id($session_id);
			$usr_info_obj->update();
			$usr_info_obj->dbi_commit;
			$self->session_id($usr_info_obj->session_id); 
	 	}
  	}
	sub current_ip {
	    my $self = shift;
	    if(defined $ENV{'HTTP_PC_REMOTE_ADDR'}){	# is mac os x server
	    	return $ENV{'HTTP_PC_REMOTE_ADDR'};
	    } else {	# use standard cgi remote host call
	    	my $q = $self->get_cgi;
	    	return $q->remote_host();
	    }
	}
	sub system_ip {
		use Net::Address::IPv4::Local;
		my $ip = Net::Address::IPv4::Local->public;
		return $ip;
	}
	sub current_sess_time {	# from cgi
		my $self = shift;
      	$self->session_arry($self->session_id,1);
	} 
	sub session_ip {	# from db
      	my $self = shift;
      	$self->session_arry($self->get_user_session,0);
  	}
	sub session_id {
		my $self = shift;
		my $q = $self->get_cgi;
		if (@_) {
			$q->param('session_id',shift);
		} else {
			$q->param('session_id');
		}
	}
  	sub session_time {	# from db
      	my $self = shift;
      	$self->session_arry($self->get_user_session,1);
  	}
  	sub session_arry {
      	my $self 	= shift;
      	my $session = shift;	# e.g. 127.0.0.1,2007/10/22 12:2:14
      	my @session = split (/,/, $session);
      	if (@_) {
	        my $element = shift;
	        return($session[$element]);
      	} else {
          	return(@session);
        }
  	}
  	sub get_user_session {
  		my $self = shift;
      	my $user_obj = $self->get_user_info;
		return $user_obj->session_id;	# e.g. 127.0.0.1,2007/10/22 12:2:14
  	}
	sub get_user_info {
	    my $self = shift;
	    unless ($self->{ _user_info }){
	    	$self->{ _user_info } = DBLoader::UserInformation->retrieve($self->personnel_id);
	    }
	    return $self->{ _user_info };
  	}
	sub check_user_pass {
		my $self = shift;
		my $user_name = $self->db_user_name;
		my $user_pass = $self->db_user_pass;
		my $statement = "
			SELECT personnel_id
			FROM user_information
			WHERE full_name = '$user_name'
			AND password = OLD_PASSWORD(?)
		";
		if (my $personnel_id = $self->sql_fetch_bindparam($statement,$user_pass)){
			my $q = $self->get_cgi;
			$q->delete('password','Login');
			$self->personnel_id($personnel_id);
			$self->update_session;
		} else {
			$self->db_error('login failed');
		}
	}
	# user_name and user_pass are only set at login
	sub db_user_name {
		my $self = shift;
		my $q = $self->get_cgi;
		$q->param('user_name');
	}
	sub db_user_pass {
		my $self = shift;
		my $q = $self->get_cgi;
		$q->param('password');
	}
	# personnel_id set by check_login()
	sub personnel_id {
		my $self = shift;
		my $q = $self->get_cgi;
		if (@_) {
			$q->param('personnel_id',shift);
		} else {
			$q->param('personnel_id');
		}
	}
	sub text_errors {
		my $self = shift;
		return $self->get_error_string($self->db_error,$self->standard_error);
	}
	sub print_db_errors {
		my $self = shift;
		return unless (my $aErrors = $self->db_error);
		if ($self->has_cgi){
			my $q = $self->get_cgi;
			$self->print_header unless ($self->title_printed);
			print 	$q->h2("The following errors were reported:"),
					$q->start_p({-class=>'lims_error'});
			for my $error (@$aErrors){
				print 	$q->em($error), 
						$q->br;
			}
			print 	$q->end_p;
		} else {
			print $self->get_error_string($aErrors);
		}
	}
	sub any_error {
		my $self = shift;
		if (($self->standard_error) || ($self->db_error)){
			return 1;
		} else {
			return;
		}
	}
	sub print_errors {
		my $self = shift;
		$self->print_db_errors;
		$self->print_standard_errors;
	}
	sub clear_all_errors {
		my $self = shift;
		$self->clear_db_errors;
		$self->clear_standard_errors;
	}
	sub write_log {
		my $self = shift;
		my $oLog_File = $self->get_log_file;
		$oLog_File->add_text(@_);
	}
	sub close_log {
		my $self = shift;
		if ($self->is_log_open){
			my $oLog_File = $self->get_log_file;
			$oLog_File->close_filehandle;
		}
	}
	sub log_open {
		my $self = shift;
		$self->{ _log_open }++;
	}
	sub is_log_open {
		my $self = shift;
		$self->{ _log_open };
	}
	sub get_log_file {
		require Microarray::File;
		my $self = shift;
		unless (defined $self->{ _log_file }) {
			$self->{ _log_file } = log_file->new($self->create_storage_path('log_file'));
			$self->log_open;
		} 
		$self->{ _log_file };
	}
	sub save_file {
		my $self = shift;
		my $var = shift;
		my ($filehandle,$file_name);
		if (ref $var){	# isa filehandle
			$file_name = shift;
			$filehandle = $var;
		} else {	# var isa file param name
			if (@_){
				($filehandle,$file_name) = $self->upload_file($var,shift);
			} else {
				($filehandle,$file_name) = $self->upload_file($var);
			}
		}
		my $file_id = $self->filehandle_to_blob($filehandle,$file_name);
		return ($file_id, $file_name);
	}

}

1;

__END__


=head1 NAME

LIMS::Controller - Perl object layer controlling the LIMS database and its web interface

=head1 SYNOPSIS

	use LIMS::Controller;

	# login and session control
	my $database = database->new('My CGI Page');
	my $database = database->new_guest('My CGI Page');	# for pages where no user/pass required
	
	# embedded DBI and CGI objects
	my $dbh = database->get_dbh;
	my $q = database->get_cgi;

	# simplified database queries/inserts
	$database->sql_fetch_singlefield($statement);
	my $insert_id = $database->insert_into_table($table,$values);
	
	# error handling for DBI functions
	$database->kill_pipeline if ($database->any_error);
	
	# ....and it even tidies up after itself
	$database->finish;

=head1 DESCRIPTION

LIMS::Controller is a versatile object-oriented Perl module designed to control a LIMS database and its web interface. Inheriting from the L<LIMS::Web::Interface|LIMS::Web::Interface> and L<LIMS::Database::Util|LIMS::Database::Util> classes, the module provides automation for many core and advanced functions required of a web/database object layer, enabling rapid development of Perl CGI scripts.  

=head1 WRITING A LIMS::Controller PLUG-IN

First, look at the L<LIMS::ArrayPipeLine|LIMS::ArrayPipeLine> module. This is the plug-in written along-side LIMS::Controller, to control our laboratory's CGH-microarray LIMS database. There are many standard methods in there that you will probably want/need in your own module. For most situations, simply editing the config file (see below) to set defaults for your own system will suffice to provide you with a working LIMS.  

=head2 SETTING UP YOUR DATABASE

There are several parameters that must be set in a config file. For our L<LIMS::ArrayPipeLine|LIMS::ArrayPipeLine> plug-in, running on a UNIX/LINUX type system, the path to this file is set as '/etc/pipeline.conf' and defined in L<LIMS::ArrayPipeLine|LIMS::ArrayPipeLine>. Most of the parameters are self-explanatory, including database hostname, database login, the base URL for the web server, etc. 

The database being controlled by the module must have a table called C<'USER_INFORMATION'> as described in the accompanying documentation. This table handles user login at the WEB/CGI level. At the database level, a user should be defined with relevant privileges for all required WEB/CGI operations, and the user name and password for this account must be set in the config file. If, for some reason, you need to set other privilege levels beyond these, we suggest you do this at the WEB server level on a script-by-script basis. For instance, you might want to provide browse-only access to some members of staff, or reserve some admin functions for other members of staff. 

=head1 METHODS

=head2 Basic functions

There are actually only a few methods that are used on a regular basis in a CGI script. 

=over 4

=item B<new, new_guest, new_script>

All create a new LIMS::Controller object, but of subtly different flavours. C<new()> creates the embedded DBI and CGI objects, and requires two form parameters; C<'user_name'>, and either C<'password'> or C<'session_id'> which it verifies I<via> the C<'USER_INFORMATION'> table in your database. The method C<new_guest()> is similar but does not require the user parameters and does not verify login. The method C<new_script()> returns a new object without CGI/DBI or user login. So the initial login page to the system would use the C<new_guest()> method, and provide a form to enter a C<user_name> and C<password>. A script receiving a valid C<user_name/password> combination will then return an object from the C<new()> method, and create a valid session_id. Subsequently, the C<new()> method will return an object from a valid C<user_name/session_id> combination. 

=item B<get_dbh, get_cgi>

These methods return the embedded DBI database handle and CGI object respectively. The database handle should not be required, since most DBI functions are handled within LIMS::Controller. It is recommended that you use the object-oriented style of calling CGI methods, although you I<probably> don't HAVE to.  

=item B<is_back_sensitive>

Prevents the user from using the back button on their browser by rejecting an old C<session_id>. 

=item B<is_unrepentant>

Causes the script to die if any errors are thrown, printing out all errors and issuing a C<rollback> call to the database.

=item B<finish>

Tidies up at the end of a script; prints a page footer (if there is one), forwards parameters if not already performed, disconnects from the database and closes a log file (if there is one open).

=item B<page_title>

Returns the page title, set in the C<new()> and C<new_guest()> methods. 

=back

=head2 DBI Functions

Most of these methods are simply wrappers for DBI calls, catching possible errors so that the way they are reported can be controlled in the CGI script. Why not use L<Class::DBI|Class::DBI>? Well you can if you prefer - table classes are already loaded I<via> L<Class::DBI::Loader|Class::DBI::Loader>.  

=head3 Simple SQL 'fetch' methods

Methods fetching the results of C<SELECT> queries are offered in a variety of flavours, returning results in different Perl data structures. Pass these methods a string C<'SELECT'> query. 

=over

=item B<sql_fetch_singlefield>

Return a single row, single value, as a scalar

=item B<sql_fetch_multisinglefield>

Multiple rows of a single value are returned as an array reference 

=item B<sql_fetcharray_singlerow>

Wrapper for the DBI method C<fetchrow_arrayref()>. A single row of multiple values is returned as an array reference

=item B<sql_fetchlist_singlerow>

Wrapper for the DBI method C<fetchrow_array()>. A single row of multiple values is returned as an array

=item B<sql_fetcharray_multirow>

Wrapper for the DBI method C<fetchall_arrayref()>. Multiple rows of multiple values are returned as a reference to a 2D array 

=item B<sql_fetch_twofieldhash>

Special use; If you have a query that returns a row of two values, where the first value is a primary key or other unique index. This method will return a reference to a hash whose keys/values are the first/second values of each row

=item B<sql_fetchhash_singlerow>

Wrapper for the DBI method C<fetchrow_hashref()>. A single row of multiple values is returned as a reference to a hash, whose keys are the column names, and whose values are the row values

=item B<sql_fetchhash_multirow>

Multiple rows of multiple values are returned as a reference to an array of hashes

=item B<retrieve_file_blob>

Utilises C<sql_fetch_singlefield()>, but sets the L<DBI {LongReadLen}|DBI/"LongReadLen_(unsigned_integer,_inherited)"> variable to a default value of 32Mb in order to return long BLOB fields

=back

=head3 SQL Insert and Update methods

Please note: LIMS::Controller does not control database privileges - it is assumed that the database login used by the module is only Grant[ed] privileges necessary/suitable for your application. Therefore, if the login does not have update/insert privileges, these methods will return relevant database errors caught by DBI. 

=over 4

=item B<insert_into_table>

Pass this method the table name together with the values to be inserted as a pre-formatted string, in the correct table column order. The method will generate the field values which will not include an auto-increment primary key. If you need/want to specify the field values, you can pass them as a pre-formatted string after the insert values - in which case the order of the two should match but do not have to be the table column order

=item B<insert_with_placeholders>

Use this method for inserts of multiple rows of data, or if you need to insert quoted strings. This method is called similar to C<insert_into_table()>, except that the values are passed as a reference to a 2D array of values to be inserted. If you need to pass the table fields, then you also need to pass a string of the correct number of placeholders. OK, so this isn't so tidy, but I was lost for a better way to do it. 

Unlike other methods, this will call C<kill_pipeline()> if any errors are caught, or C<commit_session()> upon successful completion of all inserts. If the insert statament returns an C<insert_id>, and the call to this method requests an array, it will return a list of the insert_ids created by each executed statement. Otherwise, it will return the number of inserted rows.

	my $aaValues = [
		[ $value1, $value2 ],
		[ $value3, $value4 ]
	];
	$database->insert_with_placeholders($table,$aaValues);
	$database->insert_with_placeholders($table,$aaValues,"field1,field2","?,?");

=item B<simple_update_placeholders>

Use this method to update a single value in a table row. Pass the table name, the field to be set, the new value, and finally a C<'WHERE'> clause.

=back

=head3 CGI methods

=over 4

=item B<param_forward>

Forwards all current parameters as hidden values. (Hidden in a '4-year old playing hide-and-seek' kind of way - in the HTML).

=item B<min_param_forward>

Forwards only C<'user_name'> and C<'session_id'> parameters as hidden values

=item B<format_url_base_query>

Formats C<'user_name'> and C<'session_id'> parameter values to append to a cgi script's url

=item B<format_redirect>

Pass a script name to format a url to the script with C<'user_name'> and C<'session_id'> parameter values

=item B<format_redirect_full>

Pass a script name to format a url to the script with all parameters

=item B<javascript>

Creates a C<<script>> tag in the HTML header for defining Javascript code. You can pass either an array ref containing one or more URLs to javascript files, or a C<HERE> string of formatted javascript code. 

=back

=head3 Handling Errors

One of the main reasons for writing this module was because I wanted to be able to deal with all errors - Perl, CGI, DBI - in a more efficient manner, all at the same time. If you want your script to die straight away printing relevant errors to the web page, you can set the object to be 'unrepentant' as described above. The default is that the object allows you to be sorry for your coding sins, and then explains nicely what's gone wrong. 

Three methods, C<db_error()>, C<standard_error()> and C<any_error()> handle the errors for us, and the C<kill_pipeline()> method prints them out upon killing the script; C<db_error()> returns any database (DBI) errors that have been caught; C<standard_error()> can be used to set any error/complaint in a CGI script, or returns any standard_error that has already been set; while C<any_error()> returns true if errors of any type have been caught. So one line of code handles most eventualities;

	$database->kill_pipeline if ($database->any_error);  

If you have a simple situation where you want to kill the script with an error you've caught in your script, you can combine the error with the C<kill_pipeline()> method;

	$database->kill_pipeline('got a problem');

Errors can be returned in text (rather than HTML) format by calling the method C<text_errors()>, or printed separately without calling C<kill_pipeline()> using the C<print_db_errors()>, C<print_standard_errors()> or C<print_errors()> methods. If you need to, you can clear errors using the methods C<clear_db_errors()>, C<clear_standard_errors()> or C<clear_all_errors()>. 

=head1 SEE ALSO

L<LIMS::Base|LIMS::Base>, L<LIMS::Web::Interface|LIMS::Web::Interface>, L<LIMS::Database::Util|LIMS::Database::Util>, L<LIMS::ArrayPipeLine|LIMS::ArrayPipeLine>

=head1 AUTHORS

Christopher Jones and James Morris, Translational Research Laboratories, Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/trl>

c.jones@ucl.ac.uk, james.morris@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Christopher Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
