use strict;
use warnings FATAL => 'all';

package HTML::Tested::Test;
use base 'Exporter';
use Data::Dumper;
use Text::Diff;
use Carp;

our @EXPORT_OK = qw(Register_Widget_Tester Stash_Mismatch Ensure_Value_To_Check);

sub Stash_Mismatch {
	my ($n, $res, $v) = @_;
	my $ret = sprintf("Mismatch at %s: got %s, expected %s",
				$n, defined($res) ? "\"$res\"" : "undef",
				defined($v) ? "\"$v\"" : "undef");
	goto OUT unless (defined($res) && defined($v)
		&& $res =~ /\n.*\n/ms && $v =~ /\n.*\n/ms);
	$ret .= ". The diff is\n" . diff(\$v, \$res);
OUT:
	return $ret;
}

sub Ensure_Value_To_Check {
	my ($r_stash, $name, $e_val, $errs) = @_;
	my $r_val = $r_stash->{$name};
	return if (!defined($r_val) && !defined($e_val));

	if (defined($r_val) xor defined($e_val)) {
		push @$errs, Stash_Mismatch($name, $r_val, $e_val);
		return;
	}
	return $r_val;
}

sub compare_stashes {
	my ($class, $e_root, $stash, $e_stash) = @_;
	return () if (!defined($stash) && !defined($e_stash));
	if (defined($stash) xor defined($e_stash)) {
		return ("Stash " . Dumper($stash)
				. "differ from "
				. "expected " . Dumper($e_stash));
	}
	return $class->_run_checks('stash', $e_root, $stash, $e_stash);
}

sub _run_checks {
	my ($class, $check, $e_root, $res, $e_stash) = @_;
	my $f = "check_$check";
	return map {
		$_->__ht_tester->$f($e_root, $_->name, $e_stash, $res);
	} @{ $e_root->Widgets_List };
}

sub compare_text_to_stash {
	my ($class, $e_root, $text, $e_stash) = @_;
	return $class->_run_checks('text', $e_root, $text, $e_stash);
}

my $_index = 0;

sub Make_Expected_Class {
	my ($target_class, $expected) = @_;
	my $package = "$target_class\::__HT_TESTER_" . $_index++;
	{ 
		no strict 'refs';
		push @{ *{ "$package\::ISA" } }, $target_class 
			unless @{ *{ "$package\::ISA" } };
	};
	my $wl = $target_class->Widgets_List;
	$package->Widgets_List([ grep {
		exists($expected->{ $_->name });
	} @$wl ]);
	return $package;
}

sub bless_unknown_widget {
	my ($class, $n, $v, $err) = @_;
	push @$err, "Unknown widget $n found in expected!";
	return $v;
}
	 
sub bless_from_tree_for_test {
	my ($class, $target, $expected, $err) = @_;
	my $res = {};
	my (@disabled, %e, @reverted, @sealed, @unsorted);
	while (my ($n, $v) = each %$expected) {
		my $rev = ($n =~ s/^HT_NO_//);
		my $sealed = ($n =~ s/^HT_SEALED_//);
		my $unsorted = ($n =~ s/^HT_UNSORTED_//);
		push @reverted, $n if $rev;
		push @sealed, $n if $sealed;
		push @unsorted, $n if $unsorted;
		$e{$n} = $v;
	}
	$expected = \%e;

	my $e_class = Make_Expected_Class($target, $expected);
	while (my ($n, $v) = each %$expected) {
		if (defined($v) && !ref($v) && $v eq 'HT_DISABLED') {
			push @disabled, $n;
			next;
		}
		my $wc = $e_class->ht_find_widget($n);
		$res->{$n} = $wc ?
			$wc->__ht_tester->bless_from_tree($wc, $v, $err)
			: $class->bless_unknown_widget($n, $v, $err);
	}
	my $e_root = bless($res, $e_class);
	$e_root->ht_set_widget_option($_, "is_disabled", 1) for @disabled;
	$e_root->{"__HT_REVERTED__$_"} = 1 for @reverted;
	$e_root->{"__HT_SEALED__$_"} = 1 for @sealed;
	$e_root->{"__HT_UNSORTED__$_"} = 1 for @unsorted;
	return $e_root;
}

sub do_comparison {
	my ($class, $compare, $obj_class, $stash, $expected) = @_;
	my $e_stash = {};
	my @res;
	my $e_root = $class->bless_from_tree_for_test($obj_class
			, $expected, \@res);
	$e_root->_ht_render_i($e_stash);

	push @res, $class->$compare($e_root, $stash, $e_stash);
	return @res;
}

sub check_stash { return shift()->do_comparison('compare_stashes', @_); }
sub check_text {
	return shift()->do_comparison('compare_text_to_stash', @_);
}

=head2 Register_Widget_Tester($widget_class, $tester_class)

Registers C<$tester_class> as tester for C<$widget_class>.

=cut
sub Register_Widget_Tester {
	my ($w_class, $t_class) = @_;
	no strict 'refs';
	*{ "$w_class\::__ht_tester" } = sub { return $t_class; };
}

sub _tree_to_param_fallback {
	my ($class, $n) = @_;
	confess "Unable to find widget for $n";
}

sub convert_tree_to_param {
	my ($class, $obj_class, $r, $tree, $parent_name) = @_;
	while (my ($n, $v) = each %$tree) {
		my $sealit = ($n =~ s/^HT_SEALED_//);
		my $wc = $obj_class->ht_find_widget($n);
		if ($wc) {
			$v = $wc->__ht_tester->convert_to_sealed($v) if $sealit;
			$wc->__ht_tester->convert_to_param($wc, $r, 
				$parent_name ? $parent_name . "__$n" : $n, $v);
		} else {
			$class->_tree_to_param_fallback($n);
		}
	}
}

my %_testers = qw(HTML::Tested::Value HTML::Tested::Test::Value
	HTML::Tested::Value::Upload HTML::Tested::Test::Upload
	HTML::Tested::Value::Radio HTML::Tested::Test::Radio
	HTML::Tested::List HTML::Tested::Test::List);
while (my ($n, $v) = each %_testers) {
	eval "use $n; use $v;";
	die "Unable to use $n or use $v" if $@;
	Register_Widget_Tester($n, $v);
}

1;
