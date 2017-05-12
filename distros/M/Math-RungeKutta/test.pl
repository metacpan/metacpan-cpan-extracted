#! /usr/bin/perl
#########################################################################
#        This Perl script is Copyright (c) 2002, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This script is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################

use Math::RungeKutta qw(:ALL);
use Test::Simple tests => 12;

my $func_evals = 0;
my $i_test     = 0;
my $n_failed   = 0;
my $n_passed   = 0;
sub dydt { my ($t, @y) = @_;
	my @dydt;
	$dydt[$[] = $y[$[+1];
	$dydt[$[+1] = 0.0 - $y[$[];
	$func_evals++;
	return @dydt;
}
sub dydt_hash { my ($t, %y) = @_;
	my %dydt;
	$dydt{'x'} = $y{'y'};
	$dydt{'y'} = 0.0 - $y{'x'};
	$func_evals++;
	return %dydt;
}
$twopi = 2.0 * 3.141592653589;
%passmark0 = (
	rk2=>0.2, rk4=>.0004, rk4_classical=>.0015, rk4_ralston=>.0015,
	epsilon=>.0001, errors=>.0003,
);
%passmark1 = (
	rk2=>0.04, rk4=>.00004, rk4_classical=>.0006, rk4_ralston=>.0006,
	epsilon=>.00001, errors=>.00001,
);
foreach $algorithm ('rk2','rk4','rk4_classical','rk4_ralston') {
	$i_test++;
	$n = 16;
	$dt= $twopi / $n;

	@y = (0,1); $t=0;
	foreach (1..$n) { ($t, @y) = &{$algorithm}( \@y, \&dydt, $t, $dt ); }
	my $err0 = abs $y[$[]; my $err1 = abs ($y[$[+1]-1.0);
	ok(($err0 < $passmark0{$algorithm} && $err1 < $passmark1{$algorithm}),
	 "$algorithm with array");

	my %y = ('x'=>0, 'y'=>1); $t=0;
	foreach (1..$n) { ($t, %y) = &{$algorithm}( \%y, \&dydt_hash, $t, $dt ); }
	my $err0 = abs $y{'x'}; my $err1 = abs ($y{'y'}-1.0);
	ok(($err0 < $passmark0{$algorithm} && $err1 < $passmark1{$algorithm}),
	 "$algorithm with hash");
}
$algorithm = 'rk4_auto';
my ($t_midpoint, @y_midpoint);
MODE: foreach $mode ('epsilon','errors') {
	$i_test++;
	my $i = 0;
	my $epsilon;
	# array
	if ($mode eq 'epsilon') { $epsilon = .0001;
	} else { @errors = (.01, .0001); $epsilon = \@errors;
	}
	@y = (0,1); $t=0; $dt = 0.1;
	$func_evals = 0;
	while ($t+$dt < $twopi) {
		$i++;
		($t, $dt, @y) = &rk4_auto( \@y, \&dydt, $t, $dt, $epsilon );
		($t_midpoint, @y_midpoint) = &rk4_auto_midpoint();
		if ($func_evals > 500) { ok(0,
			"rk4_auto with array and $mode , $func_evals func evals");
			next MODE;
		}
	}
	$i++; $dt = $twopi-$t;
	($t, @y) = &rk4( \@y, \&dydt, $t, $dt );
	my $err0 = abs $y[$[]; my $err1 = abs ($y[$[+1]-1.0);
	ok (($err0 < $passmark0{$mode} && $err1 < $passmark1{$mode}),
	"rk4_auto with array and $mode");

	# hash
	if ($mode eq 'epsilon') { $epsilon = .0001;
	} else { %errors = ("x"=>.01, "y"=>.0001); $epsilon = \%errors;
	}
	%y = ("x"=>0, "y"=>1); $t=0; $dt = 0.1;
	$func_evals = 0;
	while ($t+$dt < $twopi) {
		$i++;
		($t, $dt, %y) = &rk4_auto( \%y, \&dydt_hash, $t, $dt, $epsilon );
		($t_midpoint, %y_midpoint) = &rk4_auto_midpoint();
		if ($func_evals > 500) { ok(0,
			"rk4_auto with hash and $mode , $func_evals func evals");
			next MODE;
		}
	}
	$i++; $dt = $twopi-$t;
	($t, %y) = &rk4( \%y, \&dydt_hash, $t, $dt );
	my $err0 = abs $y{"x"}; my $err1 = abs ($y{"y"} - 1.0);
	ok (($err0 < $passmark0{$mode} && $err1 < $passmark1{$mode}),
	"rk4_auto with hash and $mode");
}

__END__

=pod

=head1 NAME

test.pl - Perl script to test Math::RungeKutta.pm

=head1 SYNOPSIS

 perl test.pl

=head1 DESCRIPTION

This script tests Math::RungeKutta.pm

=head1 AUTHOR

Peter J Billam http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

Math::RungeKutta.pm , http://www.pjb.com.au/ , perl(1).

=cut

