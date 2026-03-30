use strict;
use warnings;
use Test::More tests => 5;
use Eshu;

# Code example with inconsistent indentation normalized
{
	my $input = <<'END';
=head1 SYNOPSIS

    my $obj = My::Module->new();
        $obj->do_something();
      $obj->finish();

=cut
END

	my $expected = <<'END';
=head1 SYNOPSIS

	my $obj = My::Module->new();
	    $obj->do_something();
	  $obj->finish();

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, 'code examples preserve relative indentation');
}

# Code example with tab indentation
{
	my $input = <<'END';
=head1 EXAMPLE

		my $x = 1;
		my $y = 2;

=cut
END

	my $expected = <<'END';
=head1 EXAMPLE

	my $x = 1;
	my $y = 2;

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, 'tab-indented code examples normalized');
}

# Mixed text and code
{
	my $input = <<'END';
=head1 DESCRIPTION

This module does things.

    use My::Module;
    my $m = My::Module->new;

And then more text.

    $m->run;

=cut
END

	my $expected = <<'END';
=head1 DESCRIPTION

This module does things.

	use My::Module;
	my $m = My::Module->new;

And then more text.

	$m->run;

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, 'mixed text and code blocks');
}

# Code example in Perl file POD
{
	my $input = <<'END';
sub foo {
return 1;
}

=head1 SYNOPSIS

    use My::Module;
    my $obj = My::Module->new;

=cut

sub bar {
return 2;
}
END

	my $expected = <<'END';
sub foo {
	return 1;
}

=head1 SYNOPSIS

	use My::Module;
	my $obj = My::Module->new;

=cut

sub bar {
	return 2;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'code examples in Perl file POD normalized');
}

# Code example with single space indent
{
	my $input = <<'END';
=head1 EXAMPLE

 my $x = 1;
 my $y = 2;

=cut
END

	my $expected = <<'END';
=head1 EXAMPLE

	my $x = 1;
	my $y = 2;

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, 'single space indent code normalized to one level');
}
