use strict;
use warnings;
package Dist::Zilla::MintingProfile::Author::ETHER;
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Mint distributions like ETHER does

our $VERSION = '0.166';

use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use Moose;
with 'Dist::Zilla::Role::MintingProfile' => { -version => '5.047' };
use File::ShareDir;
use Path::Tiny;
use Carp;
use namespace::autoclean;

sub profile_dir {
    my ($self, $profile_name) = @_;

    die 'minting requires perl 5.014' unless "$]" >= 5.013002;

    my $dist_name = 'Dist-Zilla-PluginBundle-Author-ETHER';
    my $profile_dir = path(File::ShareDir::dist_dir($dist_name))->child('profiles', $profile_name);
    return $profile_dir if -d $profile_dir;

    confess "Can't find profile $profile_name via $self: it should be in $profile_dir";
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MintingProfile::Author::ETHER - Mint distributions like ETHER does

=head1 VERSION

version 0.166

=head1 SYNOPSIS

    dzil new -P Author::ETHER -p github Foo::Bar

or:

    #!/bin/bash
    newdist() {
        local dist=$1
        local module=`perl -we"print q{$dist} =~ s/-/::/r"`
        pushd ~/git
        dzil new -P Author::ETHER -p github $module
        cd $dist
    }
    newdist Foo-Bar

=head1 DESCRIPTION

The new distribution is packaged with L<Dist::Zilla> using
L<Dist::Zilla::PluginBundle::Author::ETHER>.

Profiles available are:

=over 4

=item *

C<github>

Creates a distribution hosted on L<github|http://github.com>, with hooks to determine the
module version and other metadata from git. Issue tracking is disabled, as RT
is selected as the bugtracker in the distribution's metadata (via the plugin
bundle).

You will be prompted to create a repository on github immediately; if you
decline, you must create one manually before you do your first C<push>.

=item *

C<default>

Presently the same as C<github>. Available since version 0.087.

=back

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::PluginBundle::Author::ETHER>

=item *

L<Pod::Weaver::PluginBundle::Author::ETHER>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-Author-ETHER>
(or L<bug-Dist-Zilla-PluginBundle-Author-ETHER@rt.cpan.org|mailto:bug-Dist-Zilla-PluginBundle-Author-ETHER@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.libera.chat>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
