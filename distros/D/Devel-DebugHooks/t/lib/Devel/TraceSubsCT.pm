package Devel::TraceSubsCT;



sub import {
	shift->SUPER::import( @_ );
}

BEGIN {
	$DB::dbg //=  __PACKAGE__;
	$DB::options{ trace_subs }  //=  1;
	push @ISA, 'Devel::DebugHooks';
}

sub trace_subs {
	my $self =  shift;

	print $self->SUPER::trace_subs( @_ );
}


use Devel::DebugHooks();
1;
