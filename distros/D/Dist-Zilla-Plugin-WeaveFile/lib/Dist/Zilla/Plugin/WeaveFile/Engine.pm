package Dist::Zilla::Plugin::WeaveFile::Engine;
## no critic (ControlStructures::ProhibitPostfixControls)
## no critic (ControlStructures::ProhibitUnlessBlocks)

use strict;
use warnings;
use 5.010;

our $VERSION = '0.002';

use Carp       qw( croak );
use Path::Tiny qw( path );
use YAML       qw( LoadFile );
use Template;
use Pod::Markdown;

sub new {
    my ( $class, %args ) = @_;
    croak 'config_path is required' unless $args{config_path};
    return bless {
        config_path => $args{config_path},
        root_dir    => $args{root_dir} // q{.},
        dist        => $args{dist}     // {},
        _config     => undef,
        _pod_cache  => {},
    }, $class;
}

sub config {
    my $self = shift;
    unless ( $self->{_config} ) {
        my $config_file = path( $self->{root_dir}, $self->{config_path} );
        croak "Config file not found: $config_file" unless $config_file->is_file;
        $self->{_config} = LoadFile("$config_file");
    }
    return $self->{_config};
}

sub available_files {
    my $self = shift;
    return keys %{ $self->config->{files} // {} };
}

sub render_file {
    my ( $self, $filename ) = @_;
    croak 'filename is required' unless $filename;

    my $config        = $self->config;
    my $template_text = $config->{files}{$filename} // croak "No file definition for '$filename' in config";

    my $tt = Template->new( { STRICT => 1 } )
      or croak 'Template error: ' . Template->error();

    my $engine    = $self;
    my $base_vars = {
        dist => $self->{dist},
        pod  => sub { return $engine->extract_pod_section(@_) },
    };

    # Pre-render snippets so TT tags inside them are processed.
    my %rendered_snippets;
    my $raw_snippets = $config->{snippets} // {};
    for my $name ( keys %{$raw_snippets} ) {
        my $snippet_out = q{};
        $tt->process( \$raw_snippets->{$name}, $base_vars, \$snippet_out )
          or croak "Template error in snippet '$name': " . $tt->error();
        $rendered_snippets{$name} = $snippet_out;
    }

    my $vars = { %{$base_vars}, snippets => \%rendered_snippets, };

    my $output = q{};
    $tt->process( \$template_text, $vars, \$output )
      or croak 'Template processing error: ' . $tt->error();

    $output =~ s/ [[:space:]]+ \z /\n/msx;

    return $output;
}

sub extract_pod_section {
    my ( $self, $source, $section_name ) = @_;
    croak 'source is required for pod()'       unless $source;
    croak 'section_name is required for pod()' unless $section_name;

    my $file_path = $self->_resolve_source($source);
    my $cache_key = "$file_path";

    unless ( $self->{_pod_cache}{$cache_key} ) {
        my $parser   = Pod::Markdown->new;
        my $markdown = q{};
        $parser->output_string( \$markdown );
        $parser->parse_file("$file_path");
        $self->{_pod_cache}{$cache_key} = $markdown;
    }

    return $self->_extract_markdown_section( $self->{_pod_cache}{$cache_key}, $section_name, );
}

sub _resolve_source {
    my ( $self, $source ) = @_;
    my $root = path( $self->{root_dir} );

    # Direct file path (contains / or has a file extension)
    if ( $source =~ m{/}msx || $source =~ m{ [.] \w+ \z }msx ) {
        my $p = $root->child($source);
        return $p if $p->is_file;
        croak "Cannot find file: $source (looked at $p)";
    }

    # Module name: Foo::Bar -> lib/Foo/Bar.pm
    my $rel = $source;
    $rel =~ s{::}{/}gmsx;
    $rel .= '.pm';
    my $p = $root->child( 'lib', $rel );
    return $p if $p->is_file;
    croak "Cannot find module: $source (looked at $p)";
}

sub _extract_markdown_section {
    my ( $self, $markdown, $section_name ) = @_;

    my @lines      = split /\n/msx, $markdown;
    my $in_section = 0;
    my $section_level;
    my @result;

    for my $line (@lines) {
        if ( $line =~ /^ ( [#]+ ) \s+ (.+) /msx ) {
            my $level   = length $1;
            my $heading = $2;

            if ( !$in_section && lc $heading eq lc $section_name ) {
                $in_section    = 1;
                $section_level = $level;
                push @result, $line;
                next;
            }

            last if $in_section && $level <= $section_level;
        }
        push @result, $line if $in_section;
    }

    return q{} unless @result;

    pop @result while @result && $result[-1] =~ / ^ \s* $ /msx;

    return join "\n", @result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::WeaveFile::Engine

=head1 VERSION

version 0.002

=head1 DESCRIPTION

Renders files by processing L<Template::Toolkit|Template> templates from a
YAML config, with access to distribution metadata, reusable snippets, and
a C<pod()> function that extracts POD sections as Markdown.

Not intended for direct use. Called by L<Dist::Zilla::App::Command::weave>
and L<Dist::Zilla::Plugin::Test::WeaveFile>.

=head1 NAME

Dist::Zilla::Plugin::WeaveFile::Engine - Core weaving engine

=head1 METHODS

=head2 new

Create a new engine class.

=head2 config

Return config

=head2 available_files

return list of available files.

=head2 render_file

Return a ready file as string.

=head2 extract_pod_section

Extract pod section from a source file and return it.

=head1 AUTHOR

Mikko Koivunalho <mikkoi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
