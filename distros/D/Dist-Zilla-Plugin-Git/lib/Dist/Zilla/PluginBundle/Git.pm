#
# This file is part of Dist-Zilla-Plugin-Git
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Dist::Zilla::PluginBundle::Git;
# ABSTRACT: All git plugins in one bundle

our $VERSION = '2.042';

use Moose;
use Module::Runtime 'use_module';
use namespace::autoclean;

with 'Dist::Zilla::Role::PluginBundle';

# bundle all git plugins
my @names   = qw{ Check Commit Tag Push };

my %multi;
for my $name (@names) {
    my $class = "Dist::Zilla::Plugin::Git::$name";
    use_module $class;
    @multi{$class->mvp_multivalue_args} = ();
}

sub mvp_multivalue_args { keys %multi; }

sub bundle_config {
    my ($self, $section) = @_;
    #my $class = ( ref $self ) || $self;
    my $arg   = $section->{payload};

    my @config;

    for my $name (@names) {
        my $class = "Dist::Zilla::Plugin::Git::$name";
        my %payload;
        foreach my $k (keys %$arg) {
            $payload{$k} = $arg->{$k} if $class->can($k);
        }
        push @config, [ "$section->{name}/$name" => $class => \%payload ];
    }

    return @config;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Git - All git plugins in one bundle

=head1 VERSION

version 2.042

=head1 SYNOPSIS

In your F<dist.ini>:

    [@Git]
    changelog   = Changes             ; this is the default
    allow_dirty = dist.ini            ; see Git::Check...
    allow_dirty = Changes             ; ... and Git::Commit
    commit_msg  = v%v%n%n%c           ; see Git::Commit
    tag_format  = %v                  ; see Git::Tag
    tag_message = %v                  ; see Git::Tag
    push_to     = origin              ; see Git::Push

=head1 DESCRIPTION

This is a plugin bundle to load the most common Git plugins.
It is equivalent to:

    [Git::Check]
    [Git::Commit]
    [Git::Tag]
    [Git::Push]

Any options given are passed through to each plugin.  See each
plugin's documentation for the options it supports.  (Plugins just
ignore options they don't understand.)

=for Pod::Coverage bundle_config
    mvp_multivalue_args

=head1 SEE ALSO

=over 4

=item * L<Git::Check|Dist::Zilla::Plugin::Git::Check>

Before a release, check that the repo is in a clean state
(you have committed your changes).

=item * L<Git::Commit|Dist::Zilla::Plugin::Git::Commit>

After a release, commit updated files.

=item * L<Git::Tag|Dist::Zilla::Plugin::Git::Tag>

After a release, tag the just-released version.

=item * L<Git::Push|Dist::Zilla::Plugin::Git::Push>

After a release, push the released code & tag to your public repo.

=back

For a list of Git plugins in this distribution that are not part of
this bundle, see L<Dist::Zilla::Plugin::Git>.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Git>
(or L<bug-Dist-Zilla-Plugin-Git@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Git@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
