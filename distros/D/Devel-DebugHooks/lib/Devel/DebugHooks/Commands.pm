package Devel::DebugHooks::Commands;

our $lines_before =  15;
our $lines_after  =  15;

# FIX: segmentation fault when:
# use strict;
# use warnings;

# BEGIN {
# 	if( $DB::options{ w } ) { require 'warnings.pm';  'warnings'->import(); }
# 	if( $DB::options{ s } ) { require 'strict.pm';    'strict'->import();   }
# 	if( $options{ d } ) { require 'Data/Dump.pm'; 'Data::Dump'->import( 'pp'); }
# }

# TODO: implement 'hard_go' to go over all traps to the 'line' or end
# TODO: implement do not stop in current sub
# TODO: black box command 'T': 50..70 Black box
# TODO: enable/disable group of traps
# TODO: implement option to show full/short sub options
# TODO: split all code by two: user code and core
# TODO: implement distance 'T XXX'; Automatically sets XXX to the current line
# TODO: implement 'b &' to set breakpoint to current sub
# TODO: implement 'd code' command to debug given subroutine
# TODO: implement 'l ~TEXT' to list specific lines
# TODO: implement 'ge -2' to edit
# TODO: implement 's 7', 'n 7', 'go +5' commands to skip N expressions
# FIX: when returning from sub by 'r' and upper sub has no any stop point
# we out many frames out
# TODO: implement tracing subroutine which user run manually 't $subname'
# NOTICE: when return we can go into destroy
# TODO: returning from try/catch block
# Show code flow in NON stop mode
# TODO: do not exit on blocks. This is usefull when we want to see result of statement
# if() { statement; }
# TODO: implement command to list all available packages
# TODO: implement command to list all available subs in package ( DB::subs )
# TODO: IT: closed variables are created at compile time. We do not see them when just eval at sub

my $file_line =  qr/(?:(.+):)?(\d+|\.)/;


sub file {
	my( $file, $do_not_set ) =  @_;

	return DB::state( 'list.file' ) // DB::state( 'file' )
		unless defined $file;

	my $files =  DB::state( 'cmd.f' );
	$file =  $files->[ $file ]
		if $file =~ m/^(\d+)$/  &&  exists $files->[ $file ];

	DB::state( 'list.file', $file )   unless $do_not_set;

	return $file;
}



my %cmd_T = (
	G => '&',
	C => '=',
	D => '-',
	L => '\\',
);



sub _cursor_position {
	my( $frames, $file ) =  @_;

	my $run_level =  0;
	my $lines;
	for( @$frames ) {
		# Frames are counted from the end
		$lines->{ $_->{ line } } =  $#$frames -$run_level
			if $_->{ file } eq $file;
		$run_level++;
	}

	return $lines;
}



# TODO: implement trim for wide lines to fit text into window size
sub _list {
	my( $file, $from, $to ) =  @_;

	# Fix window boundaries
	my $source =  DB::source( $file );
	$from =  0           if $from < 0;        # TODO: testcase; 0 exists if -d
	$to   =  $#$source   if $to > $#$source;  # TODO: testcase

	# The place where to display *run marker*: '>>'
	my $cursor_at =  _cursor_position( DB::state( 'stack' ) ,$file );


	print $DB::OUT "$file\n";
	my $traps  =  DB::traps( $file );
	for my $line ( $from..$to ) {
		next   unless exists $source->[ $line ];

		# Print flags
		if( exists $traps->{ $line } ) {
			print $DB::OUT exists $traps->{ $line }{ action } ? 'a' : ' ';
			print $DB::OUT exists $traps->{ $line }{ onetime } ? '!'
				: exists $traps->{ $line }{ breakpoint }{ disabled  }? '-'
				: exists $traps->{ $line }{ breakpoint }{ condition }? 'b' : ' ';
		}
		else {
			print $DB::OUT '  ';
		}


		# Print *breakable* and *cursor* marks
		if( defined( my $level =  $cursor_at->{ $line } ) ) {
			if( $level ) {
				if( $level < 10 ) {
					printf $DB::OUT '%d>', $level;
				}
				else {
					printf $DB::OUT '*>';
				}
			}
			else {
				printf $DB::OUT '>>';
			}
		}
		else {
			printf $DB::OUT  DB::can_break( $file, $line ) ? ' x' : '  ';
		}


		# Print source line number
		print $DB::OUT "$line:";


		# Print source line
		(my $sl =  $source->[ $line ]) =~ s/\t/    /g; #/
		$sl  =  " $sl";                       # Space after line number
		$sl .=  "\n"   unless $sl =~ m/\n$/s; # Last line maybe without EL
		$sl  =~ s/\s+\n$/\n/s;                # Remove whitespaces at EOL
		print $DB::OUT $sl;
	}
}



# TODO: tests 'l;l', 'l 0', 'f;l 19 3', 'l .'
sub list {
	my( $args ) =  @_;


	# Just list source at current position
	if( $args eq '' ) {
		my $file =  DB::state( 'list.file' );
		my $line =  DB::state( 'list.line' );
		 $line += $lines_after +1;
		_list( $file, $line, $line +$lines_before +$lines_after  );

		# Move cursor to the next window.
		# Window is: lines before, current line and lines after
		DB::state( 'list.line',  $line +$lines_before );

		return 1;
	}


	if( my( $stack, $file, $line, $to ) =  $args =~ m/^(-)?${file_line}(?:-(\d+))?$/ ) {
		my $from;
		if( $stack && !$file ) {
			# Here $line is stack frame number from the last frame
			# Frames are counted from the end. -1 subscript is for current frame
			my $frames =  DB::state( 'stack' );
			return -2   if $line +1 > @$frames;
			DB::state( 'list.level', $line );
			( $file, $line ) =  @{ $frames->[ -$line -1 ] }{ qw/ file line / };
		}
		elsif( $line eq '.' ) {
			DB::state( 'list.level', 0 );
			# TODO: 'current' means file and line! FIX this in other places too
			$file =  DB::state( 'file' );
			$line =  DB::state( 'line' );
		}
		else {
			$file =  file( $file );
		}


		if( $to ) {
			$from =  $line;
			$line =  $to -$lines_after;
		}
		else {
			$from =  $line -$lines_before;
			$to   =  $line +$lines_after;
		}

		_list( $file, $from, $to );


		# Move cursor to the next window.
		# Window is: lines before, current line and lines after
		DB::state( 'list.file', $file );
		DB::state( 'list.line', $line );
	}
	elsif( my( $ref, $subname ) =   $args =~ m/^(\$?)(&\d*|.+)?$/ ) {
		# 1.Deparse the current sub or n frames before
		# TODO: Check is it possible to spy subs from goto_frames?
		# If yes think about interface to access to them ( DB::frames??? )
		if( $subname =~ /^&(\d*)$/ ) {
			my $level =  $1 // 0;
			# FIX: 'eval' does not update @DB::stack.
			# Eval exists at real stack but does not at our
			my $frames =  DB::state( 'stack' );
			return -2   if $level +1 > @$frames;
			my $coderef =  $frames->[ -$level -1 ]{ sub };
			return -4   if $coderef eq ''; # The main:: namespace
			print $DB::OUT "sub $coderef ";
			$coderef =  \&$coderef   unless ref $coderef;
			return deparse( $coderef );
		}

		# 2. List sub by code ref in the variable
		# TODO: findout sub name from the reference
		# TODO: locate this sub at '_<$file' hash and do usual _list
		# to show breakpoints, lines etc
		$ref  &&  return [()
			,sub{ deparse( @{ $_[0] } ); return { code =>  \&interact } }
			,"\$$subname"
		];


		# 3. List sub from source
		$subname =  DB::state( 'package' ) ."::${ subname }"
			if $subname !~ m/::/;

		# The location format is 'file:from-to'
		my $location =  DB::location( $subname );
		if( defined $location  &&  $location =~ m/^(.*):(\d+)-(\d+)$/ ) {
			_list( $1, $2, $3 );
		}

		return 1;
	}
	else {
		print $DB::OUT "Can not list: $args\n";

		return -1;
	}


	return 1;
}



sub deparse {
	require B::Deparse;
	my( $coderef ) =  @_;
	return -3   unless ref $coderef eq 'CODE';

	print $DB::OUT B::Deparse->new("-p", "-sC")
		->coderef2text( $coderef )
		,"\n"
	;

	return 1;
}



sub interact {
	my $handler =  shift;
	my $dbg =  $handler->{ context }; # This is better
	my $str =  $dbg->get_command();
	return   unless defined $str;
	print $DB::OUT +(" "x60 ."*"x20 ."\n")x10   if DB::state( 'ddd' );

	my $result =  process( undef, $str );
	return   unless defined $result;

	if( $result == 0 ) {
		# No command found
		# eval $str; print eval results; goto interact again
		return[ sub{
			# We got ARRAYREF if EXPR was evalutated
			DB::state( 'db.last_eval', $str );

			if( ref $_[0] eq 'DB::Error' ) {
				print $DB::OUT "ERROR: $_[0]";
			}
			else {
				print $DB::OUT "\nEvaluation result:\n"   if DB::state( 'ddd' );
				my @res =  map{ $_ // $DB::options{ undef } } @{ $_[0] };
				local $" =  $DB::options{ '"' }  //  $";
				print $DB::OUT "@res\n";
			}

			return $handler;
		}
			# EXPRessions to evaluate in user context
			,$str
		];
	}


	#FIX: Implement sub to return interaction command
	return $handler   unless ref $result;
	return $result;
}



sub dd {
	require Data::Dump;
	Data::Dump::pp( @_ );
}



sub get_expr {
	my( $data ) =  @_;
	my @expr =  keys %{ $data->{ eval } };
	# This sub is called with expressions evaluation result
	# Additionally we pass and source data structure and corresponding keys
	# Old values we get by those keys
	return [ sub{ watch_checker( $data, \@expr, \@_ ) }, @expr ];
}



sub watch_checker {
	my( $data, $keys, $nv ) =  @_;

	my $stop =  0;
	for my $i ( 0 .. $#$keys ) { #TODO: IT: for commit:035e182e4f case
		my $ov =  \$data->{ eval }{ $keys->[ $i ] };
		# dd( $$ov, $nv->[ $i ], $#$$ov );
		next   if defined $$ov  &&  @{ $nv->[ $i ] } == grep {
				defined $$ov->[$_]  &&  defined $nv->[$i][$_]
				&&  $$ov->[$_] eq $nv->[$i][$_]
				|| !defined $$ov->[$_]  &&  !defined $nv->[$i][$_]
			} 0..$#$$ov;

		# Do not stop for first time
		if( defined $$ov ) {
			$stop ||=  1;
			local $" =  ',';
			print $DB::OUT $keys->[ $i ] .": @$$ov -> @{ $nv->[ $i ] }\n";
		}

		$$ov =  $nv->[ $i ];
	}

	$stop;
}



#TODO: I: global watch when we do not rely on $file:$line and just watching
# this expression at any place it is mentioned
sub watch {
	my( $file, $line, $expr ) =  shift =~ m/^${file_line}(?:\s+(.+))?$/;

	$line     =  DB::state( 'line' )   if $line eq '.';
	$file     =  file( $file );

	my $traps =  DB::traps( $file );


	unless( $expr ) {
		for( defined $line ? ( $line ) : sort{ $a <=> $b } keys %$traps ) {
			next   unless exists $traps->{ $_ }{ watch };

			print $DB::OUT "line $_:\n";
			print $DB::OUT "  " .dd( $_ ) ."\n"
				for @{ $traps->{ $_ }{ watch } };
		}

		return 1;
	}


	unless( DB::can_break( $file, $line ) ) {
		print $DB::OUT file(). "This line is not breakable. Can not watch at this point\n";
	}


	my $data =  DB::reg( 'trap', 'watch', $file, $line );
	$$data->{ code } =  \&get_expr;
	# We do not know $expr result until eval it
	$$data->{ eval }{ $expr } =  undef;

	1;
}



sub load {
	my $self =  shift;
	my( $file ) =  @_;
	$file ||=  $ENV{ HOME } .'/.dbgini';


	my( $stops, $traps ) =  do $file;

	for( keys %$traps ) {
		# TODO? do we need to can_break( $file, $line )?
		%{ DB::traps( $_ ) || {} } =  %{ $traps->{ $_ } };
	}

	#IT: check we are stopped in right place after loading
	DB::state( 'on_call', $stops );


	return 1;
}



# TODO: implement AutoSave option
sub save {
	my $self =  shift;
	my( $file ) =  @_;
	$file ||=  $ENV{ HOME } .'/.dbgini';

	my $traps;
	for my $source ( keys %$DB::_tfiles ) {
		$traps->{ $source } =  DB::traps( $source );
		delete $traps->{ $source } # Do not save empty hashes
			unless keys %{ $traps->{ $source } };
	}

	open my $fh, '>', $file   or die $!;
	print $fh dd( DB::state( 'on_call' ), $traps );

	return 1;
}



sub trace_variable {
	my( $var ) =  shift;

	require Devel::DebugHooks::TraceAccess;

	return [()
		,sub { return { code =>  \&interact } }
		,"tie $var, 'Devel::DebugHooks::TraceAccess', \\$var, desc => '$var'"
	]
}



sub get_expr_a {
	my( $data ) =  @_;

	my @expr =  @{ $data->{ eval } };
	for my $expr_or_cmd ( @expr ) {
		my $result =  process( undef, $expr_or_cmd );
		$expr_or_cmd =  $result   if ref $result;
	}

	return [ sub{ 0 }, @expr ];
}


sub action {
	my( $file, $line, $expr ) =  shift =~ m/^${file_line}(?:\s+(.+))$/;

	$line     =  DB::state( 'line' )   if $line eq '.';
	$file     =  file( $file );

	my $traps =  DB::traps( $file );


	unless( $expr ) {
		for( defined $line ? ( $line ) : sort{ $a <=> $b } keys %$traps ) {
			next   unless exists $traps->{ $_ }{ action };

			print $DB::OUT "line $_:\n";
			print $DB::OUT "  " .dd( $_ ) ."\n"
				for @{ $traps->{ $_ }{ action } };
		}

		return 1;
	}


	unless( DB::can_break( $file, $line ) ) {
		print $DB::OUT file(). "This line is not breakable. Can not set action at this point\n";
	}


	my $data =  DB::reg( 'trap', 'action', $file, $line );
	#FIX: register callback only once at some global structure
	$$data->{ code } =  \&get_expr_a;
	push @{ $$data->{ eval } }, $expr;


	return 1;
}



# Stop on the first OP in a given subroutine
sub stop_on_call {
	my( $data, $current_sub ) =  @_;
	my $target_subs =  $data->{ list };

	if(
		# IF exists  &&  not disabled (value is TRUE)
		$target_subs->{ $current_sub }

		# OR exists  &&  not disabled  &&  partially matched name
		|| grep{
			$target_subs->{ $_ }
				&&
			$current_sub =~ m/$_$/
		} keys %$target_subs
	) {
		DB::state( 'single', 1 ); # Stop on next OP
	}
}



# Stop if trap is not disabled and condition evaluated to TRUE value
sub stop_on_line {
	my( $data ) =  @_;

	return 0   if $data->{ disabled }  ||  !exists $data->{ condition };

	return [ sub{ my $x =  shift; @$x && $x->[0] && 1 }, $data->{ condition } ];
}



sub step_done {
	my( $data ) =  @_;
	return   if --$data->{ steps_left };

	DB::unreg( 'stop', 'step' );
	return 1;
};



sub nested {
	no warnings 'void';
	2;
	printf $DB::OUT "%s at %s:%s\n"
		,DB::state( 'single' ), DB::state( 'file' ), DB::state( 'line' );
	3;
}



$DB::commands =  {()
	,debug => sub {
		no warnings 'void';
		1;
		nested();
		4;
	}
	,'.' => sub {
		$curr_file   =  DB::state( 'file' );
		$line_cursor =  DB::state( 'line' );

		(my $tmp=DB::source()->[ $line_cursor ]) =~ s/^\s+//;
		print $DB::OUT "$curr_file:$line_cursor    $tmp";

		1;
	}

	,st => sub {
		print $DB::OUT dd( DB::state( 'stack' ), DB::state( 'goto_frames' ) );
		print $DB::OUT "S: $DB::single T:$DB::trace A:$DB::signal\n";

		1;
	}

	# Return from sub call to the first OP at some outer frame
	# In compare to 's' and 'n' commands 'r' will not stop at each OP. So we set
	# 0 to $DB::single for current frame and N-1 last frames. For target N frame
	# we set $DB::single value to 1 which will be restored by &pop_frame
	# Therefore DB::DB will be called at the first OP followed this sub call
	,r => sub {
		my( $frames_out, $sharp ) =  shift =~ m/^(\d+)(\^)?$/;

		my $leave_chain =  defined $frames_out;
		$frames_out //=  1;

		my $stack =  DB::state( 'stack' );
		my $stack_size =  @$stack;
		$frames_out =  $stack_size -$frames_out   if $sharp;
		return -2   if $frames_out < 0; # Do nothing for unexisting frame

		# Return to the last possible frame. If no frames then exit from script
		$frames_out =  $stack_size   if $frames_out > $stack_size;

		# ... skip N next frames
		$_->{ single } =  0   for @$stack[ -$frames_out .. -1 ];

		# and stop at some outer frame
		$_->{ single } =  1   for @$stack[ -$stack_size .. -$frames_out-1 ];

		# Do not stop if subcall is maden
		if( $leave_chain  &&  $frames_out < $stack_size ) { # have parent frame
			my $handler =  DB::reg( 'call', 'step_over' );
			# FIX: move 'on_frame' handler code to upper frames if we leave current one
			$$handler->{ code } =  sub{ DB::state( 'single', 0 ); 1 };
			$handler =  DB::reg( 'stop', 'step_over' );
			$$handler->{ code } =  sub{
				DB::unreg( 'stop', 'step_over' );
				DB::unreg( 'call', 'step_over' );
				1;
			};
		}

		return;
	}

	# Do single step to the next OP
	# Here we force $DB::single = 1 for current frame and all outer frames.
	# Because current OP maybe the last OP in sub. It also maybe the last OP in
	# the outer frame. And so on.
	,s => sub {
		if( shift =~ m/^(\d+)$/ ) {
			my $handler =  DB::reg( 'stop', 'step' );
			$$handler->{ code } =  \&step_done;
			$$handler->{ steps_left } =  $1;
		}

		$_->{ single } =  1   for @{ DB::state( 'stack' ) };

		return;
	}

	# Do single step to the next OP. If current OP is sub call. Step over it
	# ...As for the 's' command we stop at each OP in the script. But when the
	# sub is called we turn off debugging for that sub at DB::sub.
	# DB::state( 'single', 0 )   if $DB::single & 2;
	# After that sub returns $DB::single will be restored because of localizing
	# Therefore DB::DB will be called at the first OP followed this sub call
	,n => sub {
		if( shift =~ m/^(\d+)$/ ) {
			my $handler =  DB::reg( 'stop', 'step' );
			$$handler->{ code } =  \&step_done;
			$$handler->{ steps_left } =  $1;
		}


		# Do not stop if subcall is maden
		my $handler =  DB::reg( 'frame', 'step_over' );
		# FIX: move handler code to upper frames if we leave current one
		$$handler->{ code } =  sub{ $_[1]{ single } =  0; 1 };
		$handler =  DB::reg( 'stop', 'step_over' );
		$$handler->{ code } =  sub{
			DB::unreg( 'stop', 'step_over' );
			DB::unreg( 'frame', 'step_over' );
			1;
		};

		my $stack =  DB::state( 'stack' );
		# If the current OP is last OP in this sub we stop at *some* outer frame
		$_->{ single } =  2   for @$stack;

		return;
	}

	# Quit from the debugger
	,q => sub {
		for( @$DB::state ) {
			for( @{ $_->{ stack } } ) { # TODO: implement interface to debugger instance
				$_->{ single } =  0;
			}
		}

		exit;
	}

	# TODO: print list of vars which refer this one
	,vars => sub {
		my( $level, $type, $var ) =
			(' '.shift) =~ m/^(?:\s+-(\d+))?(?:\s+([amogucs]+))?(?:\s+([\$\%\*\&].*))?$/;

		for( split '', $type ) {
			$type |= ~0   if /^a|all$/;
			$type |= 1    if /^m|my$/;
			$type |= 2    if /^o|our$/;
			$type |= 4    if /^g|global$/;
			$type |= 8    if /^u|used$/;
			$type |= 16   if /^c|closured$/;
			$type |= 24   if /^s|sub$/;       #u+c
		}
		$level //=  DB::state( 'list.level' );
		$type  //=  DB::state( 'vars.type' ) // 3   unless $var;


		my $dbg_frames =  0;
		{ # Count debugger frames
			my @frame;
			1 while( @frame =  caller( $dbg_frames++ )  and  $frame[3] ne 'DB::DB' );
			$dbg_frames--;
		}


		#FIX: When we debug debugger we can not 'go <line>' we always stops at
		#require at third line at PadWalker.pm. Debug who set $DB::state = 1
		require 'PadWalker.pm';
		require 'Package/Stash.pm'; # BUG? spoils DB:: by emacs, dbline

		my $my =   PadWalker::peek_my(  $level +$dbg_frames );
		my $our =  PadWalker::peek_our( $level +$dbg_frames );

		if( $type & 1 ) {
			# TODO: for terminals which support color show
			# 1. not used variables as grey
			# 2. closed over variables as green or bold
			print $DB::OUT "\nMY:\n", join( ', ', sort keys %$my ), "\n";
		}

		if( $type & 2 ) {
			print $DB::OUT "\nOUR:\n", join( ', ', sort keys %$our ), "\n";
		}

		if( $type & 4 ) {
			my $stash =  Package::Stash->new( DB::state( 'package' ) )->get_all_symbols();
			# Show only user defined variables
			# TODO? implement verbose flag
			if( DB::state( 'package' ) eq 'main' ) {
				for( keys %$stash ) {
					delete $stash->{ $_ }   if /::$/;
					delete $stash->{ $_ }   if /^_</;
					delete $stash->{ $_ }   if /^[\x00-0x1f]/; #Remove $^ variables
				}

				delete @$stash{ qw# STDERR stderr STDIN stdin STDOUT stdout # };
				delete @$stash{ qw# SIG INC F ] ENV ; > < ) ( $ " _ # }; # a b
				delete @$stash{ qw# - + ` & ' #, 0..99 };
				# BUG? warning still exists despite on explicit escaping of ','
				delete @$stash{ qw# ARGV ARGVOUT \, . / \\ | # };
				delete @$stash{ qw# % - : = ^ ~ # };
				delete @$stash{ qw# ! @ ? # };
			}
			delete $stash->{ sub }   if DB::state( 'package' ) eq 'DB';

			my @globals =  ();
			my %sigil =  ( SCALAR => '$', ARRAY => '@', HASH => '%' );
			for my $key ( keys %$stash ) {
				my $glob =  $stash->{ $key };
				for my $type ( keys %sigil ) {
					next   unless defined *{ $glob }{ $type };
					next   if $type eq 'SCALAR'  &&  !defined $$glob;
					next   if $key =~ /::/;
					push @globals, $sigil{ $type } .$key;
				}
			}

			print $DB::OUT "\nGLOBAL:\n", join( ', ', sort @globals ), "\n";
		}

		if( $type & 8 ) {
			print $DB::OUT "\nUSED:\n";

			# First element starts at -1 subscript
			# FIX: When debug debugger and we step over this statement
			# the $sub contain reference ot &vars instead of name of last
			# client's sub
			my $sub =  DB::state( 'stack' )->[ -$level -1 ]{ sub };
			if( !defined $sub ) {
				# TODO: Mojolicious::__ANON__[/home/feelsafe/perl_lib/lib/perl5/Mojolicious.pm:119]
				# convert this to subroutine refs
				# print $DB::OUT "Not in a sub: $sub\n";
				print $DB::OUT "Not in a sub\n";
			}
			else {
				$sub =  \&$sub;
				print $DB::OUT join( ', ', sort keys %{ PadWalker::peek_sub( $sub ) } ), "\n";
			}
		}

		if( $type & 16 ) {
			print $DB::OUT "\nCLOSED OVER:\n";

			# First elements starts at -1 subscript
			my $sub =  DB::state( 'stack' )->[ -$level -1 ]{ sub };
			if( !defined $sub ) {
				print $DB::OUT "Not in a sub\n";
				# print $DB::OUT (ref $sub ) ."Not in a sub: $sub\n";
			}
			else {
				$sub =  \&$sub;
				print $DB::OUT join( ', ', sort keys %{ (PadWalker::closed_over( $sub ))[0] } ), "\n";
			}
		}

		if( $var ) {
			my( $sigil, $name, $extra ) =  $var =~ m/^(.)(\w+)(.*)$/;

			$var =  $sigil .$name;
			unless( exists $my->{ $var } || exists $our->{ $var } ) {
				print $DB::OUT "Variable '$var' does not exists at this scope\n";
				return -1;
			}

			my $value =  $my->{ $var }  ||  $our->{ $var };
			$value =  $$value   if $sigil eq '$';
			eval "\$value =  \$value$extra; 1"   or die $@;
			print $DB::OUT dd( $value ), "\n";
		}

		1;
	}
	,B => sub {
		my( $args, $opts ) =  @_;
		$opts->{ verbose } //=  1;

		if( $_[0] eq '*' ) {
			#TODO: implement removing all traps
			#B 3:* - remove all traps from file number 3
		}


		my( $file, $line, $subname ) =  shift =~ m/^${file_line}|([\w:]+|&)$/;


		if( defined $subname ) {
			if( $subname eq '&' ) {
				$subname =  DB::state( 'goto_frames' )->[ -1 ][ 3 ];
				return -1   if ref $subname; # can not set trap on coderef
			}

			DB::unreg( 'call', 'breakpoint', $subname );
			# Q: Should we remove all matched keys?
			# A: No. You may remove required keys. Maybe *subname?
		}
		else {
			#FIX: this is copy/paste block. see above
			$line     =  DB::state( 'line' )   if $line eq '.';
			my $traps =  DB::traps( file( $file, 1 ) );
			return -1   unless exists $traps->{ $line };

			# TODO: remove only one action
			DB::unreg( 'trap', 'breakpoint', $file, $line );
		}


		#TODO? use &DB::process
		$DB::commands->{ b }->()   if $opts->{ verbose };

		1;
	}

	,b => sub {
		my( $sign, $file, $line, $subname, $condition, $tmp ) =
			shift =~ m/^([-+])?(?:${file_line}|([\w:]+|&))(?:\s+(.*?))?(!)?$/;


		if( defined $subname ) {
			if( $subname eq '&' ) {
				$subname =  DB::state( 'goto_frames' )->[ -1 ][ 3 ];
				return -1   if ref $subname; # can not set trap on coderef
			}

			my $data =  DB::reg( 'call', 'breakpoint' );
			$$data->{ code } =  \&stop_on_call;
			$$data->{ list } =
				{ $subname => defined $sign  &&  $sign eq '-' ? 0 : 1};

			return 1;
		}


		$line     =  DB::state( 'line' )   if $line eq '.';
		$file     =  file( $file, 1 );


		# list all breakpoints
		unless( $line ) {
			my $cmd_f =  [];
			my $file_no =  0;
			# First display traps in the current file
			print $DB::OUT "Breakpoints:\n";
			for my $source ( $file, grep { $_ ne $file } keys %$DB::_tfiles ) {
				my $traps =  DB::traps( $source );
				next   unless keys %$traps;

				push @$cmd_f, $source;
				print $DB::OUT $file_no++ ." $source\n";

				for( sort{ $a <=> $b } keys %$traps ) {
					# FIX: the trap may be in form '293 => {}' in this case
					# we do not see it ever
					# next   unless exists $traps->{ $_ }{_breakpoint}{ condition }
					# 	||  exists $traps->{ $_ }{ breakpoint }{ onetime }
					# 	||  exists $traps->{ $_ }{ breakpoint }{ disabled }
					# 	;

					printf $DB::OUT "  %-3d%s %s\n"
						,$_
						,exists $traps->{ $_ }{ onetime }      ? '!'
							:(exists $traps->{ $_ }{ breakpoint }{ disabled } ? '-' : ':')
						,$traps->{ $_ }{ breakpoint }{ condition }
						;

					warn "The breakpoint at $_ is zero and should be deleted"
						if $traps->{ $_ } == 0;
				}
			}

			DB::state( 'cmd.f', $cmd_f );

			print $DB::OUT "Stop on subs:\n";
			my $target_subs =  DB::state( 'on_call' ); #TODO: get info
			$target_subs =  $target_subs->{'breakpoint'}{ list };

			print $DB::OUT ' ' .($target_subs->{ $_ } ? ' ' : '-') ."$_\n"
				for keys %$target_subs;

			return 1;
		}


		# set breakpoint
		unless( DB::can_break( $file, $line ) ) {
			print $DB::OUT file(). " -- $file This line is not breakable\n";
			# Set breakpoint in any case. This is usefull when you edit file
			# and want to add traps to those new lines
			# return -1;
		}

		my $traps =  DB::traps( $file );

		# One time trap just exists or not.
		# We stop on it uncoditionally, also we can not disable it
		if( defined $tmp ) {
			my $data =  DB::reg( 'trap', 'onetime', $file, $line );
			$$data->{ code } =  sub{ DB::unreg( 'trap', 'onetime', $file, $line ); 1 };
		}
		else {
			my $data =  DB::reg( 'trap', 'breakpoint', $file, $line );
			$$data->{ code } =  \&stop_on_line;

			# TODO: Move trap from/into $traps into/from $disabled_traps
			# This will allow us to not trigger DB::DB if trap is disabled
			$$data->{ disabled } =  1     if $sign eq '-';
			delete $$data->{ disabled }   if $sign eq '+';

			$$data->{ condition } =  $condition   if defined $condition;
			$$data->{ condition } //=  1; # trap always triggered by default
		}

		return 1;
	}

	,go => sub {
		# If we supply line to go to we just set temporary trap there
		if( defined $_[0]  &&  $_[0] ne '' ) {
			#FIX: use &process
			return 1   if 0 > $DB::commands->{ b }->( "$_[0]!" );
		}

		$_->{ single } =  0   for @{ DB::state( 'stack' ) };

		#TODO: Implement force mode to run code until the end despite on traps

		return;
	}

	,f => sub {
		my( $args, $expr ) =  @_;

		# Set current file to selected one:
		if( $args ne ''  &&  $args =~ /^(\d+)$/ ) {
			print $DB::OUT file( $args ) ."\n";
			return 1;
		}

		# List available files
		my $cmd_f   =  [];
		my $file_no =  0;
		for( sort $0, values %INC, DB::sources() ) {
		# for( sort $0, keys %$expr ) {
			if( /(?:$args)/ ) {
				push @$cmd_f, $_;
				print $DB::OUT $file_no++ ." $_\n";
			}
		}
		DB::state( 'cmd.f', $cmd_f );

		1;
	}
	,e => sub {
		return [()
			,sub{
				if( ref $_[0] eq 'DB::Error' ) {
					print $DB::OUT "ERROR: $_[0]";
				}
				else {
					print $DB::OUT dd( @{ $_[0] } ) ."\n";
				}
				return { code => \&interact };
			}
			,length $_[0] ? shift : DB::state( 'db.last_eval' ) // ''
		];
	}


	# TODO: give names to ANON
	,T => sub {
		my( $one, $count ) =  shift =~ m/^(-?)(\d+)$/;
		$count =  -1   unless $count; # Show all frames. $count == 0 never

		my $T =  {()
			,oneline   =>
				'"\n$d $type $context $subname$args <--  $file:$line\n"'
			,multiline =>
				'"\n$d $type $subname\n    $context $args\n    <--  $file:$line\n"'
		};
		my $format =  'multiline';

		my @frames =  DB::frames();
		my $number =  -1;
		if( $one ) {
			return 1   unless @frames >= $count; # Check we have enough frames
			@frames =  $frames[ $count -1 ];     # Get only given frame
			$number =  -$count;                  # ...and display it number
		}
		for my $frame ( @frames ) {
			my $context =  $frame->[7]? '@' : defined $frame->[7]? '$' : ';';
			my $type    =  $cmd_T{ $frame->[0] };
			my $subname =  $frame->[5];
			my $args    =  $frame->[6] ? $frame->[1] : '';
			my $file    =  $frame->[3];
			my $line    =  $frame->[4];

			if( $args ) {
				$args =  join ', ', map{ defined $_ ? $_ : '&undef' } @$args;
				$args = "($args)";
			}

			my $d =  $frame->[0] eq 'D' ? 'D' : $number;
			print $DB::OUT eval $T->{ $format };
			$number--  if $frame->[0] ne 'G';
			last   unless --$count; # Stop to show frames when $count == 0
		}

		return 1;
	}

	,l    => \&list
	,w    => \&watch
	,load => \&load
	,save => \&save
	,pid  => sub {
		print $DB::OUT Devel::DebugHooks::Server::tinfo();
		return 1;
	}
	,t    => \&trace_variable
	,a    => \&action
	,A    => sub {
		my( $args, $opts ) =  @_;

		if( $_[0] eq '*' ) {
			#TODO: implement removing all actions
			#B 3:* - remove all traps from file number 3
		}


		my( $file, $line ) =  shift =~ m/^${file_line}$/;


		#FIX: this is copy/paste block. see above
		$line     =  DB::state( 'line' )   if $line eq '.';
		my $traps =  DB::traps( file( $file, 1 ) );
		return -1   unless exists $traps->{ $line };

		# TODO: remove only one action
		DB::unreg( 'trap', 'action', $file, $line );

		1;
	}
	,ge   => sub {
		my( $file, $line ) =  shift =~ m/^${file_line}$/;
		$line =  DB::state( 'line' )   unless defined $line;
		$file =  file( $file );

		`rsub $file`;

		1;
	}
	,gef   => sub {
		my( $file, $line ) =  shift =~ m/^${file_line}$/;
		$line =  DB::state( 'line' )   unless defined $line;
		$file =  file( $file );

		`rsub -f $file`;

		1;
	}
	,suspend => sub {
		uwsgi::suspend();

		1;
	}
	,R => sub {
		`killall uwsgi`;
	}
	,d => sub {
		return [()
			,sub {
				print $DB::OUT "\n@_\n";
				return { code =>  \&interact };
			}
			,"\$DB::single =  0; \$^D |= (1<<30);".DB::state( 'db.last_eval', shift )
		]
	}
};



sub process {
	my( $dbg, $str ) =  @_;

	my( $cmd, $args_str ) =  $str =~ m/^([\w.]+)(?:\s+(.*))?$/;
	$args_str //=  '';


	unless(  $cmd  &&  exists $DB::commands->{ $cmd } ) {
		print $DB::OUT "No such command: '$str'\n"   if DB::state( 'ddd' );
		return 0;
	}

	# The command also should return defined value to keep interaction
	print $DB::OUT "Start to process '$cmd' command\n"   if DB::state( 'ddd' );
	my $result =  eval { $DB::commands->{ $cmd }( $args_str ) };
	print $DB::OUT "Command '$cmd' processed\n"   if DB::state( 'ddd' );
	do{ print $DB::OUT "'$cmd' command died: $@"; return -1; }   if $@;

	return $result;
}



1;

__END__
FIX:
   x380:     if( $errors =  !$self->_check( $self->validation ) ) {                     #2
    x381:         warn [ $self->validation ];
    x382:     } elsif( $errors =  $self->_save( $self->validation ) ) {       #3
     383:     }
     384:     else {
     385:         # inside 'saved' we may return uri to redirect to
  >>x386:         $redirect_page =  $self->_saved( $self->validation );          #4-a
     387:     }

 if we 'n' from last expression of _check we do not stop on _save

FIX: do not create new trap if it not exists before 'b +...' command

FIX: терминал клинит при выводе большой русской и
