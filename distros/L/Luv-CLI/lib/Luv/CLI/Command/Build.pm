package Luv::CLI::Command::Build;

# ABSTRACT: package the project into a .love file

use v5.38;
use Object::Pad;

use App::Cmd::Setup -command;

use Luv::CLI::Manifest;
use Luv::CLI::Package;

sub abstract {
    "Packages the project into a .love file.";
}

sub execute ( $self, $opt, $args ) {
    my $manifest_path = "luv.json";
    die "No luv.json found — run 'luv init' first\n" unless -e $manifest_path;

    my $manifest = Luv::CLI::Manifest->new( path => $manifest_path );
    $manifest->load;

    my $package     = Luv::CLI::Package->new( manifest => $manifest );
    my $output_path = $package->build;

    print "Built $output_path\n";
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Luv::CLI::Command::Build - package the project into a .love file

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    luv build

=head1 DESCRIPTION

Reads C<luv.json> and packages the project's source, vendored
libraries, and assets (plus C<main.lua>/C<conf.lua>) into a C<.love>
archive, written to the configured build directory.

=head1 NAME

Luv::CLI::Command::Build - package the project into a .love file

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
