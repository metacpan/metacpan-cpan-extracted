#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Getopt::Long ();

use Game::Terminal;

plan skip_all => 'Author tests not required for installation' unless $ENV{RELEASE_TESTING};

my %pinned;
{
	open my $fh, '<', 'Makefile.PL' or die $!;
	while (my $line = <$fh>) {
		$pinned{$1} = $2 if $line =~ m/^\s*'((?:Game|Term)::\w+)'\s*=>\s*'([\d.]+)'/;
	}
}

my %seen;
for my $row (Game::Terminal::games()) {
	next if $seen{$row->{class}}++;
	subtest $row->{class} => sub {
		plan tests => 10;
		my $class = eval { Game::Terminal::load($row) };
		ok $class, "loads" or diag $@;
		ok $class && $class->can('run'), 'has run'
			or return diag "no run, so nothing more can be asked of $row->{class}";
		(my $file = "$row->{module}.pm") =~ s{::}{/}g;
		eval { require $file };
		my $version = do { no strict 'refs'; ${"$row->{module}::VERSION"} };
		cmp_ok $version, '>=', $pinned{$row->{module}}, "$row->{module} $version is at least the pinned $pinned{$row->{module}}";

		my $getopt = Getopt::Long::Configure('default');
		Getopt::Long::Configure($getopt);
		my @layers = PerlIO::get_layers(\*STDOUT);
		my @sig = @SIG{qw(INT TERM HUP)};

		my ($help, $bad) = ('', '');
		my ($help_status, $bad_status);
		{
			open my $out, '>', \$help or die $!;
			local *STDOUT = $out;
			$help_status = eval { $class->run('--help') };
			diag $@ if $@;
		}
		{
			open my $err, '>', \$bad or die $!;
			local *STDERR = $err;
			local *STDOUT = $err;
			$bad_status = eval { $class->run('--no-such-option') };
			diag $@ if $@;
		}
		is $help_status, 0, '--help returns 0';
		is $bad_status, 2, 'a bad option returns 2';

		my $after = Getopt::Long::Configure('default');
		Getopt::Long::Configure($after);
		is_deeply [ @{$after}[1 .. $#{$after}] ], [ @{$getopt}[1 .. $#{$getopt}] ],
			'the Getopt configuration is as it was (the first element is the last parse error count, not a setting)';
		is_deeply [ PerlIO::get_layers(\*STDOUT) ], \@layers, 'STDOUT has the layers it had';
		is_deeply [ @SIG{qw(INT TERM HUP)} ], \@sig, 'and the handlers are as they were';

		my $fields = Game::Terminal::options_for($row);
		ok $class->can('options'), 'has options';
		is_deeply [Game::Terminal::Kit::Options::validate($fields)], [], 'and its fields are sound';
	};
}

done_testing;
