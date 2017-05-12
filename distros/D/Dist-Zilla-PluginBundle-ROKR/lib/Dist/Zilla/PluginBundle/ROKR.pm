package Dist::Zilla::PluginBundle::ROKR;
BEGIN {
  $Dist::Zilla::PluginBundle::ROKR::VERSION = '0.0019';
}
# ABSTRACT: A nifty little plugin bundle for Dist::Zilla


use strict;
use warnings;

use Moose;
use Moose::Autobox;
with qw/ Dist::Zilla::Role::PluginBundle::Easy /;


sub configure {
    my $self = shift;

    $self->add_bundle('@ROKR::Basic');
    $self->add_plugins('UpdateGitHub');
    $self->add_plugins('Git::Tag');
}

sub parse_hint {
    my $self = shift;
    my $content = shift;

    my %hint;
    if ( $content =~ m/^\s*#+\s*(?:Dist::Zilla):\s*(.+)$/m ) { 
        %hint = map {
            m/^([\+\-])(.*)$/ ?
                ( $1 eq '+' ? ( $2 => 1 ) : ( $2 => 0 ) ) :
                ()
        } split m/\s+/, $1;
    }

    return \%hint;
}

1;

__END__
=pod

=head1 NAME

Dist::Zilla::PluginBundle::ROKR - A nifty little plugin bundle for Dist::Zilla

=head1 VERSION

version 0.0019

=head1 DESCRIPTION

C<@ROKR::Basic> - L<Dist::Zilla::PluginBundle::ROKR::Basic>

This is an enhancement on the @Basic bundle (L<Dist::Zilla::PluginBundle::Basic>), specifically:

    @Basic (without Readme)
    CopyReadmeFromBuild
    DynamicManifest
    SurgicalPkgVersion
    SurgicalPodWeaver

C<CopyReadmeFromBuild> - L<Dist::Zilla::Plugin::CopyReadmeFromBuild>

C<DynamicManifest> - L<Dist::Zilla::Plugin::DynamicManifest>

C<SurgicalPkgVersion> - L<Dist::Zilla::Plugin::SurgicalPkgVersion>

C<SurgicalPodWeaver> - L<Dist::Zilla::Plugin::SurgicalPodWeaver>

C<UpdateGitHub> - L<Dist::Zilla::Plugin::UpdateGitHub>

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

