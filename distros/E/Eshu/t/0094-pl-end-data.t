use strict;
use warnings;
use Test::More tests => 7;
use Eshu;

# __END__ stops Perl parsing
{
	my $input = <<'END';
package Foo;
use strict;
sub hello {
print "hi\n";
}
1;
__END__

This is some text after __END__.
It should not be indented.
END

	my $expected = <<'END';
package Foo;
use strict;
sub hello {
	print "hi\n";
}
1;
__END__

This is some text after __END__.
It should not be indented.
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, '__END__ stops Perl processing');
}

# __DATA__ stops Perl parsing
{
	my $input = <<'END';
package Bar;
sub load {
my $data = <DATA>;
return $data;
}
1;
__DATA__
key1=value1
key2=value2
key3=value3
END

	my $expected = <<'END';
package Bar;
sub load {
	my $data = <DATA>;
	return $data;
}
1;
__DATA__
key1=value1
key2=value2
key3=value3
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, '__DATA__ stops Perl processing');
}

# __END__ with POD after it
{
	my $input = <<'END';
package Baz;
sub test {
return 1;
}
1;
__END__

=head1 NAME

Baz - A test module

=head1 SYNOPSIS

    my $baz = Baz->new;
    $baz->test;

=cut
END

	my $expected = <<'END';
package Baz;
sub test {
	return 1;
}
1;
__END__

=head1 NAME

Baz - A test module

=head1 SYNOPSIS

	my $baz = Baz->new;
	$baz->test;

=cut
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'POD after __END__ is handled correctly');
}

# __END__ with plain text containing braces
{
	my $input = <<'END';
sub process {
my $x = 1;
}
1;
__END__

Example JSON:
{
  "name": "test",
  "nested": {
    "key": "value"
  }
}

More text here.
END

	my $expected = <<'END';
sub process {
	my $x = 1;
}
1;
__END__

Example JSON:
{
  "name": "test",
  "nested": {
    "key": "value"
  }
}

More text here.
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'braces after __END__ do not affect depth');
}

# __END__ idempotency
{
	my $input = <<'END';
package Qux;
sub new {
	return bless {}, shift;
}
1;
__END__

=head1 DESCRIPTION

Some description.

=cut
END

	my $got = Eshu->indent_pl($input);
	is($got, $input, '__END__ with POD is idempotent');
}

# __DATA__ with mixed content
{
	my $input = <<'END';
package DataMod;
use strict;
sub read_data {
local $/;
my $data = <DATA>;
return $data;
}
1;
__DATA__
{ this has braces }
sub fake_code {
    not really code;
}
$var = 1;
END

	my $expected = <<'END';
package DataMod;
use strict;
sub read_data {
	local $/;
	my $data = <DATA>;
	return $data;
}
1;
__DATA__
{ this has braces }
sub fake_code {
    not really code;
}
$var = 1;
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, '__DATA__ with code-like content not parsed as Perl');
}

# __END__ not at column 0 is not treated as end marker
{
	my $input = <<'END';
sub test {
my $s = "__END__";
return $s;
}
END

	my $expected = <<'END';
sub test {
	my $s = "__END__";
	return $s;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, '__END__ inside string not treated as end marker');
}
