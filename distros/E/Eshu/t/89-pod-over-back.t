use strict;
use warnings;
use Test::More tests => 5;
use Eshu;

# Basic over/back
{
	my $input = <<'END';
=head1 OPTIONS

=over 4

=item --verbose

Enable verbose output.

=item --help

Show help message.

=back

=cut
END

	my $expected = <<'END';
=head1 OPTIONS

=over 4

=item --verbose

Enable verbose output.

=item --help

Show help message.

=back

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, 'over/back with items');
}

# Nested over/back
{
	my $input = <<'END';
=over 4

=item Level 1

=over 4

=item Level 2

=back

=back

=cut
END

	my $expected = <<'END';
=over 4

=item Level 1

=over 4

=item Level 2

=back

=back

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, 'nested over/back');
}

# Over/back with code examples
{
	my $input = <<'END';
=over 4

=item Example

    my $x = 1;
    my $y = 2;

=back

=cut
END

	my $expected = <<'END';
=over 4

=item Example

	my $x = 1;
	my $y = 2;

=back

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, 'code examples inside over/back');
}

# Over/back in Perl source
{
	my $input = <<'END';
sub process {
my $self = shift;
}

=head1 METHODS

=over 4

=item process()

Process the data.

    $obj->process();

=back

=cut

sub run {
my $self = shift;
}
END

	my $expected = <<'END';
sub process {
	my $self = shift;
}

=head1 METHODS

=over 4

=item process()

Process the data.

	$obj->process();

=back

=cut

sub run {
	my $self = shift;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'over/back in Perl source file');
}

# 3-level nested over/back
{
	my $input = <<'END';
=over 4

=item Level 1

=over 4

=item Level 2

=over 4

=item Level 3

Deep item text.

=back

=back

=back

=cut
END

	my $expected = <<'END';
=over 4

=item Level 1

=over 4

=item Level 2

=over 4

=item Level 3

Deep item text.

=back

=back

=back

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, '3-level nested over/back');
}
