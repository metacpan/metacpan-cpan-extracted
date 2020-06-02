package Mail::MtPolicyd::Plugin;

use Moose;
use namespace::autoclean;

our $VERSION = '2.04'; # VERSION
# ABSTRACT: a base class for plugins


has 'name' => ( is => 'rw', isa => 'Str', required => 1 );
has 'log_level' => ( is => 'ro', isa => 'Int', default => 4 );
has 'vhost_name' => ( is => 'ro', isa => 'Maybe[Str]' );

has 'on_error' => ( is => 'ro', isa => 'Maybe[Str]' );


sub run {
	my ( $self, $r ) = @_;
	die('plugin did not implement run method!');
}

sub log {
	my ($self, $r, $msg) = @_;
	if( defined $self->vhost_name ) {
		$msg = $self->vhost_name.': '.$msg;
	}
	$r->log($self->log_level, $msg);

	return;
}

sub init {
    return;
}

sub cron {
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Plugin - a base class for plugins

=head1 VERSION

version 2.04

=head1 ATTRIBUTES

=head2 name

Contains a string with the name of this plugin as specified in the configuration.

=head2 log_level (default: 4)

The log_level used when the plugin calls $self->log( $r, $msg ).

=head1 METHODS

=head2 run( $r )

This method has be implemented by the plugin which inherits from this base class.

=head2 log( $r, $msg )

This method could be used by the plugin to log something.

Since this is mostly for debugging the default is to log plugin specific
messages with log_level=4. (see log_level attribute)

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
