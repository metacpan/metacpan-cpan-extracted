package Fry::Lib::CDBI::Basic;
use strict;

our $VERSION='0.15';
my $sql_count;
#our $cdbi_search = "search_abstract";
#other possible values are cdbi_search,cdbi_regex and cdbi_search_like

#functions
	sub _default_data {
		my $class = shift;
		
		return {
			depend=>[':CDBI::Load'],
			vars=>{
				editor=>$ENV{EDITOR},
				splitter=>'=',
				insert_columns=>'',
				abstract_opts=>{logic=>'and'},
				insert_delimiter=>',,',
				cdbi_search=>'search_abstract',
				#flags
				safe_update=>1,
				only_modified=>1,
			},
			subs=>{parseHash=>{qw/a h/},parseHashref=>{qw/a hr/},
				printTextTable=>{qw/a tt/}
				#search=>{sub=>'search'},search_like=>{}
			},
			cmds=>{
				print_columns=>{a=>'pc',d=>'Prints columns of current table',u=>''},
				search_abstract=>{a=>'s',aa=>\&aliasInputAndSql,
					d=>'Search for results via AbstractSearch'
					,u=>'@search_term'},
				cdbi_search=>{a=>'sn',aa=>\&aliasInputAndSql,u=>'@search_term'},
				cdbi_search_like=>{a=>'sl',aa=>\&aliasInputAndSql,u=>'@search_term'},
				cdbi_search_regex=>{a=>'sr',aa=>\&aliasInputAndSql,u=>'@search_term'},
				cdbi_delete=>{a=>'d',aa=>\&aliasInputAndSql,
					d=>'Deletes results of given query',u=>'@search_term'},
				cdbi_create=>{a=>'i',aa=>\&aliasInsert, d=>"Creates a record",
					u=>'($value$delim)+'},
				cdbi_find_or_create=>{a=>'fc',aa=>\&aliasInputAndSql, d=>"Find or create a record",
					u=>'@search_term'},
				cdbi_multi_insert=>{a=>'mi',arg=>'$file',u=>'$file'},
				cdbi_update=>{a=>'U',aa=>\&aliasInputAndSql, d=>'Updates records via a text editor',
					u=>'@search_term'},
				replace=>{d=>'evals each value of each result row with $operation', a=>'r',
					u=>'@search_term$operation'},
				cdbi_delete_obj=>{a=>':d',u=>'@cdbi'},
				cdbi_update_obj=>{a=>':U',u=>'@cdbi'},
				verify_no_delim=>{a=>'V',aa=>\&aliasInputAndSql, u=>'@cdbi',
					d=>"Verify that specified records don't have display delimiter in them"},
				display_table_list=>{qw/a dpt/, d=>'Displays public tables',u=>''},
				print_dbi_log=>{a=>'dpl',d=>'Prints the current DBI log',u=>''},
				clear_dbi_log=>{d=>'Clears the dbi log',u=>'',a=>'dcl',u=>''},
				set_dbi_log_level=>{a=>'dsl',d=>'Sets the log level of a DBI handler',
					u=>'$num'},
			},
			opts=>{cdbi_search=>{qw/a cs type var noreset 1 default cdbi_search_regex/ }}
			#retrieve_all retrieve/],
			#construct,has*,trigger,constrain_column,set_sql
			#}
			#subs=>{aliasInputAndSql=>{}},
			#td: obj-$result(autoupdate,update,delete,set/get,copy,discard_changes,is_changed),$iterator,$col,$relation
		}
	}	
	sub _initLib {
		my $cls = shift;
		$cls->_set_insert_col;
		$cls->Var('abstract_opts')->{cmp} =  $cls->_regex_operator;

		#ugly, should be in _default_data
		$cls->call(var=>'set','cdbi_search',enum=>[qw/cdbi_search cdbi_search_like cdbi_search_regex search_abstract/]);
	       	$cls->call(var=>'set','cdbi_search',default=>'cdbi_search_regex');
	}
	#note for library use outside of shell
	#this module depends on external subs: &parse_num

	##utils
	sub uniqueInArrays {
		my ($cls,$uniq,$array2) =@_; 
		my (@unique,%seen,$i,@num);
		
		for (@$array2) {$seen{$_}++}
		for (@$uniq) { $i++; do {push(@unique,$_);push(@num,$i) } if (! exists $seen{$_}) }
		return (\@unique,\@num);
	}
	sub file2array {
		shift;
		#local function
		#d:converts file to @ of lines
		open(FILE,"< $_[0]");
		my @lines; chomp(@lines = <FILE>);
		close FILE;
		return @lines;
	} 
	sub check_for_regex {
		#d: AoHregexp, could be used as an 'or' search on multiple columns
		my ($class,$regex,@records) = @_;
		my @unclean;

		for (@records) {
			for my $col (@{$class->Var('action_columns')}) {
				if ($_->$col =~ /$regex/) {
					push(@unclean,$_);
					last; #break?
				}
			}
		}
		return @unclean;
	}
	#internal methods
	sub _set_insert_col {
		my $cls = shift;
		#set insert_columns 
		my @insert_columns = @{$cls->Var('columns')};
		shift @insert_columns;
		$cls->setVar(insert_columns=>\@insert_columns);

	}	
	sub regexChangeAoH {
		my ($cls,$op,@records2update) = @_;
		for my $rec (@records2update) {
			for (my $j=0; $j < @{$cls->Var('action_columns')}; $j++) {
				my $col= $cls->Var('action_columns')->[$j];
				$_ = $rec->$col;
				eval $op; die($@) if $@;
				$rec->$col($_);
			}
		$rec->update;
		}
	}
	sub modify_file {	
		my ($cls,$tempfile) = @_;
		my $inp;

		system($cls->Var('editor') . " $tempfile");# or die "can't execute command as $<: $@";
		#?: why does this system always return a fail code
		#$cls->view("cdbi_update (y/n)? "); chomp($inp = <STDIN>);
		$inp = $cls->Rline->stdin("cdbi_update (y/n)?");
		return ($inp eq "y");
	}
	sub update_from_file {
		my ($cls,$tempfile,@records) = @_;

		my @lines = $cls->file2array($tempfile);

		#my $firstline = shift(@lines);
		#read column order from file
		#my @fields = split(/$updatedelim/,$firstline);
		#or not
		my @fields = @{$cls->Var('action_columns')};

		my $i;
		foreach (@records) {		#each row to update
			my @fvalues = split(/${\$cls->Var('field_delimiter')}/,$lines[$i]);
			for (my $j=0; $j < @fields; $j++) {		#each column to update

				my $temp=$fields[$j];
				$_->$temp($fvalues[$j]);		# this line = $_->$field($fieldvalue)
			}
			$_->update;
			#$_->dbi_commit if ($db = postgres
			$i++;
		}
	}
	sub col2f1 {
		#d: aliases column names with c and number
		my $class = shift;
		my @newterms;

		for (@_) { 
		#if (/c(\d+)=/) { my $col = $col[$1-1];s/c\d+/$col/} 
		if (/c([-,\d]+)(.*)/) { 
		my @tempcol = $class->sub->parseNum($1,@{$class->Var('columns')});
			for my $eachcol (@tempcol) {  
				push(@newterms,$eachcol.$2);
			}
		}
		else {push (@newterms,$_)}
		}
		return @newterms;
	}
#sub objects
	##print functions,input is objects
	sub printtofile {
		#d:prints rows to temporary file
		my ($cls,$tempfile,@records) =  @_;

		my $output = join($cls->Var('field_delimiter'),@{$cls->Var('action_columns')})."\n";
		$output .= $cls->View->objAoH_dt(\@records,$cls->Var('action_columns'));
		$cls->View->file($tempfile,$output);
	}
	sub printTextTable {
		my $cls = shift;
		$cls->print_text_table(\@_,$cls->Var('action_columns'));
	}
	sub print_text_table {
		my $cls = shift;
		my ($ref1,$ref2) = @_; my @row = @{$ref1}; my @columns = @{$ref2};
		my (@column_values,@longest);

		#defaul
		eval { use Text::Reform}; die $@ if ($@);

		for my $column (@columns) {
			my @column_value;
			my $longest = length($column);
			for (@row) {
				#find longest string in each column including string
				my $newlength = length($_->$column);
				$longest = $newlength if ($newlength > $longest);

				push(@column_value,$_->$column);
			}
			push(@longest,$longest);
			push(@column_values,\@column_value);
		}	

		#create format
		my $line_length = 3 * @columns + 1; 
		my $picture_line = "|";

		for (@longest) { 
			$line_length += $_ ;
			$picture_line .= " " . "["x $_ . " |";
		}
		my $firstline = "=" x $line_length;
		#$picture_line .= "\n" . "-" x $line_length; 

		#print column names
		$cls->view(form $picture_line,@columns);
		#print body
		$cls->view(form $firstline,$picture_line, @column_values);
	}
	sub print_horizontal_numbered_list {
		my ($cls,$prompt,$list) = @_;
		my $a;

		my $output = $prompt; 
		for (@$list){$a++;$output .= "$a.$_ " };
	       	$output .= "\n";
		$cls->view($output);
	}	
	##alias fns
	sub cdbiDbh { shift->Var('table_class')->db_Main }
	sub aliasInputAndSql { my $cls = shift; 
		return $cls->aliasSqlAbstract($cls->aliasInput(@_)) }
	sub aliasInput {
		my $class =  shift;
		@_ = $class->Var('columns')->[0].$class->Var('splitter').".*" if ($_[0] eq "a");  #all results given
		@_ = $class->col2f1(@_) if ("@_" =~ /c[-,\d]+=/);	#c\d instead of column name
		return @_;
	}
	sub aliasInsert {
		#d:parses userinput to hashref for &create
		my $cls = shift;
		my %chosenf;
		#die "Nothing given for cdbi_insert" if (not defined @_);
		my @fields = split(/${\$cls->Var('insert_delimiter')}/,"@_");
		my @insert_columns = @{$cls->Var('insert_columns')};

		for (my $i=0;$i< @insert_columns;$i++) {
			$chosenf{$insert_columns[$i]} = $fields[$i];
			$cls->view("$insert_columns[$i] = $fields[$i]\n");
		}
		return \%chosenf;
	} 
	sub aliasSqlAbstract {
		#d:parse to feed to sql::abstract
		#note: operators hardcoded for now	
		my $class =  shift;
		my @processf;
		my $splitter = $class->Var('splitter');

		foreach (@_) {
			if (/$splitter([>!<])=/) {
				my $operator = $1;
				my ($key,$value) = split(/=$operator=/);
				push(@processf,$key,{"$operator\=",$value});
			}	
			elsif (/$splitter([><=])/) {
				my $operator = $1;
				my ($key,$value) = split (/$splitter$operator/);
				push(@processf,$key,{$operator,$value});
			}	
			#embedded sql
			elsif (/$splitter(.*)$splitter/) {
				my $literal_sql = $1;
				$literal_sql =~ s/_/ /g;
				my ($key,$dump) = split (/$splitter/);
				push(@processf,$key,\$literal_sql);
			}	
			#default operator
			#elsif(/=/) 
			else {
				my ($key,$value) = split(/$splitter/) or die "error splitting select";
				push(@processf,$key,$value);
			}	
			#else { warn "no valid operator specified" };	
		}
		return @processf;
	}
	##parse functions,input is from commandine
	sub parseHash {
		my ($cls,$input) = @_;

		my @arg = split(/ /,$input);
		my $cmd = shift @arg;
		my %results = $cls->parseIndHash($cls->Var('splitter'),@arg);
		return ($cmd,%results)
	}
	sub parseHashref {
		my ($cls,$input) = @_;
		my ($cmd,%results) = $cls->parseHash($input);
		return ($cmd,\%results);
	}
	sub parseIndHash {
		my ($class,$splitter,@chunks) =  @_;
		my %processf;

		for (@chunks) {
			my ($key,$value) = split(/$splitter/) or die "error splitting select";
			$processf{$key} = $value;
		}	
		return %processf;
	}
#commands
	sub print_columns {
		my $cls =  shift;
		$cls->print_horizontal_numbered_list($cls->Var('table')."'s columns are ",$cls->Var('columns')); 
	}
	sub search_abstract {
		#d:handles multiple parsing cases and returns search results 
		my $cls =  shift;
		if (@_ ==0 ) {warn("No arguments given to &search_abstract\n");return () }  
		$cls->sub->_require('Class::DBI::AbstractSearch');
		$cls->sub->useThere('Class::DBI::AbstractSearch',$cls->Var('table_class'));

		#calling class determines class
		my @results = $cls->Var('table_class')->Class::DBI::AbstractSearch::search_where(\@_,$cls->Var('abstract_opts'));
		$cls->saveArray(@results) if ($cls->Flag('menu'));
		return @results;
	}
	sub cdbi_search { shift->Var('table_class')->search(@_) }
	sub cdbi_search_like { shift->Var('table_class')->search_like(@_) }
	sub cdbi_search_regex { shift->Var('table_class')->search_regex(@_) }
	sub cdbi_create { shift->Var('table_class')->create(@_) }
	sub cdbi_delete {
		#td: chain
		my $cls =  shift;
		my @aliasedinput = @_;
		my @results = $cls->${\$cls->Var('cdbi_search')}(@aliasedinput);
		#my @results = $cls->sub->subHook(args=>\@aliasedinput,var=>'cdbi_search',default=>'search_abstract',caller=>$cls);
		$cls->cdbi_delete_obj(@results);
	}
	sub cdbi_find_or_create {
		my ($cls,%dt)    = @_;
		#my $hash     = ref $_[0] eq "HASH" ? shift: {@_};
		my ($exists) = $cls->${\$cls->Var('cdbi_search')}(%dt);
		return defined($exists) ? $exists : $cls->Var('table_class')->create(\%dt);
	}
	sub cdbi_multi_insert {
		my ($cls,$file) = @_;

		chomp(my @lines= $cls->file2array($file));
		for (@lines) {
			$cls->create($cls->aliasInsert($_));
		}	
	}
	sub replace {
		#td:chain
		my $cls = shift;
		my $op = pop(@_);

		my @records2update = $cls->${\$cls->Var('cdbi_search')}($cls->aliasInputAndSql(@_));
		$cls->regexChangeAoH($op,@records2update);
	}
	sub verify_no_delim {
		#td:chain
		my $cls = shift;

		my @records2update = $cls->${\$cls->Var('cdbi_search')}(@_);
		my $clean = $cls->verify_no_delim_obj(@records2update);
		$cls->view("No records containing delimiter found") if ($clean);
	}
	sub cdbi_update {
		#td:chain
		my $cls =  shift;
		#$cls->cdbi_update_obj($cls->${\$cls->Var('cdbi_search')}(@_));
		$cls->cdbi_update_obj($cls->search_abstract(@_));
	}
	##$result obj
	sub cdbi_update_obj {
		my ($cls,@records2update) = @_;
		$cls->sub->_require('File::Temp');
		do {warn("File::Temp"); return} if ($@);
		my (undef,$tempfile) = File::Temp::tempfile();
		#$tempfile = 'ya';

		if ($cls->Flag('safe_update')) {
			my $clean = $cls->verify_no_delim_obj(@records2update);
			return if (not $clean);
		}

		$cls->printtofile($tempfile,@records2update);

		#only for changed rec
		my @original_lines = $cls->file2array($tempfile)
			if ($cls->Flag('only_modified'));

		my $modify = $cls->modify_file($tempfile);

		#only update changed records
		if ($cls->Flag('only_modified')) {
			my @new_lines = $cls->file2array($tempfile);
			#shift off columns line
			shift(@new_lines); shift(@original_lines);

			my ($modified_lines,$num) = ([],[]);
			($modified_lines,$num) = $cls->uniqueInArrays(\@new_lines,\@original_lines);
			#exit early if nothing to modify
			if (@$modified_lines == 0) { $modify = 0; last }

			#write new file
			$cls->View->file($tempfile,join("\n",@$modified_lines));
			@records2update = $cls->sub->parseNum(join(',',@$num),@records2update);
		}

		$cls->update_from_file($tempfile,@records2update) if ($modify);
	}
	sub verify_no_delim_obj {
		my ($cls,@records) = @_;

		my @unclean_records =
		$cls->check_for_regex($cls->Var('field_delimiter'),@records);
		#$cls->check_for_regex('a',@records);

		if (defined @unclean_records) {
			$cls->view( "The following are records containing the delimiter '",
			$cls->Var('field_delimiter'),"':\n\n");
			$cls->View->objAoH(\@unclean_records,$cls->Var('action_columns'));
			return 0;
		}
		#passed successfully
		return 1;
	}
	sub cdbi_delete_obj {
		my $class =  shift;
		for (@_) { $_->delete; }
	}
#$dbh commands: could be used in DBI
	sub display_table_list {
		my ($class,$dbh) = @_;
		$class->print_horizontal_numbered_list("Database's tables are ",[$class->get_table_list($dbh)]); 
	}
	sub print_dbi_log {
		my ($cls) = @_;
		my $dbh =  $cls->cdbiDbh;
		$cls->view($dbh->{Profile}->format);
	}
	sub clear_dbi_log {
		my ($cls) = @_;
		my $dbh =  $cls->cdbiDbh;
		$dbh->{Profile}->{Data}=undef;
	}
	sub set_dbi_log_level{
		my ($cls,$num) = @_;
		my $dbh =  $cls->cdbiDbh;

		if ($num > 15 or $num < -15) {
			warn" given log level out of -15 to 15 range";
		}	
		else { $dbh->{Profile} = $num; }
	}
	#$dbh = (defined $dbh) ? $cls->idToObj($dbh) : $cls->cdbiDbh;
	##other
	sub t_file {
		my $cls = shift;
		#w
		my $file = shift || do { $cls->view("No file given.\n"); return 0 };
		if (! -e $file) { $cls->view("File doesn't exist.\n"); return 0};
		return 1;
	}
	sub cmpl_file {
	}
	###internal
	sub get_table_list {
		my ($cls,$dbh) = @_;
		$dbh = (defined $dbh) ? $cls->idToObj($dbh) : $cls->cdbiDbh;
		my $sth = $cls->get_table_info($dbh);
		return warn "Driver hasn't implemented the table_info() method" unless (ref $sth);
		my @tables =  map {$_->[2]} @{$sth->fetchall_arrayref};
		return @tables;
	}
	sub get_table_info {
		#d: displays public tables for postgres, may have to adjust &table_info per database
		my ($class,$dbh,$table) = @_;
		my $catalog = undef;
		my $schema = ($class->Var('db') eq "postgres") ? 'public' : undef;
		my $type;
		return  $dbh->table_info($catalog,$schema,$table,$type);
	}
1;

__END__	

	#unused
	sub print2darr { 
		#d: not used since similar fn ported to View::CLI 
		#d: prints a two dimensional table with objects as rows and object attributes as columns
		my $cls = shift;
		my ($ref1,$ref2,$FH) = @_; my @row = @{$ref1}; my @columns = @{$ref2};
		my $i;
		no strict 'refs'; #due to TEMP symbol
		
		for (@row) {
			#h:
			if ($cls->Flag('menu')) {
				$i++; print $FH "$i: "
			}
			for my $column (@columns) {
				print $FH $_->$column;
				print $FH $cls->Var('field_delimiter');
			}
			print $FH "\n";
		}
	}
	##experimental
	##has_a,has_many
	sub cdbi_hasa {
		my ($class,$from_class,$to_class,$column) = @_;
		$from_class->has_a($column=>$to_class);
	}
	sub direct_sql {
		#d:experimental
		my $class = shift;
		$sql_count++;

		$class->set_sql($sql_count=>"@_");
		my $method = "search_$sql_count";
		my @results = $class->$method;
		$class->print2darr(\@results,$class->action_columns,'STDOUT');
	}
	#from select: $o->has_a(path_id=>$o) if ($o->_flag->{join});

=head1 NAME

Fry::Lib::CDBI::Basic - A basic library of Class::DBI functions for use with Fry::Shell.

=head1 VERSION

This document describes version 0.14.

=head1 DESCRIPTION 

This module contain wrappers around Class::DBI methods for common database functions such as
creating,deleting,inserting and updating records.  There are also some basic functions to enable and
view DBI::Profile logs.

=head1 COMMANDS

	Search
		*search_abstract
		*cdbi_search
		*cdbi_search_like
		*cdbi_search_regex
	Search based
		cdbi_delete
		*cdbi_update
		*verify_no_delim
		*replace
		cdbi_find_or_create
	Menu based
		cdbi_delete_obj
		cdbi_update_obj
		verify_no_delim_obj
	Debugging via DBI::Profile
		set_dbi_log_level	
		print_dbi_log
		clear_dbi_log
	Other
		cdbi_create
		cdbi_multi_insert
		display_table_list
		print_columns

	Note: Any command with a * is affected by the variable action_columns

=head2 Search Commands

These commands search and give back Class::DBI objects. 

	cdbi_search(@search_term): wrapper around &Class::DBI::search
	cdbi_search_like(@search_term): wrapper around &Class::DBI::search_like
	cdbi_search_regex(@search_term): does regular expression searches (ie REGEXP for Mysql or ~ for Postgresql)
	search_abstract(@search_term): wrapper around Class::DBI::AbstractSearch::search_where,
		by default does regular expression searches, change this via
		$cls->Var('abstract_opts')->{cmp}

These commands have a common input format that supports searching a column by
a value.  A column constraint is in the regular expression form:
	
	$column$splitter$operator?$column_value

The above form will be represented by $search_term in any argument
descriptions of functions.
$splitter is controlled by the splitter variable.  $operator is only used by
&search_abstract and has the possible values: 

	> :  greater than
	>= : greater than or equal to
	< : less than
	<= : less than or equal to
	= : equal to
	!= : not equal to

Like Class::DBI's search method, multiple column constraints are anded together.
To specify multiple column constraints, separate them with white space.

Examples: 

Using &search, the input 'hero=superman weakness=kryptonite' translates to
(hero=>'superman',weakness=>'kryptonite') being passed to &search and
the sql where part being: WHERE hero = 'superman' AND weakness = 'kryptonite'

Using &search_abstract, the input 'id=>41 module=Class::DBI' translates to 
the sql where part being: WHERE id >= 41 AND module ~ 'Class::DBI'.

Note: To set the columns and tables for a query look at OPTIONS under Fry::Lib::CDBI::Load.

=head2 Search based Commands 

These commands get the results of a search and then do something with it.  The variable cdbi_search
contains the search command called for any of these functions.  This variable is found in other CDBI
libraries and is also an option for easily changing search types.

	cdbi_delete(@search_term): deletes result objects
	cdbi_update(@search_term): result objects printed to a file, user changes file and objects updated

		This function contains two flags, safe_update and only_modified. By
		default, both flags are set. The safe_update flag calls &verify_no_delim_obj to
		verify none of the results contain a display delimiter. If any are found, the command exits
		early. For many records, this may be slow, in which case run
		&verify_no_delim on all the objects once and then turn off the flag.
		The only_modified flag modifies the command to only call &update on
		objects that have been changed. With the flag off, &update would be called
		on all objects. If you don't mind this and want to speed up the update,
		then you can turn off the flag.

	replace(@search_term,$perl_operation): evaluates a perl operation on each column value of the results,
	treating each value as $_
			
		For example if one result row had the following values:
		'4','many','amazing','some bold punk' 
		and you did the perl operation 's/o/a/g', the result row would be
		converted to:
		'4','many','amazing','same bald punk' 

		note: Since $operation is distinguished from @search_terms by a
		white space, $operation can't contain any white space.

	verify_no_delim(@search_term): Verifies that result objects do not contain the display
		delimiter.  Since this delimiter can be used to separate fields in a
		file, having them in the data could result in incorrect parsing. The
		delimiter is specified by the variable field_delimiter

	cdbi_find_or_create(@search_term): If no result objects found then one is created

=head2 Menu based Commands

 cdbi_delete_obj(@cdbi): same functionality as cdbi_delete
 cdbi_update_obj(@cdbi): same functionality as cdbi_update
 verify_no_delim_obj(@cdbi): same functionality as verify_no_delim

The three menu commands take Class::DBI row objects as input. The only way to
currently enter objects as input is via the menu option. To use these
commands, first execute a search command with the -m option 

	`-m search_abstract tags=goofy` 

Then execute one of the menu based commands with numbers specifying which
objects you choose from the numbered menu.  

	`cdbi_delete_obj 1-4,8-10`

Why not just use the corresponding search based command? You'd use a menu
based command when you want to pick only certain results and perform actions
on them.

=head2 Debugging via DBI::Profile.

There are three commands that wrap around DBI::Profile that manage benchmark
data useful in debugging DBI statements, set_dbi_log_level, print_dbi_log and
clear_dbi_log. These commands respectively set the log level (which is between
-15 and 15), print the current log, and clear the log. To enable debugging,
you must first set a log level via &set_dbi_log_level. See DBI::Profile for
more details.


=head2 Other Commands

	cdbi_create(($value$delim)+): wrapper around &Class::DBI::create. &cdbi_create uses
		&aliasInsert to parse the input into values for the table's columns. The
		columns which map to the parsed values are defined via the variable insert_columns.
		Ie if @insert_columns = ('car','year') and the insert delimiter is ',,' and your
		input is 'chevy,,57' then &create will create a record with car='chevy' and
		year='57'

		note: records with multi-line data can't be inserted this way 

	cdbi_multi_insert($file): same input format as &cdbi_create,reads several lines from
		file and inserts them as new records
	display_table_list(): lists tables in the database
	print_columns(): prints the current table's columns

=head1 Library Variables

	editor: sets the editor used by &cdbi_update
	splitter: separates column from its value in arguments of search-based functions and used
		for &Class::DBI::AbstractSearch::search_where searches	
	abstract_opts: optional parameters passed to &Class::DBI:AbstractSearch::search_where
	delim: hash with the following keys:
		display: delimits column values when editing records in file with &cdbi_update
		insert: delimits values when using &cdbi_insert
		tag: delimits values used in CDBI::Tags library.
	insert_columns(\@): implicit order of columns for 

=head1 Miscellaneous

=head2 Input Aliasing

If there are queries you do often then you can alias them to an even shorter command via
&aliasInput. The default &aliasInput aliases 'a' to returning all rows of a table and replaces
anything matching /c\d/ with the corresponding column.

=head2 Changing Output Format

Via the subhook viewsub, it's possible to choose your own subroutine to format
your output. By default all search results are displayed using
&View::CLI::objAoH. If you want an aligned output similar to most database
shells, use &printTextTable ie (-v=tt s id=48).

=head1 Writing Class::DBI Libraries

Make sure you've read Fry::Shell's 'Writing Libraries' section. 

When writing a Class::DBI library:

	1. Define 'CDBI::Load' as dependent module in your &_default_data.
	2. Refer to Fry::Lib::CDBI::Load for a list of core Class::DBI global data
	to use in your functions.

I encourage not only wrapper libraries around Class::DBI::* modules but any DBI modules. Even
libraries that use tables of a specific schema are welcome (see Fry::Lib::CDBI::Tags).

=head1 Suggested Modules

Three functions are dependent on external modules. 
Since their require statements are wrapped in
an eval, the functions fail safely if not found.

	&cdbi_update: File::Temp
	&search_abstract: Class::DBI::AbstractSearch
	&print_text_table: Text::Reform

=head1 See Also	

L<Fry::Shell>, L<Class::DBI>

=head1 TO DO

 -port old TESTS!
 -defining relations between tables with has_*
 -provide direct SQL queries
 -support shell-like parsing of quotes to allow spaces in queries
 -specify sorting and limit of queries
 -embed sql or database functions in queries
 -create an easily-parsable syntax for piecing chunks into 'or' and 'and' parts
	to be passed to Class::DBI::AbstractSearch

=head1 Thanks	

I give a shot out to Kwan for encouraging me to check out Postgresql and Perl
when my ideas of a database shell were simply bash and a text file.

A shot out also to Jeff Bisbee for pointing me to Class::DBI when I was pretty
naive in the perl world.

=head1 AUTHOR

Me. Gabriel that is.  I welcome feedback and bug reports to cldwalker AT chwhat DOT com .  If you
like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.
