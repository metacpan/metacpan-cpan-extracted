package Devel::DZV;

BEGIN {
	$DB::dbg //=  __PACKAGE__;
	push @ISA, 'Devel::DebugHooks';
}


sub bbreak {
	my $self =  shift;

	print $self->SUPER::bbreak( @_ );
}


use Devel::DebugHooks();
1;
