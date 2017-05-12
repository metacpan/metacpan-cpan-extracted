package Log::Saftpresse::Plugin::LinuxNetfilter;

use Moose;

# ABSTRACT: plugin to parse network packets logged by linux/netfilter
our $VERSION = '1.6'; # VERSION

extends 'Log::Saftpresse::Plugin';

with 'Log::Saftpresse::Plugin::Role::CounterUtils';

sub process {
	my ( $self, $stash ) = @_;
	my $program = $stash->{'program'};
	if( ! defined $program || $program ne 'kernel' ) {
		return;
	}

	my ( $prefix, $msg ) =
		$stash->{'message'} =~ /^\[\d+\.\d+\] ([^:]+): (IN=\S* OUT=\S* .+) ?$/;

	if( ! defined $prefix ) {
		return;
	}

	my %values = map {
		my ( $key, $value ) = split('=', $_, 2);
		defined $value && $value ne '' ? ( lc($key) => $value ) : ();
	} split(' ', $msg);

	$stash->{'prefix'} = $prefix;
	@$stash{ keys %values } = values %values;

	$self->count_fields_occur( $stash, 'prefix' );

	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Plugin::LinuxNetfilter - plugin to parse network packets logged by linux/netfilter

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
