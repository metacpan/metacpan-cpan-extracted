package Log::Shiras::Report::CSVFile;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare("v0.48.0");
use strict;
use warnings;
use 5.010;
use utf8;
use Moose;
use namespace::autoclean;
use MooseX::StrictConstructor;
use MooseX::HasDefaults::RO;
use lib '../../../';
#~ use Log::Shiras::Unhide qw( :InternalReporTCSV );
###InternalReporTCSV	warn "You uncovered internal logging statements for Log::Shiras::Report::CSVFile-$VERSION" if !$ENV{hide_warn};
###InternalReporTCSV	use Log::Shiras::Switchboard;
###InternalReporTCSV	my	$switchboard = Log::Shiras::Switchboard->instance;
use Text::CSV_XS 1.25;
use File::Copy qw( copy );
use File::Temp;
#~ $File::Temp::DEBUG = 1;
use Carp qw( confess cluck );
use Fcntl qw( :flock LOCK_EX LOCK_UN SEEK_END);#
use MooseX::Types::Moose qw(
		FileHandle		ArrayRef		HashRef			Str			Bool
    );
use Log::Shiras::Types qw( HeaderArray HeaderString CSVFile IOFileType );
with 'Log::Shiras::LogSpace';

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has file =>(
		isa			=> CSVFile,
		writer		=> 'set_file_name',
		reader		=> 'get_file_name',
		clearer		=> '_clear_file',
		predicate	=> '_has_file',
		required	=> 1,
		coerce		=> 1,
	);
	
has headers =>(
		isa	=> HeaderArray,
		traits =>['Array'],
		writer	=> 'set_headers',
		reader	=> 'get_headers',
		predicate => 'has_headers',
		clearer	=> '_clear_headers',
		handles =>{
			number_of_headers => 'count',
		},
		coerce => 1,
	);
	
has reconcile_headers =>(
		isa => Bool,
		writer => 'set_reconcile_headers',
		reader => 'should_reconcile_headers',
		default => 1,
	);

has test_first_row =>(
		isa	=> Bool,
		writer	=> '_test_first_row',
		reader	=> 'should_test_first_row',
		default => 1,
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub add_line{

    my ( $self, $input_ref ) = @_;
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalReporTCSV		name_space => $self->get_all_space( 'add_line' ),
	###InternalReporTCSV		message =>[ 'Adding a line to the csv file -' . $self->get_file_name . '- :', $input_ref ], } );
	my $message_ref;
	my( $first_ref, @other_args ) = @{$input_ref->{message}};
	if( !$first_ref ){
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 1,
		###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_find_the_actual_message' ),
		###InternalReporTCSV		message =>[ 'No data in the first position - adding an empty row' ], } );
		$message_ref = $self->_build_message_from_arrayref( [] );
	}elsif( @other_args ){
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 1,
		###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_find_the_actual_message' ),
		###InternalReporTCSV		message =>[ 'Multiple values passed - treating the inputs like a list' ], } );
		$message_ref = $self->_build_message_from_arrayref( [ $first_ref, @other_args ] );
	}elsif( is_HashRef( $first_ref ) ){
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 1,
		###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_find_the_actual_message' ),
		###InternalReporTCSV		message =>[ 'Using the ref as it stands:', $first_ref ], } );
		$message_ref = $self->_build_message_from_hashref( $first_ref );
	}else{
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 3,
		###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_find_the_actual_message' ),
		###InternalReporTCSV		message =>[ 'Treating the input as a one element string' ], } );
		$message_ref = $self->_build_message_from_arrayref( [ $first_ref ] );
	}
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 3,
	###InternalReporTCSV		name_space => $self->get_all_space( 'add_line' ),
	###InternalReporTCSV		message =>[ "committing the message:", $message_ref ], } );
	$self->_send_array_ref( $self->_get_file_handle, $message_ref );
	
	return 1;
}

sub get_class_space{ 'CSVFile' }

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _file_handle =>(
		isa	=> IOFileType,
		writer	=> '_set_file_handle',
		reader	=> '_get_file_handle',
		clearer	=> '_clear_file_handle',
		predicate => '_has_file_handle',
		init_arg => undef,
	);

has _file_headers =>(
		isa	=> HeaderArray,
		traits =>['Array'],
		writer	=> '_set_file_headers',
		reader	=> '_get_file_headers',
		clearer	=> '_clear_file_headers',
		predicate => '_has_file_headers',
		handles =>{
			_file_header_count => 'count',
		},
		init_arg => undef,
	);

has _expected_header_lookup =>(
		isa	=> HashRef,
		traits =>['Hash'],
		writer	=> '_set_header_lookup',
		reader	=> '_get_header_lookup',
		clearer	=> '_clear_header_lookup',
		predicate => '_has_header_lookup',
		handles =>{
			_get_header_position => 'get',
			_has_header_named => 'exists',
		},
		init_arg => undef,
	);

has _csv_parser =>(
		isa	=> 'Text::CSV_XS',
		writer => '_set_csv_parser',
		clearer => '_clear_csv_parser',
		init_arg => undef,
		handles =>{
			_set_parsing_header => 'header',
			_send_array_ref => 'say',
			_send_hash_ref => 'print_hr',
			_read_next_line => 'getline',
			_separator_char => 'sep_char',
		},
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub BUILD{
	my( $self, ) = @_;
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalReporTCSV		name_space => $self->get_all_space( 'BUILD' ),
	###InternalReporTCSV		message =>[ "Organizing the new file instance"], } );
		
	# Open and collect the header if available
	$self->_open_file( $self->get_file_name );
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 1,
	###InternalReporTCSV		name_space => $self->get_all_space( 'BUILD' ),
	###InternalReporTCSV		message =>[ "Open file complete"], } );
	
	# Check requested headers against an empty file
	if( $self->has_headers ){
		my $header_ref = $self->get_headers;
		$self->_set_expected_header_lookup( $header_ref	);
		if( $self->should_reconcile_headers and !$self->_has_file_headers ){ 
			###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 1,
			###InternalReporTCSV		name_space => $self->get_all_space( 'BUILD' ),
			###InternalReporTCSV		message =>[ "Ensuring the requested headers are in the file:", $header_ref ], } );
			$self->_add_headers_to_file( $header_ref );
		}
	}
	#~ confess "Died here";
	return 1;
}

after 'set_file_name' => sub{ my( $self, $file ) = @_; $self->_open_file( $file ) };

sub _open_file{

    my ( $self, $file ) = @_;
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalReporTCSV		name_space => $self->get_all_space( '_open_file' ),
	###InternalReporTCSV		message =>[ "Arrived at _open_file for:", $file ], } );
	$self->_clear_file_handle;
	$self->_clear_file_headers;
	$self->_clear_csv_parser;
	
	# Build the csv parser
	$self->_set_csv_parser( Text::CSV_XS->new({ binary => 1, eol => $\, auto_diag => 1 }) );#
		
	# Open the file handle and collect the header if available
	open( my $fh, "+<:encoding(UTF-8)", $file ) or confess "Can't open $file: $!";
	binmode( $fh );
	flock( $fh, LOCK_EX );
	$self->_set_file_handle( $fh );
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 1,
	###InternalReporTCSV		name_space => $self->get_all_space( '_open_file' ),
	###InternalReporTCSV		message =>[ 'Read file handle built: ' . -s $fh ], } );
	
	# Collect the header if available
	if( -s $self->_get_file_handle ){
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 1,
		###InternalReporTCSV		name_space => $self->get_all_space( '_open_file' ),
		###InternalReporTCSV		message =>[ "The file appears to have pre-existing content (headers)" ], } );
		my $header_ref;
		@$header_ref = $self->_set_parsing_header( $fh );
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 1,
		###InternalReporTCSV		name_space => $self->get_all_space( '_open_file' ),
		###InternalReporTCSV		message =>[ "File headers are: " . join( '~|~', @$header_ref ) ], } );
		$self->_set_file_headers( $header_ref );
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 1,
		###InternalReporTCSV		name_space => $self->get_all_space( '_open_file' ),
		###InternalReporTCSV		message =>[ "File headers set" ], } );
	}else{
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 1,
		###InternalReporTCSV		name_space => $self->get_all_space( '_open_file' ),
		###InternalReporTCSV		message =>[ "The file is zero size" ], } );
	}
	
	# Get to the end for add_line (in case you weren't there before)
	seek( $self->_get_file_handle, 0, SEEK_END) or confess "Can't seek (end) on $file: $!";
	
	return 1;
}

around '_set_file_headers' => sub{
		my( $_set_file_headers, $self, $header_ref ) = @_;
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 1,
		###InternalReporTCSV		name_space => $self->get_all_space( '_set_file_headers' ),
		###InternalReporTCSV		message =>[ 'Attempting to set the file headers to:',  $header_ref ], } );
		if( $self->should_reconcile_headers ){
			my( $one_extra, $two_extra ) = $self->_test_headers( $header_ref, $self->get_headers );
			###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
			###InternalReporTCSV		name_space => $self->get_all_space( '_set_file_headers' ),
			###InternalReporTCSV		message =>[ 'Returned from the header test:', $one_extra, $two_extra ], } );
			$self->set_reconcile_headers( 0 );
			if( $two_extra ){
				###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 3,
				###InternalReporTCSV		name_space => $self->get_all_space( '_set_file_headers' ),
				###InternalReporTCSV		message =>[ 'There are more expected headers than were found in the file:', $two_extra ], } );
				push @$header_ref, @$two_extra;
				$self->_add_headers_to_file( $header_ref );
			}
			if( $one_extra ){
				###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 3,
				###InternalReporTCSV		name_space => $self->get_all_space( '_set_file_headers' ),
				###InternalReporTCSV		message =>[ 'There are more file headers than expected headers:', $one_extra ], } );
				$self->set_headers( $header_ref );
			}
			$self->set_reconcile_headers( 1 );
		}
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 3,
		###InternalReporTCSV		name_space => $self->get_all_space( '_set_file_headers' ),
		###InternalReporTCSV		message =>[ "Setting file headers to: ", $header_ref ], } );
		$self->$_set_file_headers( $header_ref );
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
		###InternalReporTCSV		name_space => $self->get_all_space( '_set_file_headers' ),
		###InternalReporTCSV		message =>[ 'Final file headers:', $self->_get_file_headers ], } );
	};

around 'set_headers' => sub{
		my( $set_headers_method, $self, $header_ref ) = @_;
		$self->_clear_header_lookup;
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 1,
		###InternalReporTCSV		name_space => $self->get_all_space( 'set_headers' ),
		###InternalReporTCSV		message =>[ 'Received a request to set headers to:', $header_ref ], } );
		$header_ref = $self->_scrub_header_array( $header_ref );
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 1,
		###InternalReporTCSV		name_space => $self->get_all_space( 'set_headers' ),
		###InternalReporTCSV		message =>[ 'Attempting to set the requested headers with:',  $header_ref ], } );
		$self->_set_expected_header_lookup( $header_ref	);
		my( $one_extra, $two_extra, $translation );
		if( $self->should_reconcile_headers ){
			my $file_headers = $self->_get_file_headers;
			( $one_extra, $two_extra, $translation ) = $self->_test_headers( $file_headers, $header_ref, );
			###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
			###InternalReporTCSV		name_space => $self->get_all_space( '_set_file_headers' ),
			###InternalReporTCSV		message =>[ 'Returned from the header test:', $one_extra, $two_extra, $translation ], } );
			$self->set_reconcile_headers( 0 );
			if( $two_extra ){
				###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 3,
				###InternalReporTCSV		name_space => $self->get_all_space( '_set_file_headers' ),
				###InternalReporTCSV		message =>[ 'There are more expected headers than were found in the file:', $two_extra ], } );
				my $new_ref;
				push @$new_ref, @$file_headers if $file_headers;
				push @$new_ref, @$two_extra;
				$self->_add_headers_to_file( $new_ref );
				$header_ref = $new_ref;
			}
			$self->set_reconcile_headers( 1 );
		}
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 3,
		###InternalReporTCSV		name_space => $self->get_all_space( '_set_file_headers' ),
		###InternalReporTCSV		message =>[ "Setting requested headers to: ", $header_ref ], } );
		$self->$set_headers_method( $header_ref );
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
		###InternalReporTCSV		name_space => $self->get_all_space( 'set_headers' ),
		###InternalReporTCSV		message =>[ 'Final requested headers resolved to:', $header_ref,
		###InternalReporTCSV					'...with passing-to translation resolved as:', $translation ], } );
		return $translation;
	};

sub _add_headers_to_file{

    my ( $self, $new_ref ) = @_;
	#~ my $new_line = join( $self->_separator_char, @$new_ref ) . "\n";
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalReporTCSV		name_space => $self->get_all_space( '_add_headers_to_file' ),
	###InternalReporTCSV		message =>[ "Arrived at _add_headers_to_file for:", $new_ref, ], } );
		
	# Make a temp file to create new data
	my $temp_dir = File::Temp->newdir( CLEANUP => 1 );
	my $fh = File::Temp->new( UNLINK => 0, DIR => $temp_dir );
	my $temp_parser = Text::CSV_XS->new({ binary => 1, sep_char => $self->_separator_char, eol => $\, auto_diag => 1  });#
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
	###InternalReporTCSV		name_space => $self->get_all_space( '_add_headers_to_file' ),
	###InternalReporTCSV		message =>[ "Tempfile open: " . $fh->filename, ], } );
	
	# Add the new header
	$temp_parser->say( $fh, $new_ref );
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
	###InternalReporTCSV		name_space => $self->get_all_space( '_add_headers_to_file' ),
	###InternalReporTCSV		message =>[ "Added headers to the tempfile: ", $new_ref, ], } );
	
	# Write the rest of the lines (except the old header)
	my $original_fh = $self->_get_file_handle;
	$self->_clear_file_handle;
	my $first_line = 1;
	seek( $original_fh, 0, 0 );
	while (my $row = $self->_read_next_line($original_fh)) {
		if( $first_line ){
			$first_line = 0;
			next;
		}
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
		###InternalReporTCSV		name_space => $self->get_all_space( '_add_headers_to_file' ),
		###InternalReporTCSV		message =>[ "Printing line to tempfile:", $row], } );
		$temp_parser->say( $fh, $row );
	}
	
	# Close the original file
	flock( $original_fh, LOCK_UN );
	close( $original_fh ) or confess "Couldn't close file: $!";
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
	###InternalReporTCSV		name_space => $self->get_all_space( '_add_headers_to_file' ),
	###InternalReporTCSV		message =>[ "Closed the original file handle" ], } );
	
	# Close the new tempfile
	flock( $fh, LOCK_UN );
	close( $fh );
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
	###InternalReporTCSV		name_space => $self->get_all_space( '_add_headers_to_file' ),
	###InternalReporTCSV		message =>[ "Closed the new temp file" ], } );
	
	# Replace the original file with the tempfile
	copy( $fh->filename, $self->get_file_name ) or confess "Couldn't copy file: $!";
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
	###InternalReporTCSV		name_space => $self->get_all_space( '_add_headers_to_file' ),
	###InternalReporTCSV		message =>[ "Original file replaced: " . $self->get_file_name,
	###InternalReporTCSV					'..with file: ' . $fh->filename	], } );
	$fh = undef;
	
	# Re-run the file to get the headers registered with Text::CSV_XS;
	$self->_open_file( $self->get_file_name );
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
	###InternalReporTCSV		name_space => $self->get_all_space( '_add_headers_to_file' ),
	###InternalReporTCSV		message =>[ "Updated file re-test complete" ], } );
	
	return 1;
}

sub _test_headers{

    my ( $self, $header_ref_1, $header_ref_2 ) = @_;
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalReporTCSV		name_space => $self->get_all_space( '_test_headers' ),
	###InternalReporTCSV		message =>[ "Arrived at test headers with:", $header_ref_1, $header_ref_2 ], } );
	my( $one_extra, $two_extra, $translation );
	if( !$header_ref_2 ){
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 3,
		###InternalReporTCSV		name_space => $self->get_all_space( '_test_headers' ),
		###InternalReporTCSV		message =>[ "No second header list passed for testing" ], } );
		$one_extra = $header_ref_1;
	}else{
		my $x = 0;
		for my $second_header ( @$header_ref_2 ){
			###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
			###InternalReporTCSV		name_space => $self->get_all_space( '_test_headers' ),
			###InternalReporTCSV		message =>[ "Testing second header: $second_header" ], } );
			my $y = 0;
			my $found_match = 0;
			NEWHEADERTEST: for my $first_header ( @$header_ref_1 ){
				###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
				###InternalReporTCSV		name_space => $self->get_all_space( '_test_headers' ),
				###InternalReporTCSV		message =>[ "Testing first header -$first_header- for a match" ], } );
				if( $second_header eq $first_header ){
					###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
					###InternalReporTCSV		name_space => $self->get_all_space( '_test_headers' ),
					###InternalReporTCSV		message =>[ "Second header list -$second_header- at position: $x",
					###InternalReporTCSV					"matches first header list header -$first_header- at position: $y" ], } );
					$translation->{$x} = $y;
					$found_match = 1;
					last NEWHEADERTEST;
				}
				$y++;
			}
			push @$two_extra, $second_header if !$found_match;
			$x++;
		}
		for my $pos ( 0 .. $#$header_ref_1 ){
			if( !exists $translation->{$pos} ){
				push @$one_extra, $header_ref_1->[$pos];
			}
		}
		my $next_pos = $#$header_ref_1 + 1;
		for my $pos ( 0 .. $#$header_ref_2 ){
			if( !exists $translation->{$pos} ){
				$translation->{$pos} = $next_pos++;
			}
		}
	}
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalReporTCSV		name_space => $self->get_all_space( '_test_headers' ),
	###InternalReporTCSV		message =>[ "Finished with header list 1 extra:", $one_extra,
	###InternalReporTCSV					"...and header list 2 extra:", $two_extra,
	###InternalReporTCSV					"...and translation ref:", $translation				], } );
	return( $one_extra, $two_extra, $translation );
}

sub _build_message_from_arrayref{
	my( $self, $array_ref )= @_;
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_arrayref' ),
	###InternalReporTCSV		message =>[ 'Testing the message from an array ref: ' . ($self->should_test_first_row//0), $array_ref ], } );
	my @expected_headers = $self->has_headers ? @{$self->get_headers} : ();
	if( $self->should_test_first_row ){
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 1,
		###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_arrayref' ),
		###InternalReporTCSV		message =>[ 'First row - testing if the list matches the header count' ], } );
		
		if( $#$array_ref != $#expected_headers ){
			if( scalar( @expected_headers ) == 0 ){
				###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 3,
				###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_arrayref' ),
				###InternalReporTCSV		message =>[ 'Adding dummy file headers' ], } );
				my $dummy_headers;
				map{ $dummy_headers->[$_] = "header_" . $_ } ( 0 .. $#$array_ref );
				###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 1,
				###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_arrayref' ),
				###InternalReporTCSV		message =>[ 'New dummy headers:', $dummy_headers ], } );
				cluck "Setting dummy headers ( " . join( ', ', @$dummy_headers ) . " )" if !$ENV{hide_warn};
				$self->set_reconcile_headers( 1 );
				$self->set_headers( $dummy_headers );
			}else{
				cluck 	"The first added row has -" . scalar( @$array_ref ) .
						"- items - but the report expects -" .
						scalar( @expected_headers ) . "- items" if !$ENV{hide_warn};
			}
		}
		$self->_test_first_row ( 0 );
	}
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_arrayref' ),
	###InternalReporTCSV		message =>[ 'Returning message ref:', $array_ref ], } );
	return $array_ref;
}

sub _build_message_from_hashref{
	my( $self, $hash_ref )= @_;
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_hashref' ),
	###InternalReporTCSV		message =>[ 'Building the array ref from the hash ref: ' . ($self->should_test_first_row//0), $hash_ref ], } );
	
	# Scrub the hash
	my( $better_hash, @missing_list );
	for my $key ( keys %$hash_ref ){
		my $fixed_key = $self->_scrub_header_string( $key );
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
		###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_hashref' ),
		###InternalReporTCSV		message =>[ "Managing key -$fixed_key- for key: $key" ], } );
		push @missing_list, $fixed_key if $self->should_test_first_row and !$self->_has_header_named( $fixed_key );
		$better_hash->{$fixed_key} = $hash_ref->{$key};
	}
	$self->_test_first_row( 0 );
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
	###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_hashref' ),
	###InternalReporTCSV		message =>[ "Updated hash message:", $better_hash,
	###InternalReporTCSV					"...with missing list:", @missing_list ], } );
	
	# Handle first row errors
	if( @missing_list ){
		my @expected_headers = $self->has_headers ? @{$self->get_headers} : ();
		push @expected_headers, @missing_list;
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 3,
		###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_hashref' ),
		###InternalReporTCSV		message =>[ "Updating the expected headers with new data", [@expected_headers] ], } );
		cluck "Adding headers from the first hashref ( " . join( ', ', @missing_list ) . " )" if !$ENV{hide_warn};
		$self->set_reconcile_headers( 1 );
		$self->set_headers( [@expected_headers] );
	}
	
	# Build the array_ref
	my $array_ref = [];
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_hashref' ),
	###InternalReporTCSV		message =>[ 'Building an array ref with loookup:', $self->_get_header_lookup ], } );
	for my $header ( keys %$better_hash ){
		if( $self->_has_header_named( $header ) ){
			$array_ref->[$self->_get_header_position( $header )] = $better_hash->{$header};
		}else{
			cluck "found a hash key in the message that doesn't match the expected header ( $header )" if !$ENV{hide_warn};
		}
	}
	
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_hashref' ),
	###InternalReporTCSV		message =>[ 'Returning message array ref:', $array_ref ], } );
	return $array_ref;
}

sub _set_expected_header_lookup{
	my ( $self, $hash_ref ) = @_;
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalReporTCSV		name_space => $self->get_all_space( '_set_expected_header_lookup' ),
	###InternalReporTCSV		message =>[ "Arrived at _set_expected_header_lookup with:", $hash_ref ], } );
	my( $i, $positions, ) = ( 0, {} );
	map{ $positions->{$_} = $i++ } @$hash_ref;
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalReporTCSV		name_space => $self->get_all_space( '_set_expected_header_lookup' ),
	###InternalReporTCSV		message =>[ "Header lookup hash is:", $positions ], } );
	$self->_set_header_lookup( $positions );
}

sub _scrub_header_array{
	my ( $self, @args ) = @_;
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalReporTCSV		name_space => $self->get_all_space( '_scrub_header_array' ),
	###InternalReporTCSV		message =>[ "Arrived at _scrub_header_array:", @args ], } );
	my $new_ref = [];
	for my $header ( @{$args[0]} ){
		push @$new_ref, $self->_scrub_header_string( $header );
	}
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalReporTCSV		name_space => $self->get_all_space( '_scrub_header_array' ),
	###InternalReporTCSV		message =>[ "Updated header is:", $new_ref ], } );
	return $new_ref;
}

sub _scrub_header_string{
	my ( $self, $string ) = @_;
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalReporTCSV		name_space => $self->get_all_space( '_scrub_header_string' ),
	###InternalReporTCSV		message =>[ "Arrived at _scrub_header_string with: $string" ], } );
	$string = lc( $string );
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
	###InternalReporTCSV		name_space => $self->get_all_space( '_scrub_header_string' ),
	###InternalReporTCSV		message =>[ "The updated string is: $string" ], } );
	$string =~ s/\n/ /gsxm;
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
	###InternalReporTCSV		name_space => $self->get_all_space( '_scrub_header_string' ),
	###InternalReporTCSV		message =>[ "The updated string is: $string" ], } );
	$string =~ s/\r/ /gsxm;
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
	###InternalReporTCSV		name_space => $self->get_all_space( '_scrub_header_string' ),
	###InternalReporTCSV		message =>[ "The updated string is: $string" ], } );
	$string =~ s/\s/_/gsxm;
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
	###InternalReporTCSV		name_space => $self->get_all_space( '_scrub_header_string' ),
	###InternalReporTCSV		message =>[ "The updated string is: $string" ], } );
	chomp $string;
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalReporTCSV		name_space => $self->get_all_space( '_scrub_header_string' ),
	###InternalReporTCSV		message =>[ "The final string is: $string" ], } );
	return $string;
}

sub DEMOLISH{
	my ( $self ) = @_;
	###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalReporTCSV		name_space => $self->get_all_space( 'DEMOLISH' ),
	###InternalReporTCSV		message =>[ "Arrived at DEMOLISH" ], } ) if $switchboard;
	if( $self->_has_file_handle ){
		flock( $self->_get_file_handle, LOCK_UN );
		close( $self->_get_file_handle ) or confess "Couldn't close the file handle";
		$self->_clear_file_handle;
		###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 1,
		###InternalReporTCSV		name_space => $self->get_all_space( 'DEMOLISH' ),
		###InternalReporTCSV		message =>[ "Arrived at DEMOLISH" ], } ) if $switchboard;
	}
}

#########1 Phinish    	      3#########4#########5#########6#########7#########8#########9

__PACKAGE__->meta->make_immutable;

1;
# The preceding line will help the module return a true value

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9

__END__

=head1 NAME

Log::Shiras::Report::CSVFile - A report base for csv files

=head1 SYNOPSIS

	use Modern::Perl;
	#~ use Log::Shiras::Unhide qw( :InternalReporTCSV );
	use Log::Shiras::Switchboard;
	use Log::Shiras::Telephone;
	use Log::Shiras::Report;
	use Log::Shiras::Report::CSVFile;
	use Log::Shiras::Report::Stdout;
	$ENV{hide_warn} = 1;
	$| = 1;
	my	$operator = Log::Shiras::Switchboard->get_operator(
			name_space_bounds =>{
				UNBLOCK =>{
					to_file => 'info',# for info and more urgent messages
				},
			},
			reports =>{
				to_file =>[{
					superclasses =>[ 'Log::Shiras::Report::CSVFile' ],
					roles =>[ 'Log::Shiras::Report' ],# checks inputs and class requirements
					file => 'test.csv',
				}],
			}
		);
	my	$telephone = Log::Shiras::Telephone->new( report => 'to_file' );
		$telephone->talk( level => 'info', message => 'A new line' );
		$telephone->talk( level => 'trace', message => 'A second line' );
		$telephone->talk( level => 'warn', message =>[ {
			header_0 => 'A third line',
			new_header => 'new header starts here' } ] );
        
	#######################################################################################
	# Synopsis file (test.csv) output
	# 01: header_0
	# 02: "A new line"
	# 03: "A third line"
	#######################################################################################
        
	#######################################################################################
	# Synopsis file (test.csv) output with line 24 commented out
	# 01: header_0,new_header
	# 02: "A third line","new header starts here"
	#######################################################################################
    
=head1 DESCRIPTION

This is a report module that can act as a destination in the 
L<Log::Shiras::Switchboard/reports> name-space.  It is meant to be fairly flexible and 
will have most of the needed elements in the class without added roles.  An instance
of the class can be built either with ->new or using the implied 
L<MooseX::ShortCut::BuildInstance> helpers. (See lines 18 - 20 in the example)  When the 
report is set up any call to that report namespace will then implement the L<add_line
|/add_line> method of this class.

As implied in the Synopsis one of the features of this class is the fact that it will try to 
reconcile the headers to inbound data and header requests.  This class will attempt to 
reconcile any deviation between the first passed row and the header.  Subsequent added 
rows using a passed array ref will add all values without warning whether the count matches 
the header count or not.  Subsequent added rows using a passed hashref will only used the 
headers in the fixed L<header|/header> list but will warn for any passed headers not matching 
the header list.

This class will attempt to obtain an exclusive lock on the file.  If the file is previously 
locked it will wait.  That will allow you to attach more than one report script to the same 
file name and not overwrite lines.  On the other hand this does have the potential to create 
scripts that appear to be hung.

=head2 Warning

This class will always use the header list when adding new hash values.  As a consequence 
there can be no duplicates in the header list after it is coereced to this files requirements.  
Since the class allows for mixed passing of array refs and hash refs it also has the 
no duplicate header requirement with array ref handling too.

=head2 Attributes

Data passed to ->new when creating an instance.  For modification of these attributes 
after the instance is created see the attribute methods.

=head3 file

=over

B<Definition:> This is the file name to be used by the .csv file.  This should include the 
full file path.  If the file does not exist then the file will be created.

B<Default:> None

B<Required:> Yes

B<Range:> it must have a .csv extention and can be opened

B<attribute methods>

=over

B<set_file_name( $file_name )>

=over

B<Description> used to set the attribute

=back

B<get_file_name>

=over

B<Description> used to return the current attribute value

=back

=back

=back

=head3 headers

=over

B<Definition:> This an array ref of the requested headers in the file. Each of the headers 
must match header string requirements.  The header strings will be coerced as needed buy forcing 
then lower case and removing any newlines.

B<Default:> None

B<Required:> No

B<Range:> An array ref of strings starting with a lower case letter and containing letters, 
underscores, and numbers

B<attribute methods>

=over

B<set_headers( $array_ref )>

=over

B<Description> used to set all the attribute at once

=back

B<get_headers>

=over

B<Description> used to return all the attribute at once

=back

B<has_headers>

=over

B<Description> predicate for the whole attribute

=back

B<number_of_headers>

=over

B<Description> Returns the complete header count list

=back

=back

=back

=head3 reconcile_headers

=over

B<Definition:> It may be that when you open a file the file already has headers.  This 
attribute determines if the action or L<requested headers|/headers> are merged with the 
file headers.  In the merge the file headers are given order precedence so new requested 
headers wind up at the end even when that means the requested headers are added out of 
order to the original request!

B<Default:> 1 = the headers will be reconciled

B<Range:> Boolean

B<attribute methods>

=over

B<set_reconcile_headers( $bool )>

=over

B<Description> used to set the attribute

=back

B<should_reconcile_headers>

=over

B<Description> used to return the current attribute value

=back

=back

=back

=head3 test_first_row

=over

B<Definition:> It may be that when you send the first row after instance instantiation 
that the row and the headers don't agree.  This will update the requested headers (
L<and maybe the file headers|/reconcile headers>) with any variation between the two.  
In the case of a passed array ref no header change is implemented but a warning is 
emitted when the passed list and the header list don't have the same count.  For 
passed hash refs new headers are added to the end of the requested headers.  After 
the first line no warning is emitted for passed array refs that don't match and 
new hash keys (and their values) that don't match the header will just be left off 
the report.  New hash keys for the first row will be added in a random order.

B<Default:> 1 = the first row will attempt reconciliation

B<Range:> Boolean

B<attribute methods>

=over

B<should_test_first_row>

=over

B<Description> used to return the current attribute value

=back

=back

=back

=head2 Methods

=head3 new( %args )

=over

B<Definition:> This creates a new instance of the CSVFile L<report
|Log::Shiras::Switchboard/reports> class.

B<Range:> It will accept any or none of the L<Attributes|/Attributes>

B<Returns:> A report class to be stored in the switchboard.

=back

=head3 add_line( $message_ref )

=over

B<Definition:> This is the method called by the switchboard to add lines to the report.  It will 
expect a message compatible with L<Log::Shiras::Switchboard/master_talk( $args_ref )>.  There is 
some flexibility in the consumption of the value within the 'message' key.  This package will 
check if there is more than one item and handle it like an elements list. If there is only one 
item and it is a hash ref it will attempt to consume the hashref as having keys matching the 
columns.  Other single elements will be consumed as sub-elements of an element list.

B<Returns:> 1 (or dies)

=back

=head1 GLOBAL VARIABLES

=over

=item B<$ENV{hide_warn}>

The module will warn when debug lines are 'Unhide'n.  In the case where the you 
don't want these notifications set this environmental variable to true.

=back

=head1 SUPPORT

=over

L<Log-Shiras/issues|https://github.com/jandrew/Log-Shiras/issues>

=back

=head1 TODO

=over

B<1.> Nothing L<currently|/SUPPORT>

=back

=head1 AUTHOR

=over

=item Jed Lund

=item jandrew@cpan.org

=back

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DEPENDENCIES

=over

L<perl 5.010|perl/5.10.0>

L<utf8>

L<version>

L<Moose>

L<MooseX::StrictConstructor>

L<MooseX::HasDefaults::RO>

L<MooseX::Types::Moose>

L<Text::CSV_XS>

L<File::Copy> - copy

L<File::Temp>

L<Carp> - confess cluck

L<Fcntl> - :flock LOCK_EX LOCK_UN SEEK_END

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9