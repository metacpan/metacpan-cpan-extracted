# PODNAME: Luv::CLI::Package
# ABSTRACT: packages a luv project into a .love file

use v5.38;
use Object::Pad;

use Archive::Zip qw(:ERROR_CODES);
use File::Find;

class Luv::CLI::Package;

field $manifest : param;

method build () {
    my $output_path = $manifest->build_dir . '/' . $manifest->output_name;

    my $zip = Archive::Zip->new;

    for my $file ( 'main.lua', 'conf.lua' ) {
        if ( -f $file ) {
            $zip->addFile( $file, $file );
        }
    }

    $self->add_dir( $zip, $manifest->source_dir,  '' );
    $self->add_dir( $zip, $manifest->library_dir, $manifest->library_dir );
    $self->add_dir( $zip, $manifest->assets_dir,  $manifest->assets_dir );

    File::Path::make_path( $manifest->build_dir )
        unless -d $manifest->build_dir;

    unless ( $zip->writeToFileNamed($output_path) == Archive::Zip::AZ_OK() ) {
        die "Failed to write $output_path\n";
    }

    return $output_path;
}

method add_dir ( $zip, $dir, $zip_prefix ) {
    return unless -d $dir;

    my $build_dir = $manifest->build_dir;

    File::Find::find(
        {   wanted => sub {
                return unless -f $_;
                my $rel = $File::Find::name;

                return if $rel =~ m{^\Q$build_dir\E(/|$)};

                $rel =~ s{^\Q$dir\E/?}{};
                my $zip_path = $zip_prefix ? "$zip_prefix/$rel" : $rel;
                $zip->addFile( $_, $zip_path );
            },
            no_chdir => 1,
        },
        $dir
    );

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Luv::CLI::Package - packages a luv project into a .love file

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $pkg = Luv::CLI::Package->new(manifest => $manifest);
    my $output_path = $pkg->build;

=head1 DESCRIPTION

Assembles a project's source, vendored libraries, and assets (plus
C<main.lua>/C<conf.lua> from the project root) into a single C<.love>
zip archive, as described by a L<Luv::CLI::Manifest>.

=head1 NAME

Luv::CLI::Package - packages a luv project into a .love file

=head1 METHODS

=head2 build()

Builds the C<.love> archive and writes it to the manifest's configured
build directory and output filename. Returns the path to the written file.

=head2 add_dir($zip, $dir, $zip_prefix)

Recursively adds every file under C<$dir> to C<$zip>, placed under
C<$zip_prefix> within the archive. Skips anything under the manifest's
build directory.

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
