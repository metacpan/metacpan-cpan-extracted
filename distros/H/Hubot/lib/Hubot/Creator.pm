package Hubot::Creator;
$Hubot::Creator::VERSION = '0.2.8';
use Moose;
use namespace::autoclean;

use Cwd 'cwd';
use File::Copy ();
use File::Copy::Recursive 'dircopy';
use File::Path 'mkpath';
use File::ShareDir 'dist_dir';
use File::Spec::Functions 'catfile';
use Try::Tiny;

has 'path' => ( is => 'ro', isa => 'Str', default => './hubot', );

sub copy {
    my ( $self, $src, $dst ) = @_;

    print "Copying $src -> $dst\n";
    File::Copy::copy( $src, $dst );
}

sub run {
    my $self = shift;

    my $path = $self->path;

    print "Create a hubot install at $path\n";

    my $dist_dir = try {
        File::ShareDir::dist_dir('Hubot');
    }
    catch {
        warn "not installed `Hubot` module";    # ignore $_
        cwd() . '/share';
    };

    mkpath( catfile( $path, 'bin' ) );
    mkpath( catfile( $path, 'lib/Hubot/Adapter' ) );
    mkpath( catfile( $path, 'lib/Hubot/Scripts' ) );

    my @modules = qw(
        Hubot/EventEmitter.pm
        Hubot/Scripts/help.pm
        Hubot/Scripts/ascii.pm
        Hubot/Scripts/shorten.pm
        Hubot/Scripts/tweet.pm
        Hubot/Scripts/roles.pm
        Hubot/Response.pm
        Hubot/Robot.pm
        Hubot/User.pm
        Hubot/Adapter.pm
        Hubot/TextListener.pm
        Hubot/Listener.pm
        Hubot/Adapter/Irc.pm
        Hubot/Adapter/Shell.pm
        Hubot/Adapter/Campfire.pm
        Hubot/Message.pm
        Hubot/Brain.pm
        Hubot/Creator.pm
        Hubot.pm
    );

    my $installed   = $dist_dir =~ /share$/ ? 0  : 1;
    my $path_prefix = $installed            ? '' : cwd() . '/lib';

    for my $module (@modules) {
        if ($installed) {
            next unless require $module;
        }

        my ( $src, $dst ) = (
            $installed ? $INC{"$module"} : "$path_prefix/$module",
            catfile( "$path", 'lib', $module )
        );
        $self->copy( $src, $dst );
    }

    dircopy( catfile( $dist_dir, 'lib' ), catfile( $path, 'lib' ), );

    my @files = qw(
        .gitignore
        Procfile
        README.md
        cpanfile
        hubot-scripts.json
    );

    for my $file (@files) {
        my ( $src, $dst )
            = ( catfile("$dist_dir/$file"), catfile("$path/$file") );
        $self->copy( $src, $dst );
    }

    my @bins = qw(
        bin/hubot
    );

    for my $file (@bins) {
        my ( $src, $dst )
            = ( catfile("$dist_dir/$file"), catfile("$path/$file") );
        $self->copy( $src, $dst );
        chmod 0755, "$dst";
    }
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding utf-8

=head1 NAME

Hubot::Creator - deployable package builder for C<hubot>

=head1 VERSION

version 0.2.8

=head1 SYNOPSIS

    Hubot::Creator->new(path => '/path/to/hubot')->run;

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
