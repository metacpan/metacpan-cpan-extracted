package Log::Shiras::Test2;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare("v0.48.0");
use strict;
use warnings;
use 5.010;
use utf8;
use lib '../../';
#~ use Log::Shiras::Unhide qw( :InternalLoGShiraSTesT );
###InternalLoGShiraSTesT	warn "You uncovered internal logging statements for Log::Shiras::Test2-$VERSION";
use	Moose;
use MooseX::StrictConstructor;
use	MooseX::HasDefaults::RO;
use Test2::API qw/context/;
use MooseX::Types::Moose qw( RegexpRef Bool ArrayRef );
use Data::Dumper;
use Log::Shiras::Switchboard 0.029;
use Log::Shiras::Types qw( PosInt );

our	$last_buffer_position = 11;# This one goes to eleven :^|

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has keep_matches =>(
    isa     => Bool,
    default => 0,
    writer  => 'set_match_retention',
);

has test_buffer_size =>(
	isa		=> PosInt,
	default	=> sub{ $last_buffer_position },#
	writer	=> 'change_test_buffer_size',
	trigger => \&_set_buffer_size,
);


#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub get_buffer{
	my ( $self, $report_name ) = @_;
	###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
	###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::get_buffer',
	###InternalLoGShiraSTesT		message =>[ "getting the buffer for: $report_name" ], } );
	my	$buffer_ref = [];
	if( $self->_has_test_buffer( $report_name ) ){
		$buffer_ref = $self->_get_test_buffer( $report_name );
	}
	###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 0,
	###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::get_buffer',
	###InternalLoGShiraSTesT		message =>[ "returning: $buffer_ref" ], } );
	return $buffer_ref;
}

#########1 Test Methods       3#########4#########5#########6#########7#########8#########9

sub clear_buffer{
    my ( $self, $report_name, $test_description ) = @_;
	###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
	###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::clear_buffer',
	###InternalLoGShiraSTesT		message =>[ "Reached clear_buffer for  : $report_name" ], } );
	$self->_set_test_buffer( $report_name => [] );
    my $ctx = context();
    $ctx->ok(1, $test_description);
    $ctx->release;
    return $report_name;
}

sub has_buffer{
    my ( $self, $report_name, $expected, $test_description ) = @_;
	###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
	###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::has_buffer',
	###InternalLoGShiraSTesT		message =>[ "Reached has_buffer for report: $report_name",
	###InternalLoGShiraSTesT					"........with expected outcome: $expected",
	###InternalLoGShiraSTesT					"..........and primary message: $test_description" ], } );
    my $ctx = context();
	my $result = $self->_has_test_buffer( $report_name );
	###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 0,
	###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::has_buffer',
	###InternalLoGShiraSTesT		message =>[ "resulting in: $result" ], } );
    $ctx->ok( $result == $expected, $test_description);
    if( $result != $expected ){
        if( !$result ){
            $ctx->diag( "Expected to find a buffer for -$report_name- but it didn't exist" );
        }else{
            $ctx->diag( "A buffer for -$report_name- was un-expectedly found" );
        }
    }
    $ctx->release;
    return $report_name;
}

sub buffer_count{
    my ( $self, $report_name, $guess, $test_description ) = @_;
	###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
	###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::buffer_count',
	###InternalLoGShiraSTesT		message =>[ "testing the row count loaded in the buffer ...",
	###InternalLoGShiraSTesT					"for       : $report_name",
	###InternalLoGShiraSTesT					"with guess: $guess" ], } );
    my $ctx = context();
    my  $actual_count = scalar( @{$self->get_buffer( $report_name )} );
    $ctx->ok($actual_count == $guess, $test_description);
    if( $actual_count != $guess ){
        $ctx->diag( "Expected -$guess- items in the buffer but found -$actual_count- items" );
    }
    $ctx->release;
    return $report_name;
}

sub match_message{
    my ( $self, $report_name, $line, $test_description ) = @_;
    chomp $line;
	$test_description //= '';
	###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
	###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::match_message',
	###InternalLoGShiraSTesT		message =>[ "Reached match_output",
	###InternalLoGShiraSTesT					"for             : $report_name",
	###InternalLoGShiraSTesT					"testing line    : $line",
	###InternalLoGShiraSTesT					"with explanation: $test_description" ] } );
    my $ctx = context();
    my $result = 0;
    my @failarray;
	###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
	###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::match_message',
	###InternalLoGShiraSTesT		message =>[ "Check if the buffer exists" ] } );
    if( $self->_has_test_buffer( $report_name ) ){
		###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
		###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::match_message',
		###InternalLoGShiraSTesT		message =>[ "The buffer exists" ] } );
        my @buffer_list = @{$self->_get_test_buffer( $report_name )};
		###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 0,
		###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::match_message',
		###InternalLoGShiraSTesT		message =>[ "The buffer list is:", @buffer_list ] } );
        @failarray = (
            'Expected to find: ',  $line,
            "but could not match it to data in -$report_name-..."
        );
        if( !@buffer_list ){
			###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
			###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::match_message',
			###InternalLoGShiraSTesT		message =>[ "The buffer list is EMPTY!", ] } );
            push @failarray, 'Because the test buffer is EMPTY!';
        }else{
			my $position = 0;
            TESTALL: for my $buffer_message ( @buffer_list ){
				my $buffer_array_ref = $buffer_message->{message};
				###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
				###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::match_message',
				###InternalLoGShiraSTesT		message =>[ "testing line:", $buffer_array_ref, ] } );
				for my $ref_element ( @$buffer_array_ref ){
					if( !$ref_element or length( $ref_element ) == 0 ){
						###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
						###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::match_message',
						###InternalLoGShiraSTesT		message =>[ "Nothing to match in this message", ] } );
					}elsif( ( is_RegexpRef( $line ) and $ref_element =~ $line ) or
							( $ref_element eq $line )           					){
						###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
						###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::match_message',
						###InternalLoGShiraSTesT		message =>[ "Found a match!", ] } );
						splice( @buffer_list, $position, 1 ) if !$self->keep_matches;
						$result = 1;
						last TESTALL;
					}else{
						###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
						###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::match_message',
						###InternalLoGShiraSTesT		message =>[ "No Match Here", ] } );
						push @failarray, "---" . Dumper( $ref_element );
					}
				}
				$position++;
            }
        }
		###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
		###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::match_message',
		###InternalLoGShiraSTesT		message =>[ "The match test result is: $result", ] } );
        if( $result ){
			###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
			###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::match_message',
			###InternalLoGShiraSTesT		message =>[ "Reloading the updated buffer", ] } );
            $self->_set_test_buffer( $report_name => [@buffer_list] );
			###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
			###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::match_message',
			###InternalLoGShiraSTesT		message =>[ "Updates complete", ] } );
        }
    } else {
		my $message = "The master test buffer does not contain: $report_name";
		###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 0,
		###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::match_message',
		###InternalLoGShiraSTesT		message =>[  $message ], } );
        @failarray = ( $message );
    }
	###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 0,
	###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::match_message',
	###InternalLoGShiraSTesT		message =>[ "passing result to Test2::API: $result" ], } );
    $ctx->ok($result, $test_description);
    if( !$result ) {
        map{ $ctx->diag( $_ ) } @failarray;
		$report_name = 0;
    }
    $ctx->release;
	return $report_name;
}

sub cant_match_message{
    my ( $self, $report_name, $line, $test_description ) = @_;
	###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 0,
	###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::cant_match_message',
	###InternalLoGShiraSTesT		message =>[ "Reached cant_match_output",
	###InternalLoGShiraSTesT					"for             : $report_name",
	###InternalLoGShiraSTesT					"testing line    : $line",
	###InternalLoGShiraSTesT					"with explanation: $test_description" ] } );
    my $ctx    = context();
    my $result = 1;
    my $i      = 0;
    my @failarray;
	###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
	###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::cant_match_message',
	###InternalLoGShiraSTesT		message =>[ "Checking if the buffer exists" ] } );
    if( $self->_has_test_buffer( $report_name ) ){
		###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
		###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::cant_match_message',
		###InternalLoGShiraSTesT		message =>[ "The buffer exists" ] } );
        my @buffer_list = @{$self->_get_test_buffer( $report_name )};
		###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 0,
		###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::cant_match_message',
		###InternalLoGShiraSTesT		message =>[ "The buffer list is:", @buffer_list ] } );
        TESTMISS: for my $test_line ( @buffer_list) {
			$test_line = $test_line->{message};
			###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
			###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::cant_match_message',
			###InternalLoGShiraSTesT		message =>[ "testing line:", $test_line, ] } );
			if( is_ArrayRef( $test_line ) ){
				###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 0,
				###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::cant_match_message',
				###InternalLoGShiraSTesT		message =>[ "Message line already an ArrayRef - do nothing", ] } );
			}else{
				###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 0,
				###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::cant_match_message',
				###InternalLoGShiraSTesT		message =>[ "Making the buffer line an ArrayRef", ] } );
				$test_line = [ $test_line ];
			}
			for my $ref_element ( @$test_line ){
				if( ( is_RegexpRef( $line ) and $ref_element =~ $line ) or
					( $ref_element eq $line )           					){
					###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
					###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::cant_match_message',
					###InternalLoGShiraSTesT		message =>[ "Found a match! (BAD)", ] } );
					$result = 0;
					push @failarray, (
							"For the -$report_name- buffer a no match condition was desired",
							"for the for the test -$line-",
							"a match was found at position -$i-",
							"(The line was not removed from the buffer!)"
						);
					last TESTMISS;
					$result = 1;
				}else{
					###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 0,
					###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::cant_match_message',
					###InternalLoGShiraSTesT		message =>[ "No Match For: $ref_element", ] } );
					$i++;
				}
			}
        }
        if( $result ) {
			###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
			###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::cant_match_message',
			###InternalLoGShiraSTesT		message =>[ "Test buffer exists but the line was not found in: $report_name", ] } );
        }
    } else {
		###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 1,
		###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::cant_match_message',
		###InternalLoGShiraSTesT		message =>[ "Pass! no buffer found ...", ] } );
    }
    $ctx->ok($result, $test_description);
    if( !$result ) {
        map{ $ctx->diag( $_ ) } @failarray;
		$report_name = 0;
    }
    $ctx->release;
	return $report_name;
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _switchboard_link =>(# Use methods from the Switchboard singleton
	isa		=> 'Log::Shiras::Switchboard',
	reader	=> '_get_switchboard',
	handles =>[ qw(
		_has_test_buffer	_get_test_buffer	_set_test_buffer
		master_talk			_clear_all_test_buffers
	) ],
	default	=> sub{ Log::Shiras::Switchboard->get_operator(); },
);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

after 'change_test_buffer_size' => \&_set_buffer_size;

sub _set_buffer_size{
	my ( $self, $new_size ) = @_;
	###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 0,
	###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::_set_buffer_size',
	###InternalLoGShiraSTesT		message =>[ "setting the new test buffer size to: $new_size" ], } );
	$last_buffer_position = $new_size;
}

sub DEMOLISH{
	my ( $self, ) = @_;
	###InternalLoGShiraSTesT	$self->master_talk( { report => 'log_file', level => 3,
	###InternalLoGShiraSTesT		name_space => 'Log::Shiras::Switchboard::DEMOLISH',
	###InternalLoGShiraSTesT		message =>[ "clearing ALL the test buffers" ], } );
	$self->_clear_all_test_buffers;
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose;
__PACKAGE__->meta->make_immutable;

1;
# The preceding line will help the module return a true value

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Log::Shiras::Test2 - Test2 for traffic in the ::Switchboard

=head1 SYNOPSIS
    
	use Test2::Bundle::Extended qw( !meta );
	use Test2::Plugin::UTF8;
	use Test::Log::Shiras;
	plan( 3 );
	
	~~ Set up the Log::Shiras::Switchboard operator here ($ella_peterson) ~~
	
	my $test_class;
	ok( lives{	$test_class = Log::Shiras::Test2->new },
											"Build a test class for reading messages from the bat phone" ) or note($@);;
	ok( lives{
				$ella_peterson->master_talk({ # Use Ella Petersons bat phone
					name_space => 'main', report => 'report1', level => 'eleven', 
					message =>[ 'Hello World' ], });
	},										"Test making a call (with Ella Petersons bat phone)" ) or note($@);
	$test_class->match_message( 'report1', "Hello World",
											"... and check the output" );
    
=head1 DESCRIPTION

This is a class used for testing.  It inherits directly from L<Test2::API> without going through 
Test::Builder.  This will feed back to any Test2 rooted test with the understanding that even 
Test::More now uses Test2 Under the hood.  The tests are object oriented methods rather than 
functions.  That was a conscious choice in order to auto link to the singleton once without 
re-connecting over and over.  The goal is to be able to set up messages to the switchboard with 
minimum wiring to the reports and still be able to see if the messages are working as expected.  
Log::Shiras::Switchboard will actually check if this module is active and store messages to a test 
buffer right before sending them to the reports.  This allows the reports to exist in name only 
and to still test permissions levels and caller actions without using L<Capture::Tiny> or reading 
output files for test results.

=head2 Attributes

These are things that can be passed to the ->new argument in order to change the general behavior 
of the test instance.

=head3 keep_matches

=over

B<Description:> This determines whether a match is deleted from the test buffer when it is matched 
by the test L<match_message|/match_message( $report, $test_line, $message )>.

B<Range:> accepts a boolean value

B<Default:> 1 = yes, matches are deleted when found

B<attribute methods:>

=over

B<set_match_retention( $bool )>

=over

B<Description:> Changes the keep_matches attribute setting to the passed $bool

=back

=back

=back

=head3 test_buffer_size

=over

B<Description:> This attribute attempts to mirror L<$Test::Log::Shiras::last_buffer_position
|/$Test::Log::Shiras::last_buffer_position>.  If you set it upon instantiation of an instance of this 
class then it will change the global variable too.

B<Range:> accepts a positive integer

B<Default:> 11 this starts at eleven

B<attribute methods:>

=over

B<change_test_buffer_size( $int )>

=over

B<Definition:> This will change the maximum test buffer size.  If the target buffer size is 
reduced greater than the current buffer contents the size will not be resolved until the next 
message is sent to the buffer.

=back

=back

=back

=head2 Methods

These are not tests!

=head3 get_buffer( $report )

=over

B<Definition:> This will return the full test buffer for a given report.  It should be noted 
that messages are stored with metadata.  Active buffers are not an ArrayRef of strings.

B<Accepts:> The target $report name

B<Returns:> An ArrayRef of HashRefs

=back

=head2 Tests

All tests here are written as methods on an object not exportable functions.  As such they 
are implemented in the following fashion.

	my $tester = Test::Log::Shiras->new;
	$tester->match_message( $report, $wanted, $message );
	
=head3 clear_buffer( $report, $message )

=over

B<Definition:> This test will clear the buffer.  It always passes.

B<Accepts:> The target $report name string to clear and the $message to append to the test report.

B<Returns:> The cleared test name_space

=back

=head3 has_buffer( $report, $expected, $message )

=over

B<Definition:> This test checks to see if there is a test buffer for the $report name.  It allows 
for testing a buffer existence whether the buffer is $expected to exist or not.

B<Accepts:> The target $report name string to check and whether you $expected to find the buffer or not.  
It also accepts the $message used for test result reporting.

B<Returns:> The tested report buffer name

=back

=head3 buffer_count( $report, $expected, $message )

=over

B<Definition:> This test checks a known buffer to see how many records it contains.  It will compare that 
to how many records are $expected.  The buffer count will mostly never exceed the L<mandated max
|/$Test::Log::Shiras::last_buffer_position> buffer size.

B<Accepts:> The target $report name string to check and how many records were $expected in the buffer.  
It also accepts the $message used for test result reporting.

B<Returns:> The tested report buffer name

=back

=head3 match_message( $report, $test_line, $message )

=over

B<Definition:> This test checks if a $test_line exists in any of the message elements in the test buffer.  
The message elements take the following relevant format.

	$message->{message} =>[ $compare_line1, $compare_line2, etc. ]
	
$compare_line1 and $compare_line2 are the elements tested.  If $test_line is a RegexpRef then it will 
do a regex compare otherwise it does an exact string 'eq' compare.  If there is a match the test will 
splice out the message from the buffer so It won't show up again unless you re-send it to the buffer.  
This behavior can be changed with the attribute L<keep_matches|/keep_matches>.

B<Accepts:> The target $report name string a $test_line [or regex] to check with.  It also accepts the 
$message used for test result reporting.

B<Returns:> The tested report buffer name

=back

=head3 cant_match_message( $report, $test_line, $message )

=over

B<Definition:> This test checks all messages in a buffer to see if a $test_line exists in any of the 
message elements.  The message elements take the following relevant format.

	$message->{message} =>[ $compare_line1, $compare_line2, etc. ]
	
$compare_line1 and $compare_line2 are the elements tested.  If $test_line is a RegexpRef then it will 
do a regex compare otherwise it does an exact string 'eq' compare.  Even if there is a match the buffer 
remains un-edited but the test fails.

B<Accepts:> The target $report name string a $test_line [or regex] to check with.  It also accepts the 
$message used for test result reporting.

B<Returns:> The tested report buffer name

=back

=head2 GLOBAL VARIABLES

=over

B<$Test::Log::Shiras::last_buffer_position>

=over

In order to not have memory issues with long running tests that accumulate buffers without 
flushing there is a global variable for the max items in the test buffer.  The actual test 
buffer is not stored here but rather in the L<Switchboard|Log::Shiras::Switchboard> in 
order to leverage the Singleton there.  The default value is 11 (Store to 11).  So if you 
want to do a lot of work and then check if a message was processed early on then you need 
to increase this value (equivalent to max buffer size).  Internal to the instance it is 
best to change the max buffer using the attribute L<test_buffer_size|/test_buffer_size> 
and it's method.

=back

=back

=head1 SUPPORT

=over

=item L<github Log-Shiras/issues|https://github.com/jandrew/Log-Shiras/issues>

=back

=head1 TODO

=over

B<1.> Nothing yet

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

This software is copyrighted (c) 2012, 2016 by Jed Lund.

=head1 DEPENDANCIES

=over

L<version> - 0.77

L<5.010|http://perldoc.perl.org/perl5100delta.html> (for use of
L<defined or|http://perldoc.perl.org/perlop.html#Logical-Defined-Or> //)

L<utf8>

L<Moose>

L<MooseX::StrictConstructor>

L<MooseX::HasDefaults::RO>

L<Test2::API> - context

L<MooseX::Types::Moose> - RegexpRef Bool ArrayRef

L<Log::Shiras::Switchboard> - 0.029

L<Log::Shiras::Types>

=back

=head1 SEE ALSO

=over

L<Log::Log4perl::Appender::TestBuffer>

L<Log::Log4perl::Appender::TestArrayBuffer>

=back

=cut

#################### <where> - main pod documentation end ###################