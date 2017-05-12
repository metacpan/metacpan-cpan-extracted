package # hide from PAUSE
	Hopkins::Plugin::HMI::Catalyst;
BEGIN {
  $Hopkins::Plugin::HMI::Catalyst::VERSION = '0.900';
}

use strict;
use warnings;

=head1 NAME

Hopkins::Plugin::HMI::Catalyst - Catalyst application

=head1 DESCRIPTION

=cut

use Catalyst;
use Catalyst::Engine::Embeddable;

use File::ShareDir;

# catalyst compile-time fuckery

__PACKAGE__->config(%$Hopkins::Plugin::HMI::catalyst);

use Hopkins::Plugin::HMI::Log;

__PACKAGE__->setup(qw/Authentication Session Session::Store::FastMmap Session::State::Cookie Static::Simple/);
__PACKAGE__->log(new Hopkins::Plugin::HMI::Log);

sub setup_home
{
	my $self = shift;

	$self->next::method(@_);

	my $share = eval { File::ShareDir::dist_dir('Hopkins-Plugin-HMI') . '/root' };
	my $local = Hopkins::Plugin::HMI::Catalyst->path_to('share/root');

	my $root = -d $local ? $local : $share;

	die 'unable to determine template location' if not $root;

	$self->config->{root} = $root;
}

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
