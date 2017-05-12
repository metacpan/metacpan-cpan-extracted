use strict;
use warnings;

package Dist::Zilla::App::Command::add_header;
$Dist::Zilla::App::Command::add_header::VERSION = '0.0.10';
# ABSTRACT: concatenate individual files from your dist into bundles

use Dist::Zilla::App -command;
use Dist::Zilla::Plugin::Web::FileHeader;
use Path::Class;



sub abstract { 'concatenate individual files from your dist into bundles' }


sub opt_spec {
  [ 'header_filename=s'  => 'a file from which to take the content of header' ],
  [ 'to=s'  => 'a file add heder to' ],
}


sub execute {
    my ($self, $opt, $args) = @_;
    
    my $zilla               = $self->zilla;
    my $header_filename     = $opt->header_filename;
    my $to                  = $opt->to;
    
    die "File with header not found: $header_filename" unless -e $header_filename;
    die "The file add header to is not exists" unless -e $to;
    
    my $plugin = Dist::Zilla::Plugin::Web::FileHeader->new({
        plugin_name         => ':AddHeader',
        zilla               => $zilla,
        header_filename     => $header_filename
    });

    $plugin->prepend_header_to_file($to);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::add_header - concatenate individual files from your dist into bundles

=head1 VERSION

version 0.0.10

=head1 SYNOPSIS

  dzil add_header [ --header_filename build/header.txt] [ --to my_project_all.min.js ]

=head1 DESCRIPTION

This command is a very thin layer over the Dist::Zilla::Plugin::Web::Bundle, please consult its docs for details.

=head1 EXAMPLE

  $ dzil add_header --header_filename build/header.txt --to my_project_all.min.js

=head1 OPTIONS

=head2 --header_filename

A file from which to take the content of the header.

=head2 --to

A file prepend the header to

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
