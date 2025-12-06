package Dist::Zilla::Plugin::DROLSKY::DevTools;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '1.24';

use Path::Tiny qw( path );

use Moose;

with qw(
    Dist::Zilla::Plugin::DROLSKY::Role::MaybeFileWriter
    Dist::Zilla::Role::BeforeBuild
);

sub before_build {
    my $self = shift;

    $self->_maybe_write_file(
        'git/setup.pl',
        $self->_git_setup_pl,
        'is executable',
    );
    $self->_maybe_write_file(
        'git/hooks/pre-commit.sh',
        $self->_git_hooks_pre_commit_sh,
        'is executable',
    );

    return;
}

my $git_setup_pl = <<'EOF';
#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw( abs_path );

symlink_hook('pre-commit');

sub symlink_hook {
    my $hook = shift;

    my $dot  = ".git/hooks/$hook";
    my $file = "git/hooks/$hook.sh";
    my $link = "../../$file";

    if ( -e $dot ) {
        if ( -l $dot ) {
            return if readlink $dot eq $link;
        }
        warn "You already have a hook at $dot!\n";
        return;
    }

    symlink $link, $dot
        or die "Could not link $dot => $link: $!";
}
EOF

sub _git_setup_pl {$git_setup_pl}

my $git_hooks_pre_commit_sh = <<'EOF';
#!/bin/bash

status=0

PRECIOUS=$(which precious)
if [[ -z $PRECIOUS ]]; then
    PRECIOUS=./bin/precious
fi

"$PRECIOUS" lint -s
if (( $? != 0 )); then
    status+=1
fi

exit $status
EOF

sub _git_hooks_pre_commit_sh {$git_hooks_pre_commit_sh}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Creates scripts to install precious and git hooks

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DROLSKY::DevTools - Creates scripts to install precious and git hooks

=head1 VERSION

version 1.24

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY/issues>.

=head1 SOURCE

The source code repository for Dist-Zilla-PluginBundle-DROLSKY can be found at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 - 2025 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
