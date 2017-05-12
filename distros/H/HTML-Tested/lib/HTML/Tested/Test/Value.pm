use strict;
use warnings FATAL => 'all';

package HTML::Tested::Test::Value;
use HTML::Tested::Test qw(Ensure_Value_To_Check Stash_Mismatch);

sub _replace_sealed {
	my ($class, $val) = @_;
	my $s = HTML::Tested::Seal->instance;
	$val =~ s#([0-9a-f]{16}[0-9a-f]*)#$s->decrypt($1) // 'ENCRYPTED'#eg;
	return $val;
}

=head2 $class->is_marked_as_sealed($e_root, $name)

Checks whether variable C<$name> was marked as HT_SEALED.

=cut
sub is_marked_as_sealed {
	my ($class, $e_root, $name) = @_;
	return $e_root->{"__HT_SEALED__$name"};
}

=head2 $class->handle_sealed($e_root, $name, $e_val, $r_val, $err)

Is called to handle sealed value if needed.

=cut
sub handle_sealed {
	my ($class, $e_root, $name, $e_val, $r_val, $err) = @_;
	if ($class->is_marked_as_sealed($e_root, $name)) {
		my $orig_r_val = $r_val;
		$e_val = $class->_replace_sealed($e_val);
		$r_val = $class->_replace_sealed($r_val);
		push @$err, "$name wasn't sealed $r_val"
			if (($orig_r_val eq $r_val)
					&& !$e_root->{"__HT_REVERTED__$name"});
	} elsif ($e_root->ht_get_widget_option($name, "is_sealed")) {
		push @$err, "HT_SEALED was not defined on $name";
	}
	return ($e_val, $r_val);
}

sub _is_equal {
	my ($class, $e_val, $cb) = @_;
	return 1 if $cb->($e_val);
	return undef unless ($e_val =~ /(\$VAR1 = \[.*\];)/ms);

	my $arr_str = $1;
	my $VAR1;
	eval $arr_str;
	die $@ if $@;
	for (@$VAR1) {
		my $ev = $e_val;
		$ev =~ s#\$VAR1 = \[.*\];\n#$_#ms;
		return 1 if $cb->($ev);
	}
	return undef;
}

sub check_stash {
	my ($class, $e_root, $name, $e_stash, $r_stash) = @_;
	my @err;
	goto OUT unless exists($e_stash->{$name});

	my $e_val = $e_stash->{$name};
	my $r_val = Ensure_Value_To_Check($r_stash, $name, $e_val, \@err);
	goto OUT unless defined($r_val);

	($e_val, $r_val) = $class->handle_sealed($e_root, $name
					, $e_val, $r_val, \@err);
	goto OUT if (@err || $class->_is_equal($e_val
				, sub { $r_val eq $_[0]; }));
	@err = Stash_Mismatch($name, $r_val, $e_val);
OUT:
	return @err;
}

sub bless_from_tree {
	my $class = shift;
	return shift()->bless_from_tree(@_);
}

sub _check_text_i {
	my ($class, $e_root, $name, $v, $text) = @_;
	return () unless defined($v);
	my @ret;
	($v, $text) = $class->handle_sealed($e_root, $name, $v, $text, \@ret);

	my $ok = $class->_is_equal($v, sub { index($text, $_[0]) != -1; });
	return ("Unexpectedly found \"$v\" in \"$text\"")
		if ($ok && $e_root->{"__HT_REVERTED__$name"});
	return ("Unable to find \"$v\" in \"$text\"")
		if (!$ok && !$e_root->{"__HT_REVERTED__$name"});
	return ();
}

sub check_text {
	my ($class, $e_root, $name, $e_stash, $text) = @_;
	return $class->_check_text_i($e_root, $name,
			, $e_stash->{$name}, $text);
}

sub convert_to_param {
	my ($class, $obj_class, $r, $name, $val) = @_;
	$r->param($name, $val);
}

sub convert_to_sealed {
	my ($class, $val) = @_;
	return HTML::Tested::Seal->instance->encrypt($val);
}

1;
