# Math::RungeKutta.pm
#########################################################################
#        This Perl module is Copyright (c) 2002, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This module is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################

package Math::RungeKutta;
no strict; no warnings;
$VERSION = '1.07';
# gives a -w warning, but I'm afraid $VERSION .= ''; would confuse CPAN
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(rk2 rk4 rk4_auto rk4_auto_midpoint);
@EXPORT_OK = qw(rk4_classical rk4_ralston arr2txt);
%EXPORT_TAGS = (ALL => [@EXPORT,@EXPORT_OK]);

sub new {
	my $arg1 = shift;
	my $class = ref($arg1) || $arg1; # can be used as class or instance method
	my $self  = {};   # ref to an empty hash
	bless $self, $class;
	$self->_initialise();
	return $self;
}

sub rk2 { my ($ynref, $dydtref, $t, $dt) = @_;
	if (ref $dydtref ne 'CODE') {
		warn "Math::RungeKutta::rk2: 2nd arg must be a subroutine ref\n";
		return ();
	}

	my $gamma = .75;  # Ralston's minimisation of error bounds
	my $alpha = 0.5/$gamma; my $beta = 1.0-$gamma;
	my $alphadt=$alpha*$dt; my $betadt=$beta*$dt; my $gammadt=$gamma*$dt;
	if (ref $ynref eq 'ARRAY') {
		my $ny = $#$ynref;
		my @ynp1; $#ynp1 = $ny;
		my @dydtn; $#dydtn = $ny;
		my @ynpalpha; $#ynpalpha = $ny;  # Gear calls this q
		my @dydtnpalpha; $#dydtnpalpha = $ny;
		@dydtn = &{$dydtref}($t, @$ynref);
		my $i; for ($i=$[; $i<=$ny; $i++) {
			$ynpalpha[$i] = ${$ynref}[$i] + $alphadt*$dydtn[$i];
		}
		@dydtnpalpha = &{$dydtref}($t+$alphadt, @ynpalpha);
		for ($i=$[; $i<=$ny; $i++) {
			$ynp1[$i]
			 = ${$ynref}[$i]+$betadt*$dydtn[$i]+$gammadt*$dydtnpalpha[$i];
		}
		return ($t+$dt, @ynp1);

	} elsif (ref $ynref eq 'HASH') {
		my %ynp1;
		my %ynpalpha;  # Gear calls this q
		my %dydtn = &{$dydtref}($t, %$ynref);
		foreach my $i (keys %$ynref) {
			$ynpalpha{$i} = ${$ynref}{$i} + $alphadt*$dydtn{$i};
		}
		my %dydtnpalpha = &{$dydtref}($t+$alphadt, %ynpalpha);
		foreach my $i (keys %$ynref) {
			$ynp1{$i}
			 = ${$ynref}{$i}+$betadt*$dydtn{$i}+$gammadt*$dydtnpalpha{$i};
		}
		return ($t+$dt, %ynp1);
	} else {
		warn "Math::RungeKutta::rk2: 1st arg must be an arrayref or hashref\n";
		return ();
	}
}
my @saved_k0; my %saved_k0; my $use_saved_k0 = 0;
sub rk4 { my ($ynref, $dydtref, $t, $dt) = @_;
	# The Runge-Kutta-Merson 5-function-evaluation 4th-order method
	# in the sine-cosine example, this seems to work as a 7th-order method !
	if (ref $dydtref ne 'CODE') {
		warn "Math::RungeKutta::rk4: 2nd arg must be a subroutine ref\n";
		return ();
	}
	if (ref $ynref eq 'ARRAY') {
		my $ny = $#$ynref; my $i;
		# @eta0 = @#ynref;
		my @k0; $#k0=$ny;
		if ($use_saved_k0) { @k0 = @saved_k0;
		} else { @k0 = &{$dydtref}($t, @$ynref);
		}
		for ($i=$[; $i<=$ny; $i++) { $k0[$i] *= $dt; }
		my @eta1; $#eta1=$ny;
		for ($i=$[; $i<=$ny; $i++) { $eta1[$i] = ${$ynref}[$i] + $k0[$i]/3.0; }
		my @k1; $#k1=$ny;
		@k1 = &{$dydtref}($t + $dt/3.0, @eta1);
		for ($i=$[; $i<=$ny; $i++) { $k1[$i] *= $dt; }
		my @eta2; $#eta2=$ny;
		my @k2; $#k2=$ny;
		for ($i=$[; $i<=$ny; $i++) {
			$eta2[$i] = ${$ynref}[$i] + ($k0[$i]+$k1[$i])/6.0;
		}
		@k2 = &{$dydtref}($t + $dt/3.0, @eta2);
		for ($i=$[; $i<=$ny; $i++) { $k2[$i] *= $dt; }
		my @eta3; $#eta3=$ny;
		for ($i=$[; $i<=$ny; $i++) {
			$eta3[$i] = ${$ynref}[$i] + ($k0[$i]+3.0*$k2[$i])*0.125;
		}
		my @k3; $#k3=$ny;
		@k3 = &{$dydtref}($t+0.5*$dt, @eta3);
		for ($i=$[; $i<=$ny; $i++) { $k3[$i] *= $dt; }
		my @eta4; $#eta4=$ny;
		for ($i=$[; $i<=$ny; $i++) {
			$eta4[$i] = ${$ynref}[$i] + ($k0[$i]-3.0*$k2[$i]+4.0*$k3[$i])*0.5;
		}
		my @k4; $#k4=$ny;
		@k4 = &{$dydtref}($t+$dt, @eta4);
		for ($i=$[; $i<=$ny; $i++) { $k4[$i] *= $dt; }
		my @ynp1; $#ynp1 = $ny;
		for ($i=$[; $i<=$ny; $i++) {
			$ynp1[$i] = ${$ynref}[$i] + ($k0[$i]+4.0*$k3[$i]+$k4[$i])/6.0;
		}
		# Merson's method for error estimation, see Gear p85, only works
		# if F is linear, ie F = Ay + bt, so that eta4 has no 4th-order
		# errors.  So in general step-doubling is the only way to do it.
		# Estimate error terms ...
		# if ($epsilon) {
		# 	my $errmax = 0; my $diff;
		# 	for ($i=$[; $i<=$ny; $i++) {
		# 		$diff = 0.2 * abs ($ynp1[$i] - $eta4[$i]);
		# 		if ($errmax < $diff) { $errmax = $diff; }
		# 	}
		# 	# print "errmax = $errmax\n"; # not much related to the actual error
		# }
		return ($t+$dt, @ynp1);

	} elsif (ref $ynref eq 'HASH') {
		my %k0;
		if ($use_saved_k0) { %k0 = %saved_k0;
		} else { %k0 = &{$dydtref}($t, %$ynref);
		}
		foreach my $i (keys(%$ynref)) { $k0{$i} *= $dt; }
		my %eta1;
		foreach my $i (keys(%$ynref)) { $eta1{$i} = ${$ynref}{$i}+$k0{$i}/3.0; }
		my %k1 = &{$dydtref}($t + $dt/3.0, %eta1);
		foreach my $i (keys(%$ynref)) { $k1{$i} *= $dt; }
		my %eta2;
		foreach my $i (keys(%$ynref)) {
			$eta2{$i} = ${$ynref}{$i} + ($k0{$i}+$k1{$i})/6.0;
		}
		my %k2 = &{$dydtref}($t + $dt/3.0, %eta2);
		foreach my $i (keys(%$ynref)) { $k2{$i} *= $dt; }
		my %eta3;
		foreach my $i (keys(%$ynref)) {
			$eta3{$i} = ${$ynref}{$i} + ($k0{$i}+3.0*$k2{$i})*0.125;
		}
		my %k3 = &{$dydtref}($t+0.5*$dt, %eta3);
		foreach my $i (keys(%$ynref)) { $k3{$i} *= $dt; }
		my %eta4;
		foreach my $i (keys(%$ynref)) {
			$eta4{$i} = ${$ynref}{$i} + ($k0{$i}-3.0*$k2{$i}+4.0*$k3{$i})*0.5;
		}
		my %k4 = &{$dydtref}($t+$dt, %eta4);
		foreach my $i (keys(%$ynref)) { $k4{$i} *= $dt; }
		my %ynp1;
		foreach my $i (keys(%$ynref)) {
			$ynp1{$i} = ${$ynref}{$i} + ($k0{$i}+4.0*$k3{$i}+$k4{$i})/6.0;
		}
		return ($t+$dt, %ynp1);
	} else {
		warn "Math::RungeKutta::rk4: 1st arg must be an arrayref or hashref\n";
		return ();
	}
}
my $t; my $halfdt;
my @y2; my %y2;  # need to be remembered for the midpoint
sub rk4_auto { my $ynref=shift; my $dydtref=shift; $t=shift;
	my ($dt, $arg4) = @_;
	if (ref $dydtref ne 'CODE') {
		warn "Math::RungeKutta::rk4_auto: 2nd arg must be a subroutine ref\n";
		return ();
	}
	if ($dt == 0) { $dt = 0.1; }
	if (ref $ynref eq 'ARRAY') {
		my @errors; my $epsilon;
		if (ref $arg4 eq 'ARRAY') {
			@errors = @$arg4; undef $epsilon;
		} else {
			$epsilon = abs $arg4; undef @errors;
			if (! $epsilon) { $epsilon = .0000001; }
		}
		my $ny = $#$ynref; my $i;
		my @y1; $#y1 = ny;
		$#y2 = ny; %y2 = ();
		my @y3; $#y3 = ny;
		$#saved_k0 = ny; @saved_k0 = &{$dydtref}($t, @$ynref);
		my $resizings = 0;
		my $highest_low_error = 0.1E-99; my $highest_low_dt = 0.0;
		my $lowest_high_error = 9.9E99;  my $lowest_high_dt = 9.9E99;
		while (1) {
			$halfdt = 0.5 * $dt; my $dummy;
			$use_saved_k0 = 1;
			($dummy, @y1) = &rk4($ynref, $dydtref, $t, $dt);
			($dummy, @y2) = &rk4($ynref, $dydtref, $t, $halfdt);
			$use_saved_k0 = 0;
			($dummy, @y3) = &rk4(\@y2, $dydtref, $t+$halfdt, $halfdt);
			my $relative_error;
			if ($epsilon) {
	 			my $errmax = 0; my $diff; my $ymax = 0;
	 			for ($i=$[; $i<=$ny; $i++) {
	 				$diff = abs ($y1[$i]-$y3[$i]);
	 				if ($errmax < $diff) { $errmax = $diff; }
	 				if ($ymax < abs ${$ynref}[$i]) {$ymax = abs ${$ynref}[$i];}
	 			}
				$relative_error = $errmax/($epsilon*$ymax);
			} elsif (@errors) {
				$relative_error = 0.0; my $diff;
	 			for ($i=$[; $i<=$ny; $i++) {
	 				$diff = abs ($y1[$i]-$y3[$i]) / abs $errors[$i];
	 				if ($relative_error < $diff) { $relative_error = $diff; }
	 			}
			} else { die
			 "RungeKutta::rk4_auto: \$epsilon & \@errors both undefined\n";
			}
			# Gear's correction assumes error is always in 5th-order terms :-(
			# $y1[$i] = (16.0*$y3{$i] - $y1[$i]) / 15.0;
			if ($relative_error < 0.60) {
				if ($dt > $highest_low_dt) {
					$highest_low_error = $relative_error;
					$highest_low_dt = $dt;
				}
			} elsif ($relative_error > 1.67) {
				if ($dt < $lowest_high_dt) {
					$lowest_high_error = $relative_error;
					$lowest_high_dt = $dt;
				}
			} else {
				last;
			}
			if ($lowest_high_dt<9.8E99 && $highest_low_dt>1.0E-99) { # interp
				my $denom = log ($lowest_high_error/$highest_low_error);
				if ($highest_low_dt==0.0||$highest_low_error==0.0||$denom==0.0){
					$dt = 0.5 * ($highest_low_dt+$lowest_high_dt);
				} else {
					$dt = $highest_low_dt * ( ($lowest_high_dt/$highest_low_dt)
				 	** ((log (1.0/$highest_low_error)) / $denom) );
				}
			} else {
				my $adjust = $relative_error**(-0.2); # hope error is 5th-order ...
				if (abs $adjust > 2.0) {
					$dt *= 2.0;  # prevent infinity if 4th-order is exact ...
				} else {
					$dt *= $adjust;
				}
			}
			$resizings++;
			if ($resizings>4 && $highest_low_dt>1.0E-99) {
				# hope a small step forward gets us out of this mess ...
				$dt = $highest_low_dt;  $halfdt = 0.5 * $dt;
				$use_saved_k0 = 1;
				($dummy, @y2) = &rk4($ynref, $dydtref, $t, $halfdt);
				$use_saved_k0 = 0;
				($dummy, @y3) = &rk4(\@y2, $dydtref, $t+$halfdt, $halfdt);
				last;
			}
		}
		return ($t+$dt, $dt, @y3);

	} elsif (ref $ynref eq 'HASH') {
		my %errors; my $epsilon;
		if (ref $arg4 eq 'HASH') {
			%errors = %$arg4; undef $epsilon;
		} else {
			$epsilon = abs $arg4; undef %errors;
			if (! $epsilon) { $epsilon = .0000001; }
		}
		my $i; my %y1; @y2 = (); my %y3;
		%saved_k0 = &{$dydtref}($t, %$ynref);
		my $resizings = 0;
		my $highest_low_error = 0.1E-99; my $highest_low_dt = 0.0;
		my $lowest_high_error = 9.9E99;  my $lowest_high_dt = 9.9E99;
		while (1) {
			$halfdt = 0.5 * $dt; my $dummy;
			$use_saved_k0 = 1;
			($dummy, %y1) = &rk4($ynref, $dydtref, $t, $dt);
			($dummy, %y2) = &rk4($ynref, $dydtref, $t, $halfdt);
			$use_saved_k0 = 0;
			($dummy, %y3) = &rk4(\%y2, $dydtref, $t+$halfdt, $halfdt);
			my $relative_error;
			if ($epsilon) {
	 			my $errmax = 0; my $diff; my $ymax = 0;
	 			foreach $i (keys(%$ynref)) {
	 				$diff = abs ($y1{$i}-$y3{$i});
	 				if ($errmax < $diff) { $errmax = $diff; }
	 				if ($ymax < abs ${$ynref}{$i}) {$ymax = abs ${$ynref}{$i};}
	 			}
				$relative_error = $errmax/($epsilon*$ymax);
			} elsif (%errors) {
				$relative_error = 0.0; my $diff;
	 			foreach $i (keys(%$ynref)) {
	 				$diff = abs ($y1{$i}-$y3{$i}) / abs $errors{$i};
	 				if ($relative_error < $diff) { $relative_error = $diff; }
	 			}
			} else { die
			 "RungeKutta::rk4_auto: \$epsilon & \%errors both undefined\n";
			}
			# Gear's correction assumes error is always in 5th-order terms :-(
			# $y1[$i] = (16.0*$y3{$i] - $y1[$i]) / 15.0;
			if ($relative_error < 0.60) {
				if ($dt > $highest_low_dt) {
					$highest_low_error = $relative_error;
					$highest_low_dt = $dt;
				}
			} elsif ($relative_error > 1.67) {
				if ($dt < $lowest_high_dt) {
					$lowest_high_error = $relative_error;
					$lowest_high_dt = $dt;
				}
			} else {
				last;
			}
			if ($lowest_high_dt<9.8E99 && $highest_low_dt>1.0E-99) { # interp
				my $denom = log ($lowest_high_error/$highest_low_error);
				if ($highest_low_dt==0.0||$highest_low_error==0.0||$denom==0.0){
					$dt = 0.5 * ($highest_low_dt+$lowest_high_dt);
				} else {
					$dt = $highest_low_dt * ( ($lowest_high_dt/$highest_low_dt)
				 	** ((log (1.0/$highest_low_error)) / $denom) );
				}
			} else {
				my $adjust = $relative_error**(-0.2); # hope error is 5th-order ...
				if (abs $adjust > 2.0) {
					$dt *= 2.0;  # prevent infinity if 4th-order is exact ...
				} else {
					$dt *= $adjust;
				}
			}
			$resizings++;
			if ($resizings>4 && $highest_low_dt>1.0E-99) {
				# hope a small step forward gets us out of this mess ...
				$dt = $highest_low_dt;  $halfdt = 0.5 * $dt;
				$use_saved_k0 = 1;
				($dummy, %y2) = &rk4($ynref, $dydtref, $t, $halfdt);
				$use_saved_k0 = 0;
				($dummy, %y3) = &rk4(\%y2, $dydtref, $t+$halfdt, $halfdt);
				last;
			}
		}
		return ($t+$dt, $dt, %y3);

	} else { die
		"Math::RungeKutta::rk4_auto: 1st arg must be arrayref or hashref\n";
		# return ();
	}
}
sub rk4_auto_midpoint {
	if (@y2) { return ($t+$halfdt, @y2); } else { return ($t+$halfdt, %y2); }
}

# ---------------------- EXPORT_OK routines ----------------------

sub rk4_ralston { my ($ynref, $dydtref, $t, $dt) = @_;
	if (ref $dydtref ne 'CODE') {
		warn "RungeKutta::rk4_ralston: 2nd arg must be a subroutine ref\n";
		return ();
	}
	# Ralston's minimisation of error bounds, see Gear p36
	if (ref $ynref eq 'ARRAY') {
		my $ny = $#$ynref; my $i;
		my $alpha1=0.4; my $alpha2 = 0.4557372542; # = .875 - .1875*(sqrt 5);
		my @k0; $#k0=$ny;
		@k0 = &{$dydtref}($t, @$ynref);
		for ($i=$[; $i<=$ny; $i++) { $k0[$i] *= $dt; }
		my @k1; $#k1=$ny;
		for ($i=$[; $i<=$ny; $i++) { $k1[$i] = ${$ynref}[$i] + 0.4*$k0[$i]; }
		@k1 = &{$dydtref}($t + $alpha1*$dt, @k1);
		for ($i=$[; $i<=$ny; $i++) { $k1[$i] *= $dt; }
		my @k2; $#k2=$ny;
		for ($i=$[; $i<=$ny; $i++) {
			$k2[$i] = ${$ynref}[$i] + 0.2969776*$k0[$i] + 0.15875966*$k1[$i];
		}
		@k2 = &{$dydtref}($t + $alpha2*$dt, @k2);
		for ($i=$[; $i<=$ny; $i++) { $k2[$i] *= $dt; }
		my @k3; $#k3=$ny;
		for ($i=$[; $i<=$ny; $i++) {
			$k3[$i] = ${$ynref}[$i] + 0.21810038*$k0[$i] - 3.0509647*$k1[$i]
		 	+ 3.83286432*$k2[$i];
		}
		@k3 = &{$dydtref}($t+$dt, @k3);
		for ($i=$[; $i<=$ny; $i++) { $k3[$i] *= $dt; }
		my @ynp1; $#ynp1 = $ny;
		for ($i=$[; $i<=$ny; $i++) {
			$ynp1[$i] = ${$ynref}[$i] + 0.17476028*$k0[$i]
		 	- 0.55148053*$k1[$i] + 1.20553547*$k2[$i] + 0.17118478*$k3[$i];
		}
		return ($t+$dt, @ynp1);

	} elsif (ref $ynref eq 'HASH') {
		my $i;
		my $alpha1=0.4; my $alpha2 = 0.4557372542; # = .875 - .1875*(sqrt 5);
		my %k0 = &{$dydtref}($t, %$ynref);
		foreach $i (keys(%$ynref)) { $k0{$i} *= $dt; }
		my %k1;
		foreach $i (keys(%$ynref)) { $k1{$i} = ${$ynref}{$i} + 0.4*$k0{$i}; }
		%k1 = &{$dydtref}($t + $alpha1*$dt, %k1);
		foreach $i (keys(%$ynref)) { $k1{$i} *= $dt; }
		my %k2;
		foreach $i (keys(%$ynref)) {
			$k2{$i} = ${$ynref}{$i} + 0.2969776*$k0{$i} + 0.15875966*$k1{$i};
		}
		%k2 = &{$dydtref}($t + $alpha2*$dt, %k2);
		foreach $i (keys(%$ynref)) { $k2{$i} *= $dt; }
		my %k3;
		foreach $i (keys(%$ynref)) {
			$k3{$i} = ${$ynref}{$i} + 0.21810038*$k0{$i} - 3.0509647*$k1{$i}
		 	+ 3.83286432*$k2{$i};
		}
		%k3 = &{$dydtref}($t+$dt, %k3);
		foreach $i (keys(%$ynref)) { $k3{$i} *= $dt; }
		my %ynp1;
		foreach $i (keys(%$ynref)) {
			$ynp1{$i} = ${$ynref}{$i} + 0.17476028*$k0{$i}
		 	- 0.55148053*$k1{$i} + 1.20553547*$k2{$i} + 0.17118478*$k3{$i};
		}
		return ($t+$dt, %ynp1);

	} else {
		warn "Math::RungeKutta::rk4_ralston: 1st arg must be arrayref or hashref\n";
		return ();
	}
}
sub rk4_classical { my ($ynref, $dydtref, $t, $dt) = @_;
	if (ref $dydtref ne 'CODE') {
		warn "RungeKutta::rk4_classical: 2nd arg must be subroutine ref\n";
		return ();
	}
	# The Classical 4th-order Runge-Kutta Method, see Gear p35
	if (ref $ynref eq 'ARRAY') {
		my $ny = $#$ynref; my $i;
		my @k0; $#k0=$ny;
		@k0 = &{$dydtref}($t, @$ynref);
		for ($i=$[; $i<=$ny; $i++) { $k0[$i] *= $dt; }
		my @eta1; $#eta1=$ny;
		for ($i=$[; $i<=$ny; $i++) { $eta1[$i] = ${$ynref}[$i] + 0.5*$k0[$i]; }
		my @k1; $#k1=$ny;
		@k1 = &{$dydtref}($t+0.5*$dt, @eta1);
		for ($i=$[; $i<=$ny; $i++) { $k1[$i] *= $dt; }
		my @eta2; $#eta2=$ny;
		for ($i=$[; $i<=$ny; $i++) { $eta2[$i] = ${$ynref}[$i] + 0.5*$k1[$i]; }
		my @k2; $#k2=$ny;
		@k2 = &{$dydtref}($t+0.5*$dt, @eta2);
		for ($i=$[; $i<=$ny; $i++) { $k2[$i] *= $dt; }
		my @eta3; $#eta3=$ny;
		for ($i=$[; $i<=$ny; $i++) { $eta3[$i] = ${$ynref}[$i] + $k2[$i]; }
		my @k3; $#k3=$ny;
		@k3 = &{$dydtref}($t+$dt, @eta3);
		for ($i=$[; $i<=$ny; $i++) { $k3[$i] *= $dt; }
		my @ynp1; $#ynp1 = $ny;
		for ($i=$[; $i<=$ny; $i++) {
			$ynp1[$i] = ${$ynref}[$i] +
		 	($k0[$i] + 2.0*$k1[$i] + 2.0*$k2[$i] + $k3[$i]) / 6.0;
		}
		return ($t+$dt, @ynp1);

	} elsif (ref $ynref eq 'HASH') {
		my %k0 = &{$dydtref}($t, %$ynref);
		foreach my $i (keys(%$ynref)) { $k0{$i} *= $dt; }
		my %eta1;
		foreach $i (keys(%$ynref)) { $eta1{$i} = ${$ynref}{$i} + 0.5*$k0{$i}; }
		my %k1 = &{$dydtref}($t+0.5*$dt, %eta1);
		foreach $i (keys(%$ynref)) { $k1{$i} *= $dt; }
		my %eta2;
		foreach $i (keys(%$ynref)) { $eta2{$i} = ${$ynref}{$i} + 0.5*$k1{$i}; }
		my %k2 = &{$dydtref}($t+0.5*$dt, %eta2);
		foreach $i (keys(%$ynref)) { $k2{$i} *= $dt; }
		my %eta3;
		foreach $i (keys(%$ynref)) { $eta3{$i} = ${$ynref}{$i} + $k2{$i}; }
		my %k3 = &{$dydtref}($t+$dt, %eta3);
		foreach $i (keys(%$ynref)) { $k3{$i} *= $dt; }
		my %ynp1;
		foreach $i (keys(%$ynref)) {
			$ynp1{$i} = ${$ynref}{$i} +
		 	($k0{$i} + 2.0*$k1{$i} + 2.0*$k2{$i} + $k3{$i}) / 6.0;
		}
		return ($t+$dt, %ynp1);

	} else {
		warn "Math::RungeKutta::rk4_classical: 1st arg must be arrayref or hashref\n";
		return ();
	}
}

# --------------------- infrastructure ----------------------

sub arr2txt { # neat printing of arrays for debug use
	my @txt; foreach (@_) { push @txt, sprintf('%g',$_); }
	return join (' ',@txt)."\n";
}
my $flag;
sub gaussn {   my $standdev = $_[$[];
	# returns normal distribution around 0.0 by the Box-Muller rules
	if (! $flag) {
		$a = sqrt(-2.0 * log(rand)); $b = 6.28318531 * rand;
		$flag = 1; return ($standdev * $a * sin($b));
	} else {
		$flag = 0; return ($standdev * $a * cos($b));
	}
}
1;

__END__

=pod

=head1 NAME

Math::RungeKutta.pm - Integrating Systems of Differential Equations

=head1 SYNOPSIS

 use Math::RungeKutta;

 # When working on data in an array ...
 sub dydt { my ($t, @y) = @_;   # the derivative function
   my @dydt; ... ; return @dydt;
 }
 @y = @initial_y; $t=0; $dt=0.4;  # the initial conditions
 # For automatic timestep adjustment ...
 while ($t < $tfinal) {
    ($t, $dt, @y) = &rk4_auto(\@y, \&dydt, $t, $dt, 0.00001);
    &display($t, @y);
 }
 # Or, for fixed timesteps ...
 while ($t < $tfinal) {
   ($t, @y) = &rk4(\@y, \&dydt, $t, $dt); # Merson's 4th-order method
   &display($t, @y);
 }
 # alternatively, though not so accurate ...
 ($t, @y) = &rk2(\@y, \&dydt, $t, $dt);   # Heun's 2nd-order method

 # Or, working on data in a hash...
 sub dydt { my ($t, %y) = @_;   # the derivative function
   my %dydt; ... ; return %dydt;
 }
 %y = %initial_y; $t=0; $dt=0.4;  # the initial conditions
 # For automatic timestep adjustment on hashes ...
 while ($t < $tfinal) {
    ($t, $dt, %y) = &rk4_auto(\%y, \%dydt, $t, $dt, 0.00001);
    &display($t, %y);
 }
 # Or, for fixed timesteps on hashes ...
 while ($t < $tfinal) {
   ($t, %y) = &rk4(\%y, \%dydt, $t, $dt); # Merson's 4th-order method
   &display($t, %y);
 }
 # alternatively, though not so accurate ...
 ($t, %y) = &rk2(\%y, \%dydt, $t, $dt);   # Heun's 2nd-order method

 # or, also available but not exported by default ...
 import qw(:ALL);
 ($t, @y) = &rk4_classical(\@y, \&dydt, $t, $dt); # Runge-Kutta 4th-order
 ($t, @y) = &rk4_ralston(\@y, \&dydt, $t, $dt);   # Ralston's 4th-order
 # or similarly for data in hashes.

=head1 DESCRIPTION

RungeKutta.pm offers algorithms for the numerical integration
of simultaneous differential equations of the form

 dY/dt = F(t,Y)

where Y is an array of variables whose initial values Y(0) are
known, and F is a function known from the dynamics of the problem.

The Runge-Kutta methods all involve evaluating the derivative function
F(t,Y) more than once, at various points within the timestep, and
combining the results to reach an accurate answer for the Y(t+dt).
This module only uses explicit Runge-Kutta methods; the implicit methods
involve, at each timestep, solving a set of simultaneous equations
involving both Y(t) and F(t,Y), and this is generally intractable.

Three main algorithms are offered.  I<rk2> is Heun's 2nd-order
Runge-Kutta algorithm, which is relatively imprecise, but does have
a large range of stability which might be useful in some problems.  I<rk4>
is Merson's 4th-order Runge-Kutta algorithm, which should be the normal
choice in situations where the step-size must be specified.  I<rk4_auto>
uses the step-doubling method to adjust the step-size of I<rk4> automatically
to achieve a specified precision; this saves much fiddling around trying
to choose a good step-size, and can also save CPU time by automatically
increasing the step-size when the solution is changing only slowly.

I<Perl> is not the right language for high-end numerical integration like
global weather simulation, colliding galaxies and so on (if you need
something like this you could check out I<xmds>).  But as Gear says,
"Many equations that are solved on digital computers can be classified
as trivial by the fact that even with an inefficient method of solution,
little computer time is used. Economics then dictates that the best method
is the one that minimises the human time of preparation of the program."

This module has been designed to be robust and easy to use, and should
be helpful in solving systems of differential equations which arise
within a I<Perl> context, such as economic, financial, demographic
or ecological modelling, mechanical or process dynamics, etc.

Version 1.07

=head1 SUBROUTINES

=over 3

=item I<rk2>( \@y, \&dydt, $t, $dt )

=item I<rk2>( \%y, \&dydt, $t, $dt )

where the arguments are:
 I<\@y> a reference to the array of initial values of variables,
 I<\%y> a reference to the hash of initial values of variables,
 I<\&dydt> a reference to the function calculating the derivatives,
 I<$t> the initial time,
 I<$dt> the timestep.

The algorithm used is that derived by Ralston, which uses Lotkin's bound
on the derivatives, and minimises the solution error (gamma=3/4).
It is also known as the Heun method, though unfortunately several other
methods are also known under this name. Two function evaluations are needed
per timestep, and the remaining error is in the 3rd and higher order terms.

I<rk2> returns ($t, @y) where $t and @y are now the new values
at the completion of the timestep,
or it returns ($t, %y) if called with the data in a hashref.

=item I<rk4>( \@y, \&dydt, $t, $dt )

=item I<rk4>( \%y, \&dydt, $t, $dt )

The arguments are the same as in I<rk2>.

The algorithm used is that developed by Merson,
which performs five function evaluations per timestep.
For the same timestep, I<rk4> is much more accurate than I<rk4_classical>,
so the extra function evaluation is well worthwhile.

I<rk4> returns ($t, @y) where $t and @y are now the new values
at the completion of the timestep.

=item I<rk4_auto>( \@y, \&dydt, $t, $dt, $epsilon )

=item I<rk4_auto>( \@y, \&dydt, $t, $dt, \@errors )

=item I<rk4_auto>( \%y, \&dydt, $t, $dt, $epsilon )

=item I<rk4_auto>( \%y, \&dydt, $t, $dt, \%errors )

In the I>epsilon> form the arguments are:
 I<\@y> a reference to the array of initial values of variables or
 I<\%y> a reference to the hash of initial values of variables,
 I<\&dydt> a reference to the function calculating the derivatives,
 I<$t> the initial time,
 I<$dt> the initial timestep,
 I<$epsilon> the errors per step will be about $epsilon*$ymax

In the I<errors> form the last argument is:
 I<\@errors> a reference to an array of maximum permissible errors,
 or I<\%errors> a reference to a hash, accordingly.

The first I<$epsilon> calling form is useful when all the elements of
I<@y> are in the same units and have the same typical size (e.g. y[10]
is population aged 10-11 years, y[25] is population aged 25-26 years).
The default value of the 4th argument is I<$epsilon = 0.00001>.

The second I<errors> form is useful otherwise
(e.g. $y[1] is gross national product, $y[2] is interest rate,
or $y{'gross national product'} and $y{'interest rate'} accordingly.
In this calling form, the permissible errors are specified in
absolute size for each variable; they won't get scaled at all.

I<rk4_auto> adjusts the timestep automatically to give the
required precision.  It does this by trying one full-timestep,
then two half-timesteps, and comparing the results.
(Merson's method, as used by I<rk4>, was devised to be able
to give an estimate of the remaining local error; for the
record, it is I<0.2*($ynp1[i]-$eta4[i])> in each term.
I<rk4_auto> does not exploit this feature because it only
works for linear I<dydt> functions of the form I<Ay + bt>.)

I<rk4_auto> needs 14 function evaluations per double-timestep, and
it has to re-do 13 of those every time it adjusts the timestep.

I<rk4_auto> returns ($t, $dt, @y) where $t, $dt and @y
are now the new values at the completion of the timestep,
or ($t, $dt, %y) accordingly.

=item I<rk4_auto_midpoint>()

I<rk4_auto> performs a double timestep within $dt, and returns
the final values; the values as they were at the midpoint do
not normally get returned.  However, if you want to draw a
nice smooth graph, or to update a nice smoothly-moving display,
those values as they were at the midpoint would be useful to you.
Therefore, I<rk4_auto_midpoint> provides a way of retrieving them.

Note that you must call I<rk4_auto> first, which returns the values at
time $t+$dt, then I<rk4_auto_midpoint> subsequently, which returns the
values at $t+$dt/2, in other words you get the two sets of values out
of their chronological order. Sorry about this.  For example,

 while ($t<$tfinal) {
   ($t, $dt, @y) = &rk4_auto(\@y, \&dydt, $t, $dt, $epsilon);
   ($t_midpoint, @y_midpoint) = &rk4_auto_midpoint();
   &update_display($t_midpoint, @y_midpoint);
   &update_display($t, @y);
 }

I<rk4_auto_midpoint> returns ($t, @y) where $t and @y were the
values at the midpoint of the previous call to I<rk4_auto>;
or ($t, %y) accordingly.

=back

=head1 CALLER-SUPPLIED SUBROUTINES

=over 3

=item I<dydt>( $t, @y );

=item I<dydt>( $t, %y );

You will pass this subroutine by reference as the second argument to
I<rk2>, I<rk4> and I<rk4_auto>. The name doesn't matter of course.
It must expect the following arguments:
 I<$t> the time (in case the equations are time-dependent),
 I<@y> the array of values of variables or
 I<%y> the hash of values of variables.

It must return an array (or hash, accordingly)
of the derivatives of the variables with respect to time.

=back

=head1 EXPORT_OK SUBROUTINES

The following routines are not exported by default, but are
exported under the I<ALL> tag, so if you need them you should:

 import Math::RungeKutta qw(:ALL);

=over 3

=item I<rk4_classical>( \@y, \&dydt, $t, $dt )

=item I<rk4_classical>( \%y, \&dydt, $t, $dt )

The arguments and the return values are the same as in I<rk2> and I<rk4>.

The algorithm used is the classic, elegant, 4th-order Runge-Kutta
method, using four function evaluations per timestep:
 k0 = dt * F(y(n))
 k1 = dt * F(y(n) + 0.5*k0)
 k2 = dt * F(y(n) + 0.5*k1)
 k3 = dt * F(y(n) + k2)
 y(n+1) = y(n) + (k0 + 2*k1 + 2*k2 + k3) / 6

=item I<rk4_ralston>( \@y, \&dydt, $t, $dt )

=item I<rk4_ralston>( \%y, \&dydt, $t, $dt )

The arguments and the return values are the same as in I<rk2> and I<rk4>.

The algorithm used is that developed by Ralston, which optimises
I<rk4_classical> to minimise the error bound on each timestep.
This module does not use it as the default 4th-order method I<rk4>,
because Merson's algorithm generates greater accuracy, which allows
the timestep to be increased, which more than compensates for
the extra function evaluation.

=back

=head1 EXAMPLES

There are a couple of example scripts in the I<examples/>
subdirectory of the build directory.
You can use their code to help you get your first application going.

=over 3

=item I<sine-cosine>

This script uses I<Term::Clui> (arrow keys and Return, or q to quit)
to offer a selection of algorithms, timesteps and error criteria for
the integration of a simple sine/cosine wave around one complete cycle.
This was the script used as a testbed during development.

=item I<three-body>

This script uses the vt100 or xterm 'moveto' and 'reverse'
sequences to display a little simulation of three-body gravity.
It uses I<rk4_auto> because a shorter timestep is needed when
two bodies are close to each other. It also uses I<rk4_auto_midpoint>
to smooth the display.  By changing the initial conditions you
can experience how sensitively the outcome depends on them.

=back

=head1 TRAPS FOR THE UNWARY

Alas, things can go wrong in numerical integration.

One of the most fundamental is B<instability>. If you choose a timestep
I<$dt> much larger than time-constants implied in your derivative
function I<&dydt>, then the numerical solution will oscillate wildy,
and bear no relation to the real behaviour of the equations.
If this happens, choose a shorter I<$dt>.

Some of the most difficult problems involve so-called B<stiff>
derivative functions. These arise when I<&dydt> introduces a wide
range of time-constants, from very short to long. In order to avoid
instability, you will have to set I<$dt> to correspond to the shortest
time-constant; but this makes it impossibly slow to follow the
evolution of the system over longer times.  You should try to separate
out the long-term part of the problem, by expressing the short-term
process as the finding of some equilibrium, and then assume that that
equilibrium is present and solve the long-term problem on its own.

Similarly, numerical integration doesn't enjoy problems where
time-constants change suddenly, such as balls bouncing off hard
surfaces, etc. You can often tackle these by intervening directly
in the I<@y> array between each timestep. For example, if I<$y[17]>
is the height of the ball above the floor, and I<$y[20]> is the
vertical component of the velocity, do something like

 if ($y[17]<0.0) { $y[17]*=-0.9; $y[20]*=-0.9; }

and thus, again, let the numerical integration solve just the
smooth part of the problem.

=head1 JAVASCRIPT

In the C<js/> subdirectory of the install directory there is I<RungeKutta.js>,
which is an exact translation of this Perl code into JavaScript.
The function names and arguments are unchanged.
Brief Synopsis:

 <SCRIPT type="text/javascript" src="RungeKutta.js"> </SCRIPT>
 <SCRIPT type="text/javascript">
 var dydt = function (t, y) {  // the derivative function
    var dydt_array = new Array(y.length); ... ; return dydt_array;
 }
 var y = new Array();

 // For automatic timestep adjustment ...
 y = initial_y(); var t=0; var dt=0.4;  // the initial conditions
 // Arrays of return vaules:
 var tmp_end = new Array(3);  var tmp_mid = new Array(2);
 while (t < tfinal) {
    tmp_end = rk4_auto(y, dydt, t, dt, 0.00001);
    tmp_mid = rk4_auto_midpoint();
    t=tmp_mid[0]; y=tmp_mid[1];
    display(t, y);   // e.g. could use wz_jsgraphics.js or SVG
    t=tmp_end[0]; dt=tmp_end[1]; y=tmp_end[2];
    display(t, y);
 }

 // Or, for fixed timesteps ...
 y = post_ww2_y(); var t=1945; var dt=1;  // start in 1945
 var tmp = new Array(2);  // Array of return values
 while (t <= 2100) {
    tmp = rk4(y, dydt, t, dt);  // Merson's 4th-order method
    t=tmp[0]; y=tmp[1];
    display(t, y);
 }
 </SCRIPT>

I<RungeKutta.js> uses several global variables
which all begin with the letters C<_rk_> so you should
avoid introducing variables beginning with these characters.

=head1 LUA

In the C<lua/> subdirectory of the install directory there is
I<RungeKutta.lua>, which is an exact translation of this Perl code into Lua.
The function names and arguments are unchanged.
Brief Synopsis:

 local RK = require 'RungeKutta'
 function dydt(t, y) -- the derivative function
   -- y is the table of the values, dydt the table of the derivatives
   local dydt = {}; ... ; return dydt
 end
 y = initial_y(); t=0; dt=0.4;  -- the initial conditions
 -- For automatic timestep adjustment ...
 while t < tfinal do
    t, dt, y = RK.rk4_auto(y, dydt, t, dt, 0.00001)
    display(t, y)
 end

 -- Or, for fixed timesteps ...
 while t < tfinal do
   t, y = RK.rk4(y, dydt, t, dt)  -- Merson's 4th-order method
   display(t, y)
 end
 -- alternatively, though not so accurate ...
 t, y = RK.rk2(y, dydt, t, dt)   -- Heun's 2nd-order method

 -- or, also available ...
 t, y = RK.rk4_classical(y, dydt, t, dt) -- Runge-Kutta 4th-order
 t, y = RK.rk4_ralston(y, dydt, t, dt)   -- Ralston's 4th-order

=head1 AUTHOR

Peter J Billam, http://www.pjb.com.au/comp/contact.html

=head1 REFERENCES

I<On the Accuracy of Runge-Kutta's Method>,
M. Lotkin, MTAC, vol 5, pp 128-132, 1951

I<An Operational Method for the study of Integration Processes>,
R. H. Merson,
Proceedings of a Symposium on Data Processing,
Weapons Research Establishment, Salisbury, South Australia, 1957

I<Numerical Solution of Ordinary and Partial Differential Equations>,
L. Fox, Pergamon, 1962

I<A First Course in Numerical Analysis>, A. Ralston, McGraw-Hill, 1965

I<Numerical Initial Value Problems in Ordinary Differential Equations>,
C. William Gear, Prentice-Hall, 1971

=head1 SEE ALSO

See also the scripts examples/sine-cosine and examples/three-body,
http://www.pjb.com.au/,
http://www.pjb.com.au/comp/,
Math::WalshTransform,
Math::Evol,
Term::Clui,
Crypt::Tea_JS,
http://www.xmds.org/

=cut
