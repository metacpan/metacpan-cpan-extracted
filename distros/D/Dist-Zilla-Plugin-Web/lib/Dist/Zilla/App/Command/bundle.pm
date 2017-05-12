use strict;
use warnings;

package Dist::Zilla::App::Command::bundle;
$Dist::Zilla::App::Command::bundle::VERSION = '0.0.10';
# ABSTRACT: concatenate individual files from your dist into bundles

use Dist::Zilla::App -command;
use Dist::Zilla::Plugin::Web::Bundle;
use Path::Class;



sub abstract { 'concatenate individual files from your dist into bundles' }


sub opt_spec {
  [ 'filename=s'  => 'a file from which to take the bundling information', { default => 'components.json' } ],
  [ 'lib_dir=s'  => 'a name for lib dir', { default => 'lib' } ],
}


sub execute {
    my ($self, $opt, $args) = @_;
    
    my $zilla       = $self->zilla;
    my $filename    = $opt->filename;
    
    die "File with bundles information not found: $filename" unless -e $filename;
    
    my $plugin = Dist::Zilla::Plugin::Web::Bundle->new({
        plugin_name => ':Bundler',
        zilla       => $zilla,
        filename    => $filename,
        lib_dir     => $opt->lib_dir
    });


    $plugin->process_components();
    
    for my $file (@{$zilla->files}) {
    
        my $file_path   = file($file->name);
        my $to_dir      = file($file->name)->dir;
        
        $to_dir->mkpath unless -e $to_dir;
    
        open my $out_fh, '>', "$file_path" or die "couldn't open $file_path to write: $!";
    
        # This is needed, or \n is translated to \r\n on win32.
        # Maybe :raw:utf8 is needed, but not sure.
        #     -- Kentnl - 2010-06-10
        binmode( $out_fh , ":raw" );
    
        print { $out_fh } $file->content;
        close $out_fh or die "error closing $file_path: $!";
        
        chmod $file->mode, "$file_path" or die "couldn't chmod $file_path: $!";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::bundle - concatenate individual files from your dist into bundles

=head1 VERSION

version 0.0.10

=head1 SYNOPSIS

  dzil bundle [ --filename components.json] [ --lib_dir lib ]

=head1 DESCRIPTION

This command is a very thin layer over the Dist::Zilla::Plugin::Web::Bundle, please consult its docs for details.

=head1 EXAMPLE

  $ dzil bundle
  $ dzil build --filename build/concat_info.js --lib_dir js

=head1 OPTIONS

=head2 --file

A file from which to take the bundling information. Default value is "components.json".

=head2 --lib_dir

A name for "lib" directory. Default is "lib".

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
