package Mail::MtPolicyd::VirtualHost;

use Moose;
use namespace::autoclean;

our $VERSION = '2.02'; # VERSION
# ABSTRACT: class for a VirtualHost instance

use Mail::MtPolicyd::PluginChain;

has 'port' => ( is => 'ro', isa => 'Str', required => 1 );
has 'name' => ( is => 'ro', isa => 'Str', required => 1 );

has 'chain' => (
	is => 'ro',
	isa => 'Mail::MtPolicyd::PluginChain',
	required => 1,
	handles => [ 'run' ],
);

sub new_from_config {
	my ( $class, $port, $config ) = @_;

	if( ! defined $config->{'Plugin'} ) {
		die('no <Plugin> defined for <VirtualHost> on port '.$port.'!');
	}
	my $vhost = $class->new(
		'port' => $port,
		'name' => $config->{'name'},
		'chain' => Mail::MtPolicyd::PluginChain->new_from_config(
			$config->{'name'},
			$config->{'Plugin'}
		),
	);

	return $vhost;
}

sub cron {
    my $self = shift;
    return $self->chain->cron(@_);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::VirtualHost - class for a VirtualHost instance

=head1 VERSION

version 2.02

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
