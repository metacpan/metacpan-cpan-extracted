use strict;
use warnings FATAL => 'all';

package HTML::Tested::Test::Radio;
use base 'HTML::Tested::Test::Value';

sub _grep_my_vars {
	my ($class, $name, $stash) = @_;
	my @res;
	while (my ($n, $v) = each %$stash) {
		next unless $n =~ /^$name\_/;
		push @res, $n;
	}
	return @res;
}

sub check_stash {
	my ($class, $e_root, $name, $e_stash, $r_stash) = @_;
	my @err;
	for my $n ($class->_grep_my_vars($name, $e_stash)) {
		my $e_val = $e_stash->{$n};
		my $r_val = HTML::Tested::Test::Ensure_Value_To_Check(
				$r_stash, $n, $e_val, \@err);
		next unless defined($r_val);
		next if ($r_val eq $e_val);
		push @err, HTML::Tested::Test::Stash_Mismatch(
				$n, $r_val, $e_val);
	}

	for my $n ($class->_grep_my_vars($name, $r_stash)) {
		next if exists $e_stash->{$n};
		push @err, HTML::Tested::Test::Stash_Mismatch(
				$n, $r_stash->{$n}, undef);
	}
	return @err;
}

sub check_text {
	my ($class, $e_root, $name, $e_stash, $text) = @_;
	return map {
		$class->_check_text_i($e_root, $name, $e_stash->{$_}, $text)
	} $class->_grep_my_vars($name, $e_stash);
}

1;
