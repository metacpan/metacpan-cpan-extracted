package Log::Saftpresse::CounterOutputs;

use Moose;

# ABSTRACT: class to manage saftpresse counter output
our $VERSION = '1.6'; # VERSION

extends 'Log::Saftpresse::PluginContainer';

has 'plugin_prefix' => ( is => 'ro', isa => 'Str',
	default => 'Log::Saftpresse::CountersOutput::',
);

sub output {
	my ( $self, @events ) = @_;

	foreach my $plugin ( @{$self->plugins} ) {
		$plugin->output( @events );
	}

	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::CounterOutputs - class to manage saftpresse counter output

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
