package Luv::CLI::Command::Init;

# ABSTRACT: initialize a new luv project

use v5.38;
use Object::Pad;

use App::Cmd::Setup -command;
use File::Copy     qw(copy);
use File::Path     qw(make_path);
use File::ShareDir qw(dist_dir);
use File::Basename qw(basename);
use Cwd            qw(getcwd chdir);
use FindBin        qw($Bin);

use Luv::CLI::Manifest;

sub abstract {
    "Initializes a new Love2D project.";
}

sub opt_spec {
    return (
        [   "name|n=s" =>
                "Project name (defaults to the current directory's name)."
        ],
        [   "force|f" =>
                "Overwrites an existing luv.json file within the project directory."
        ],
    );
}

sub execute( $self, $opt, $args ) {
    my $project_name = $opt->{name} // basename( getcwd() );

    if ( $opt->{name} ) {
        make_path($project_name) unless -d $project_name;
        chdir($project_name)
            or die "Cannot access directory '$project_name': $!\n";
    }

    my $manifest_path = "luv.json";

    if ( -e $manifest_path && !$opt->{force} ) {
        die
            "luv.json already exist: use --force|-f to overwrite the current file.\n";
    }

    my $manifest = Luv::CLI::Manifest->new(
        path         => $manifest_path,
        project_name => $project_name
    );

    $manifest->save;

    make_path(
        $manifest->source_dir, $manifest->library_dir,
        $manifest->assets_dir, $manifest->build_dir
    );

    my $share_dir = eval { dist_dir("Luv-CLI") } // "$Bin/../share";
    my %vars      = ( project_name => $project_name );

    render( "$share_dir/templates/conf.lua.tpl", "conf.lua", %vars );
    copy( "$share_dir/templates/main.lua.tpl", "main.lua" )
        or die "Cannot copy main.lua template: $!\n";
    copy( "$share_dir/templates/gitignore.tpl", ".gitignore" )
        or die "Cannot copy .gitignore template: $!\n";

    print "Initialized Love2D project '$project_name'\n";

    return;
}

sub render( $template_path, $destination_path, %vars ) {
    open my $fh, '<', $template_path
        or die "Cannot read from $template_path: $!\n";
    local $/;
    my $content = <$fh>;
    close $fh;

    for my $key ( keys %vars ) {
        my $value = $vars{$key};
        $content =~ s/\{\{\Q$key\E\}\}/$value/ge;
    }

    open my $out, '>', $destination_path
        or die "Cannot write to $destination_path: $!\n";
    print {$out} $content;
    close $out;

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Luv::CLI::Command::Init - initialize a new luv project

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    luv init
    luv init --name my-game

=head1 DESCRIPTION

Scaffolds a new luv project: writes C<luv.json>, C<main.lua>,
C<conf.lua>, C<.gitignore>, and the source/library/assets/build
directories. Optionally creates and enters a new directory when
C<--name> is given.

=head1 NAME

Luv::CLI::Command::Init - initialize a new luv project

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
