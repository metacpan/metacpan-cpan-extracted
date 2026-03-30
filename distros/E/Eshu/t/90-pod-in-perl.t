use strict;
use warnings;
use Test::More tests => 5;
use Eshu;

# POD at start of file
{
	my $input = <<'END';
=head1 NAME

Foo - a module

=head1 SYNOPSIS

    use Foo;

=cut

package Foo;
sub new {
my $class = shift;
return bless {}, $class;
}
1;
END

	my $expected = <<'END';
=head1 NAME

Foo - a module

=head1 SYNOPSIS

	use Foo;

=cut

package Foo;
sub new {
	my $class = shift;
	return bless {}, $class;
}
1;
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'POD at start of Perl file');
}

# POD at end of file (no =cut)
{
	my $input = <<'END';
package Foo;
sub new {
my $class = shift;
return bless {}, $class;
}
1;

=head1 NAME

Foo - a module

=head1 SYNOPSIS

    use Foo;
    my $f = Foo->new;

END

	my $expected = <<'END';
package Foo;
sub new {
	my $class = shift;
	return bless {}, $class;
}
1;

=head1 NAME

Foo - a module

=head1 SYNOPSIS

	use Foo;
	my $f = Foo->new;

END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'POD at end of file with code examples');
}

# Multiple POD sections with code examples
{
	my $input = <<'END';
sub alpha {
return 'a';
}

=head1 METHODS

=head2 alpha

    my $a = $obj->alpha;

=cut

sub beta {
return 'b';
}

=head2 beta

    my $b = $obj->beta;

=cut

sub gamma {
return 'g';
}
END

	my $expected = <<'END';
sub alpha {
	return 'a';
}

=head1 METHODS

=head2 alpha

	my $a = $obj->alpha;

=cut

sub beta {
	return 'b';
}

=head2 beta

	my $b = $obj->beta;

=cut

sub gamma {
	return 'g';
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'multiple POD sections with code examples');
}

# POD with =begin/=end
{
	my $input = <<'END';
=head1 EXAMPLES

=begin text

    This is preformatted text.
      Indented more.

=end text

=cut
END

	my $expected = <<'END';
=head1 EXAMPLES

=begin text

	This is preformatted text.
	  Indented more.

=end text

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, 'POD with =begin/=end blocks preserves relative indent');
}

# indent_string with lang=pod
{
	my $input = <<'END';
=head1 NAME

Test

    my $code = 1;

=cut
END

	my $expected = <<'END';
=head1 NAME

Test

	my $code = 1;

=cut
END

	my $got = Eshu->indent_string($input, lang => 'pod');
	is($got, $expected, 'indent_string dispatches to POD');
}
