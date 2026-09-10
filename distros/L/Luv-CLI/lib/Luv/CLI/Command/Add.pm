package Luv::CLI::Command::Add;

# ABSTRACT: add a library dependency from a git repo or the registry

use v5.38;
use Object::Pad;

use App::Cmd::Setup -command;
use File::HomeDir;

use Luv::CLI::Manifest;
use Luv::CLI::Git;
use Luv::CLI::Registry;

sub abstract {
    "Adds a library dependency from a git repo.";
}

sub opt_spec {
    return ( [ 'ref=s' => 'git ref (branch/tag/commit) to check out' ], );
}

sub execute ( $self, $opt, $args ) {
    my $target = $args->[0] or die "Usage: luv add <repo-url|library-name>\n";

    my $manifest_path = "luv.json";
    die "No luv.json found — run 'luv init' first\n" unless -e $manifest_path;

    my $manifest = Luv::CLI::Manifest->new( path => $manifest_path );
    $manifest->load;

    my ( $name, $url );

    if ( $target =~ m{^https?://} || $target =~ m{^git\@} ) {
        $url = $target;
        ($name) = $url =~ m{([^/]+?)(?:\.git)?/?$};
    }
    else {
        my $cache_path = File::HomeDir->my_home . '/.cache/luv/registry.json';
        my $registry   = Luv::CLI::Registry->new( cache_path => $cache_path );
        $registry->load;

        my $entry = $registry->find($target);
        die
            "Library '$target' not found in registry — try 'luv search $target' or pass a git URL\n"
            unless $entry;

        $name = $target;
        $url  = $entry->{url};
    }

    die "Dependency '$name' already exists\n"
        if $manifest->has_dependency($name);

    my $dest = $manifest->library_dir . "/$name";
    my $git  = Luv::CLI::Git->new;
    $git->clone( $url, $dest, $opt->{ref} );

    $manifest->add_dependency(
        $name,
        url  => $url,
        ref  => $opt->{ref} // 'main',
        path => $dest
    );
    $manifest->save;

    print "Added '$name' from $url\n";
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Luv::CLI::Command::Add - add a library dependency from a git repo or the registry

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    luv add baton
    luv add https://github.com/tesselode/baton --ref v1.0

=head1 DESCRIPTION

Resolves the given argument either as a library name (looked up in the
local registry cache) or a raw git URL, clones it into the project's
library directory, and records it in C<luv.json>.

=head1 NAME

Luv::CLI::Command::Add - add a library dependency from a git repo or the registry

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ogun.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
