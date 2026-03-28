use strict;
use warnings;
use Test::More tests => 5;
use Eshu;

# Basic POD directives at column 0
{
	my $input = <<'END';
=head1 NAME

My::Module - a module

=head1 DESCRIPTION

This is a description.

=cut
END

	my $expected = <<'END';
=head1 NAME

My::Module - a module

=head1 DESCRIPTION

This is a description.

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, 'basic POD directives stay at column 0');
}

# POD with indented directives (directives go to column 0, text with
# leading whitespace treated as verbatim per POD spec)
{
	my $input = <<'END';
   =head1 NAME

   My::Module - a module

   =cut
END

	my $expected = <<'END';
=head1 NAME

	My::Module - a module

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, 'indented directives normalized, indented text is verbatim');
}

# All directive types
{
	my $input = <<'END';
=pod

=head1 HEADING ONE

=head2 HEADING TWO

=head3 HEADING THREE

=head4 HEADING FOUR

=over 4

=item * First

=item * Second

=back

=encoding utf8

=cut
END

	my $expected = <<'END';
=pod

=head1 HEADING ONE

=head2 HEADING TWO

=head3 HEADING THREE

=head4 HEADING FOUR

=over 4

=item * First

=item * Second

=back

=encoding utf8

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, 'all directive types preserved at column 0');
}

# Empty POD
{
	my $input = <<'END';
=pod

=cut
END

	my $expected = <<'END';
=pod

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, 'empty POD section');
}

# Detect .pod extension
{
	my $lang = Eshu->detect_lang('Module.pod');
	is($lang, 'pod', 'detect_lang returns pod for .pod files');
}
