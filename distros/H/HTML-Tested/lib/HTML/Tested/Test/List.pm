use strict;
use warnings FATAL => 'all';

package HTML::Tested::Test::List;
use Carp;
use Math::Combinatorics;

sub _comp_stashes {
	my ($class, $er_arr, $r_arr, $e_arr) = @_;
	my @err;
	for (my $i = 0; $i < @$r_arr || $i < @$e_arr; $i++) {
		push @err, HTML::Tested::Test->compare_stashes(
				$er_arr->[$i], $r_arr->[$i], $e_arr->[$i]);
	}
	return @err;
}

sub check_stash {
	my ($class, $e_root, $name, $e_stash, $r_stash) = @_;
	my @err;
	goto OUT unless exists($e_stash->{$name});

	my $e_arr = $e_stash->{$name};
	my $r_arr = HTML::Tested::Test::Ensure_Value_To_Check(
			$r_stash, $name, $e_arr, \@err);
	return @err if (!defined($r_arr) || @err);
	return $class->_comp_stashes($e_root->$name, $r_arr, $e_arr)
		unless $e_root->{"__HT_UNSORTED__$name"};

	my @rrs = permute(@$r_arr);
	for (my $i = 0; $i < @rrs; $i++) {
		@err = $class->_comp_stashes($e_root->$name, $rrs[$i], $e_arr);
		return () if !@err;
	}
	return @err;
};

sub check_text {
	my ($class, $e_root, $name, $e_stash, $text) = @_;
	return () unless exists $e_stash->{$name};
	my $expected = $e_stash->{$name};
	my @err;
	for (my $i = 0; $i < @$expected; $i++) {
		push @err, HTML::Tested::Test->compare_text_to_stash(
				$e_root->$name->[$i],
				$text, $expected->[$i]);
	}
	return @err;
}

sub bless_from_tree {
	my ($class, $w_class, $p, $err) = @_;
	my $target = $w_class->containee;
	confess $w_class->name . " should be ARRAY reference"
		unless ($p && ref($p) eq 'ARRAY');
	return [ map { HTML::Tested::Test->bless_from_tree_for_test($target
				, $_, $err); } @$p ];
}

sub convert_to_param {
	my ($class, $obj_class, $r, $name, $val) = @_;
	my $c = $obj_class->containee;
	HTML::Tested::Test->convert_tree_to_param(
		$c, $r, $val->[$_ - 1], $name . "__$_") for (1 .. @$val);
}

1;
