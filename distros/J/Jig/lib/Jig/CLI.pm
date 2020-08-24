package Jig::CLI;

use Getopt::Long qw/GetOptionsFromArray :config require_order/;

use base 'Exporter';
our @EXPORT = qw/cli/;

sub _process {
	my ($flags, $subs, $args, $cmd, $opts) = @_;
	my $ignored = GetOptionsFromArray($args, $opts, @{ $flags || [] });

	if (@$args) {
		for my $sub (keys %$subs) {
			next unless $sub eq $args->[0];
			push @$cmd, $args->[0]; shift @$args;
			my ($new_flags, %subs) = @{ $subs->{$sub} || [] };
			return _process([@$flags, @{$new_flags || []}], \%subs, $args, $cmd, $opts);
		}
	}
	return;
}

sub cli {
	my ($spec, @args) = @_;
	my ($flags, %subs) = @$spec;
	@args = @ARGV if @_ == 1;

	my (%opts, @cmd);
	_process($flags, \%subs, \@args, \@cmd, \%opts);
	join(' ', @cmd), \%opts, \@args;
}

1;
