package Devel::DebugHooks::KillPrint;



my $actions  =  {};
my @profiles =  ();


#FIX: Do this after script is compiled. Look for some hook...
sub trace_load {
	if( $_[1] eq "*main::_<$0" ) { #<-- This is tricky
		while( my( $key, $value ) =  each %$actions ) {
			#TODO: call process here
			$DB::commands->{ a }->( "$key $value" );
		}
	}
}



use Devel::DebugHooks();
BEGIN{
	push @ISA, 'Devel::DebugHooks';
	my $handler =  DB::reg( 'trace_load', 'kill_print' );
	$$handler->{ context } =  $DB::dbg;
	$$handler->{ code }    =  $DB::dbg->can( 'trace_load' );
}
use Filter::Util::Call;



sub import {
	# Pay attention to $actions, because it is module global
	# We do not expect here that we would be used twice or more times!
	filter_add( bless $actions );

	my $class =  shift;

	while( @_ && $_[0] ne '--' ) {
		push @profiles, shift;
	}

	shift   if @_; # Remove '--'. Here the @_ exists only if '--' was supplied

	$class->SUPER::import( @_ );
}



sub filter {
	my( $self ) =  @_;

	my $status;
	if( ( $status =  filter_read() ) > 0 ) {

		if( /#DBG:(\w*) (.*) #$/ ) {
			my $profile =  $1 || 'default';
			if( !@profiles  ||  grep{ $_ eq $profile } @profiles ) {
				my( $file, $line ) =  (caller 0)[1,2];
				$self->{ "$file:$line" } =  $2;

				s/^(\s*)(#DBG:\w* .* #)$/${1}1;   $2/;
			}
		}
	}

	$status;
}


sub Devel::DebugHooks::Commands::interact { 0 }

1;
