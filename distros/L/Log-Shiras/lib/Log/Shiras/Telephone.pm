package Log::Shiras::Telephone;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare("v0.48.0");
use strict;
use warnings;
use 5.010;
use utf8;
use lib '../../';
#~ use Log::Shiras::Unhide qw( :InternalTelephonE );
###InternalTelephonE	warn "You uncovered internal logging statements for Log::Shiras::Telephone-$VERSION" if !@$ENV{hide_warn};
use Moose;
use	MooseX::StrictConstructor;
use	MooseX::HasDefaults::RO;
use MooseX::Types::Moose qw( Bool ArrayRef HashRef Str );
use Carp qw( longmess );
use Clone 'clone';
use Log::Shiras::Switchboard;
my	$switchboard = Log::Shiras::Switchboard->instance;
use Log::Shiras::Types qw( NameSpace ElevenInt );

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has name_space =>(
		isa		=> NameSpace,
		writer	=> 'set_name_space',
		reader	=> 'get_name_space',
		default	=> sub{
			my 	$name_space = (caller( 2 ))[3];
				$name_space //= 'main';
			return $name_space;
		},
		coerce	=> 1,
	);

has report =>(
		isa		=> Str,
		writer	=> 'set_report',
		reader	=> 'get_report',
		default	=> 'log_file',
	);

has level =>(
		isa		=> ElevenInt|Str,
		writer	=> 'set_level',
		reader	=> 'get_level',
		default	=> 11,
	);

has message =>(
		isa		=> ArrayRef,
		writer	=> 'set_shared_message',
		reader	=> 'get_shared_message',
		default	=> sub{ [ '' ] },# Empty strings are better handled than attempting to join or print undef
	);

has carp_stack =>(
		isa		=> Bool,
		writer	=> 'set_carp_stack',
		reader	=> 'should_carp_longmess',
		default => 0,
	);

has fail_over =>(
		isa		=> Bool,
		writer	=> 'set_fail_over',
		reader	=> 'should_fail_over',
		default => 0,
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub talk{
	my ( $self, @passed ) = @_;

	# Coerce the passed data into a standard format
	my $test_adjust_1 = scalar( @passed ) % 2 == 0 ? { @passed } : undef;
	my $test_adjust_2 = $passed[0];
	my( $x, $data_ref )= ( 1, );
	for my $attempt ( $test_adjust_1, $test_adjust_2 ){
		###InternalTelephonE	$switchboard->master_talk( { report => 'log_file', level => 0,
		###InternalTelephonE		name_space => 'Log::Shiras::Telephone::talk',
		###InternalTelephonE 		message => [ "Testing attempt:", $attempt ], } );
		if(	$attempt and is_HashRef( $attempt ) and
			( exists $attempt->{message} or exists $attempt->{ask} or
				( exists $attempt->{level} and $attempt->{level} =~ /fatal/i ) ) ){
			###InternalTelephonE	$switchboard->master_talk( { report => 'log_file', level => 1,
			###InternalTelephonE		name_space => 'Log::Shiras::Telephone::talk',
			###InternalTelephonE 		message => [ "Found a compatible ref on try: $x"], } );
			$data_ref = $attempt;
			last;
		}
		$x++;
	}
	$data_ref //= (is_ArrayRef( $passed[0] ) and scalar( @passed ) == 1) ? { message => $passed[0] } : { message => [ @passed ] };

	# Ensure a message key
	$data_ref->{message} //= $self->get_shared_message;
	# Ensure the message is an ArrayRef
	$data_ref->{message} = is_ArrayRef( $data_ref->{message} ) ? $data_ref->{message} : [ $data_ref->{message} ];
	###InternalTelephonE	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalTelephonE		name_space => 'Log::Shiras::Telephone::talk',
	###InternalTelephonE 		message => [ 'Resolved Log::Shiras::Telephone::talk to say:', $data_ref ], } );

	# Ensure a report key
	if( !$data_ref->{report} ){
		###InternalTelephonE	$switchboard->master_talk( { report => 'log_file', level => 3,
		###InternalTelephonE		name_space => 'Log::Shiras::Telephone::talk',
		###InternalTelephonE		message =>[ "No report destination was defined so the message will be sent to: " . $self->get_report, ]} );
		$data_ref->{report}	= $self->get_report;
	}

	# Ensure a level key
	if( !$data_ref->{level} ){
		###InternalTelephonE	$switchboard->master_talk( { report => 'log_file', level => 3,
		###InternalTelephonE		name_space => 'Log::Shiras::Telephone::level',
		###InternalTelephonE		message =>[	"No urgency level was defined so the message will be sent at level: " . $self->get_level . " (These go to eleven)", ] } );
		$data_ref->{level}	= $self->get_level;
	}

	# Ensure a name_space key
	$data_ref->{name_space} //= $self->get_name_space;

	# Check for carp_stack
	$data_ref->{carp_stack} //= $self->should_carp_longmess;

	# Set the source_sub (Fixed for this class)
	$data_ref->{source_sub} = 'Log::Shiras::Telephone::talk';

	# Checking if input is requested ( ask => 1 )
	###InternalTelephonE	$switchboard->master_talk( { report => 'log_file', level => 1,
	###InternalTelephonE		name_space => 'Log::Shiras::Telephone::talk',
	###InternalTelephonE		message	=> [ "Current urgency -$data_ref->{level}- for destination -" .
	###InternalTelephonE			$data_ref->{report} . '- from NameSpace: ' . $data_ref->{name_space},
	###InternalTelephonE			"Checking if input is requested" ], } );
	if( $data_ref->{ask} ){
		###InternalTelephonE	$self->master_talk( { report => 'log_file', level => 3,
		###InternalTelephonE		name_space => 'Log::Shiras::Telephone::talk',
		###InternalTelephonE		message =>[ "Input request confirmed" ], } );
		my $ask_ref = clone( $data_ref->{message} );
		unshift @{$ask_ref}, "Adding to message -";
		push @$ask_ref, ($data_ref->{name_space} . " asked for input:", $data_ref->{ask});
		print STDOUT join "\n", @$ask_ref;
		my $input = <>;
		chomp $input;
		if( $input and length( $input ) > 0 ){
			push @{$data_ref->{message}}, $input;
		}
	}

	# Dispatch the message
	my $report_count = $switchboard->master_talk( $data_ref );
	###InternalTelephonE	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalTelephonE		name_space => 'Log::Shiras::Telephone::talk',
	###InternalTelephonE		message	=> [ "Message reported |$report_count| times" ], } );

	# Handle fail_over
	if( $report_count < 1 and ( $data_ref->{fail_over} or $self->should_fail_over) ){
		###InternalTelephonE	$switchboard->master_talk( { report => 'log_file', level => 4,
		###InternalTelephonE		name_space => 'Log::Shiras::Telephone::talk',
		###InternalTelephonE		message	=> [ "Message allowed but found no destination!", $data_ref->{message} ], } );
		warn longmess( "This message sent to the report -$data_ref->{report}- was approved but found no destination objects to use" ) if !$ENV{hide_warn};
		print STDOUT join( "\n\t", @{$data_ref->{message}} ) . "\n";
	}

	# Return the result
	return $report_count;
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9



#########1 Private Methods    3#########4#########5#########6#########7#########8#########9



#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose;
__PACKAGE__->meta->make_immutable;

1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Log::Shiras::Telephone - Send messages with Log::Shiras

=head1 SYNOPSIS

	package MyCoolPackage;
	use Moose;
	use lib 'lib', '../lib',;
	use Log::Shiras::Telephone;

	sub make_a_noise{
		my( $self, $message ) = @_;
		my $phone = Log::Shiras::Telephone->new(
						name_space => 'TellMeAbout::make_a_noise',
						fail_over => 1,
						report => 'spy',
					);
		$phone->talk( level => 'debug',
			message => "Arrived at make_a_noise with the message: $message" );
		print '!!!!!!!! ' . uc( $message  ) . " !!!!!!!!!\n";
		$phone->talk( level => 'info',
			message => "Finished printing message" );
	}

	package main;

	use Modern::Perl;
	use Log::Shiras::Switchboard;
	use Log::Shiras::Report::Stdout;
	use MyCoolPackage;
	$| = 1;
	my	$agitation = MyCoolPackage->new;
		$agitation->make_a_noise( 'Hello World 1' );#
	my	$operator = Log::Shiras::Switchboard->get_operator(
			name_space_bounds =>{
				TellMeAbout =>{
					make_a_noise =>{
						UNBLOCK =>{
							# UNBLOCKing the report (destinations)
							# 	at the 'TellMeAbout::make_a_noise' caller name_space and deeper
							spy	=> 'info',# for info and more urgent messages
						},
					},
				},
			},
		);
		$agitation->make_a_noise( 'Hello World 2' );#
		$operator->add_reports(
			spy =>[ Print::Log->new, ],
		);
		$agitation->make_a_noise( 'Hello World 3' );#

	#######################################################################################
	# Synopsis Screen Output
	# 01: !!!!!!!! HELLO WORLD 1 !!!!!!!!!
	# 02: !!!!!!!! HELLO WORLD 2 !!!!!!!!!
	# 03: This message sent to the report -spy- was approved but found no destination objects to use at log_shiras_telephone.pl line 16, <DATA> line 1.
	# 04: 	MyCoolPackage::make_a_noise(MyCoolPackage=HASH(0x58df970), "Hello World 2") called at log_shiras_telephone.pl line 67
	# 05: Finished printing message
	# 06: !!!!!!!! HELLO WORLD 3 !!!!!!!!!
	# 07: | level - info   | name_space - TellMeAbout::make_a_noise
	# 08: | line  - 0016   | file_name  - log_shiras_telephone.pl
	# 09: 	:(	Finished printing message ):
	#######################################################################################

=head2 SYNOPSIS EXPLANATION

=head3 Output explanation

01: This is the result of

	$agitation->make_a_noise( 'Hello World 1' );

Where the output is processed by the make_a_noise method of the package MyCoolPackage

02: Same as line 01

03-05: The switchboard actually turned on permissions for some logging from MyCoolPackage
prior to the output from line 02 but there was no report destination available so the
'fail_over' attribute kicked in and printed the message out with a warning.

06: Same as line 01

07-09: This time before the output for line 06 was sent an actual report object was
registered in the switchboard against the 'spy' report name that MyCoolPackage was
sending logging messages to.  These lines are the result of that report object
L<Log::Shiras::Report::Stdout> with the note that line 09: and line 05: have the same
content but ~::Report::Stdout leverages some of the meta-data in the message to create
a more informative output set.

=head1 DESCRIPTION

This is a convenience wrapper for the method 
L<Log::Shiras::Switchboard/master_talk( $args_ref )>.  It also provides some
additional function not provided in the leaner and stricter master_talk method.  First,
the input is more flexible allowing for several ways to compose the message.  Second,
most of the L<Attributes|/Attributes> of a phone are sent as the key parts of a
message ref for to the Switchboard.  Each of these attributes has a default allowing for
them to be ommited from the phone L<talk|/talk( %args )> method call. Third, the phone has
an additional attribute L<fail_over|/fail_over> which can be used to trigger printing the
message when it is cleared by the switchboard but a report object isn't built yet.  This
will allow for development work on writing messages without having to predefine the full
output destination.  Finally, built into 'talk' is the ability to request input with the
'ask' key. This is done without accessing the Switchboard.  This creates a range of uses
for the 'talk' command.  It is possible to call 'talk' with no arguments and only collect
the metadata for that script point to be sent to a destination log.  Any talk command 
merges the response into the message.

Updating the default $phone attributes are done with the L<attribute methods
|/attribute methods>.

Please note the effect of calling level => 'fatal' documented in
L<Log::Shiras::Switchboard/logging_levels>

Please also note that the switchboard will add some meta data to the message before
it passes the message on to the report.  See the documentation in
L<Log::Shiras::Switchboard/master_talk( $args_ref )>

This module is meant to work with L<Log::Shiras::Switchboard> at run time.  When
collecting output from the phone the switchboard must be activated to enable desired
messages to get through. For an overview of the package see L<Log::Shiras>.

=head2 Attributes

Data passed to ->new when creating an instance.  For modification of these attributes
after the instance is created see the attribute methods.

=head3 name_space

=over

B<Definition:> This is meant to represent the 'from' designation of a Telephone call.  This
attribute stores the specific point in a hierarchical name-space used by the instance of
this class.  The name-space position called does not have to be unique.  The name-space is
identified in a string where levels of the name-space in the string are marked with '::'.
If this attribute receives an array ref then it joins the elements of the array ref with '::'.

B<Default:> If no name-space is passed then this attribute defaults to the value returned
by

    (caller( 2 ))[3]

which is driven by the location where the ->new command is called.

B<Range:> L<Log::Shiras::Types/NameSpace>

B<attribute methods>

=over

B<set_name_space>

=over

B<Description> used to set the attribute

=back

B<get_name_space>

=over

B<Description> used to return the current attribute value

=back

=back

=back

=head3 report

=over

B<Definition:> This is meant to represent the 'to' nature of a Telephone call.  This
attribute stores the specific destination name in a flat name-space for this instance
of this class.

B<Default:> 'log_file'

B<Range:> a string

B<attribute methods>

=over

B<set_report>

=over

B<Description> used to set the attribute

=back

B<get_report>

=over

B<Description> used to return the current attribute value

=back

=back

=back

=head3 level

=over

B<Definition:> This represents the urgency for which the message is sent.  A message
level of fatal will kill the script if the Switchboard permissions are set to allow
it through.

B<Default:> 11 = 'eleven' or the very highest setting (urgency)

B<Range:> L<Log::Shiras::Types/ElevenInt> or L<Log::Shiras::Switchboard/logging_levels>

B<attribute methods>

=over

B<set_level>

=over

B<Description> used to set the attribute

=back

B<get_level>

=over

B<Description> used to return the current attribute value

=back

=back

=back

=head3 message

=over

B<Definition:> This is a message ref that will be sent to the report.

B<Default:> [ '' ]

B<Range:> an ArrayRef or a string (which will be used as [ $string ] )  If you wish
to send a $hashref send it as [ $hashref ].

B<attribute methods>

=over

B<set_shared_message>

=over

B<Description> used to set the attribute

=back

B<get_shared_message>

=over

B<Description> used to return the current attribute value

=back

=back

=back

=head3 carp_stack

=over

B<Definition:> This is a flag used to append the message with a L<Carp> - longmess

B<Default:> 0 = No appended longmess

B<Range:> 1 or 0

B<attribute methods>

=over

B<set_carp_stack>

=over

B<Description> used to set the attribute

=back

B<should_carp_longmess>

=over

B<Description> used to return the current attribute value

=back

=back

=back

=head3 fail_over

=over

B<Definition:> This attribute stores a boolean value that acts as a switch to turn off or
on an outlet to messages sent via ->talk that are approved based on name_space and urgency
but do not find any report objects to interact with.  If fail_over is on then the 'message'
elements are printed to STDOUT.  (joined by "\n\t",) This is a helpfull
feature when writing code containing the Telephone but you don't want to set up a
report to see what is going on.  You can managage a whole script by having a
$fail_over variable at the top that is used to set each of the fail_over attributes for
new telephones.  That way you can turn this on or off for the whole script at once if
you want.

B<Default:> 0 = off -> unreported succesfull messages die silently

B<Range:> a boolean 1 or 0

B<attribute methods>

=over

B<set_fail_over>

=over

B<Description> used to set the attribute

=back

B<should_fail_over>

=over

B<Description> used to return the current attribute value

=back

=back

=back

=head2 Methods

=head3 new( %args )

=over

B<Definition:> This creates a new instance of the Telephone class.  It is used to talk
to L<reports|Log::Shiras::Switchboard/reports> through the switchboard.

B<Range:> This is a L<Moose|Moose::Manual> class and new is managed by Moose.  It
will accept any or none of the L<Attributes|/Attributes>

B<Returns:> A phone instance that can be used to 'talk' to reports.

=back

=head3 talk( %args )

=over

B<Definition:> This is the method to place a call to a L<reports|Log::Shiras::Switchboard/reports> name.
The talk command accepts any of the attributes as arguments as well as an 'ask' key.  The
ask key set to 1 will cause the telephone to pause for input and append that input to the
'message'.  Any passed key that matches an attribute will locally implement the passed value
without overwriting the default value.  The passed %args with attribute keys can either be
a Hash or a HashRef.  If the passed content does not show either a message key, an ask key,
or a level key set to fatal then it is assumed to be the message and 'talk' will re-wrap it
with a message key into a hashref.  If you want the message to be a HashRef then it has to
reside inside of an ArrayRef. ex.

	[ { ~ my message hash ~ } ],

When the message has been coerced into a format that the Switchboard will consume the {ask}
key is tested and implemented.  After the ask key processing is complete the message is
sent to L<Log::Shiras::Switchboard/master_talk( $args_ref )>.  The return value from that
call is then evaluated against the attribute L<fail_over|/fail_over>.  If needed the
message is output at that time.  It should be noted that the results of the 'master_talk'
can fall in the following range.

	-3 = The call was not allowed by name_space permissions set in the switchboard
	-2 = The message was buffered rather than sent to a report
	-1 = You should never get this from a Telephone talk call
	 0 = The call had permissions but found no report implementations to connect with
	 1(and greater) = This indicates how many report instances received the message

fail_over is only implemented on a '0' return.  Read the L<name_space_bounds
|Log::Shiras::Switchboard/name_space_bounds> documentation to understand how the switchboard
handles message filtering.  I<Note: the switchboard will set the urgency level of a call to
0 if a level name is sent but it does not match the L<available log level list
|Log::Shiras::Switchboard/logging_levels> for the destination report held by the
Switchboard>.

B<Returns:> The number of times the message was sent to a report object with 'add_line'

=back

=head1 GLOBAL VARIABLES

=over

=item B<$ENV{hide_warn}>

The module will warn if debug lines are 'Uhide'n.  In the case where the you don't want
this notification set this environmental variable to true.

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

L<version>

L<Moose>

L<MooseX::StrictConstructor>

L<MooseX::HasDefaults::RO>

L<MooseX::Types::Moose>

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9
