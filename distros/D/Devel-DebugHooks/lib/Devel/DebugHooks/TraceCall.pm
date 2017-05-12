package Devel::DebugHooks::TraceCall;

our @ISA;

BEGIN {
	@DB::options{ qw/ w s / } = ( 1, 1 );
	push @ISA, 'Devel::DebugHooks';
}



sub import {
	my $class =  shift;

	$class->SUPER::import( @_ );
}


my $flow_fh;
sub log_call {
	$flow_fh  or  open  $flow_fh, '>dbg_flow.txt';

	my( $from, $to ) =  @{ DB::state( 'stack' ) }[ -2, -1 ];

	my $extra =  '';
	$extra =  "$to->{ file }:$to->{ line }:"   if $to->{ sub } =~ /^CODE/;

	$from =  $from &&( $from->{ sub } // $from->{ package }.'::' )   //  '';
	$to   =  $to   && $to->{ sub }    //  '';
	print $flow_fh "$from -> $extra$to\n";


	1;
}



use Devel::DebugHooks();



my $handler =  DB::reg( 'call', 'TraceCall' );
$$handler->{ context } =  $DB::dbg;
$$handler->{ code }    =  \&log_call;


1;
