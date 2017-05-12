package EPUB::Parser::File::OPF;
use strict;
use warnings;
use Carp;
use EPUB::Parser::File::Parser::OPF;
use EPUB::Parser::File::OPF::Context;
use EPUB::Parser::File::Container;
use Smart::Args;

sub new {
    args(
        my $class => 'ClassName',
        my $zip   => { isa => 'EPUB::Parser::Util::Archive' },
        my $epub_version,
    );

    my $self = bless {
        zip          => $zip,
        epub_version => $epub_version,
    } => $class;

    return $self;
}

sub parser {
    my $self = shift;

    $self->{parser}
        ||= EPUB::Parser::File::Parser::OPF->new({ data => $self->data });
}

sub path {
    my $self = shift;

    $self->{path} ||= do {
        my $container = EPUB::Parser::File::Container->new({ zip => $self->{zip} });
        $container->opf_path;
    };
}

sub dir {
    my $self = shift;
    require File::Basename;
    $self->{dir} ||= File::Basename::dirname($self->path);
}


sub data {
    my $self = shift;
    $self->{data} ||= $self->{zip}->get_member_data({ file_path => $self->path });
}

sub context {
    my $self = shift;
    my $context_name = shift;
    return $self->{$context_name} if $self->{$context_name};

    $self->{$context_name} = EPUB::Parser::File::OPF::Context->new({
        opf       => $self,
        parser    => $self->parser,
        context_name => $context_name,
    });
}

sub spine    { shift->context('spine'   ) }
sub manifest { shift->context('manifest') }
sub metadata { shift->context('metadata') }
sub guide    { shift->context('guide'   ) }

sub nav_path {
    my $self = shift;
    $self->{nav_path} ||= sprintf("%s/%s", $self->dir, $self->manifest->nav_path);
}

sub cover_image_path {
    shift->manifest->cover_image_path(@_);
}

sub guess_version {
    my $self = shift;
    my $version = $self->parser->single('/pkg:package/@version')->string_value;
    
    if ($version) {
        return $version;
    }
    elsif ( $self->nav_path ) {
        return '3.0';
    }
    else {
        return;
    }
}


1;


__END__

=encoding utf-8

=head1 NAME

 EPUB::Parser::File::OPF - parses opf file

=head1 SYNOPSIS

 use EPUB::Parser;
 my $ep = EPUB::Parser->new->load_file({ file_path  => 'sample.epub' });
 my $opf = $ep->opf;

=head1 METHODS

=head2 new(\%opts)

Constructor.
This method called from L<EPUB::Parser> object.
$epub_parser->opf;

=head2 parser

Returns instance of L<EPUB::Parser::File::Parser::OPF>.

=head2 path

get opf file path from 'META-INF/container.xml'

=head2 dir

get directory path of opf file.
File::Basename::dirname($self->path);

=head2 data

get blob of opf file from loaded EPUB

=head2 spine

Returns instance of L<EPUB::Parser::File::OPF::Context::Spine>.

=head2 manifest

Returns instance of L<EPUB::Parser::File::OPF::Context::Manifest>.

=head2 metadata

Returns instance of L<EPUB::Parser::File::OPF::Context::Metadata>.

=head2 guide

Returns instance of L<EPUB::Parser::File::OPF::Context::Guide>.

=head2 nav_path

Returns navigation file path from manifest.

=head2 cover_image_path(\%opt)

Shortcut method.
see L<EPUB::Parser::File::OPF::Context::Manifest>.

=head2 guess_version

get opf version.
return '3.0' if version is not found and navigation file exists.

=head1 LICENSE

Copyright (C) tokubass.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokubass E<lt>tokubass {at} cpan.orgE<gt>

=cut

