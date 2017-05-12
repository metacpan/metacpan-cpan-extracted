use strict;
use warnings;
package Dist::Zilla::PluginBundle::Author::ALTREUS;

use Moose;
extends 'Dist::Zilla::PluginBundle::Author::DBOOK';

our $VERSION = '0.002';

before 'configure' => sub {
    my $self = shift;
    $self->{payload}->{github_user} //= 'Altreus';
};

1;

__END__

=encoding utf-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::ALTREUS - BeLike::ALTREUS, who is exactly
like DBOOK (except less obsessed with Mojolicious)

=head1 DESCRIPTION

This is exactly DBOOK's bundle except I've overridden the default github username.

=head1 SEE ALSO

L<Dist::Zilla::PluginBundle::Author::DBOOK>
