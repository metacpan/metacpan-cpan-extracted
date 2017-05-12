package Dist::Zilla::Plugin::Rsync;
BEGIN {
  $Dist::Zilla::Plugin::Rsync::VERSION = '0.1';
}

=encoding utf8

=head1 SYNOPSIS

Upload your distribution tarball using C<rsync>:

    [Rsync]
    where = user@somewhere:destination/path
    options = --progress -e ssh

=head1 DESCRIPTION

The C<where> config key is required. The C<options> default to
C<-e ssh>.

=head1 AUTHOR

Tomáš Znamenáček, zoul@fleuron.cz

=cut

use Moose;
use CLASS;

with 'Dist::Zilla::Role::Releaser';

has where => (is => 'ro', isa => 'Str', required => 1);
has options => (is => 'ro', isa => 'Str', default => '-e ssh');

sub release
{
    my $self    = shift;
    my $tarball = shift;
    my @options = split(/\s/, $self->options);
    system('rsync', @options, $tarball, $self->where);
}

CLASS->meta->make_immutable;
no Moose;
'SDG';
