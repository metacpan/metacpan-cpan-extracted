package Devel::TraceLoadCT;



BEGIN {
	$DB::dbg //=  __PACKAGE__;
	$DB::options{ trace_load }  //=  1;
	push @ISA, 'Devel::DebugHooks';
}

sub trace_load {
	my $self =  shift;

	print $self->SUPER::trace_load( @_ );
}


use Devel::DebugHooks();
1;
