package Mail::MtPolicyd::Result;

use Moose;
use namespace::autoclean;

our $VERSION = '2.02'; # VERSION
# ABSTRACT: class to hold the results of a request returned by plugins

has 'plugin_results' => (
	is => 'ro',
	isa => 'ArrayRef[Mail::MtPolicyd::Plugin::Result]',
	lazy => 1,
	default => sub { [] },
	traits => [ 'Array' ],
	handles => {
		'add_plugin_result' => 'push',
	},
);

has 'last_match' => ( is => 'rw', isa => 'Maybe[Str]' );

sub actions {
	my $self = shift;
	return map {
		defined $_->action ? $_->action : ()
	} @{$self->plugin_results};
}

sub as_log {
	my $self = shift;
	return join(',', $self->actions);
}

sub as_policyd_response {
	my $self = shift;
	my @actions = $self->actions;
	if( ! @actions ) {
		# we have nothing to say
		return("action=dunno\n\n");
	}
	return('action='.join("\naction=", @actions)."\n\n");
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Result - class to hold the results of a request returned by plugins

=head1 VERSION

version 2.02

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
