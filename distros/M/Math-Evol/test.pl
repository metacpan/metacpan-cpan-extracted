#! /usr/bin/perl -w
#########################################################################
#        This Perl script is Copyright (c) 2002, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This script is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################

use Math::Evol;
use Test::Simple tests => 6;
my $detailed = 0;

sub minimise {
	my $sum = 1.0;
	foreach (@_) { $sum += ($_ * $_); }
	return $sum;
}
sub contain {
   if ($_[0] > 1.0) { $_[0] = 1.0;  # it's a greyscale value
   } elsif ($_[0] < 0.0) { $_[0] = 0.0;
   }
   if ($_[1] > 1.0) { $_[1] = 1.0;  # it's a greyscale value
   } elsif ($_[1] < 0.0) { $_[1] = 0.0;
   }
   if ($_[2] > 1.0) { $_[2] = 1.0;  # it's a greyscale value
   } elsif ($_[2] < 0.0) { $_[2] = 0.0;
   }
	return @_;
}
sub choosebetter { my ($a_ref, $b_ref) = @_;
	my $a_sum = 0.0; foreach (@$a_ref) { $a_sum += ($_ * $_); }
	my $b_sum = 0.0; foreach (@$b_ref) { $b_sum += ($_ * $_); }
	my $preference = 0; if ($b_sum < $a_sum)     { $preference = 1; }
	my $continue   = 0; if ($a_sum > 0.00000001) { $continue   = 1; }
	return ($preference, $continue);
}
my $text = <<'EOT';
/w 3.456  def % evol step 0.8 min 0 max 1
/x 1.234  def % evol step 0.4 min 0 max 1
/y -2.345 def % evol step 0.6 min 0 max 1
/z 4.567  def % evol step 1.2
EOT

my @x  = (3.456, 1.234, -2.345, 4.567);
my @sm = (.8, .4, .6, 1.2);

# ----------------- test &evol --------------------
my @returns = &evol(\@x, \@sm, \&minimise, \&contain, 10);
my $fail1 = 0;
foreach (@{$returns[0]}) {
	if (abs $_>0.00015) { if ($detailed) { warn "\$_ = $_\n"; } $fail1++; }
}
ok (!$fail1, "evol");
if ($detailed) {
	if ($fail1) { warn "subroutine &evol failed to find the minimum\n"; }
	foreach (@{$returns[1]}) {
		if (abs $_ > 0.00015) { warn "step size still $_\n"; $fail1++; }
	}
	if ($fail1) {
		warn "evol returns:\n x = ", join(", ", @{$returns[0]}), "\n";
		warn "sm = ", join(", ", @{$returns[1]}), "\n";
		warn "objective = $returns[2]\n";
		warn "success   = $returns[3]\n";
	}
	if (! $returns[3]) {
		warn "evol ran out of time; maybe you have a slow cpu ?\n";
	}
}

undef $Math::Evol::ec;
@returns = &evol(\@x, \@sm, \&minimise, \&contain, 10);
$fail1 = 0;
foreach (@{$returns[0]}) {
	if (abs $_>0.0001) { if ($detailed) { warn "\$_ = $_\n"; } $fail1++; }
}
ok (!$fail1, "evol without absolute convergence criterion");
if ($detailed) {
	if ($fail1) { warn "subroutine &evol failed to find the minimum\n"; }
	foreach (@{$returns[1]}) {
		if (abs $_ > 0.0001) { warn "step size still $_\n"; $fail1++; }
	}
	if ($fail1) {
		warn "evol returns:\n x = ", join(", ", @{$returns[0]}), "\n";
		warn "sm = ", join(", ", @{$returns[1]}), "\n";
		warn "objective = $returns[2]\n";
		warn "success   = $returns[3]\n";
	}
	if (! $returns[3]) {
		warn "evol ran out of time; maybe you have a slow cpu ?\n";
	}
}

$Math::Evol::ec = 1e-16;
undef $Math::Evol::ed;
@returns = &evol(\@x, \@sm, \&minimise, \&contain, 10);
$fail1 = 0;
foreach (@{$returns[0]}) {
	if (abs $_>0.0001) { if ($detailed) { warn "\$_ = $_\n"; } $fail1++; }
}
ok (!$fail1, "evol without relative convergence criterion");
if ($detailed) {
	if ($fail1) { warn "subroutine &evol failed to find the minimum\n"; }
	foreach (@{$returns[1]}) {
		if (abs $_ > 0.0001) { warn "step size still $_\n"; $fail1++; }
	}
	if ($fail1) {
		warn "evol returns:\n x = ", join(", ", @{$returns[0]}), "\n";
		warn "sm = ", join(", ", @{$returns[1]}), "\n";
		warn "objective = $returns[2]\n";
		warn "success   = $returns[3]\n";
	}
	if (! $returns[3]) {
		warn "evol ran out of time; maybe you have a slow cpu ?\n";
	}
}

undef $Math::Evol::ec;
undef $Math::Evol::ed;
@returns = &evol(\@x, \@sm, \&minimise, \&contain, 2);
$fail1 = 0;
foreach (@{$returns[0]}) {
	if (abs $_>0.0001) { if ($detailed) { warn "\$_ = $_\n"; } $fail1++; }
}
ok (!$fail1, "evol with \$tm timelimit paramater");
ok (!$returns[3], "evol correctly reports timelimit exceeded");
if ($detailed) {
	if ($fail1) { warn "subroutine &evol failed to find the minimum\n"; }
	foreach (@{$returns[1]}) {
		if (abs $_ > 0.0001) { warn "step size still $_\n"; $fail1++; }
	}
	if ($fail1) {
		warn "evol returns:\n x = ", join(", ", @{$returns[0]}), "\n";
		warn "sm = ", join(", ", @{$returns[1]}), "\n";
		warn "objective = $returns[2]\n";
		warn "success   = $returns[3]\n";
	}
	if (! $returns[3]) {
		warn "evol ran out of time, as it's supposed to\n";
	}
}

# ----------------- test &select_evol --------------------
@returns = &select_evol( \@x, \@sm, \&choosebetter, 0, 1);
my $fail2 = 0;
foreach (@{$returns[0]}) {
	if (abs $_>0.001) { if ($detailed) { warn "\$_ = $_\n"; } $fail2++; }
}
ok (!$fail2, "select_evol");
if ($detailed) {
	if ($fail2) { warn "subroutine &select_evol failed to find the minimum\n"; }
	foreach (@{$returns[1]}) {
   	if (abs $_ > 0.001) { warn "step size still $_\n"; $fail2++; }
	}
	if ($fail2) {
   	warn "select_evol returns:\n x = ", join(", ", @{$returns[0]}), "\n";
   	warn "sm = ", join(", ", @{$returns[1]}), "\n";
	}
}

__END__

# needs a sub choosebettertext, RSN ...
# ----------------- third test &select_evol --------------------
my $new_text = &text_evol( $text, \&choosebettertext, 1);
my $fail3 = 0;
print "new_text = ...\n$new_text";
if ($fail3) {
   warn "select_evol returns:\n x = ", join(", ", @{$returns[0]}), "\n";
   warn "sm = ", join(", ", @{$returns[1]}), "\n";
} else {
   print "subroutine text_evol OK\n";
}

=pod

=head1 NAME

test.pl - Perl script to test Math::Evol.pm

=head1 SYNOPSIS

 perl test.pl

=head1 DESCRIPTION

This script tests Math::Evol.pm

=head1 AUTHOR

Peter J Billam <peter@pjb.com.au>

=head1 SEE ALSO

Math::Evol.pm , http://www.pjb.com.au/ , perl(1).

=cut

