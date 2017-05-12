package Devel::DebugHooks::Verbose;

our @ISA;

BEGIN {
	push @ISA, 'Devel::DebugHooks';
}



sub trace_load {
	my $self =  shift;

	my $res =  "Loaded '@_'\n";
	#FIX: Events are emitted in scalar context (see while condition)
	# return $res   if defined wantarray;

	print $DB::OUT $res;
}





my %frame_name =  (
	G => 'GOTO',
	D => 'DBGF',
	C => 'FROM',
);

sub trace_subs {
	my( $self ) =  @_;

	BEGIN{ 'warnings'->unimport( 'uninitialized' )   if $DB::options{ w } }


	my $info = '';
	local $" =  ' -';
	my( $orig_frame, $last_frame );
	for my $frame ( DB::frames() ) {
		$last_frame //=  $frame   if $frame->[0] ne 'D';
		$orig_frame //=  $frame   if $frame->[0] ne 'D'  &&  $frame->[0] ne 'G';

		$info .=  $frame_name{ $frame->[0] } .": @$frame[2..5]\n";
	}

	my $context = $orig_frame->[7] ? 'list'
			: defined $orig_frame->[7] ? 'scalar' : 'void';

	$" =  ', ';
	my @args =  map { !defined $_ ? '&undef' : $_ } @{ $orig_frame->[1] };
	$info =
		"\n" .' =' x15 ."\n"
		."DEEP: ". @{ DB::state( 'stack' ) } ."\n"
		."CNTX: $context\n"
		.$last_frame->[0] ."SUB: " .$last_frame->[5] ."( @args )\n"
		# print "TEXT: " .DB::location( $DB::sub ) ."\n";
		# NOTICE: even before function call $DB::sub changes its value to DB::location
		# A: Because @_ keep the reference to args. So
		# 1. The reference to $DB::sub is saved into @_
		# 2. The DB::location is called
		# 3. The value of $DB::sub is changed to DB::location
		# 4. my( $sub ) =  @_; # Here is too late to get the orig value of $DB::sub
		."TEXT: " .DB::location( $last_frame->[5] ) ."\n\n"
		.$info;

	$info .=  ' =' x15 ."\n";

	print $DB::OUT $info;
}



sub trace_returns {
	my $self =  shift;

	my $info;
	$info =  $DB::options{ trace_subs } ? '' : "\n" .' =' x15 ."\n";
	# FIX: uninitializind value while 'n'
	# A: Can not reproduce...
	$info .= join '->', map { $_->[3] } @{ DB::state( 'goto_frames' ) };
	$info .= " RETURNS:\n";

	$info .=  @_ ?
		'  ' .join "\n  ", map { defined $_ ? $_ : '&undef' } @_:
		'>>NOTHING<<';

	print $DB::OUT $info ."\n" .' =' x15 ."\n";
}



sub bbreak {
	my $info =  "\n" .' =' x30 .DB::state( 'inDB' ) ."\n";

	#NOTICE: We do not add '\n' because each line of a source has one
	$info .=  sprintf "%s:%s    %s"
		,DB::state( 'file' )
		,DB::state( 'line' )
		,DB::source()->[ DB::state( 'line' ) ]
	;

	print $DB::OUT $info;
}



sub import {
	my( $class ) =  shift;

	$class->SUPER::import( @_ );

	# Enabled by default
	# The differece when we set option at compile time, we see module loadings
	# and compilation order whereas setting up it at run time we lack that info
	$DB::options{ trace_load } //=  1;           # compile time option
	$DB::options{ trace_subs } //=  1;           # compile time & runtime option
	$DB::options{ trace_returns } //=  1;


	if( $DB::options{ trace_load } ) {
		my $handler =  DB::reg( 'trace_load', 'Verbose' );
		$$handler->{ code }    =  \&trace_load;
	}

	if( $DB::options{ trace_subs } ) {
		my $handler =  DB::reg( 'call', 'Verbose' );
		$$handler->{ code }    =  \&trace_subs;
	}

	if( $DB::options{ trace_returns } ) {
		my $handler =  DB::reg( 'trace_returns', 'Verbose' );
		$$handler->{ code }    =  \&trace_returns;
	}
}



use Devel::DebugHooks();

1;
