use strict;
use warnings;
use Test::More tests => 6;
use Eshu;

# Verbatim block preserves relative indentation
{
	my $input = <<'END';
=head1 SYNOPSIS

    my $app = Chandra::App->new(
        handler => sub {
            my ($app) = @_;
            $app->title('Hello');
        }
    );
    $app->run;

=cut
END

	my $expected = <<'END';
=head1 SYNOPSIS

	my $app = Chandra::App->new(
	    handler => sub {
	        my ($app) = @_;
	        $app->title('Hello');
	    }
	);
	$app->run;

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, 'verbatim block preserves relative indent (nested sub)');
}

# Multiple indent levels in verbatim
{
	my $input = <<'END';
=head1 EXAMPLE

    level1
        level2
            level3
        level2
    level1

=cut
END

	my $expected = <<'END';
=head1 EXAMPLE

	level1
	    level2
	        level3
	    level2
	level1

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, 'multiple indent levels preserved');
}

# Two separate verbatim blocks
{
	my $input = <<'END';
=head1 EXAMPLES

First example:

    my $x = 1;
    my $y = 2;

Second example:

    if ($cond) {
        do_thing();
    }

=cut
END

	my $expected = <<'END';
=head1 EXAMPLES

First example:

	my $x = 1;
	my $y = 2;

Second example:

	if ($cond) {
	    do_thing();
	}

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, 'two separate verbatim blocks each preserve relative indent');
}

# Verbatim with tabs in original
{
	my $input = <<'END';
=head1 CODE

	line_at_one_tab
		line_at_two_tabs
	line_at_one_tab

=cut
END

	my $expected = <<'END';
=head1 CODE

	line_at_one_tab
	    line_at_two_tabs
	line_at_one_tab

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, 'verbatim with tabs preserves relative indent');
}

# Verbatim block idempotency
{
	my $input = <<'END';
=head1 SYNOPSIS

	my $obj = Foo->new(
	    bar => 1,
	    baz => sub {
	        return 42;
	    },
	);

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $input, 'verbatim block is idempotent');
}

# Deep nesting in verbatim
{
	my $input = <<'END';
=head1 CONFIG

    my %config = (
        database => {
            host => 'localhost',
            port => 5432,
            options => {
                timeout => 30,
                retry => 1,
            },
        },
    );

=cut
END

	my $expected = <<'END';
=head1 CONFIG

	my %config = (
	    database => {
	        host => 'localhost',
	        port => 5432,
	        options => {
	            timeout => 30,
	            retry => 1,
	        },
	    },
	);

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, 'deep nesting in verbatim block preserved');
}
