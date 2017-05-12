package Log::Shiras::Report::Upsert;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare("v0.48.0");
use strict;
use warnings;
use 5.010;
use utf8;
use lib '../../../';
use Log::Shiras::Unhide qw( :InternalReporTUpserT );
###InternalReporTUpserT	warn "You uncovered internal logging statements for Log::Shiras::Report::Upsert-$VERSION" if !$ENV{hide_warn};
###InternalReporTUpserT	use Log::Shiras::Switchboard;
###InternalReporTUpserT	my	$switchboard = Log::Shiras::Switchboard->instance;
use Moose::Role;
requires qw( get_log_space );
#~ use MooseX::Types::Moose qw( ArrayRef HashRef CodeRef );
use Log::Shiras::Types qw( JsonFile FileHash );
use Carp 'confess';

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

#~ has pre_sub =>(
		#~ isa => CodeRef,
		#~ clearer => 'clear_pre_sub',
		#~ predicate => 'has_pre_sub',
		#~ reader => 'get_pre_sub',
		#~ writer => 'set_pre_sub',
	#~ );
	
#~ has hashpend =>(
		#~ isa => HashRef,
		#~ traits =>['Hash'],
		#~ clearer => 'clear_hashpend',
		#~ predicate => 'has_hashpend',
		#~ reader => 'get_all_hashpend',
		#~ handles =>{
			#~ add_to_hashpend => 'set',
			#~ remove_from_hashpend => 'delete',
		#~ },
	#~ );

#~ has prepend =>(
		#~ isa => ArrayRef,
		#~ traits =>['Array'],
		#~ clearer => 'clear_prepend',
		#~ predicate => 'has_prepend',
		#~ reader => 'get_all_prepend',
		#~ handles =>{
			#~ add_to_prepend => 'push',
		#~ },
	#~ );
	
#~ has postpend =>(
		#~ isa	=> ArrayRef,
		#~ traits =>['Array'],
		#~ clearer => 'clear_postpend',
		#~ predicate => 'has_postpend',
		#~ reader => 'get_all_postpend',
		#~ handles =>{
			#~ add_to_postpend => 'push',
		#~ },
	#~ );

#~ has post_sub =>(
		#~ isa => CodeRef,
		#~ clearer => 'clear_post_sub',
		#~ predicate => 'has_post_sub',
		#~ reader => 'get_post_sub',
		#~ writer => 'set_post_sub',
	#~ );

has merge_rules =>( 
		isa => FileHash,
		traits =>['Hash'],
		reader => 'get_merge_rules',
		handles =>{
			merge_columns => 'keys',
			get_merge_rule => 'get',
			modify_merge_rule => 'set',
		},
	);

has merge_modify =>(# Document this as an attribute but don't store it!!!!!!!!!!
		isa => FileHash,
		traits =>['Hash'],
		reader => 'get_merge_modify',
		writer => 'set_merge_modify',
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub add_line{
    my(	$self, $args_ref, @other_args ) = @_;
###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 2, 
###InternalReporTUpserT		name_space => $self->get_all_space( 'Upsert::add_line' ),
###InternalReporTUpserT		message =>[ 'Arrived at add_line with args:', $args_ref, @other_args ], } );
}
#########1 Merge Actions      3#########4#########5#########6#########7#########8#########9
#########1 Input : $input_value, $db_value, $modifier(optional)                 8#########9
#########1 Output: $result, $result_value                                       8#########9

sub use_new_data{
	my ( $self, $input_value, $db_value ) = @_;
	my ( $result, $final_value ) = ( 0, $db_value );
	my $phone = Log::Shiras::Telephone->new(
				name_space => $self->meta->name . '::add_row::use_new_data' );
	no warnings 'uninitialized';
	$phone->talk( level => 'debug',
		message => [	"Reached the 'use_new_data' merge action input " .
						"value -$input_value- and database value -$db_value-" ] );
	if( !defined $input_value ){
		$phone->talk( level => 'debug',
			message => ["No value in the new row - the old value -$db_value- stands" ] );
	}elsif( !defined $db_value and defined $input_value ){
		$phone->talk( level => 'debug',
			message => [	"No value in the database row - the new value " .
							"-$input_value- will be used" ] );
		( $result, $final_value ) = ( 1, $input_value );
	}elsif( $input_value ne $db_value ){
		$phone->talk( level => 'debug',
			message => [	"The database value -$db_value- does not equal the " .
							"new value -$input_value- the new value will be used" ] );
		( $result, $final_value ) = ( 1, $input_value );
	}
	use warnings 'uninitialized';
	return ( $result, $final_value );
}

sub use_old_data{
	my ( $self, $input_value, $db_value ) = @_;
	my ( $result, $final_value ) = ( 0, $db_value );
	my $phone = Log::Shiras::Telephone->new(
				name_space => $self->meta->name . '::add_row::use_old_data' );
	if( !defined $db_value and defined $input_value ){
		$phone->talk( level => 'debug', message =>[
			"No value in the database row - the new value -$input_value- will be used" ] );
		( $result, $final_value ) = ( 1, $input_value );
	}elsif( !defined( $db_value ) and !defined( $input_value ) ){
		$phone->talk( level => 'debug', message =>[
			"No value in either the database or new row" ] );
		( $result, $final_value ) = ( 1, undef );
	}else{
		$phone->talk( level => 'debug', message =>[
			"Merge action 'use_old_data' will pass the database value -$db_value-" ] );
	}
	return ( $result, $final_value );
}

sub attempt_merge{
	my ( $self, $input_value, $db_value ) = @_;
	my ( $result, $final_value ) = ( 0, $db_value );
	my $phone = Log::Shiras::Telephone->new(
				name_space => $self->meta->name . '::add_row::attempt_merge' );
	no warnings 'uninitialized';
	$phone->talk( level => 'debug',
		message => [	"Reached the 'attempt_merge' merge action input " .
						"value -$input_value- and database value -$db_value-" ] );
	use warnings 'uninitialized';
	if( !defined $input_value ){
		no warnings 'uninitialized';
		$phone->talk( level => 'debug',
			message => ["No value in the new row - the old value -$db_value- stands" ] );
		use warnings 'uninitialized';
	}elsif( !defined $db_value and defined $input_value ){
		$phone->talk( level => 'debug',
			message => [	"No value in the database row - the new value " .
							"-$input_value- will be used" ] );
		( $result, $final_value ) = ( 1, $input_value );
	}else{
		my	$lc_input	= lc( $input_value );
		my	$lc_db		= lc( $db_value );
			$lc_input	=~ s/[^\x20-\x7E]//g;
			$lc_db		=~ s/[^\x20-\x7E]//g;
		if( $lc_input eq $lc_db ){
			$phone->talk( level => 'debug',
				message => [	"The database value -$db_value- effectivly equals the " .
								"new value -$input_value- the database value will be used" ] );
		}elsif( $lc_db =~ /\Q$lc_input\E/ ){
			$phone->talk( level => 'debug',
				message => [	"The new value -$input_value- is a subset of the " .
								"database value -$db_value- the database value will be used" ] );
		}elsif( $lc_input =~ /\Q$lc_db\E/ ){
			$phone->talk( level => 'debug',
				message => [	"The database value -$db_value- is a subset of the " .
								"new value -$input_value- the new value will be used" ] );
			( $result, $final_value ) = ( 1, $input_value );
		}else{
			$phone->talk( level => 'debug',
				message => [	"The new value -$input_value- and the " .
								"database value -$db_value- are different and will be merged" ] );
			( $result, $final_value ) = ( 2, "$db_value ~|~ $input_value" );
		}
	}
	return ( $result, $final_value );
}

sub use_old_except{
	my ( $self, $input_value, $db_value, $modifier ) = @_;
	my ( $result, $final_value ) = ( 0, $db_value );
	my $phone = Log::Shiras::Telephone->new(
				name_space => $self->meta->name . '::add_row::use_old_except' );
	no warnings 'uninitialized';
	$phone->talk( level => 'debug',
		message => [	"Reached the 'use_old_except' merge action with input " .
						"value -$input_value- and database value -$db_value- ",
						'Modified by:', $modifier ] );
	if( !defined $db_value and defined $input_value ){
		$phone->talk( level => 'debug',
			message => [	"No value in the database row - the new value " .
							"-$input_value- will be used" ] );
		( $result, $final_value ) = ( 1, $input_value );
	}elsif( defined $db_value and defined $input_value ){
		my	$no_match = 1;
		for my $test_value ( @$modifier ){
			if( $test_value eq $db_value ){
				( $result, $final_value ) = ( 1, $input_value );
				$phone->talk( level => 'debug',
					message => [	"The database value -$db_value- is excluded - the " .
									"new value -$input_value- will be used" ] );
				$no_match = 0;
				last;
			}
		}
		if( !$no_match ){
			for my $test_value ( @$modifier ){
				if( $test_value eq $input_value ){
					( $result, $final_value ) = ( 0, $db_value );
					$phone->talk( level => 'debug',
						message => [	"The new value -$input_value- is excluded as well!  " .
										"the database value -$db_value- will still be used" ] );
					last;
				}
			}
		}
		if( $no_match ){
			( $result, $final_value ) = ( 0, $db_value );
			$phone->talk( level => 'debug',
				message => [ "The database value -$db_value- is selected" ] );
		}
	}else{
		( $result, $final_value ) = ( 0, $db_value );
		$phone->talk( level => 'debug',
			message => [ "There is no change, the database value -$db_value- will be used" ] );
	}
	use warnings 'uninitialized';
	return ( $result, $final_value );
}

sub use_new_except{
	my ( $self, $input_value, $db_value, $modifier ) = @_;
	my ( $result, $final_value ) = ( 0, $db_value );
	my $phone = Log::Shiras::Telephone->new(
				name_space => $self->meta->name . '::add_row::use_new_except' );
	no warnings 'uninitialized';
	$phone->talk( level => 'debug',
		message => [	"Reached the 'use_new_except' merge action with input " .
						"value -$input_value- and database value -$db_value- ",
						'Modified by:', $modifier ] );
	if( !defined $input_value ){
		$phone->talk( level => 'debug',
			message => ["No value in the new row - the old value -$db_value- stands" ] );
	}elsif( !defined $db_value and defined $input_value ){
		$phone->talk( level => 'debug',
			message => [	"No value in the database row - the new value " .
							"-$input_value- will be used" ] );
		( $result, $final_value ) = ( 1, $input_value );
	}elsif( $input_value ne $db_value ){
		my	$no_match = 1;
		for my $test_value ( @$modifier ){
			if( $test_value eq $input_value ){
				( $result, $final_value ) = ( 0, $db_value );
				$phone->talk( level => 'debug',
					message => [	"The new value -$input_value- is excluded - the " .
									"database value -$db_value- will be used" ] );
				$no_match = 0;
				last;
			}
		}
		if( !$no_match ){
			for my $test_value ( @$modifier ){
				if( $test_value eq $db_value ){
					( $result, $final_value ) = ( 1, $input_value );
					$phone->talk( level => 'debug',
						message => [	"The database value -$db_value- is excluded as well!  " .
										"the new value -$input_value- will still be used" ] );
					last;
				}
			}
		}
		if( $no_match ){
			( $result, $final_value ) = ( 1, $input_value );
			$phone->talk( level => 'debug',
				message => [ "The new value -$input_value- is selected" ] );
		}
	}else{
		( $result, $final_value ) = ( 0, $db_value );
		$phone->talk( level => 'debug',
			message => [ "There is no change, the database value -$db_value- will be used" ] );
	}
	use warnings 'uninitialized';
	return ( $result, $final_value );
}

sub use_later_date{
	my ( $self, $input_value, $db_value, $modifier ) = @_;
	my ( $result, $final_value ) = ( 0, $db_value );
	my $phone = Log::Shiras::Telephone->new(
				name_space => $self->meta->name . '::add_row::use_later_date' );
	no warnings 'uninitialized';
	$phone->talk( level => 'debug',
		message => [	"Reached the 'use_later_date' merge action with input " .
						"value -$input_value- and database value -$db_value- ",
						'Modified by:', $modifier ] );
	if( !defined $input_value ){
		$phone->talk( level => 'debug',
			message => ["No value in the new row - the old value -$db_value- stands" ] );
	}elsif( !defined $db_value and defined $input_value ){
		$phone->talk( level => 'debug',
			message => [	"No value in the database row - the new value " .
							"-$input_value- will be used" ] );
		( $result, $final_value ) = ( 1, $input_value );
	}else{
		my	@date_list;
		my	$test_date = $self->set_date_three( $input_value )->clone;
		push @date_list, $test_date;
		push @date_list, $self->set_date_three( $db_value )->clone;
		@date_list = sort @date_list;
		if( !DateTime->compare_ignore_floating( $test_date, $date_list[1] ) ){
			$phone->talk( level => 'debug', message =>[
				"The new row value is more recent, the value -$input_value- will be used" ] );
			( $result, $final_value ) = ( 1, $input_value );
		}
	}
	use warnings 'uninitialized';
	return ( $result, $final_value );
}

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

#~ sub manage_message{

    #~ my ( $self, $message_ref ) = @_;
	#~ ###InternalReporTMetaMessagE	$switchboard->master_talk( { report => 'log_file', level => 2,
	#~ ###InternalReporTMetaMessagE		name_space => 'Log::Shiras::Report::MetaMessage::manage_message',
	#~ ###InternalReporTMetaMessagE		message =>[ 'Updating the message ref:', $message_ref ], } );
	
	#~ # Handle pre_sub
	#~ if( $self->has_pre_sub ){
		#~ my $subref = $self->get_pre_sub;
		#~ ###InternalReporTMetaMessagE	$switchboard->master_talk( { report => 'log_file', level => 1,
		#~ ###InternalReporTMetaMessagE		name_space => 'Log::Shiras::Report::MetaMessage::manage_message',
		#~ ###InternalReporTMetaMessagE		message =>[ 'Handling the pre_sub now' ], } );
		#~ $subref->( $message_ref );
	#~ }
	#~ ###InternalReporTMetaMessagE	$switchboard->master_talk( { report => 'log_file', level => 1,
	#~ ###InternalReporTMetaMessagE		name_space => 'Log::Shiras::Report::MetaMessage::manage_message',
	#~ ###InternalReporTMetaMessagE		message =>[ 'Update message:', $message_ref->{message} ], } );
	
	#~ # Handle hashpend
	#~ if( $self->has_hashpend ){
		#~ my $hashpend_ref = $self->get_all_hashpend;
		#~ ###InternalReporTMetaMessagE	$switchboard->master_talk( { report => 'log_file', level => 1,
		#~ ###InternalReporTMetaMessagE		name_space => 'Log::Shiras::Report::MetaMessage::manage_message',
		#~ ###InternalReporTMetaMessagE		message =>[ 'Handling the hashpend values now:', $hashpend_ref ], } );
		#~ confess "The first element of the value (array ref) for the message key was not a hash ref" if !is_HashRef( $message_ref->{message}->[0] );
		#~ for my $element ( keys %$hashpend_ref ){
			#~ ###InternalReporTMetaMessagE	$switchboard->master_talk( { report => 'log_file', level => 0,
			#~ ###InternalReporTMetaMessagE		name_space => 'Log::Shiras::Report::MetaMessage::manage_message',
			#~ ###InternalReporTMetaMessagE		message =>[ "Handling the hashpend key -$element- with value: $hashpend_ref->{$element}" ], } );
			#~ $message_ref->{message}->[0]->{$element} =
				#~ is_CodeRef( $hashpend_ref->{$element} ) ? $hashpend_ref->{$element}->( $message_ref ) : 
				#~ exists $message_ref->{$hashpend_ref->{$element}} ? $message_ref->{$hashpend_ref->{$element}} :
				#~ $hashpend_ref->{$element} ;
		#~ }
	#~ }
	#~ ###InternalReporTMetaMessagE	$switchboard->master_talk( { report => 'log_file', level => 1,
	#~ ###InternalReporTMetaMessagE		name_space => 'Log::Shiras::Report::MetaMessage::manage_message',
	#~ ###InternalReporTMetaMessagE		message =>[ 'Update message:', $message_ref->{message} ], } );
	
	#~ # Handle prepend
	#~ if( $self->has_prepend ){
		#~ my $prepend_ref = $self->get_all_prepend;
		#~ ###InternalReporTMetaMessagE	$switchboard->master_talk( { report => 'log_file', level => 1,
		#~ ###InternalReporTMetaMessagE		name_space => 'Log::Shiras::Report::MetaMessage::manage_message',
		#~ ###InternalReporTMetaMessagE		message =>[ 'Handling the prepend values now:', $prepend_ref ], } );
		#~ for my $element ( reverse @$prepend_ref ){
			#~ ###InternalReporTMetaMessagE	$switchboard->master_talk( { report => 'log_file', level => 0,
			#~ ###InternalReporTMetaMessagE		name_space => 'Log::Shiras::Report::MetaMessage::manage_message',
			#~ ###InternalReporTMetaMessagE		message =>[ "Handling the prepend value: $element" ], } );
			#~ unshift @{$message_ref->{message}}, (
				#~ exists $message_ref->{$element} ? $message_ref->{$element} :
				#~ $element );
		#~ }
	#~ }
	#~ ###InternalReporTMetaMessagE	$switchboard->master_talk( { report => 'log_file', level => 1,
	#~ ###InternalReporTMetaMessagE		name_space => 'Log::Shiras::Report::MetaMessage::manage_message',
	#~ ###InternalReporTMetaMessagE		message =>[ 'Update message:', $message_ref->{message} ], } );
	
	#~ # Handle postpend
	#~ if( $self->has_postpend ){
		#~ my $postpend_ref = $self->get_all_postpend;
		#~ ###InternalReporTMetaMessagE	$switchboard->master_talk( { report => 'log_file', level => 1,
		#~ ###InternalReporTMetaMessagE		name_space => 'Log::Shiras::Report::MetaMessage::manage_message',
		#~ ###InternalReporTMetaMessagE		message =>[ 'Handling the postpend values now:', $postpend_ref ], } );
		#~ for my $element ( @$postpend_ref ){
			#~ ###InternalReporTMetaMessagE	$switchboard->master_talk( { report => 'log_file', level => 0,
			#~ ###InternalReporTMetaMessagE		name_space => 'Log::Shiras::Report::MetaMessage::manage_message',
			#~ ###InternalReporTMetaMessagE		message =>[ "Handling the postepend value: $element" ], } );
			#~ push @{$message_ref->{message}}, (
				#~ exists $message_ref->{$element} ? $message_ref->{$element} :
				#~ $element );
		#~ }
	#~ }
	
	#~ # Handle post_sub
	#~ if( $self->has_post_sub ){
		#~ my $subref = $self->get_post_sub;
		#~ ###InternalReporTMetaMessagE	$switchboard->master_talk( { report => 'log_file', level => 1,
		#~ ###InternalReporTMetaMessagE		name_space => 'Log::Shiras::Report::MetaMessage::manage_message',
		#~ ###InternalReporTMetaMessagE		message =>[ 'Handling the post_sub now' ], } );
		#~ $subref->( $message_ref );
	#~ }
	#~ ###InternalReporTMetaMessagE	$switchboard->master_talk( { report => 'log_file', level => 1,
	#~ ###InternalReporTMetaMessagE		name_space => 'Log::Shiras::Report::MetaMessage::manage_message',
	#~ ###InternalReporTMetaMessagE		message =>[ 'Update message:', $message_ref->{message} ], } );
	
	#~ ###InternalReporTMetaMessagE	$switchboard->master_talk( { report => 'log_file', level => 3,
	#~ ###InternalReporTMetaMessagE		name_space => 'Log::Shiras::Report::MetaMessage::manage_message',
	#~ ###InternalReporTMetaMessagE		message =>[ "Updated full message:", $message_ref ], } );
	#~ return $message_ref;
#~ }

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9



#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub BUILD{
	my( $self, $args_ref ) = @_;
###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 2,
###InternalReporTUpserT		name_space => $self->get_all_space( 'Upsert::BUILD' ),
###InternalReporTUpserT		message =>[ 'Arrived at BUILD for Log::Shiras::Report::Upsert with args:', $args_ref], } );
}


#########1 Phinish    	      3#########4#########5#########6#########7#########8#########9

no Moose::Role;

1;
# The preceding line will help the module return a true value

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9

__END__

=head1 NAME

Log::Shiras::Report::MetaMessage - Add data to messages for reports

=head1 SYNOPSIS

	use MooseX::ShortCut::BuildInstance qw( build_class );
	use Log::Shiras::Report;
	use Log::Shiras::Report::MetaMessage;
	use Data::Dumper;
	my	$message_class = build_class(
			package => 'Test',
			add_roles_in_sequence => [
				'Log::Shiras::Report',
				'Log::Shiras::Report::MetaMessage',
			],
			add_methods =>{
				add_line => sub{ 
					my( $self, $message ) = @_;
					print Dumper( $message->{message} );
					return 1;
				},
			}
		);
	my	$message_instance = $message_class->new( 
			prepend =>[qw( lets go )],
			postpend =>[qw( store package )],
		); 
	$message_instance->add_line({ message =>[qw( to the )], package => 'here', });
	
	#######################################################################################
	# Synopsis output to this point
	# 01: $VAR1 = [
	# 02:           'lets',
	# 03:           'go',
	# 04:         	'to',
	# 05:           'the',
	# 06:           'store',
	# 07:           'here'
	# 08:         ];
	#######################################################################################
	
	$message_instance->set_post_sub(
		sub{
			my $message = $_[0];
			my $new_ref;
			for my $element ( @{$message->{message}} ){
				push @$new_ref, uc( $element );
			}
			$message->{message} = $new_ref;
		}
	);
	$message_instance->add_line({ message =>[qw( from the )], package => 'here', });
	
	#######################################################################################
	# Synopsis output addition to this point
	# 01: $VAR1 = [
	# 02:           'LETS',
	# 03:           'GO',
	# 04:           'FROM',
	# 05:           'THE',
	# 06:           'STORE',
	# 07:           'HERE'
	# 08:         ];
	#######################################################################################
	
	$message_instance = $message_class->new(
		hashpend => {
			locate_jenny => sub{
				my $message = $_[0];
				my $answer;
				for my $person ( keys %{$message->{message}->[0]} ){
					if( $person eq 'Jenny' ){
						$answer = "$person lives in: $message->{message}->[0]->{$person}" ;
						last;
					}
				}
				return $answer;
			}
		},
	);
	$message_instance->add_line({ message =>[{ 
		Frank => 'San Fransisco',
		Donna => 'Carbondale',
		Jenny => 'Portland' }], });
	
	#######################################################################################
	# Synopsis output addition to this point
	# 01: $VAR1 = [
	# 02:           {
	# 03:             'locate_jenny' => 'Jenny lives in: Portland',
	# 04:             'Donna' => 'Carbondale',
	# 05:             'Jenny' => 'Portland',
 	# 06:             'Frank' => 'San Fransisco'
	# 07:           }
	# 08:         ];
	#######################################################################################
	
	$message_instance->set_pre_sub(
		sub{
			my $message = $_[0];
			my $lookup = {
					'San Fransisco' => 'CA',
					'Carbondale' => 'IL',
					'Portland' => 'OR',
				};
			for my $element ( keys %{$message->{message}->[0]} ){
				$message->{message}->[0]->{$element} .=
					', ' . $lookup->{$message->{message}->[0]->{$element}};
			}
		} 
	);
	$message_instance->add_line({ message =>[{
		Frank => 'San Fransisco',
		Donna => 'Carbondale',
		Jenny => 'Portland' }], });
	
	#######################################################################################
	# Synopsis output addition to this point
	# 01: $VAR1 = [
	# 02:           {
	# 03:             'locate_jenny' => 'Jenny lives in: Portland, OR',
	# 04:             'Donna' => 'Carbondale, IL',
	# 05:             'Jenny' => 'Portland, OR',
	# 06:             'Frank' => 'San Fransisco, CA'
	# 07:           }
	# 08:         ];
	#######################################################################################
    
=head1 DESCRIPTION

This is Moose role that can be used by L<Log::Shiras::Report> to massage the message prior 
to 'add_line' being implemented in the report.  It uses the hook built in the to Report 
role for the method 'manage_message'.

There are five ways to affect the passed message ref.  Each way is set up as an L<attribute
|/Attributes> of the class.  Details of how each is implemented is explained in the 
Attributes section.

=head2 Warning

'hashpend' and 'prepend' - 'postpend' can conflict since 'hashpend' acts on the first 
message element as if it were a hashref and the next two act as if the message is a list.  
A good rule of thumb is to not use both sets together unless you really know what is going 
on.

=head2 Attributes

Data passed to ->new when creating an instance.  For modification of these attributes 
after the instance is created see the attribute methods.

=head3 pre_sub

=over

B<Definition:> This is a place to store a perl closure that will be passed the full
$message_ref including meta data.  The results of the closure are not used so any 
desired change should be done to the $message_ref itself since it is persistent.  The 
action takes place before all the other attributes are implemented so the changes will 
NOT be available to process.  See the example in the SYNOPSIS.

B<Default:> None

B<Required:> No

B<Range:> it must pass the is_CodeRef test

B<attribute methods>

=over

B<clear_pre_sub>

=over

B<Description> removes the stored attribute value

=back

B<has_pre_sub>

=over

B<Description> predicate for the attribute

=back

B<get_pre_sub>

=over

B<Description> returns the attribute value

=back

B<set_pre_sub( $closure )>

=over

B<Description> sets the attribute value

=back

=back

=back

=head3 hashpend

=over

B<Definition:> This will update the position %{$message_ref->{message}->[0]}.  If 
that position is not a hash ref then. It will kill the process with L<Carp> - 
confess.  After it passes that test it will perform the following assuming the 
attribute is retrieved as $hashpend_ref and the entire message is passed as 
$message_ref;

	for my $element ( keys %$hashpend_ref ){
		$message_ref->{message}->[0]->{$element} =
			is_CodeRef( $hashpend_ref->{$element} ) ? 
				$hashpend_ref->{$element}->( $message_ref ) : 
			exists $message_ref->{$hashpend_ref->{$element}} ? 
				$message_ref->{$hashpend_ref->{$element}} :
				$hashpend_ref->{$element} ;
	}
	
This means that if the value of the $element is a closure then it will use the results 
of that and add that to the message sub-hashref.  Otherwise it will attempt to pull 
the equivalent key from the $message meta-data and add it to the message sub-hashref or 
if all else fails just load the key value pair as it stands to the message sub-hashref.

B<Default:> None

B<Required:> No

B<Range:> it must be a hashref

B<attribute methods>

=over

B<clear_hashpend>

=over

B<Description> removes the stored attribute value

=back

B<has_hashpend>

=over

B<Description> predicate for the attribute

=back

B<get_all_hashpend>

=over

B<Description> returns the attribute value

=back

B<add_to_hashpend( $key => $value|$closure )>

=over

B<Description> this adds to the attribute and can accept more than one $key => $value pair

=back

B<remove_from_hashpend( $key )>

=over

B<Description> removes the $key => $value pair associated with the passed $key from the 
hashpend.  This can accept more than one key at a time.

=back

=back

=back

=head3 prepend

=over

B<Definition:> This will push elements to the beginning of the list 
@{$message_ref->{message}}.  The elements are pushed in the reverse order that they are 
stored in this attribute meaning that they will wind up in the stored order in the message 
ref.  The action assumes that 
the attribute is retrieved as $prepend_ref and the entire message is passed as 
$message_ref;

	for my $element ( reverse @$prepend_ref ){
		unshift @{$message_ref->{message}}, (
			exists $message_ref->{$element} ? $message_ref->{$element} :
			$element );
	}
	
Unlike the hashpend attribute it will not handle CodeRefs.

B<Default:> None

B<Required:> No

B<Range:> it must be an arrayref

B<attribute methods>

=over

B<clear_prepend>

=over

B<Description> removes the stored attribute value

=back

B<has_prepend>

=over

B<Description> predicate for the attribute

=back

B<get_all_prepend>

=over

B<Description> returns the attribute value

=back

B<add_to_prepend( $element )>

=over

B<Description> this adds to the end of the attribute and can accept more than one $element

=back

=back

=back

=head3 postpend

=over

B<Definition:> This will push elements to the end of the list @{$message_ref->{message}}.  
The elements are pushed in the order that they are stored in this attribute.  The action 
below assumes that the attribute is retrieved as $postpend_ref and the entire message is 
passed as $message_ref;

	for my $element ( reverse @$postpend_ref ){
		push @{$message_ref->{message}}, (
			exists $message_ref->{$element} ? $message_ref->{$element} :
			$element );
	}
	
Unlike the hashpend attribute it will not handle CodeRefs.

B<Default:> None

B<Required:> No

B<Range:> it must be an arrayref

B<attribute methods>

=over

B<clear_postpend>

=over

B<Description> removes the stored attribute value

=back

B<has_postpend>

=over

B<Description> predicate for the attribute

=back

B<get_all_postpend>

=over

B<Description> returns the attribute value

=back

B<add_to_postpend( $element )>

=over

B<Description> this adds to the end of the attribute and can accept more than one $element

=back

=back

=back

=head3 post_sub

=over

B<Definition:> This is a place to store a perl closure that will be passed the full
$message_ref including meta data.  The results of the closure are not used so any 
desired change should be done to the $message_ref itself since it is persistent.  The 
action takes place after all the other attributes are implemented so the changes will 
be available to process.  See the example in the SYNOPSIS.

B<Default:> None

B<Required:> No

B<Range:> it must pass the is_CodeRef test

B<attribute methods>

=over

B<clear_post_sub>

=over

B<Description> removes the stored attribute value

=back

B<has_post_sub>

=over

B<Description> predicate for the attribute

=back

B<get_post_sub>

=over

B<Description> returns the attribute value

=back

B<set_post_sub( $closure )>

=over

B<Description> sets the attribute value

=back

=back

=back

=head2 Methods

=head3 manage_message( $message_ref )

=over

B<Definition:> This is a possible method called by L<Log::Shiras::Report> with the 
intent of implementing the L<attributes|/Attributes> on each message passed to a 
L<Log::Shiras::Switchboard/reports>.  Actions taken on that message vary from attribute 
to attribute and the specifics are explained in each.  The attributes are implemented in 
this order.

	pre_sub -> hashpend -> prepend -> postpend -> post_sub
	

B<Returns:> the (updated) $message_ref

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

L<Moose::Role>

L<MooseX::Types::Moose>

L<Carp> - confess

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9