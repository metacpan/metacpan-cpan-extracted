package Log::Shiras::TapWarn;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare("v0.48.0");
use strict;
use warnings;
use 5.010;
use utf8;
use lib '../../';
#~ use Log::Shiras::Unhide qw( :InternalTaPWarN );
###InternalTaPWarN	warn "You uncovered internal logging statements for Log::Shiras::TapWarn-$VERSION" if !$ENV{hide_warn};
use Moose::Exporter;
Moose::Exporter->setup_import_methods(
    as_is => [ qw( re_route_warn restore_warn ) ],
);
use MooseX::Types::Moose qw( HashRef );
use Carp 'longmess';
use Log::Shiras::Switchboard;
our	$switchboard = Log::Shiras::Switchboard->instance;
my $warn_store;

#########1 Public Functions   3#########4#########5#########6#########7#########8#########9

sub re_route_warn{
	warn "Re-routing warn statements" if !$ENV{hide_warn};# called at " . (caller( 0 ))[1] . ' line ' . (caller( 0 ))[2] . "\n"
	###InternalTaPWarN	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalTaPWarN		name_space => 'Log::Shiras::TapWarn::re_route_warn',
	###InternalTaPWarN		message =>[ "Re-routing warn statements", ], } );
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
	###InternalTaPWarN	$switchboard->master_talk( { report => 'log_file', level => 0,
	###InternalTaPWarN		name_space => 'Log::Shiras::TapWarn::re_route_warn',
	###InternalTaPWarN		message =>[ "With settings: ", $data_ref ], } );

	# set common report
	if(	!$data_ref->{report} ){
		$data_ref->{report}	= 'log_file';
		###InternalTaPWarN	$switchboard->master_talk( { report => 'log_file', level => 3,
		###InternalTaPWarN		name_space => 'Log::Shiras::TapWarn::re_route_warn',
		###InternalTaPWarN		message =>[ "No report was passed to 're_route_warn' so the " .
		###InternalTaPWarN			"target report for print is set to: 'log_file'" ], } );
	}

	# set common urgency level
	if(	!$data_ref->{level} ){
		$data_ref->{level} = 3;
		###InternalTaPWarN	$switchboard->master_talk( { report => 'log_file', level => 3,
		###InternalTaPWarN		name_space => 'Log::Shiras::TapWarn::re_route_warn',
		###InternalTaPWarN		message =>[ "No urgency level was defined in the 're_route_warn' method " .
		###InternalTaPWarN			"call so future 'print' messages will be sent at: 2 (These go to 11)" ], } );
	}

	# set failover
	if(	!$data_ref->{fail_over} ){
		$data_ref->{fail_over} = 0;
		###InternalTaPWarN	$switchboard->master_talk( { report => 'log_file', level => 3,
		###InternalTaPWarN		name_space => 'Log::Shiras::TapWarn::re_route_warn',
		###InternalTaPWarN		message =>[ "fail_over was not set - setting it to: 0" ], } );
	}

	# set (add) carp stack
	if(	!$data_ref->{carp_stack} ){
		$data_ref->{carp_stack} = 0;
		###InternalTaPWarN	$switchboard->master_talk( { report => 'log_file', level => 3,
		###InternalTaPWarN		name_space => 'Log::Shiras::TapWarn::re_route_warn',
		###InternalTaPWarN		message =>[ "carp_stack was not set - setting it to: 0" ], } );
	}

	# Set the source_sub (Fixed for this class)
	$data_ref->{source_sub} = 'Log::Shiras::TapWarn::__ANON__';
	###InternalTaPWarN	$switchboard->master_talk( { report => 'log_file', level => 1,
	###InternalTaPWarN		name_space => 'Log::Shiras::TapWarn::re_route_warn',
	###InternalTaPWarN		message =>[ "Adjusting the warn sig handler with the data ref: ", $data_ref, ], } );

	$warn_store = $SIG{__WARN__} if $SIG{__WARN__};
	$SIG{__WARN__} = sub{
			$data_ref->{message} = [ @_ ];
			chomp @{$data_ref->{message}};
			###InternalTaPWarN	$switchboard->master_talk( { report => 'log_file', level => 2,
			###InternalTaPWarN		name_space => 'Log::Shiras::TapWarn::warn',
			###InternalTaPWarN		message =>[ "Inbound warn statement: ", $data_ref->{message},], } );# caller( 0 ), '-----', caller( 1 ), '-----', caller( 2 ), '-----', caller( 3 ), '-----', caller( 4 ),
			my $line = (caller( 0 ))[2];
			$data_ref->{name_space} = ((caller( 1 ))[3] and (caller( 1 ))[3] !~ /__ANON__/) ?  (caller( 1 ))[3] : (caller( 0 ))[0];
			$data_ref->{name_space} .= "::$line";
			###InternalTaPWarN	$switchboard->master_talk( { report => 'log_file', level => 1,
			###InternalTaPWarN		name_space => 'Log::Shiras::TapWarn::warn',
			###InternalTaPWarN		message =>[ "Added name_space: ", $data_ref->{name_space}, ], } );

			# Dispatch the message
			my $report_count = $switchboard->master_talk( $data_ref );
			###InternalTaPWarN	$switchboard->master_talk( { report => 'log_file', level => 2,
			###InternalTaPWarN		name_space => 'Log::Shiras::TapWarn::warn',
			###InternalTaPWarN		message =>[ "Message reported |$report_count| times"], } );

			# Handle fail_over
			if( $report_count == 0 and $data_ref->{fail_over} ){
				###InternalTelephonE	$switchboard->master_talk( { report => 'log_file', level => 4,
				###InternalTelephonE		name_space => 'Log::Shiras::TapWarn::warn',
				###InternalTelephonE		message	=> [ "Message allowed but found no destination!", $data_ref->{message} ], } );
				warn longmess( "This message sent to the report -$data_ref->{report}- was approved but found no destination objects to use" ), @_;
			}
		} or die "Couldn't redirect __WARN__: $!";
	###InternalTaPWarN	$switchboard->master_talk( { report => 'log_file', level => 0,
	###InternalTaPWarN		name_space => 'Log::Shiras::TapWarn::re_route_warn',
	###InternalTaPWarN		message =>[ "Finished re_routing warn statements" ], } );
	return 1;
}

sub restore_warn{
	$SIG{__WARN__} = $warn_store ? $warn_store : undef;
	$warn_store = undef;
	###InternalTaPWarN	$switchboard->master_talk( { report => 'log_file', level => 0,
	###InternalTaPWarN		name_space => 'Log::Shiras::TapWarn::restore_warn',
	###InternalTaPWarN		message =>[ "Log::Shiras is no longer tapping into warnings!" ], } );
	return 1;
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

1;

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Log::Shiras::TapWarn - Reroute warn to Log::Shiras::Switchboard

=head1 SYNOPSIS

	use Modern::Perl;
	#~ use Log::Shiras::Unhide qw( :InternalTaPWarN );# :InternalSwitchboarD
	$ENV{hide_warn} = 0;
	use Log::Shiras::Switchboard;
	use Log::Shiras::TapWarn qw( re_route_warn restore_warn );
	my	$ella_peterson = Log::Shiras::Switchboard->get_operator(
			name_space_bounds =>{
				UNBLOCK =>{
					log_file => 'trace',
				},
				main =>{
					32 =>{
						UNBLOCK =>{
							log_file => 'fatal',
						},
					},
					34 =>{
						UNBLOCK =>{
							log_file => 'fatal',
						},
					},
				},
			},
			reports	=>{ log_file =>[ Print::Log->new ] },
		);
	re_route_warn(
		fail_over => 0,
		level => 'debug',
		report => 'log_file',
	);
	warn "Hello World 1";
	warn "Hello World 2";
	restore_warn;
	warn "Hello World 3";

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
		print $output;
		use warnings 'uninitialized';
	}

	1;

	#######################################################################################
	# Synopsis Screen Output
	# 01: Re-routing warn statements at ../lib/Log/Shiras/TapWarn.pm line 22, <DATA> line 1.
	# 02: | level - debug  | name_space - main::33
	# 03: | line  - 0033   | file_name  - log_shiras_tapwarn.pl
	# 04: 	:(	Hello World 1 at log_shiras_tapwarn.pl line 33, <DATA> line 1. ):
	# 05: Hello World 3 at log_shiras_tapwarn.pl line 36, <DATA> line 1.
	#######################################################################################

=head1 DESCRIPTION

This package allows Log::Shiras to be used for code previously written with warn statement
outputs.  It will re-direct the warn statements using the L<$SIG{__WARN__} (%SIG)
|http://perldoc.perl.org/perlvar.html> handler.  Using this
mechanisim means that the string in;

    warn "Print some line";

Will be routed to L<Log::Shiras::Switchboard> after the method call L<re_route_warn
|/re_route_warn( %args )>

This class is used to import functions into the script.  These are not object methods and
there is no reason to call ->new.  Uncomment line 2 of the SYNOPSIS to watch the inner
workings.

=head2 Output Explanation

B<01:> The method re_route_warn will throw a warning statement whenever
$ENV{hide_warn} is not set and the method is called.

B<02-04:> Line 31 of the code has been captured (meta data appended) and then sent to the
Print::Log class for reporting.

B<05:> Line 32 of the script did not print since that line has a higher required urgency
than the standard 'warn' level provided by the L<re_route_warn|/re_route_warn( %args )>
call in the SYNOPSIS.

B<06:> Line 33 of the script turns off re-routing so Line 34 of the script prints normally
with no shenanigans.  (Even though it is also blocked by line number)

=head2 Functions

These functions are used to change the routing of warn statements.

=head3 re_route_warn( %args )

This is the function used to re_route warnings to L<Log::Shiras::Switchboard> for
processing.  There are several settings adjustments that affect the routing of warnings.
Since warnings are intended to be captured in-place, with no modification, all these
settings must be fixed when the re-routing is implemented.  Fine grained control of which
warnings are processed is done by line number (See the SYNOPSIS for an example).    This
function accepts all of the possible settings, minimally scrubs the settings as needed,
builds the needed anonymous subroutine, and then redirects (runtime) future warnings to
that subroutine.  Each set of content from a warning statement will then be packaged by
the anonymous subroutine and sent to L<Log::Shiras::Switchboard/master_talk( $args_ref )>.
Since warnings are generally scattered throughout pre-existing code the auto assigned
name-space is either 'main::line_number' for top level scripts or the subroutine block
name and warning line number within the block.  For example the name_space
'main::my_sub::32' would be applied to a warning executed on line 32 within the sub
block named 'my_sub' in the 'main' script.

=over

B<Accepts>

The following keys in a hash or hashref which are passed directly to
L<Log::Shiras::Switchboard/master_talk( $args_ref )> - see the documentation there to
understand how they are used by the switchboard.  All values that are passed remain in force
until a new re_route_warn call is made or the L<restore_warn|/restore_warn> call is made.

=over

report - I<default = 'log_file'>

level - I<default = 3 (warn)>

fail_over - I<default = 0>

carp_stack - I<default = 0>

=back

B<Returns> 1

=back

=head3 restore_warn

This returns the $SIG{__WARN__} settings to what they were before or undef.
The result is warn statements will start to be processed as they were prior to the
're_route_warn' call.

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

The module will warn when re-routing warn statements are turned on.  It
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

L<Log::Shiras::Switchboard>

=back

=head1 SEE ALSO

=over

L<Capture::Tiny> - capture_stderr

=back

=cut

#########1 main pod docs end  3#########4#########5#########6#########7#########8#########9
