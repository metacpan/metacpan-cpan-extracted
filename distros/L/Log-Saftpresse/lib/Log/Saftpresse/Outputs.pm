package Log::Saftpresse::Outputs;

use Moose;

# ABSTRACT: class to manage saftpresse outputs
our $VERSION = '1.6'; # VERSION

extends 'Log::Saftpresse::PluginContainer';

has 'plugin_prefix' => ( is => 'ro', isa => 'Str',
	default => 'Log::Saftpresse::Output::',
);

use Log::Saftpresse::Log4perl;

sub output {
	my ( $self, @events ) = @_;

	foreach my $plugin ( @{$self->plugins} ) {
		eval { $plugin->output( @events ) };
		if( $@ ) {
			$log->error('error writing event to plugin '.$plugin->name.': '.$@);
		}
	}

	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Outputs - class to manage saftpresse outputs

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
