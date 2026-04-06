use strict;
use warnings;
use Test::More tests => 4;
use Eshu;

# Basic pod section
{
	my $input = <<'END';
sub foo {
my $x = 1;
}

=head1 NAME

My::Module - a module

=cut

sub bar {
my $y = 2;
}
END

	my $expected = <<'END';
sub foo {
	my $x = 1;
}

=head1 NAME

My::Module - a module

=cut

sub bar {
	my $y = 2;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'pod section preserved verbatim');
}

# Pod with braces in content
{
	my $input = <<'END';
=head1 DESCRIPTION

This uses C<{ braces }> and L<stuff>.

=cut

sub foo {
my $x = 1;
}
END

	my $expected = <<'END';
=head1 DESCRIPTION

This uses C<{ braces }> and L<stuff>.

=cut

sub foo {
	my $x = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'pod with braces in content');
}

# Pod at end of file (no =cut)
{
	my $input = <<'END';
sub foo {
my $x = 1;
}

=head1 AUTHOR

Someone

END

	my $expected = <<'END';
sub foo {
	my $x = 1;
}

=head1 AUTHOR

Someone

END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'pod at end of file');
}

# Multiple pod sections
{
	my $input = <<'END';
    sub foo {
        return 1;
    }

=head1 NAME

Foo

=cut

    sub bar {
        return 2;
    }

=head1 METHODS

=head2 bar

=cut

sub baz {
return 3;
}
END

	my $expected = <<'END';
sub foo {
	return 1;
}

=head1 NAME

Foo

=cut

sub bar {
	return 2;
}

=head1 METHODS

=head2 bar

=cut

sub baz {
	return 3;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'multiple pod sections');
}
