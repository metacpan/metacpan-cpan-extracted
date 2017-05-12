package Log::Shiras::TapPrint;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare("v0.48.0");
use strict;
use warnings;
use 5.010;
use utf8;
use lib '../../';
#~ use Log::Shiras::Unhide qw( :InternalTaPPrinT );
###InternalTaPPrinT	warn "You uncovered internal logging statements for Log::Shiras::TapPrint-$VERSION" if !$ENV{hide_warn};
use Moose::Exporter;
Moose::Exporter->setup_import_methods(
    as_is => [ qw( re_route_print restore_print ) ],
);
use MooseX::Types::Moose qw( HashRef );
use Carp 'longmess';
use IO::Callback;
use Log::Shiras::Switchboard;
my	$switchboard = Log::Shiras::Switchboard->instance;

#########1 Exported Methods   3#########4#########5#########6#########7#########8#########9

sub re_route_print{
	warn "Re-routing print statements" if !$ENV{hide_warn};
	###InternalTaPPrinT	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalTaPPrinT		name_space => 'Log::Shiras::TapPrint::re_route_print',
	###InternalTaPPrinT		message =>[ "Re-routing print statements", ], } );
	my ( @passed ) = @_;
	my 	$data_ref =
		(	exists $passed[0] and
			is_HashRef( $passed[0] ) and
			( 	exists $passed[0]->{report} or
				exists $passed[0]->{level} or
				exists $passed[0]->{carp_stack} or
				exists $passed[0]->{fail_over}	)  ) ?
			$passed[0] :
		( 	@passed % 2 == 0 and
			( 	exists {@passed}->{report} or
				exists {@passed}->{level} or
				exists {@passed}->{carp_stack} or
				exists {@passed}->{fail_over}	) ) ?
			{@passed} :
			{ level => $_[0] };
	###InternalTaPPrinT	$switchboard->master_talk( { report => 'log_file', level => 0,
	###InternalTaPPrinT		name_space => 'Log::Shiras::TapPrint::re_route_print',
	###InternalTaPPrinT		message =>[ "With settings: ", $data_ref ], } );

	# set common report
	if(	!$data_ref->{report} ){
		$data_ref->{report}	= 'log_file';
		###InternalTaPPrinT	$switchboard->master_talk( { report => 'log_file', level => 3,
		###InternalTaPPrinT		name_space => 'Log::Shiras::TapPrint::re_route_print',
		###InternalTaPPrinT		message =>[ "No report was passed to 're_route_print' so the " .
		###InternalTaPPrinT			"target report for print is set to: 'log_file'" ], } );
	}

	# set common urgency level
	if(	!$data_ref->{level} ){
		$data_ref->{level} = 2;
		###InternalTaPPrinT	$switchboard->master_talk( { report => 'log_file', level => 3,
		###InternalTaPPrinT		name_space => 'Log::Shiras::TapPrint::re_route_print',
		###InternalTaPPrinT		message =>[ "No urgency level was defined in the 're_route_print' method " .
		###InternalTaPPrinT			"call so future 'print' messages will be sent at: 2 (These go to 11)" ], } );
	}

	# set failover
	if(	!$data_ref->{fail_over} ){
		$data_ref->{fail_over} = 0;
		###InternalTaPPrinT	$switchboard->master_talk( { report => 'log_file', level => 3,
		###InternalTaPPrinT		name_space => 'Log::Shiras::TapPrint::re_route_print',
		###InternalTaPPrinT		message =>[ "fail_over was not set - setting it to: 0" ], } );
	}

	# set (add) carp stack
	if(	!$data_ref->{carp_stack} ){
		$data_ref->{carp_stack} = 0;
		###InternalTaPPrinT	$switchboard->master_talk( { report => 'log_file', level => 3,
		###InternalTaPPrinT		name_space => 'Log::Shiras::TapPrint::re_route_print',
		###InternalTaPPrinT		message =>[ "carp_stack was not set - setting it to: 0" ], } );
	}

	# Set the source_sub (Fixed for this class)
	$data_ref->{source_sub} = 'IO::Callback::print';
	###InternalTaPPrinT	$switchboard->master_talk( { report => 'log_file', level => 1,
	###InternalTaPPrinT		name_space => 'Log::Shiras::TapPrint::re_route_print',
	###InternalTaPPrinT		message =>[ "Building the coderef with the data ref: ", $data_ref, ], } );

	my	$code_ref = sub{
			$data_ref->{message} = [ @_ ];
			chomp @{$data_ref->{message}};
			###InternalTaPPrinT	$switchboard->master_talk( { report => 'log_file', level => 2,
			###InternalTaPPrinT		name_space => 'Log::Shiras::TapPrint::print',
			###InternalTaPPrinT		message =>[ "Inbound print statement: ", $data_ref->{message} ], } );
			my $line = (caller( 2 ))[2];
			$data_ref->{name_space} = ((caller( 3 ))[3] and (caller( 3 ))[3] !~ /__ANON__/) ?  (caller( 3 ))[3] : (caller( 2 ))[0];
			$data_ref->{name_space} .= "::$line";
			###InternalTaPPrinT	$switchboard->master_talk( { report => 'log_file', level => 1,
			###InternalTaPPrinT		name_space => 'Log::Shiras::TapPrint::print',
			###InternalTaPPrinT		message =>[ "Added name_space: ", $data_ref->{name_space}, ], } );

			# Dispatch the message
			my $report_count = $switchboard->master_talk( $data_ref );
			###InternalTaPPrinT	$switchboard->master_talk( { report => 'log_file', level => 2,
			###InternalTaPPrinT		name_space => 'Log::Shiras::TapPrint::print',
			###InternalTaPPrinT		message =>[ "Message reported |$report_count| times"], } );

			# Handle fail_over
			if( $report_count == 0 and $data_ref->{fail_over} ){
				###InternalTelephonE	$switchboard->master_talk( { report => 'log_file', level => 4,
				###InternalTelephonE		name_space => 'Log::Shiras::TapPrint::print',
				###InternalTelephonE		message	=> [ "Message allowed but found no destination!", $data_ref->{message} ], } );
				print STDOUT longmess( "This message sent to the report -$data_ref->{report}- was approved but found no destination objects to use" ), @_;
			}
			return 1;
		};
	select( IO::Callback->new('>', $code_ref) ) or die "Couldn't redirect STDOUT: $!";
	###InternalTaPPrinT	$switchboard->master_talk( { report => 'log_file', level => 0,
	###InternalTaPPrinT		name_space => 'Log::Shiras::TapPrint::re_route_print',
	###InternalTaPPrinT		message =>[ "Finished re_routing print statements" ], } );
	return 1;
}

sub restore_print{
	select( STDOUT ) or
			die "Couldn't reset print: $!";
	###InternalTaPPrinT	$switchboard->master_talk( { report => 'log_file', level => 0,
	###InternalTaPPrinT		name_space => 'Log::Shiras::TapPrint::restore_print',
	###InternalTaPPrinT		message =>[ "Log::Shiras is no longer tapping into 'print' statements!" ], } );
	return 1;
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

1;

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Log::Shiras::TapPrint - Reroute print to Log::Shiras::Switchboard

=head1 SYNOPSIS

	use Modern::Perl;
	#~ use Log::Shiras::Unhide qw( :InternalTaPPrinT );
	$ENV{hide_warn} = 0;
	use Log::Shiras::Switchboard;
	use Log::Shiras::TapPrint 're_route_print';
	my	$ella_peterson = Log::Shiras::Switchboard->get_operator(
			name_space_bounds =>{
				UNBLOCK =>{
					log_file => 'debug',
				},
				main =>{
					27 =>{
						UNBLOCK =>{
							log_file => 'info',
						},
					},
				},
			},
			reports	=>{ log_file =>[ Print::Log->new ] },
		);
	re_route_print(
		fail_over => 0,
		level => 'debug',
		report => 'log_file',
	);
	print "Hello World 1\n";
	print "Hello World 2\n";
    print STDOUT "Hello World 3\n";
    restore_print;
    print "Hello World 4\n";

	package Print::Log;
	use Data::Dumper;
	sub new{
		bless {}, shift;
	}
	sub add_line{
		shift;
		my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ?
						@{$_[0]->{message}} : $_[0]->{message};
		my ( @print_list, @initial_list );
		no warnings 'uninitialized';
		for my $value ( @input ){
			push @initial_list, (( ref $value ) ? Dumper( $value ) : $value );
		}
		for my $line ( @initial_list ){
			$line =~ s/\n$//;
			$line =~ s/\n/\n\t\t/g;
			push @print_list, $line;
		}
		my $output = sprintf( "| level - %-6s | name_space - %-s\n| line  - %04d   | file_name  - %-s\n\t:(\t%s ):\n",
					$_[0]->{level}, $_[0]->{name_space},
					$_[0]->{line}, $_[0]->{filename},
					join( "\n\t\t", @print_list ) 	);
		print STDOUT $output;
		use warnings 'uninitialized';
	}

	1;

	#######################################################################################
	# Synopsis Screen Output
	# 01: Re-routing print statements at ../lib/Log/Shiras/TapPrint.pm line 22, <DATA> line 1.
	# 02: | level - debug  | name_space - main::26
	# 03: | line  - 0026   | file_name  - log_shiras_tapprint.pl
	# 04: 	:(	Hello World 1 ):
	# 05: Hello World 3
	# 06: Hello World 4
	#######################################################################################

=head1 DESCRIPTION

This package allows Log::Shiras to be used for code previously written with print statement
outputs.  It will re-direct the print statements using the L<select
|http://perldoc.perl.org/functions/select.html> command with L<IO::Callback>.  Using this
mechanisim means that a call to;

    print STDOUT "Print some line\n";

Will still do as expected but;

    print "Capture this line\n";

Will be routed to L<Log::Shiras::Switchboard>.

This class is used to import functions into the script.  These are not object methods and
there is no reason to call ->new.  Uncomment line 2 of the SYNOPSIS to watch the inner
workings.

=head2 Output Explanation

B<01:> The method re_route_print will throw a warning statement whenever
$ENV{hide_warn} is not set and the method is called.

B<02-04:> Line 26 of the code has been captured (meta data appended) and then sent to the
Print::Log class for reporting.

B<05:> Line 27 of the script did not print since that line requires a different urgency than
the urgency provided by the L<re_route_print|/re_route_print( %args )> call in the SYNOPSIS.
Line 28 is not re-routed and does print normally since it is explicitly sent to STDOUT.

B<06:> Line 29 of the script turns off re-routing so Line 30 of the script prints normally
with no shenanigans.

=head2 Functions

These functions are used to change the routing of general print statements.

=head2 re_route_print( %args )

This is the function used to re_route generic print statements to
L<Log::Shiras::Switchboard> for processing.  There are several settings adjustments that
affect the routing of these statements.  Since print statments are intended to be captured
in-place, with no modification, all these settings must be fixed when the re-routing is
implemented.  Fine grained control of which print statements are used is done by line
number (See the SYNOPSIS for an example).  This function accepts all of the possible
settings, minimally scrubs the data as needed, builds the needed anonymous subroutine,
and then redirects generic print statements to that subroutine.  Each set of content from
generic print statements will then be packaged by the anonymous subroutine and sent to
L<Log::Shiras::Switchboard/master_talk( $args_ref )>. Since print statements are generally
scattered throughout pre-existing code the name-space is either 'main::line_number' for
scripts or the subroutine block name within which the print statement occurs with the line
number.  For example the name_space 'main::my_sub::32' would be applied to a print
statement executed on line 32 within the sub block named 'my_sub' in the 'main' script.

=over

B<Accepts:>

The following keys in a hash or hashref which are passed directly to
L<Log::Shiras::Switchboard/master_talk( $args_ref )> - see the documentation there to
understand how they are used by the switchboard.  All values that are passed remain in force
until a new re_route_print call is made or the L<restore_print|/restore_print> call is made.

=over

report - I<default = 'log_file'>

level - I<default = 2 (info)>

fail_over - I<default = 0>

carp_stack - I<default = 0>

=back

B<Returns:> 1

=back

=head2 restore_print

This sends all generic print statements to STDOUT using L<select
|http://perldoc.perl.org/functions/select.html>.

=over

B<Accepts:> Nothing

B<Returns:> 1

=back

=head1 SUPPORT

=over

L<github Log-Shiras/issues|https://github.com/jandrew/Log-Shiras/issues>

=back

=head1 GLOBAL VARIABLES

=over

=item B<$ENV{hide_warn}>

The module will warn when re-routing print statements are turned on.  It
will also warn when internal debug lines are 'Unhide'n.  In
the case where the you don't want these warnings then set this
environmental variable to true.

=back

=head1 TODO

=over

B<1.> Nothing currently

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

=head1 DEPENDANCIES

=over

L<version>

L<5.010|http://perldoc.perl.org/perl5100delta.html> (for use of
L<defined or|http://perldoc.perl.org/perlop.html#Logical-Defined-Or> //)

L<utf8>

L<Moose::Exporter>

L<MooseX::Types::Moose>

L<Carp> - longmess

L<IO::Callback>

L<Log::Shiras::Switchboard>

=back

=head1 SEE ALSO

=over

L<Capture::Tiny> - capture_stdout

=back

=cut

#########1 main pod docs end  3#########4#########5#########6#########7#########8#########9
