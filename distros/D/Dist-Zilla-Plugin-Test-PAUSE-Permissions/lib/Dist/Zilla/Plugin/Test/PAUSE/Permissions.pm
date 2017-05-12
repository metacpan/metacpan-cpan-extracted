# vim: set ts=8 sts=4 sw=4 tw=115 et :
use strict;
use warnings;
package Dist::Zilla::Plugin::Test::PAUSE::Permissions; # git description: v0.002-23-g6f46e24
# ABSTRACT: Generate a test to verify PAUSE permissions
# KEYWORDS: plugin test author PAUSE permissions

our $VERSION = '0.003';

use Moose;
with (
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::TextTemplate',
    'Dist::Zilla::Role::PrereqSource',
);

use Path::Tiny;
use namespace::autoclean;

sub filename { path(qw(xt release pause-permissions.t))->stringify }

has username => (
    is => 'ro', isa => 'Str|Undef',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $stash = $self->zilla->stash_named('%PAUSE');
        return if not $stash;

        my $username = $stash->username;
        $self->log_debug([ 'using PAUSE id "%s" from Dist::Zilla config', $username ]) if $username;
        $username;
    },
);

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    my $data = {
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };
    $config->{+__PACKAGE__} = $data if keys %$data;

    return $config;
};

sub register_prereqs
{
    my $self = shift;

    $self->zilla->register_prereqs(
        {
            phase => 'develop',
            type  => 'requires',
        },
        'Test::PAUSE::Permissions' => '0',
    );
}

sub gather_files
{
    my $self = shift;

    require Dist::Zilla::File::InMemory;
    $self->add_file(Dist::Zilla::File::InMemory->new(
        name => $self->filename,
        content => $self->fill_in_string(
            <<'TEST',
use strict;
use warnings;

# this test was generated with {{ ref $plugin }} {{ $plugin->VERSION }}

use Test::More;
BEGIN {
    plan skip_all => 'Test::PAUSE::Permissions required for testing pause permissions'
        if $] < 5.010;
}
use Test::PAUSE::Permissions;

all_permissions_ok({{ $username ? qq{'$username'} : '' }});
TEST
            {
                dist => \($self->zilla),
                plugin => \$self,
                username => \($self->username),
            },
        ),
    ));
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::PAUSE::Permissions - Generate a test to verify PAUSE permissions

=head1 VERSION

version 0.003

=head1 SYNOPSIS

In your F<dist.ini>:

    [Test::PAUSE::Permissions]

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that runs at the
L<gather files|Dist::Zilla::Role::FileGatherer> stage, providing a
L<Test::PAUSE::Permissions> test, named F<xt/release/pause-permissions.t>).

=for Pod::Coverage filename gather_files register_prereqs

=head1 SEE ALSO

=over 4

=item *

L<Test::PAUSE::Permissions>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-PAUSE-Permissions>
(or L<bug-Dist-Zilla-Plugin-Test-PAUSE-Permissions@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Test-PAUSE-Permissions@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Harley Pig

Harley Pig <harleypig@gmail.com>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
