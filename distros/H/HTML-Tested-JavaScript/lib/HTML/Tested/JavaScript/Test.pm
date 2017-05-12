use strict;
use warnings FATAL => 'all';

package HTML::Tested::JavaScript::Test::Serializer::Array;
use base 'HTML::Tested::Test::Value';

sub handle_sealed {
	my ($class, $e_root, $name, $e_val, $r_val, $err) = @_;
	my @e;
	my @res = $class->SUPER::handle_sealed($e_root, $name
			, $e_val, $r_val, \@e);
	push @$err, @e if (@e && !(@{ $e_root->$name } == 0
					&& $e[0] =~ /wasn't sealed/));
	return @res;
}

sub convert_to_sealed {
	my ($self, $val) = @_;
	my $seal = HTML::Tested::Seal->instance;
	return [ map { $seal->encrypt($_) } @$val ];
}

sub convert_to_param {
	my ($class, $obj_class, $r, $name, $val) = @_;
	return $class->SUPER::convert_to_param($obj_class, $r, $name
			, join(",", @$val));
}

package HTML::Tested::JavaScript::Test::Serializer::Value;
use base 'HTML::Tested::Test::Value';

sub check_text {
	my ($class, $e_root, $name, $e_stash, $text) = @_;
	$e_stash->{$name} =~ s#/#\\/#g if $e_stash->{$name};
	return $class->SUPER::check_text($e_root, $name, $e_stash, $text);
}

package HTML::Tested::JavaScript::Test::Serializer;
use base 'HTML::Tested::Test::Value';
use Text::Diff;

sub _is_anyone_sealed {
	my ($class, $e_root, $js) = @_;
	return $class->SUPER::is_marked_as_sealed($e_root, $js);
	my $a = $e_root->{$js};
	return undef unless ref($a);
	for my $r (@$a) {
		next unless ref($r);
		for my $k (keys %$r) {
			return 1 if $class->_is_anyone_sealed($r, $k);
		}
	}
	return undef;
}

sub is_marked_as_sealed {
	my ($class, $e_root, $name) = @_;
	my $ser_widget = $e_root->ht_find_widget($name);
	for my $j (@{ $ser_widget->{_jses} }) {
		next unless $class->_is_anyone_sealed($e_root, $j);
		return 1;
	}
	return undef;
}

sub check_stash {
	my ($class, $e_root, $name, $e_stash, $r_stash) = @_;
	my @res = $class->SUPER::check_stash($e_root, $name
			, $e_stash, $r_stash);
	my ($ev, $rv) = ($e_stash->{$name}, $r_stash->{$name});
	$res[0] .= "\nThe diff is:\n" . diff(\$ev, \$rv)
			if (@res && $ev && $rv);
	return @res;
}

sub check_text {
	my ($class, $e_root, $name, $e_stash, $text) = @_;
	my @res = $class->SUPER::check_text($e_root, $name, $e_stash, $text);
	if (@res) {
		my $his = HTML::Tested::JavaScript::Serializer::Extract_Text(
				$name, $text);
		my $mine = HTML::Tested::JavaScript::Serializer::Extract_Text(
				$name, $e_stash->{$name});
		$res[0] .= $his ? "\nThe diff is:\n" . diff(\$mine, \$his)
				: "\nUnable to extract text for diff\n";
	}
	return @res;
}

package HTML::Tested::JavaScript::Test;
use HTML::Tested::Test qw(Register_Widget_Tester);
use HTML::Tested::JavaScript::Serializer;
use HTML::Tested::JavaScript::Serializer::Value;
use HTML::Tested::JavaScript::Serializer::Array;
use HTML::Tested::JavaScript::RichEdit;
use HTML::Tested::JavaScript::Test::RichEdit;

Register_Widget_Tester("HTML::Tested::JavaScript::Serializer::Array"
		, 'HTML::Tested::JavaScript::Test::Serializer::Array');
Register_Widget_Tester("HTML::Tested::JavaScript::Serializer::Value"
		, 'HTML::Tested::JavaScript::Test::Serializer::Value');
Register_Widget_Tester("HTML::Tested::JavaScript::Serializer"
		, 'HTML::Tested::JavaScript::Test::Serializer');
Register_Widget_Tester("HTML::Tested::JavaScript::RichEdit"
		, 'HTML::Tested::JavaScript::Test::RichEdit');

1;
