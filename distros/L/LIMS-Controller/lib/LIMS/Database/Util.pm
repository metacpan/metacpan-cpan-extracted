package LIMS::Database::Util;

use 5.006;

our $VERSION = '1.42';

{ package lims_database;

	require LIMS::Base;
	use Class::DBI;
	use DBI;
	use Date::EzDate;

	our @ISA = qw( lims );
	
	sub DESTROY {
		my $self = shift;
		$self->disconnect_dbh;
		$self->SUPER::DESTROY;
	}
	sub load_dbi {
		use Class::DBI::Loader;
		my $self = shift;
		return if ((defined $ENV{ LIMS_DBLOADER }) &&  ($ENV{ LIMS_DBLOADER } eq 'LOADED'));
		my $loader = Class::DBI::Loader->new(
			dsn       => $self->get_dsn,
			user      => $self->admin_name,
			password  => $self->admin_pass,
			namespace => "DBLoader",
			options => { 	RaiseError => 1,
							PrintError => 1,
							AutoCommit => 0 
			}
		);
		$ENV{ LIMS_DBLOADER } = 'LOADED';
	}
	sub finish {
		my $self = shift;
		$self->disconnect_dbh;
	}
	sub is_unrepentant {
		my $self = shift;
		$self->{ _unrepentant } = 1;
	}
	sub unrepentant {
		my $self = shift;
		$self->{ _unrepentant };
	}
	sub print_db_errors {
		my $self = shift;
		return unless (my $aErrors = $self->db_error);
		print $self->get_error_string($aErrors);
	}
	sub text_errors {
		my $self = shift;
		return $self->get_error_string($self->db_error,$self->standard_error);
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
	sub clear_db_errors {
		my $self = shift;
		$self->{ _db_error } = [];
	}
	sub clear_all_errors {
		my $self = shift;
		$self->clear_db_errors;
		$self->clear_standard_errors;
	}
	
	### Database methods ###
	
	sub rollback_session {
		my $self = shift;
		my $dbh = $self->get_dbh;
		eval {
			$dbh->rollback;
		};
		if ($@){
			$self->db_error($@);
			$self->kill_pipeline;
		}
	}
	sub commit_session {
		my $self = shift;
		my $dbh = $self->get_dbh;
		eval {
			$dbh->commit;
		};
		if ($@){
			$self->db_error($@);
			$self->rollback_session;
			$self->kill_pipeline;
		}
	}
	sub disconnect_dbh {
		my $self = shift;
		if (defined $self->{ _dbh }){
			my $dbh = $self->{ _dbh };
			eval {
				$dbh->disconnect;
			};
			if ($@){
				$self->db_error($@);
				return;
			}
		}
	}
	sub get_dbh {
		my $self = shift;
		unless (defined $self->{ _dbh }){
			$self->set_dbh;
		}
		$self->{ _dbh };
	}
	sub set_dbh {
		my $self = shift;
		$self->{ _dbh } = DBI->connect($self->get_dsn, $self->admin_name, $self->admin_pass,
			{
				PrintError => 0,
				RaiseError => 1,
				AutoCommit => 0
			}) or die "LIMS::Database::Util ERROR;<BR>$@";
	}
	sub get_dsn {
		my $self = shift;
		"DBI:".$self->db_driver.":".$self->database_name.":".$self->host_name;
	}
	sub db_driver {
		'mysql'
	}
	sub host_name {
		'localhost'
	}
	sub database_name {
		'test'
	}
	sub admin_name {
		'test'
	}
	sub admin_pass {
		''
	}
	sub db_error {
		my $self = shift;
		if (@_){
			my @aErrors = @_;
			if (defined $self->{ _db_error }){
				my $aErrors = $self->{ _db_error };
				push (@$aErrors, @aErrors);
			} else {
				$self->{ _db_error } = \@aErrors;
			}
		} else {
			$self->{ _db_error };
		}
	}
	# this method is deprecated
	# insert_into_table now returns the insert_id if there is one
	sub last_insert_id {
		my $self = shift;
		my $statement = "SELECT last_insert_id()";
		$self->sql_fetch_singlefield($statement);
	}
	sub prepare_sth {
		my $self = shift;
		my $statement = shift;
		my $dbh = $self->get_dbh;
		my $sth;
		eval {
			$sth = $dbh->prepare($statement);
		};
		if ($@) {
			$self->db_error($statement,$@);
			$self->kill_pipeline;
		} else {
			return $sth; 
		} 
	}
	sub get_sth {
		my $self = shift;
		if (@_){
			$self->set_sth($self->prepare_sth(shift));
		}
		$self->{ _sth };
	}
	sub set_sth {
		my $self = shift;
		$self->{ _sth } = shift;
	}
	sub sth_finish {
		my $self = shift;
		my $sth = $self->{ _sth };
		eval {
			$sth->finish;
		};
		if ($@){
			$self->kill_pipeline($@);
		} else {
			return 1;
		}
	}
	sub sql_fetch_bindparam {
		my $self = shift;
		my $statement = shift;
		my $query = shift;
		my $dbh;		
		if (@_){
			$dbh = shift;
		} else {
			$dbh = $self->get_dbh;
		}
		my $value;
		eval {
			my $sth = $dbh->prepare($statement);
			$sth->bind_param(1,$query);
			$sth->execute();
			$sth->bind_columns(undef, \$value);
			$sth->fetch();
			$sth->finish(); 
		};
		if ($@) {
			$self->db_error($@);
			$self->standard_error($statement);
			if ($self->unrepentant){
				$self->kill_pipeline;
			} else {
				return;
			}
		} else {
			return $value;
		}
	}
	sub sql_fetch_singlefield {
		my $self = shift;
		my $statement = shift;
		my $dbh;		
		if (@_){
			$dbh = shift;
		} else {
			$dbh = $self->get_dbh;
		}
		my $value;
		eval {
			my $sth = $dbh->prepare($statement);
			$sth->execute(); 
			$sth->bind_columns(undef, \$value);
			$sth->fetch();
			$sth->finish(); 
		};
		if ($@) {
			$self->db_error($statement,$@);
			if ($self->unrepentant){
				$self->kill_pipeline;
			} else {
				return;
			}
		} else {
			return $value;
		}
	}
	sub sql_fetch_multisinglefield {
		my $self = shift;
		my $statement = shift;
		my $dbh;		
		if (@_){
			$dbh = shift;
		} else {
			$dbh = $self->get_dbh;
		}
		my @aValues;
		my $value;
		eval {
			my $sth = $dbh->prepare($statement);
			$sth->execute(); 
			$sth->bind_columns(undef, \$value);
			while($sth->fetch()) {
				push @aValues, $value;
			}
			$sth->finish(); 
		};
		if ($@) {
			$self->db_error($statement,$@);
			if ($self->unrepentant){
				$self->kill_pipeline;
			} else {
				return;
			}
		} else {
			if (wantarray()){
				return @aValues;
			} else {
				return \@aValues;
			}
		} 
	} 
	sub sql_fetcharray_singlerow {
		my $self = shift;
		my $statement = shift;
		my $dbh;		
		if (@_){
			$dbh = shift;
		} else {
			$dbh = $self->get_dbh;
		}
		my $aResult_Row;
		eval {	
			my $sth = $dbh->prepare($statement);
			$sth->execute(); 
			$aResult_Row = $sth->fetchrow_arrayref();
			$sth->finish(); 
		};
		if ($@) {
			$self->db_error($statement,$@);
			if ($self->unrepentant){
				$self->kill_pipeline;
			} else {
				return;
			}
		} else {
			if ($aResult_Row){
				return $aResult_Row;
			} else {
				return;
			}
		}
	}
	# returns an array list - NOT a reference to an array
	sub sql_fetchlist_singlerow {
		my $self = shift;
		my $statement = shift;
		my $dbh;		
		if (@_){
			$dbh = shift;
		} else {
			$dbh = $self->get_dbh;
		}
		my @aResult_Row;
		eval {	
			my $sth = $dbh->prepare($statement);
			$sth->execute(); 
			@aResult_Row = $sth->fetchrow_array();
			$sth->finish(); 
		};
		if ($@) {
			$self->db_error($statement,$@);
			if ($self->unrepentant){
				$self->kill_pipeline;
			} else {
				return;
			}
		} else {
			if (@aResult_Row){
				return @aResult_Row;
			} else {
				return;
			}
		}
	}
	sub sql_fetcharray_multirow {
		my $self = shift;
		my $statement = shift;
		my $dbh;		
		if (@_){
			$dbh = shift;
		} else {
			$dbh = $self->get_dbh;
		}
		my $aaResults_Rows;
		eval {
			my $sth = $dbh->prepare($statement);
			$sth->execute(); 
			$self->set_col_names($sth->{NAME});
			$aaResults_Rows = $sth->fetchall_arrayref();
			$sth->finish(); 
		};
		if ($@) {
			$self->db_error($statement,$@);
			if ($self->unrepentant){
				$self->kill_pipeline;
			} else {
				return;
			}
		} else {
			return $aaResults_Rows;
		}
	}
	sub sql_fetch_dataframe {
		my $self = shift;
		my $table = shift;
		my $aColumns = shift;
		my $where = shift;
		my $hData = {};
		for my $column (@$aColumns) {
			my $statement = "SELECT $column FROM $table $where";
			my $aData = $self->sql_fetch_multisinglefield($statement);
			$hData->{$column} = $aData; 
		}
		return $hData;
	}
	sub set_col_names {
		my $self = shift;
		$self->{ _sth_col_names } = shift;
	}
	sub get_col_names {
		my $self = shift;
		$self->{ _sth_col_names };
	}
	sub sql_fetch_twofieldhash {
		my $self = shift;
		my $statement = shift;
		my $dbh;		
		if (@_){
			$dbh = shift;
		} else {
			$dbh = $self->get_dbh;
		}
		my $aaResults = $self->sql_fetcharray_multirow($statement,$dbh);	# shifting ext dbh, if passed
		if ($aaResults){
			my $hResults = { };
			for my $aRow (@$aaResults){
				$hResults->{ $$aRow[0] } = $$aRow[1];
			}
			return $hResults;
		} else {
			return;
		}
	}
	sub sql_fetchhash_singlerow {
		my $self = shift;
		my $statement = shift;
		my $dbh;		
		if (@_){
			$dbh = shift;
		} else {
			$dbh = $self->get_dbh;
		}
		my $hResultRow;
		eval {
			my $sth = $dbh->prepare($statement);
			$sth->execute(); 
			$hResultRow = $sth->fetchrow_hashref();
			$sth->finish(); 
		};
		if ($@) {
			$self->db_error($statement,$@);
			if ($self->unrepentant){
				$self->kill_pipeline;
			} else {
				return;
			}
		} else {
			return $hResultRow;
		}
	}	
	sub sql_fetchhash_multirow {
		my $self = shift;
		my $statement = shift;
		my $dbh;		
		if (@_){
			$dbh = shift;
		} else {
			$dbh = $self->get_dbh;
		}
		my @ahResults_Rows;
		eval {
			my $sth = $dbh->prepare($statement);
			$sth->execute(); 
			while(my $hResult_Row = $sth->fetchrow_hashref()) {
				push @ahResults_Rows, $hResult_Row;
			}
			$sth->finish(); # we're done with this query
		};
		if ($@) {
			$self->db_error($statement,$@);
			if ($self->unrepentant){
				$self->kill_pipeline;
			} else {
				return;
			}
		} else {
			return \@ahResults_Rows;
		}
	}
	sub return_fields_array {
		my $self = shift;
		my $table = shift;
		my $all = '';
		if (@_){
			$all = shift;	# 'all' indicates return all fields
		}
		my $dbh = $self->get_dbh;

		my $statement = "DESCRIBE $table";
		my $ahResults = $self->sql_fetchhash_multirow($statement);
		my $aFields = [];
		for my $hResult (@$ahResults){
			if ($$hResult{Extra} eq 'auto_increment'){
				next unless ($all eq 'all');
			} 
			my $field = $$hResult{Field};
			push (@$aFields, $field);
		}
		return $aFields;
	}
	sub return_cs_fields {
		my $self = shift;
		my $table = shift;
		
		if (my $aFields = $self->return_fields_array($table)){	
#			my $cs_fields = "";
#			for my $field (@$aFields){		
#				$cs_fields = $cs_fields.$field.",";
#			}
#			$cs_fields =~ s/,$//;
			my $cs_fields = join(",",@$aFields);
			return $cs_fields;
		} else {
			return;
		}
	}
	sub table_fields {
		my $self = shift;
		my $table = shift;
		my $hTable_Fields = $self->{ _table_fields };
		unless (defined $hTable_Fields->{ $table }){
			$hTable_Fields->{ $table } = $self->return_cs_fields($table);
		}
		$hTable_Fields->{ $table };		
	}
	sub insert_into_table {
		my $self = shift;
		my $table = shift;
		my $values = shift;
		my $fields;
		if (@_) {
			$fields = shift;	
		} else {
			$fields = $self->table_fields($table);
		}
		unless ($values && $fields) {	
			$self->standard_error('insert statement could not be completed; values or fields were undefined');
			return;
		}
		my $statement = "
			INSERT INTO $table ($fields)
			VALUES ($values)
			";
		return $self->execute_no_commit($statement);
	}
	# faster and more reliable method, 
	# especially for quoted strings and multiple inserts
	# use insert_and_execute_placeholders where a single value
	# will kill at any execute error
	#Êreturns either array of insert_ids, or number of inserted rows
	sub insert_with_placeholders {
		my $self = shift;
		my $table = shift;
		my $aaValues = shift;
		my ($fields,$placeholders);
		if (@_) {
			$fields = shift;
			$placeholders = shift;
		} else {
			$fields = $self->table_fields($table);
			$placeholders = $self->return_table_placeholders($table);
		}
		$self->kill_pipeline('insert statement could not be completed; values, fields or placeholders were undefined')
			unless ($aaValues && @$aaValues && $fields && $placeholders);
		$self->set_dbh_errors(1,0);
		my $statement = "INSERT INTO $table ($fields) VALUES ($placeholders)";
		my $sth = $self->get_sth($statement);
		my $inserts = 0;
		my $insert_id;
		my @aInsert_IDs = ();
  		for my $aValue (@$aaValues){
  			eval{
  				$sth->execute(@$aValue);
				$insert_id = $sth->{'mysql_insertid'};
  			};
			if ($@) {
				$self->db_error($statement,$@);
				$self->kill_pipeline;
			} else {
				if ($insert_id){
					push(@aInsert_IDs,$insert_id);
				}
				$inserts += $sth->rows;
			}
  		}
		$self->rows_affected($inserts);  		
  		$sth->finish();
  		$self->commit_session unless ($self->dont_commit);
  		if (($insert_id)&&(wantarray( ))){
  			return @aInsert_IDs;
  		} else {
  			return $inserts;	# number of rows inserted
  		}
  	}
  	sub force_no_commit {
  		my $self = shift;
  		$self->{ _no_commit }++;
  	}
  	sub dont_commit {
  		my $self = shift;
  		$self->{ _no_commit };
  	}
  	sub reset_commit {
  		my $self = shift;
  		delete $self->{ _no_commit };
  	}
  	sub set_dbh_errors {
  		my $self = shift;
		my $dbh = $self->get_dbh;
		$dbh->{RaiseError} = shift;
		$dbh->{PrintError} = shift;
  	}
  	sub return_table_placeholders {
  		my $self = shift;
  		my $table = shift;
		my $values = '';
		for (@{$self->return_fields_array($table)}){
			$values .= '?,';
		}
		$values =~ s/,$//;
  		return $values;
  	}
  	sub delete_file {
		my $self = shift;
		my $file_id = shift;
		my $statement = "
			DELETE FROM files
			WHERE file_id = '$file_id'
		";
		return $self->execute_no_commit($statement);
  	}
	sub delete_from {
		my $self = shift;
		my $table = shift;
		my $field = shift;
		my $value = shift;
		my $statement = "
			DELETE FROM $table
			WHERE $field = '$value'
		";
		return $self->execute_no_commit($statement);
	}
	# this method is deprecated - use simple_update_placeholders() instead
	sub simple_table_update {
		my $self 	= shift;
		my $table 	= shift;
		my $field 	= shift;
		my $value 	= shift;
		my $where 	= shift;
		
		my $statement = "
			UPDATE $table
			SET $field='$value'
			WHERE $where
		";
		return $self->execute_no_commit($statement);
	}	
	sub simple_update_placeholders {
		my $self 	= shift;
		my $table 	= shift;
		my $field 	= shift;
		my $value 	= shift;
		my $where 	= shift;
		
		my $statement = "
			UPDATE $table
			SET $field=?
			WHERE $where
		";
		
		return $self->execute_no_commit($statement,[$value]);
	}
	# using placeholders with a single execute
	sub insert_and_execute_placeholders {
		my $self = shift;
		my $table = shift;
		my $values = shift;
		my $fields = $self->table_fields($table);
		unless ($values && $fields) {	
			$self->standard_error('insert statement could not be completed; values or fields were undefined');
			return;
		}
		my $placeholders = $self->return_table_placeholders($table);
		my $statement = "
			INSERT INTO $table ($fields)
			VALUES ($placeholders)
		";
		return $self->execute_no_commit($statement,$values);
	}
	sub execute_no_commit {
		my $self = shift;
		my $statement = shift;
		$self->set_dbh_errors(1,0);
		my $sth = $self->get_sth($statement);
		my $insert_id;
		
		if (@_){
			my $aValues = shift;
			eval {
				$sth->execute(@$aValues);
				$insert_id = $sth->{'mysql_insertid'};				
			};
		} else {		
			eval { 
				$sth->execute();
				$insert_id = $sth->{'mysql_insertid'};
			};
		}
		if ($@){
			$self->db_error($statement,$@);
			if ($self->unrepentant){
				$self->kill_pipeline;
			} else {
			    $self->sth_finish;
				return;
			}
		} else {
		    $self->rows_affected($sth->rows);
		    $self->sth_finish;
            if ($insert_id){
				return $insert_id;
			} else {
				return $statement;
			}
		}
	}
	sub rows_affected {
		my $self = shift;
		@_	?	$self->{ _rows_affected } = shift
			: 	$self->{ _rows_affected };
	}
	sub execute_and_commit {
		my $self = shift;
		my $result = $self->execute_no_commit(shift);
		if ($self->db_error){
			$self->kill_pipeline;
		} else {
			$self->commit_session;
		}
		return $result;
	}
	sub execute_sth_values {
		my $self = shift;
		my $sth = $self->get_sth;
		my $dbh = $self->get_dbh;
		my $insert_id;
		if (@_){
			eval {
				$sth->execute(@_);
				$insert_id = $sth->{'mysql_insertid'};
			};
			$self->rows_affected($sth->rows);
			if ($@){
				$self->standard_error($dbh->{Statement});
				$self->kill_pipeline($@);
			} else {
				if ($insert_id){
					return $insert_id;
				} else {
					return $dbh->{Statement};
				}
			}
		} else {
			$self->kill_pipeline('LIMS::Database::Util ERROR: No values were passed to execute_sth_values()');
		}
	}
	sub do_statement {
		my $self = shift;
		my $statement = shift;
		my $dbh = $self->get_dbh;
		my $rows;
		eval{
			$rows = $dbh->do($statement);
		};
		if ($@){
			$self->standard_error($statement);
			$self->kill_pipeline($@);
		} else {
			return $rows;
		}
	}
	sub do_commit_statement {
		my $self = shift;
		my $result = $self->do_statement(shift);
		$self->commit_session;
		return $result;
	}
	sub file_name {
		my $self = shift;
		my $file = shift;
		$file =~ s/.*\///;
		return $file;
	}
	sub retrieve_file_blob {
		my $self = shift;
		my $statement = shift;	# sql statement to retrieve a blob
		my $dbh = $self->get_dbh;
		$dbh->{LongReadLen} = $self->max_blob_length;	# will throw error if truncated
		return $self->sql_fetch_singlefield($statement);
	}
	sub filehandle_to_blob {
		my $self = shift;
		my $filehandle = shift;
		my $file_name = shift;
		my $dbh = $self->get_dbh;
		binmode($filehandle);
		my $file_str;
		{
			local( $/, undef ) ;
			$file_str = <$filehandle>;
		}
		my $file_id = $self->insert_and_execute_placeholders('files',[$file_str,$file_name]);
		if ($self->any_error) {
			$self->rollback_session;
			$self->kill_pipeline;
		} else {
			$self->commit_session;
			return $file_id;
		}   
	}
	# a db specific blob length should be set. this defaults
	sub max_blob_length {
		32000;	
	}
}

1;


__END__

=head1 NAME

LIMS::Database::Util - Perl object layer for a LIMS database

=head1 DESCRIPTION

LIMS::Database::Util is an object-oriented Perl module designed to be the object layer for a LIMS database. It inherits from L<LIMS::Base|LIMS::Base> and provides automation for DBI services required by a LIMS database, enabling rapid development of Perl CGI scripts. See L<LIMS::Controller|LIMS::Controller> for information about setting up and using the LIMS modules. 

=head1 METHODS

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

Please note: LIMS::Database::Util does not control database privileges - it is assumed that the database login used by the module is only Grant[ed] privileges necessary/suitable for your application. Therefore, if the login does not have update/insert privileges, these methods will return relevant database errors caught by DBI. 

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

=item B<rows_affected>

Returns the value from $sth->rows for the last insert. 

=back

=head3 Handling Errors

One of the main reasons for writing the LIMS modules was because I wanted to be able to deal with all errors - Perl, CGI, DBI - in a more efficient manner, all at the same time. If you want your script to die straight away when an error is caught, you can set the object to be 'unrepentant' as described below. The default is that the object allows you to be sorry for your coding sins, and then explains nicely what's gone wrong. 

Three methods, C<db_error()>, C<standard_error()> and C<any_error()> handle the errors for us, and the C<kill_pipeline()> method prints them out upon killing the script; C<db_error()> returns any database (DBI) errors that have been caught; C<standard_error()> can be used to set any error/complaint in a CGI script, or returns any standard_error that has already been set; while C<any_error()> returns true if errors of any type have been caught. So one line of code handles most eventualities;

	$database->kill_pipeline if ($database->any_error);  

If you have a simple situation where you want to kill the script with an error you've caught in your script, you can combine the error with the C<kill_pipeline()> method;

	$database->kill_pipeline('got a problem');

If you need to, you can clear errors using the methods C<clear_db_errors()>, C<clear_standard_errors()> or C<clear_all_errors()>. 

=head3 Other Methods

=over

=item B<get_dbh>

Returns the embedded DBI database handle. Rarely required, since most DBI functions are handled within LIMS::Database::Util. 

=item B<is_unrepentant>

Causes the script to die if any errors are thrown, printing out all errors and issuing a C<rollback> call to the database.

=item B<finish>

Disconnects the database handle.

=back

=head1 SEE ALSO

L<LIMS::Base|LIMS::Base>, L<LIMS::Controller|LIMS::Controller>, L<LIMS::Web::Interface|LIMS::Web::Interface>

=head1 AUTHORS

Christopher Jones and James Morris, Translational Research Laboratories, Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/trl>

c.jones@ucl.ac.uk, james.morris@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Christopher Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
