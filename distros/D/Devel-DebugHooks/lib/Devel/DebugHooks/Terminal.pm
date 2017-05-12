package Devel::DebugHooks::Terminal;

our @ISA;

BEGIN {
        $DB::options{ trace_load }  //=  0;
        $DB::options{ trace_subs }  //=  0;
        $DB::options{ trace_returns }  //=  0;
        $DB::options{ dbg_frames }  //=  0;
        @DB::options{ qw/ w s / } = ( 1, 1 );
        push @ISA, 'Devel::DebugHooks';
}



sub import {
	my $class =  shift;

	$class->SUPER::import( @_ );
}



sub bbreak {
	my $self =  shift;

	# print " -- $DB::file:$DB::line\n  " .(DB::source()->[ $DB::line ] =~ s/^(\s+)//r); #/

	Devel::DebugHooks::Commands->process( 'l .' );
}



use Devel::DebugHooks();


# use Term::ReadLine;
my $term;
# BEGIN {
# 	$term =  Term::ReadLine->new( 'Perl' );
# }
my $last_input;
sub get_command {
	my $self =  shift;

	# WORKAROUND: https://rt.cpan.org/Public/Bug/Display.html?id=110847
	# print $DB::OUT "\n";
	# print "DBG>";
	my $line =  <STDIN>; #$term->readline( 'DBG> ' );
	chomp $line;
	if( $line ne '' ) {
		$last_input =  $line;
	}
	else {
		$line =  $last_input;
	}

	return $line;
}



my $handler =  DB::reg( 'interact', 'terminal' );
$$handler->{ context } =  $DB::dbg;
$$handler->{ code } =  \&Devel::DebugHooks::Commands::interact;

#FIX: Decide where to complete subscribtion: from &import of from RT of module
$handler =  DB::reg( 'bbreak', 'Terminal' );
$$handler->{ context } =  $DB::dbg;
$$handler->{ code }    =  \&bbreak;


1;
