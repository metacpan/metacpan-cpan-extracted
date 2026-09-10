# PODNAME: Luv::CLI::Manifest
# ABSTRACT: reads and writes a luv project's luv.json manifest

use v5.38;
use Object::Pad;
use JSON::PP;

class Luv::CLI::Manifest;

field $path         : param;
field $project_name : param = "untitled";
field $output_name  : param = undef;
field $source_dir   : param = "src";
field $library_dir  : param = "lib";
field $assets_dir   : param = "assets";
field $build_dir    : param = "build";
field %dependencies;

ADJUST {
    $output_name //= "$project_name.love";
}

method add_dependency( $name, %info ) {
    die "Dependency '$name' already exists.\n"
        if exists $dependencies{ lc $name };

    $dependencies{$name} = {
        url  => $info{url},
        ref  => $info{ref}  // "main",
        path => $info{path} // "$library_dir/$name"
    };

    return;
}

method remove_dependency($name) {
    die "No such dependency: $name" unless exists $dependencies{$name};

    delete $dependencies{$name};

    return;
}

method has_dependency($name) {
    return exists $dependencies{$name};
}

method dependencies() {
    return \%dependencies;
}

method project_name() {
    return $project_name;
}

method source_dir() {
    return $source_dir;
}

method library_dir() {
    return $library_dir;
}

method assets_dir() {
    return $assets_dir;
}

method build_dir() {
    return $build_dir;
}

method output_name() {
    return $output_name;
}

method path() {
    return $path;
}

method to_hash() {
    return {
        project_name => $project_name,
        output_name  => $output_name,
        source_dir   => $source_dir,
        library_dir  => $library_dir,
        assets_dir   => $assets_dir,
        build_dir    => $build_dir,
        dependencies => \%dependencies,
    };
}

method save() {
    open my $fh, '>', $path or die "Cannot write to $path: $!.\n";
    print {$fh}
        JSON::PP->new->utf8->canonical->pretty->encode( $self->to_hash );
    close $fh;

    return;
}

method load() {
    open my $fh, '<', $path or die "Cannot read from $path: $!\n";
    local $/;
    my $data = JSON::PP->new->utf8->decode(<$fh>);
    close $fh;

    $project_name = $data->{project_name} // $project_name;
    $output_name  = $data->{output_name}  // $output_name;
    $source_dir   = $data->{source_dir}   // $source_dir;
    $library_dir  = $data->{library_dir}  // $library_dir;
    $assets_dir   = $data->{assets_dir}   // $assets_dir;
    $build_dir    = $data->{build_dir}    // $build_dir;
    %dependencies = %{ $data->{dependencies} // {} };

    return;
}

method exists_on_disk() {
    return -e $path;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Luv::CLI::Manifest - reads and writes a luv project's luv.json manifest

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $manifest = Luv::CLI::Manifest->new(
        path         => 'luv.json',
        project_name => 'my-game',
    );
    $manifest->save;

    my $loaded = Luv::CLI::Manifest->new(path => 'luv.json');
    $loaded->load;

=head1 DESCRIPTION

Owns the on-disk shape of a luv project's C<luv.json> file: project
identity, source/library/assets/build directory locations, and the
dependency list. All commands that read or modify project state go
through this class rather than touching JSON directly.

=head1 NAME

Luv::CLI::Manifest - reads and writes a luv project's luv.json manifest

=head1 METHODS

=head2 add_dependency($name, %info)

Adds a dependency to the manifest. Dies if a dependency with the same
name (case-insensitively) already exists. C<%info> may include C<url>,
C<ref>, and C<path>.

=head2 remove_dependency($name)

Removes a dependency by name (case-insensitive). Dies if it doesn't exist.

=head2 has_dependency($name)

Returns true if a dependency with the given name (case-insensitive) exists.

=head2 dependencies()

Returns a hashref of all dependencies, keyed by lowercase name.

=head2 project_name()

Returns the project's name.

=head2 source_dir()

Returns the configured source directory (default C<src>).

=head2 library_dir()

Returns the configured library/vendor directory (default C<lib>).

=head2 assets_dir()

Returns the configured assets directory (default C<assets>).

=head2 build_dir()

Returns the configured build output directory (default C<build>).

=head2 output_name()

Returns the filename the built C<.love> archive will be written as.

=head2 path()

Returns the path to the manifest file on disk.

=head2 to_hash()

Returns a plain hashref representation of the manifest, suitable for
JSON encoding.

=head2 save()

Writes the manifest to C<path> as JSON.

=head2 load()

Reads and parses the manifest from C<path>, populating this object's fields.

=head2 exists_on_disk()

Returns true if the manifest file currently exists on disk.

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
