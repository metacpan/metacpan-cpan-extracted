# ABSTRACT: Cargo cult module releases
package Dist::Zilla::PluginBundle::NUFFIN;
BEGIN {
  $Dist::Zilla::PluginBundle::NUFFIN::AUTHORITY = 'cpan:NUFFIN';
}
BEGIN {
  $Dist::Zilla::PluginBundle::NUFFIN::VERSION = '0.01';
}
use Moose;

use namespace::autoclean;

extends qw(Dist::Zilla::PluginBundle::FLORA);

has '+authority' => ( default => "cpan:NUFFIN" );

has '+github_user' => ( default => "nothingmuch" );

after configure => sub {
    my $self = shift;

    $self->add_plugins(qw(
        Signature
    ));
};

__PACKAGE__->meta->make_immutable;

# ex: set sw=4 et:

1;



=pod

=encoding utf-8

=head1 NAME

Dist::Zilla::PluginBundle::NUFFIN - Cargo cult module releases

=head1 AUTHOR

  Yuval Kogman

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Yuval Kogman.

This is free software, licensed under:

  The MIT (X11) License

=cut


__END__

