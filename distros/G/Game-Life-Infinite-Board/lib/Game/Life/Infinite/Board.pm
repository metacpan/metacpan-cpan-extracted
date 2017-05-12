#!/usr/bin/perl  

package Game::Life::Infinite::Board;  
  
use strict;  
use warnings;  
use Time::HiRes;
require 5.10.1;

BEGIN {
    use Exporter   ();
    use vars       qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = sprintf( "%d.%02d", q($Revision: 0.07 $) =~ /\s(\d+)\.(\d+)/ );
    @ISA         = qw(Exporter);
    @EXPORT_OK   = qw(format_is);
    %EXPORT_TAGS = ( );
}

sub new {
	my ( $class, $rulesRef, @args ) = @_;  
	my $self = {};  
	$self->{'maxx'} = $self->{'maxy'} = $self->{'minx'} = $self->{'miny'} = 0;	# Board boundaries.
	$self->{'gen'} = $self->{'liveCells'} = $self->{'usedCells'} = 0; 
	$self->{'delta'} = -1;	# Number of cells that changed state since previous epoch (newborns+dead).
	$self->{'factor2'} = 1;
	$self->{'oscilator'} = 0; 		# If oscilator is detected, contains the period.
	$self->{'cells'} = {};
	$self->{'currentFn'} = 'Untitled.cells';
	$self->{'name'} = 'Untitled';
	$self->{'totalTime'} = 0;
	$self->{'osccheck'} = 0;
	$self->{'color'} = 0;
	# Check for rules:
	&setRules($self, $rulesRef);
	&updateCell($self, 0, 0, 0);	# Create first cell in 0,0 coordinates.
	bless $self, $class;  
	return $self;  
};

sub setRules {
	my ( $self, $rulesRef) = @_;
	my ($breedRef, $liveRef) = (ref($rulesRef) eq "ARRAY") ? ($rulesRef->[0], $rulesRef->[1]) : ([3], [2,3]);
	if ($self->{'color'} > 0) {
		# Force standard rules in colourised board.
		($breedRef, $liveRef) = ([3], [2,3]);
	};
	$self->{'breedRules'} = (ref($breedRef) eq "ARRAY") ? $breedRef : [];
	$self->{'liveRules'} = (ref($liveRef) eq "ARRAY") ? $liveRef : [];
	return;
};

sub setColor {
	my ($self, $color) = @_;
	$color = (defined $color) ? $color : ''; 
	if ($self->{'gen'} > 0) {return;};
	if (lc($color) eq 'immigration') {
		$self->{'color'} = 1;
		# Reset rules to standard:
		&setRules($self, undef);
		return 1;
	} elsif (lc($color) eq 'quadlife') {
		$self->{'color'} = 2;
		# Reset rules to standard:
		&setRules($self, undef);
		return 2;
	} elsif (lc($color) eq 'normal') {
		$self->{'color'} = 0;
		return 0;
	} else {
		return;
	};
};

sub getColor {
	my $self = shift;
	return $self->{'color'};
};

sub updateCell {
	# Update the state of a cell. If non-existing, create it.
	my ( $self, $xpos, $ypos, $state ) = @_;
	defined ($self->{'cells'}->{$xpos, $ypos}) or &createCell($self, $xpos, $ypos);
	if (($self->{'cells'}->{$xpos, $ypos}->{'state'}) and (not $state)) {
		my $oldstate = $self->{'cells'}->{$xpos, $ypos}->{'state'};
		--$self->{'liveCells'};
		# Update neighbours counts:
		foreach my $xx ($xpos-1 .. $xpos+1) {
			foreach my $yy ($ypos-1 .. $ypos+1) {
				if (($xx == $xpos) and ($yy == $ypos)) {
					next;
				};
				if (defined ($self->{'cells'}->{$xx, $yy})) {
					--$self->{'cells'}->{$xx, $yy}->{'neighbours'}->{$oldstate};
					--$self->{'cells'}->{$xx, $yy}->{'neighbours'}->{'total'};
				} else {
					#&createCell($self, $xx, $yy);
				};
			};
		};
	};
	if ((not $self->{'cells'}->{$xpos, $ypos}->{'state'}) and ($state)) {
		# Check validity:
		if (
			(($state > 1) and ($self->{'color'} < 1)) or
			(($state > 2) and ($self->{'color'} < 2)) or
			($state > 4) or
			($state < 0)
		) {
			# Invalid state for current color.
			return -1;
		};
		++$self->{'liveCells'};
		# Update neighbours counts:
		foreach my $xx ($xpos-1 .. $xpos+1) {
			foreach my $yy ($ypos-1 .. $ypos+1) {
				if (($xx == $xpos) and ($yy == $ypos)) {
					next;
				};
				if (defined ($self->{'cells'}->{$xx, $yy})) {
					++$self->{'cells'}->{$xx, $yy}->{'neighbours'}->{$state};
					++$self->{'cells'}->{$xx, $yy}->{'neighbours'}->{'total'};
				} else {
					&createCell($self, $xx, $yy);
					++$self->{'cells'}->{$xx, $yy}->{'neighbours'}->{$state};
					++$self->{'cells'}->{$xx, $yy}->{'neighbours'}->{'total'};
				};
			};
		};
	};
	$self->{'cells'}->{$xpos, $ypos}->{'state'} = $state;
	return;
};

sub queryCell {
	# Return the state of a cell:
	my ( $self, $xpos, $ypos ) = @_;
	if (defined $self->{'cells'}->{$xpos, $ypos}) {
		return $self->{'cells'}->{$xpos, $ypos}->{'state'};
	} else {
		return;
	};
};

sub createCell {
	# Create an empty cell.
	my ($self, $xpos, $ypos, @rest) = @_;
	$self->{'cells'}->{$xpos, $ypos}->{'state'} = 0;
	$self->{'cells'}->{$xpos, $ypos}->{'neighbours'}->{1} = 0;
	$self->{'cells'}->{$xpos, $ypos}->{'neighbours'}->{2} = 0;
	$self->{'cells'}->{$xpos, $ypos}->{'neighbours'}->{3} = 0;
	$self->{'cells'}->{$xpos, $ypos}->{'neighbours'}->{4} = 0;
	$self->{'cells'}->{$xpos, $ypos}->{'neighbours'}->{'total'} = 0;
	# Update boundaries:
	$self->{'maxx'} < $xpos and $self->{'maxx'} = $xpos;
	$self->{'minx'} > $xpos and $self->{'minx'} = $xpos;
	$self->{'maxy'} < $ypos and $self->{'maxy'} = $ypos;
	$self->{'miny'} > $ypos and $self->{'miny'} = $ypos;
	++$self->{'usedCells'};
	return;
};

sub loadInit {
	# Load an initial grid from a file.
	my ($self, $fn, @rest) = @_;
	my $untitled = 'Untitled.cells';
	if (not defined $fn) { return $untitled; };
	my @array;
	open(my $fh,"<:crlf", $fn) or die "Failed to open $fn: $!";
	while (<$fh>) { push @array, $_; };
	close $fh;
	my $ftype = &format_is(\@array);
	my $loadok;
	if (not defined $ftype) {
		print "DEBUG: File format could not be detected.\n";
		return $untitled;
	}; 
	if ($ftype->{'format'} eq 'CELLS') {
		$loadok = $self->loadCells(\@array);
		print "DEBUG: Loaded CELLS\n";
	} elsif ($ftype->{'format'} eq 'RLE') {
		$loadok = $self->loadRLE(\@array);
		print "DEBUG: Loaded RLE\n";
	} elsif (($ftype->{'format'} eq 'Life') and ($ftype->{'version'} eq '1.05')) {
		$loadok = $self->loadL105(\@array);
		print "DEBUG: Loaded Life 1.05\n";
	} elsif (($ftype->{'format'} eq 'Life') and ($ftype->{'version'} eq '1.06')) {
		$loadok = $self->loadL106(\@array);
		print "DEBUG: Loaded Life 1.06\n";
	} else {
		print "DEBUG: " . $ftype->{'format'} . " V. " . $ftype->{'version'} . " not supported yet.\n";
		return $untitled;
	};
	if (not $loadok) {
		print "DEBUG: Load failed!\n";
		return $untitled;
	} else {
		$self->{'currentFn'} = $fn;
		return $fn;
	};
};

sub saveGridTxt {
	# Save a grid to a txt file.
	my ($self, $fn, @rest) = @_;
	if (not defined $fn) { return; };
	my $output;
	open($output, ">", $fn) or die "cannot open $fn: $!\n";
	for (my $yy = $self->{'miny'}; $yy <= $self->{'maxy'}; $yy++) {
		foreach my $xx ($self->{'minx'} .. $self->{'maxx'}) {
			if (defined ($self->{'cells'}->{$xx, $yy})) {
				if ($self->{'cells'}->{$xx, $yy}->{'state'} == 1) {
					print $output 'O';
				} elsif ($self->{'cells'}->{$xx, $yy}->{'state'} > 1) {
					print $output $self->{'cells'}->{$xx, $yy}->{'state'};
				} else {
					print $output '.';
				};
			} else {
				print $output '.';
			};
		};
		print $output "\n";
	};
	close $output;
	return $fn;
};


sub crudePrintBoard {
	# Basic board print.
	my $self = shift;
	for (1 .. 80) {
		print "-";
	};
	print "\n";
	for (my $yy = $self->{'miny'}; $yy <= $self->{'maxy'}; $yy++) {
		foreach my $xx ($self->{'minx'} .. $self->{'maxx'}) {
			if (defined ($self->{'cells'}->{$xx, $yy})) {
				if ($self->{'cells'}->{$xx, $yy}->{'state'} == 1) {
					print 'O';
				} elsif ($self->{'cells'}->{$xx, $yy}->{'state'} > 1) {
					print $self->{'cells'}->{$xx, $yy}->{'state'};
				} else {
					print '_';
				};
			} else {
				print '.';
			};
		};
		print "\n";
	};
	my $stats = &statistics($self);
	print "---\tGeneration: " . $stats->{'generation'} . " x: " . $stats->{'minx'} . ".." . $stats->{'maxx'} . " y: " . $stats->{'miny'} . ".." . $stats->{'maxy'} . " Size: $stats->{'size'} LiveCells: " . $stats->{'liveCells'} . "\n"; 
	print "\tDelta: " . $stats->{'delta'} . "\n";
	return;
};

sub tick {
	# Calculate next epoch.
	my ($self, $oscCheck) = @_;
	my $t0 = [Time::HiRes::gettimeofday()];
	$oscCheck = &setOscCheck($self, $oscCheck); 

	my $resref = &tickMainLoop($self);
	my @newCells = @{$resref->{'newCells'}};
	my @dieCells = @{$resref->{'dieCells'}};
	my @delCells = @{$resref->{'delCells'}};
	#use Data::Dumper;
	$self->{'delta'} = scalar(@newCells) + scalar(@dieCells);
	# Apply changes on board:
	foreach my $rec (@newCells) {
		# TODO: Do something in case of error?
		my $error = &updateCell($self, $rec->[0], $rec->[1], $rec->[2]);
		$error = (defined $error) ? $error : 0;
	};
	foreach my $rec (@dieCells) {
		my $error = &updateCell($self, $rec->[0], $rec->[1], 0);
	};
	foreach my $rec (@delCells) {
		# Verify that these cells are still without neighbours:
		if ($self->{'cells'}->{$rec->[0], $rec->[1]}->{'neighbours'}->{'total'} == 0) {
			delete $self->{'cells'}->{$rec->[0], $rec->[1]};	
			--$self->{'usedCells'};
		};
	};
	$self->{'gen'} = $self->{'gen'} + 1;
	$self->{'factor2'} = ((defined $self->{'usedCells'}) and ($self->{'usedCells'} > 0)) ? $self->{'liveCells'} / $self->{'usedCells'} : 1;
	if ($oscCheck > 1) { &oscCheck($self, $oscCheck); };
  	my $t1 = [Time::HiRes::gettimeofday];
  	my $t0_t1 = Time::HiRes::tv_interval( $t0, $t1 );
	$self->{'lastTI'} = $t0_t1;	# Time spend to calculate last epoch.
	$self->{'totalTime'} += $t0_t1;	# Total Time spend calculating this board.
	return;
};

sub tickMainLoop {
	# TODO: Return new cell's color if board is immigration or quadlife.
	my ($self) = @_;
	my @newCells;
	my @dieCells;
	my @delCells;
	foreach my $key (keys %{ $self->{'cells'} }) {
		my ($xx, $yy) = split(/$;/, $key, 2);
		my $rec = [$xx, $yy];
		if (
			($self->{'cells'}->{$xx, $yy}->{'state'} > 0) and 
			(not $self->{'cells'}->{$xx, $yy}->{'neighbours'}->{'total'} ~~ $self->{'liveRules'})
		) {
			# Die.
			push @dieCells, $rec;
		} elsif (
			($self->{'cells'}->{$xx, $yy}->{'state'} == 0) and 
			($self->{'cells'}->{$xx, $yy}->{'neighbours'}->{'total'} ~~ $self->{'breedRules'})
		) {
			# New.
			if ($self->{'color'} == 0) {
				# Standard
				$rec->[2] = 1;
				push @newCells, $rec;
			} else {
				# Colorized
				#use Data::Dumper;
				my @colorcounts = ();
				my $ccnt = 0;
				foreach my $state (keys %{ $self->{'cells'}->{$xx, $yy}->{'neighbours'} }) {
					if ($state ne 'total') {
						if ($self->{'cells'}->{$xx, $yy}->{'neighbours'}->{$state} > 0) {
							$colorcounts[$state] = $self->{'cells'}->{$xx, $yy}->{'neighbours'}->{$state};
							$ccnt++;
						};
					};
				};
				if ($ccnt == 2) {
					# Immigration, or first rule of Quadlife (Identical).
					# Select maximum.
					my $max = -1;
					for my $i (1..4) {
						if (defined $colorcounts[$i]) {
							if ($colorcounts[$i] > $max) { 
								$max = $colorcounts[$i];
								$rec->[2] = $i 
							};
						};
					};
				} elsif ($ccnt == 3) {
					# Second rule of Quadlife
					for my $i (1..4) {
						if (not defined $colorcounts[$i]) {
							$rec->[2] = $i;
							last;
						};
					};
				} elsif ($ccnt == 1) {
					# Same color as parents:
					for my $i (1..4) {
						if (defined $colorcounts[$i]) {
							$rec->[2] = $i;
							last;
						};
					};
				} else {
					# Unsupported or standard. Return first color.
					$rec->[2] = 1;
				};
				push @newCells, $rec;
			};
		} elsif (
			($self->{'cells'}->{$xx, $yy}->{'state'} == 0) and 
			($self->{'cells'}->{$xx, $yy}->{'neighbours'}->{'total'} == 0)
		) {
			# Isolated empty cell. GC.
			push @delCells, $rec;
		};
	};
	return {'newCells' => \@newCells, 'dieCells' => \@dieCells, 'delCells' => \@delCells};
};

sub setOscCheck {
	my ($self, $oscCheck) = @_;

	$oscCheck = (defined $oscCheck) ? $oscCheck : 0;
	if ($oscCheck != $self->{'osccheck'}) {
		# Change, delete all previous snapshots:
		delete $self->{'snapshots'};
	};
	$self->{'osccheck'} = $oscCheck;
	return $oscCheck;
};

sub oscCheck {
	my ($self, $oscCheck) = @_;
	my $lgen = $self->{'gen'};
	my $lgenString = sprintf("s%d", $lgen);
	my $ogen;
	my $ogenString;
	$self->{'snapshots'}->{$lgenString} = &snapshot($self);	# Smile!
	for (my $i = 2; $i <= $oscCheck; $i++) {
		$ogen = $lgen - $i;
		$ogenString = sprintf("s%d", $ogen);
		if (defined ($self->{'snapshots'}->{$ogenString})) {
			# Snapshot of grandma!
			if (
				($self->{'snapshots'}->{$ogenString}->{'snapshot'} eq $self->{'snapshots'}->{$lgenString}->{'snapshot'}) and
				($self->{'snapshots'}->{$ogenString}->{'minx'} == $self->{'snapshots'}->{$lgenString}->{'minx'}) and
				($self->{'snapshots'}->{$ogenString}->{'maxx'} == $self->{'snapshots'}->{$lgenString}->{'maxx'}) and
				($self->{'snapshots'}->{$ogenString}->{'miny'} == $self->{'snapshots'}->{$lgenString}->{'miny'}) and
				($self->{'snapshots'}->{$ogenString}->{'maxy'} == $self->{'snapshots'}->{$lgenString}->{'maxy'})
			) {
				# Grandma and grandson are identical!
				$self->{'oscilator'} = $i;
				last;
			} else {
				$self->{'oscilator'} = 0;
			};
		};
	};
	# Delete oldest snapshot.
	delete $self->{'snapshots'}->{$ogenString};
	return;
};

sub snapshot {
	# Take a snapshot of the board, in a way that it can be easily stored and compared 
	# to another snapshot.
	my $self = shift;
	my $snapshot = '';
	for (my $yy = $self->{'miny'}; $yy <= $self->{'maxy'}; $yy++) {
		foreach my $xx ($self->{'minx'} .. $self->{'maxx'}) {
			if (defined ($self->{'cells'}->{$xx, $yy})) {
				if ($self->{'cells'}->{$xx, $yy}->{'state'} == 1) {
					$snapshot .= 'O';
				} elsif ($self->{'cells'}->{$xx, $yy}->{'state'} > 1) {
					$snapshot .= $self->{'cells'}->{$xx, $yy}->{'state'};
				} else {
					$snapshot .= '.';
				};
			} else {
				$snapshot .= '.';
			};
		};
		$snapshot .= "\n";
	};
	return {
		'snapshot'	=> $snapshot,
		'minx'		=> $self->{'minx'},
		'maxx'		=> $self->{'maxx'},
		'miny'		=> $self->{'miny'},
		'maxy'		=> $self->{'maxy'},
	};
};

sub shrinkBoard {
	# Shrink board: Now mostly used to keep boundaries track, for printing and snapshot.
	my $self = shift;
	$self->{'minx'} = $self->{'maxx'} = $self->{'miny'} = $self->{'maxy'} = 0;
	my $ok = 0;
	foreach my $key (keys %{ $self->{'cells'} }) {
		my ($xx, $yy) = split(/$;/, $key, 2);
		if (($self->{'cells'}->{$xx, $yy}->{'state'} == 0) and ($self->{'cells'}->{$xx, $yy}->{'neighbours'}->{'total'} == 0)) {
			delete $self->{'cells'}->{$key};	
			--$self->{'usedCells'};
		} else {
			if ($ok) {
				if ($xx > $self->{'maxx'}) { $self->{'maxx'} = $xx; };
				if ($xx < $self->{'minx'}) { $self->{'minx'} = $xx; };
				if ($yy > $self->{'maxy'}) { $self->{'maxy'} = $yy; };
				if ($yy < $self->{'miny'}) { $self->{'miny'} = $yy; };
			} else {
				$self->{'minx'} = $xx;
				$self->{'maxx'} = $xx; 
				$self->{'miny'} = $yy; 
				$self->{'maxy'} = $yy;
				$ok = 1;
			};
		};
	};
	return;
};

sub statistics {
	my $self = shift;
	return {
		'size'		=> (($self->{'maxx'} - $self->{'minx'}) * ($self->{'maxy'} - $self->{'miny'})),
		'generation'	=> $self->{'gen'},
		'minx'		=> $self->{'minx'},
		'maxx'		=> $self->{'maxx'},
		'miny'		=> $self->{'miny'},
		'maxy'		=> $self->{'maxy'},
		'liveCells'	=> $self->{'liveCells'},
		'delta'		=> $self->{'delta'},
		'oscilator'	=> $self->{'oscilator'},
		'totalTime'	=> $self->{'totalTime'},
		'usedCells'	=> $self->{'usedCells'},
		'factor2'	=> $self->{'factor2'},
		'lastTI'	=> $self->{'lastTI'},
	};
};

sub format_is {
	my ($faref) = @_;	# Array ref containing file.
	my %result = (
		format	=> undef,
		version	=> undef
	);
	foreach my $line (@{ $faref }) {
		chomp($line);
		if (($line =~ /^#Life 1.05/) or ($line =~ /^#Life 1.06/) or ($line =~ /^#MCell/)) {
			($result{format}, $result{version}) = split / /, $line, 2;
			$result{format} =~ s/#//;
			return \%result;
		} elsif ($line =~ /^(b|o|[[:digit:]])/) {
			($result{format}, $result{version}) = ('RLE', 'N/A'); 
			return \%result;
		} elsif ($line =~ /^(\.|O|!)/) {
			($result{format}, $result{version}) = ('CELLS', 'N/A'); 
			return \%result;
		} elsif ($line =~ /^(\.|O|2|3|4|!)/) {
			($result{format}, $result{version}) = ('CELLS', 'N/A'); 
			return \%result;
		};
	};
	return undef;
};

sub loadL106 {
	# Load an initial grid from an array containing 
	# a file in Life 1.06 format.
	my ($self, $array, @rest) = @_;
	if (not defined $array) { return undef; };
	foreach my $input (@{ $array }) {
		chomp($input);
		$input =~ s/^\s*(.*?)\s*$/$1/;
		if ($input eq '') { next; };
		if ($input =~ /^#Life 1.06/) { next; };
		# Not much checks here. Assume that data are numbers.
		my ($xx, $yy) = split / /, $input, 2;
		$xx += 0;
		$yy += 0;
		$self->updateCell($xx, $yy, 1);
	};
	$self->{'name'} = '#Life 1.06 file'; # :-)
	return 1;
};


sub loadL105 {
	# Load an initial grid from an array containing 
	# a file in Life 1.05 format.
	my ($self, $array, @rest) = @_;
	if (not defined $array) { return undef; };
	my $posState = 0;
	my $name = 'Untitled';
	my $rules = '';
	my $dataline = '';
	my @descrArr = (); 
	my $ulcx = my $ulcy = 0; # Upper left corner
	my $dlinecnt = 0;
	foreach my $input (@{ $array }) {
		chomp($input);
		if ($input eq '') { next; };
		if ($input =~ /^#Life 1.05/) {
			next;
		} elsif ($input =~ /^#D Name: /) {
			# Out of spec, but it seems that it's used:
			(undef, undef, $name) = split /(^#D Name: )/, $input, 3;
			next;
		} elsif ($input =~ /^#D /) {
			if ($dlinecnt >= 22) { return undef }; # Specs.
			my (undef, undef, $dline) = split /(^#D )/, $input, 3;
			$dline =~ s/^\s*(.*?)\s*$/$1/;
			if (length($dline) > 78) {
				print "DEBUG ERROR: D-line too long\n";
				return undef; # Specs.
			} else {
				push @descrArr, $dline;
			};
			$dlinecnt++;
		} elsif ($input =~ /^#N/) {
			next;
		} elsif ($input =~ /^#R /) {
			# Rules.
			(undef, undef, $rules) = split /(^#R )/, $input, 3;
			my ($sstr, $bstr) = split /\//, $rules, 2;

			my $barr = [];
			my $sarr = [];
			for (my $i = 0; $i < length($bstr); $i++) {
				if (substr($bstr, $i, 1) =~ /[0-8]/) {
					push @{ $barr }, substr($bstr, $i, 1); 
				} else {
					# Fail. Specs.
					print "DEBUG ERROR: wrong rules\n";
					return undef;
				};
			};
			for (my $i = 0; $i < length($sstr); $i++) {
				if (substr($sstr, $i, 1) =~ /[0-8]/) {
					push @{ $sarr }, substr($sstr, $i, 1); 
				} else {
					# Fail. Specs.
					print "DEBUG ERROR: wrong rules\n";
					return undef;
				};
			};
			$self->setRules([$barr, $sarr]);
		} elsif ($input =~ /^#P /) {
			(undef, $ulcx, $ulcy) = split / /, $input, 3;
			$ulcx += 0;
			$ulcy += 0;
			$posState = 1;
		} elsif (
			($input =~/^(\.|\*)/) and 
			($posState == 1)
		) {
			# Data line:
			#print "DEBUG: DL: $input\n";
			my $xx = $ulcx;
			my $yy = $ulcy;
			while (length($input) > 0) {
				my $char = substr($input, 0, 1);
				$input = substr($input, 1);
				if ($char eq '*') {
					#print "\tDEBUG: LIVE ($xx,$yy)\n";
					$self->updateCell($xx, $yy, 1);
					$xx++;
				} elsif ($char eq '.') {
					$xx++;
				} else {
					# Fail.
					print "DEBUG ERROR: unknown char\n";
					return undef;
				};
			};
			$ulcy++;
		} else {
			# Unrecognized input:
			print "DEBUG ERROR: unknown input:\n\t|$input|\n";
			return undef;
		};
	};
	$self->{'description'} = \@descrArr;
	$self->{'name'} = $name;
	return 1;
};


sub loadRLE {
	# Load an initial grid from an array containing 
	# a file in RLE format.
	my ($self, $array, @rest) = @_;
	if (not defined $array) { return undef; };
	my $posState = 0;
	my $name = 'Untitled';
	my $headRules = my $rules = '';
	my $dataline = '';
	my $ulcx = my $ulcy = 0; # Upper left corner
	foreach my $input (@{ $array }) {
		chomp($input);
		if ($input =~ /^#N /) {
			(undef, undef, $name) = split /(^#N )/, $input, 3;
			next;
		} elsif ($input =~ /^#r /) {
			# Rules:
			(undef, undef, $headRules) = split /(^#r )/, $input, 3;
			next;
		} elsif (($input =~ /^#P /) or ($input =~ /^#R /)) {
			(undef, $ulcx, $ulcy) = split / /, $input, 3;
			next;
		} elsif ($input =~ /^#/) {
			# Ignore all other # lines:
			next;
		} elsif ($input =~ /^x/) {
			# Header line. 
			$input =~ s/ //g;
			my ($xc, $yc);
			($xc, $yc, $rules) = split /,/ , $input;
			if ((not ($xc =~ /x=/)) or (not ($yc =~ /y=/))) {
				# Fail.
				return undef;
			};
			$posState = 1;
			next;
		} else {
			# Normal line:
			if (not $posState) {
				# No header?
				return undef;
			};
			# Join in one big string:
			$dataline .= $input;
			next;
		};
	};
	# Now parse actual data:
	my @dataArr = split /\$/, $dataline;
	my %extraStates = ();
	my $extraStatesCnt = 0;
	my $xx = $ulcx;
	my $yy = $ulcy;
	#print "DEBUG: " . scalar(@dataArr) . " lines\n";
REC:	foreach my $rec (@dataArr) {
		#print "DEBUG: RLE REC: \n\t$rec\n";
		#print "\tLINE: $yy\n";
		my $cntstr = '0';
	CHAR:	while (length($rec) > 0) {
			my $char = substr($rec, 0, 1);
			$rec = substr($rec, 1);
			if ($char =~ /\d/) {
				$cntstr .= $char;
				next CHAR;
			} elsif ($char eq 'o') {
				my $cnt = ($cntstr eq '0') ? 1 : $cntstr + 0;
				$cntstr = '0'; # Reset.
				for (my $i = 0; $i < $cnt; $i++) {
					$self->updateCell($xx++, $yy, 1);
				};
			} elsif ($char eq 'b') {
				my $cnt = ($cntstr eq '0') ? 1 : $cntstr + 0;
				$cntstr = '0'; # Reset.
				$xx += $cnt;
			} elsif ($char eq '!') {
				# No more! 
				last REC;
			} else {
				# Handle unknown characters as extra states. Good luck with that.
				# We will handle a max of 3 extra states (Immigration/Quadlife).
				my $cnt = ($cntstr eq '0') ? 1 : $cntstr + 0;
				if (defined $extraStates{$char}) {
					for (my $i = 0; $i < $cnt; $i++) {
						$self->updateCell($xx++, $yy, $extraStates{$char});
					};
				} else {
					# New state 
					$extraStatesCnt++;
					if ($extraStatesCnt > 3) {
						# Fail.
						return undef;
					} else {
						$extraStates{$char} = $extraStatesCnt+1;
					};
					if ($extraStatesCnt == 1) {
						$self->setColor('immigration') or die "Failed to set color on load!\n";
					} elsif ($extraStatesCnt > 1) {
						$self->setColor('quadlife') or die "Failed to set color on load!\n";
					};
					for (my $i = 0; $i < $cnt; $i++) {
						$self->updateCell($xx++, $yy, $extraStates{$char});
					};
				};
			};
		};
		# If there are digits left, they are empty lines.
		my $cnt = ($cntstr eq '0') ? 1 : $cntstr + 0;
		$cntstr = '0'; # Reset.
		$yy += $cnt;	# Next line or skip lines.
		$xx = $ulcx;	# Reset
	};
	$self->{'name'} = $name;
	if ($extraStatesCnt > 1) {
		$self->setColor('quadlife') or die "Failed to set color on load!\n";
		#print "DEBUG: RLE: Quadlife\n";
	} elsif ($extraStatesCnt == 1) {
		$self->setColor('immigration') or die "Failed to set color on load!\n";
		#print "DEBUG: RLE: Immigration\n";
	};
	# Handle rules:
	my $bstr = my $sstr = '';
	if ($rules ne '') {
		# Rules in header line have priority over comment line rules:
		(undef, $rules) = split /=/, $rules, 2;
		($bstr, $sstr) = split /\//, $rules, 2;
	} elsif ($headRules ne '') {
		my ($sstr, $bstr) = split /\//, $headRules, 2;
	};
	if (($rules ne '') or ($headRules ne '')) {
		my $barr = [];
		my $sarr = [];
		for (my $i = 0; $i < length($bstr); $i++) {
			if (substr($bstr, $i, 1) =~ /\d/) { push @{ $barr }, substr($bstr, $i, 1); };
		};
		for (my $i = 0; $i < length($sstr); $i++) {
			if (substr($sstr, $i, 1) =~ /\d/) { push @{ $sarr }, substr($sstr, $i, 1); };
		};
		$self->setRules([$barr, $sarr]);
	};
	return 1;
};

sub loadCells {
	# Load an initial grid from an array containing 
	# a file in cells (ASCII) format.
	my ($self, $array, @rest) = @_;
	if (not defined $array) { return undef; };
	my $name = 'Untitled';
	my @descrArr = (); 
	my $xx = my $yy = my $cnt = 0;
	my $immigration = my $quadlife = 0;
	#my $input;
	#open($input, "<", $fn) or die "cannot open $input: $!\n";
	#while (<$input>) {
	foreach my $input (@{ $array }) {
		chomp($input);
		if ($input =~ /^!Name: /) {
			(undef, undef, $name) = split /(^!Name: )/, $input, 3;
			next;
		} elsif ($input =~ /^!/) {
			push @descrArr, $input;
			next;
		};
		for ($yy = 0; $yy <= length($input); $yy++) {
			if (substr($input, $yy, 1) eq 'O') {
				$self->updateCell($yy, $xx, 1);
				$cnt++;
			} elsif (substr($input, $yy, 1) eq '2') {
				$self->setColor('immigration') or die "Failed to set color on load!\n";
				$self->updateCell($yy, $xx, 2);
				$immigration = 1;
				$cnt++;
			} elsif (substr($input, $yy, 1) eq '3') {
				$self->setColor('quadlife') or die "Failed to set color on load!\n";
				$self->updateCell($yy, $xx, 3);
				$quadlife = 1;
				$cnt++;
			} elsif (substr($input, $yy, 1) eq '4') {
				$self->setColor('quadlife') or die "Failed to set color on load!\n";
				$self->updateCell($yy, $xx, 4);
				$quadlife = 1;
				$cnt++;
			};
		};
		$xx++;
	};
	$self->{'name'} = $name;
	$self->{'description'} = \@descrArr;
	# Finalize board colour:
	if ($quadlife) {
		$self->setColor('quadlife') or die "Failed to set color on load!\n";
	} elsif ($immigration) {
		$self->setColor('immigration') or die "Failed to set color on load!\n";
	};
	return 1;
};

42;

__END__
=pod 

=head1 NAME
    
Game::Life::Infinite::Board - An infinite board for Conway's Game of Life. 

=head1 SYNOPSIS

	use Game::Life::Infinite::Board;
	my $oscCheck = 2; 
	my $board = Game::Life::Infinite::Board->new();
	$board->loadInit($filename);
	$board->crudePrintBoard();
	for (1..10000) {
		$board->tick($oscCheck);
		my $stats = $board->statistics;
		if ($stats->{'liveCells'} == 0) {
			print "--- ALL CELLS DIED! --- \n";
			exit;
		};
		if ($stats->{'delta'} == 0) {
			$board->shrinkBoard; 
			$board->crudePrintBoard();
			print "--- STATIC! --- \n";
			exit;
		};
		if ($stats->{'oscilator'} > 1) {
			$board->shrinkBoard;
			$board->crudePrintBoard();
			print "--- OSCILATOR " . $stats->{'oscilator'} . " --- \n";
			$board->tick($oscCheck);
			$board->shrinkBoard;
			$board->crudePrintBoard();
			exit;
		};
	};

=head1 DESCRIPTION

This module implements the well known Conway's Game of Life in Perl.
Points of interest:

=over

=item *
Infinite grid (no "fell over" or "warp").

=item *
Oscilator detection

=item *
Rules as parameter

=item *
Simple load, save and print

=item *
Colourised life support (Immigration, Quadlife)

=back

=head1 METHODS

=head2 C<new>

C<< my $board = Game::Life::Infinite::Board->new($rules); >>

Initializes a new board. I<$rules> is a reference to an array of arrays, containing the rules that will be used to calculate the next generation. Example:

C<my $rules = [[3,4,5], [1,2,7]];>

First array sets the number of neighbours required for a live cell to survive. Second array sets the number of neighbours required for a new cell to be born. If not defined, the standard rules (C<[[3], [2,3]]>) will be used.

=head2 C<setRules>

C<< $board->setRules($rules); >>

Change the rules on an existing board.

=head2 C<updateCell>

C<< $board->updateCell($x,$y,$state); >>

Set the state of the cell with coordinates $x,$y to $state, where $state can be 0 (dead) or 1..4 (alive). Standard rules board (not colored) can only use 1 for alive cell. Immigration board can only use 1 or 2. 

=head2 C<loadInit>

C<< $board->loadInit($filename) >>

Detects file format and loads a formation from a text file. Uses the function L</&format_is> to detect the file format and if a known format is successfully detected, uses the corresponding method (see below) to load the file. For now (0.06) only .cells and .rle format are supported.

=head2 C<loadCells>

C<< $board->loadCells($file_array_ref) >>

Loads an initial grid from an array containing a file in cells (ASCII) format. Live cells are marked with 'O' (upper case o). If the character '2' is found, is used as a second color and board color is set to 'Immigration'. If characters '3' and/or '4' are found, they are used as a third and fourth color and board color is set to 'Quadlife'. All other characters are interpreted as dead cells. The standard .cells files can be loaded this way. Name (line starting with '!Name:') is stored in 'name' attribute. All other lines starting with '!' are stored as an array ref in 'description' attribute (see L</ATTRIBUTES>). 

=head2 C<loadRLE>

C<< $board->loadRLE($file_array_ref) >>

Loads an initial grid from an array containing a file in rle (run length encoded) format. The standard tags (b, o, $) are supported. The 3 first unknown tags found are used as extra cell states and the board color is set to 'Immigration' (one extra state) or 'Quadlife' (two or three extra states). If more unknown tags are found, the file fails to load. Any rules string found in either header line or #r line is honored. #P or #R (upper left corner coordinates) lines are parsed and used. If not found, upper left corner is set to (0,0). Name (#N) is stored in the 'name' attribute (see L</ATTRIBUTES>). For more information about rle format see L<http://www.conwaylife.com/wiki/Run_Length_Encoded>. 

=head2 C<loadL105>

C<< $board->loadL105($file_array_ref) >>

Loads an initial grid from an array containing a file in Life 1.05 format as described in L<http://www.conwaylife.com/wiki/Life_1.05>. If found, a comment line (#D) containing the string "Name:" is used to fill the 'name' attribute. Color is not supported in this format. 

=head2 C<loadL106>

C<< $board->loadL106($file_array_ref) >>

Loads an initial grid from an array containing a file in Life 1.06 format as described in L<http://www.conwaylife.com/wiki/Life_1.06>. Color is not supported in this format.

=head2 C<saveGridTxt>

C<< $board->saveGridTxt($filename) >>

Saves the current board formation as text, using 'O' for live cells and '.' for dead cells. '2', '3' and '4' are used for extra colors. The resulting file can be loaded using loadInit.

=head2 C<crudePrintBoard>

C<< $board->crudePrintBoard; >>

Prints the board with 'O' for live cells and '.' for dead cells, plus some information about the current state of the board. If the board is an Immigration or Quadlife board, characters '2', '3' and '4' are used for the extra colors.

=head2 C<tick>

C<< $board->tick($oscCheck); >>

Applies the rules once and transforms the board to the next generation. If $oscCheck is defined and is greater than one, then a history of the board $oscCheck generations long is kept and used to detect oscilating populations with period less or equal than $oscCheck. This detection process can be very CPU time and memory consuming for larger populations, so the whole process is disabled when $oscCheck is less than 2.

=head2 C<shrinkBoard>

C<< $board->shrinkBoard; >>

Shrinks the board by deleting cell entries from the internal grid data structure (which saves memory and speeds up processing) and adjusting minx, maxx, miny, maxy attributes, which speeds up oscilator detection and printing and keeps the file saved by saveGridTxt smaller. Since v. 0.04, dead cells are deleted anyway in each tick so there is no need to call shrinkBoard for speed reasons. shrinkBoard is now usefull when there is need for the boundaries to be adjusted. 

=head2 C<setColor>

C<< $board->setColor($color); >>

Defines the use of color. $color can be one of 'Immigration', 'Quadlife' or 'Normal'. Color cannot be changed if the board is older that generation zero. Failure (unknown color or generation > 0) returns undef. Default color setting is 'Normal'. See L<http://www.conwaylife.com/wiki/Colourised_life> for details.
The rules of colourised life assume the standard rules for breeding and dying. Using a colourised board with non-standard rules is not yet supported. Loading a colourised formation will reset the board rules to standard. Trying to set non-standard rules on a colorised board will fail.

=head1 ACCESSORS

=head2 C<getColor>

C<< my $color = $board->getColor(); >>

Returns the color of the board (see setColor above).

=head2 C<queryCell>

C<< my $result = $board->queryCell($x,$y); >>

Returns the state of the cell with coordinates $x,$y.

=head2 C<statistics>

C<< my $stats = $board->statistics; >>

Returns a reference to a hash containing statistics about the current grid. The attributes included are:

=over

=item C<minx, maxx, miny, maxy>

The boundaries of the grid. The grid "grows" with each generation that ads cells outside those boundaries. The grid shrinks only when 'shrinkBoard' is used.

=item C<gen>

The number of generations of this board.

=item C<liveCells>

The number of live cells on the grid.

=item C<usedCells>

The total number of cells. Each cell is created the first time it's state is set to 1. When a cell dies, it is not deleted from the internal data structure. Dead cells are removed only when 'shrinkBoard' is used and then only if they don't have any live neighbours.

=item C<delta>

The total state changes (cells died plus cells born) between the current and previous state.

=item C<factor2>

The ratio of live cells to total (live plus dead) cells.

=item C<oscilator>

When an oscilator is detected, this attribute is set to the period of the oscilator, otherwise is zero. 

=item C<totalTime>

The total time in seconds spent calculating generations for this board. Time::HiRes is used internaly.

=item C<lastTI>

The time in seconds spent calculating the last generation. Time::HiRes is used internaly.

=back

=head1 FUNCTIONS

=over

=item C<format_is>

C<< my $result = &format_is($file_array_ref); >>

C<< my $format = $result->{'format'}; >>

C<< my $version = $result->{'version'} >>

Expects an array ref holding a file. Returns undef if the file is not recognized or a hash ref with the result. Currently detecting: Life 1.05 and 1.06, MCell, RLE, cells.

=back

=head1 ATTRIBUTES

Some attributes of interest that you can access directly (C<< $board->{'attribute_name'} >>):

=over

=item C<currentFn>

Used to store a filename.

=item C<name>

Used to store a name for the formation.

=item C<description>

Used to store a description for the formation.

=item C<liveRules>

A reference to an array holding the numbers of neighbours that allow the survival of a cell.

=item C<breedRules>

A reference to an array holding the numbers of neighbours that allow the birth of a new cell.

=back

=head1 AUTHOR

This package was written by Theodore J. Soldatos.

=head1 COPYRIGHT

Copyright 2014 by Theodore J. Soldatos.

=head1 LICENSE

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut


