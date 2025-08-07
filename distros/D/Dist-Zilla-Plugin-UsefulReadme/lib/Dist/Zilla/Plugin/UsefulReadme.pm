package Dist::Zilla::Plugin::UsefulReadme;

# ABSTRACT: generate a README file with the useful bits

use v5.20;

use Moose;
with qw(
  Dist::Zilla::Role::AfterBuild
  Dist::Zilla::Role::AfterRelease
  Dist::Zilla::Role::FileGatherer
  Dist::Zilla::Role::FilePruner
  Dist::Zilla::Role::PPI
  Dist::Zilla::Role::PrereqSource
);

use Dist::Zilla 6.003;
use Dist::Zilla::File::InMemory;
use Hash::Ordered 0.005;
use List::Util 1.33 qw( first none pairs );
use Module::Metadata 1.000015;
use Module::Runtime qw( use_module );
use MooseX::MungeHas;
use Path::Tiny;
use PPI::Token::Pod ();
use Pod::Elemental;
use Pod::Elemental::Document;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::Nester;
use Pod::Elemental::Selectors;
use Types::Common qw( ArrayRef Bool CodeRef Enum Maybe NonEmptyStr StrMatch );

use experimental qw( lexical_subs postderef signatures );

use namespace::autoclean;

our $VERSION = 'v0.4.2';

sub mvp_multivalue_args { qw( regions sections ) }

sub mvp_aliases { return { region => 'regions', section => 'sections', fallback => 'section_fallback' } }


has source => (
    is      => 'lazy',
    isa     => NonEmptyStr,
    builder => sub($self) {
        my $file = $self->zilla->main_module->name;
        ( my $pod = $file ) =~ s/\.pm$/\.pod/;
        return -e $pod ? $pod : $file;
    }
);

sub _source_file($self) {
    my $filename = $self->source;
    return first { $_->name eq $filename } $self->zilla->files->@*;
}


has phase => (
    is      => 'ro',
    isa     => Enum [qw(build release)],
    default => 'build',
);


has location => (
    is      => 'ro',
    isa     => Enum [qw(build root)],
    default => 'build',
);


has encoding => (
    is      => 'ro',
    isa     => NonEmptyStr,
    default => 'utf8',
);


has section_fallback => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);


has sections => (
    is      => 'ro',
    isa     => ArrayRef [NonEmptyStr],
    builder => sub($self) {
        return [
            map { s/_/ /gr }
              qw(
              name
              synopsis
              description
              recent_changes
              requirements
              installation
              /support|bugs/
              source
              /authors?/
              /contributors?/
              /copyright|license|copyright_and_license/
              see_also
              )
        ];

    }
);

my %CONFIG = (
    pod => {
        filename => 'README.pod',
        prereqs  => [],
    },
    text => {
        filename => 'README',
        prereqs  => [
            'Pod::Simple::Text' => '3.23',
        ],
    },
    markdown => {
        filename => 'README.mkdn',
        prereqs  => [
            'Pod::Markdown' => '3.000',
        ],
    },
    gfm => {
        filename => 'README.md',
        prereqs  => [
            'Pod::Markdown::Github' => 0,
        ],
    },
    custom => {
        filename => '', # the user will have to specify this
        prereqs  => [],
    },
);


has type => (
    is      => 'ro',
    isa     => Enum [ keys %CONFIG ],
    default => 'text',
);


has parser_class => (
    is => 'lazy',
    isa => Maybe[ StrMatch[ qr/^[^\W\d]\w*(?:::\w+)*\z/as ] ], # based on Params::Util _CLASS;
    builder => sub($self) {
       return $CONFIG{ $self->type }{prereqs}[0];
    }
);

has _parser => (
    is       => 'lazy',
    isa      => CodeRef,
    init_arg => undef,
    builder  => sub($self) {
        my $prereqs = $CONFIG{ $self->type }{prereqs};
        my $class   = $self->parser_class;
        if ($class) {
            if ( $class ne $prereqs->[0] ) {
                use_module($class);
            }
            else {
                foreach my $prereq ( pairs $prereqs->@* ) {
                    use_module( $prereq->[0], $prereq->[1] );
                }
            }
            return sub($pod) {
                my $parser = $class->new();
                $parser->output_string( \my $content );
                $parser->parse_characters(1);
                $parser->parse_string_document($pod);
                return $content;
            }
        }
        else {
            return sub($pod) {
                return $pod;
            }
        }
    }
);


has filename => (
    is      => 'lazy',
    isa     => NonEmptyStr,
    builder => sub($self) {
        return $CONFIG{ $self->type }{filename};
    }
);


has regions => (
    is      => 'lazy',
    isa     => ArrayRef [NonEmptyStr],
    builder => sub($self) {
        my @regions = qw( stopwords Pod::Coverage Test::MixedScripts );
        return [ map { s/^://r } @regions, $CONFIG{ $self->type }{regions}->@* ];
    }
);

sub gather_files($self) {
    my $filename = $self->filename;

    if ( ( $self->location eq 'build' )
        && none { $_->name eq $filename } $self->zilla->files->@* )
    {
        my $file = Dist::Zilla::File::InMemory->new(
            {
                content => '', # placeholder
                name    => $self->filename,
            }
        );
        $self->add_file($file);
    }

    return;
}

sub register_prereqs($self) {

    if ( my $prereqs = $CONFIG{ $self->type }{prereqs} ) {
        $self->zilla->register_prereqs(
            {
                phase => 'develop',
                type  => 'requires',
            },
            ref($self) => $VERSION,
            $prereqs->@*
        );
    }

    return;
}

sub prune_files($self) {

    if ( $self->location eq "root"
        && none { ref($self) eq ref($_) && $_->location ne $self->location && $_->filename eq $self->filename }
        $self->zilla->plugins->@* )
    {
        for my $file ( $self->zilla->files->@* ) {
            next unless $file->name eq $self->filename;
            $self->log_debug( [ 'pruning %s', $file->name ] );
            $self->zilla->prune_file($file);
        }
    }

    return;
}

sub after_build( $self, $build ) {
    # Updating the content of the file after the build has no effect, so we update the actual file on disk
    if ( $self->phase eq 'build' ) {
        my $dir = $self->location eq "build" ? $build->{build_root} : $self->zilla->root;
        $self->_create_readme($dir);
    }
}

sub after_release( $self, @ ) {
    $self->_create_readme( $self->zilla->root ) if $self->phase eq 'release';
}

sub _create_readme( $self, $dir ) {
    my $file = path( $dir, $self->filename );
    $file->spew_raw( $self->_generate_readme_content );
}

sub _generate_readme_content($self) {
    my $config  = $CONFIG{ $self->type };
    return $self->_parser->( $self->_generate_raw_pod );
}

sub _generate_raw_pod($self) {

    # We need to extract the POD from the source file

    my $ppi   = $self->ppi_document_for_file( $self->_source_file );
    my $pods  = $ppi->find('PPI::Token::Pod') or return;
    my $bytes = PPI::Token::Pod->merge( $pods->@* );

    # Then we need to parse the POD and transform that into a list of =head1 sections

    my $doc = Pod::Elemental->read_string($bytes);
    Pod::Elemental::Transformer::Pod5->new->transform_node($doc);

    my %regions = map { $_ => 1 } $self->regions->@*;

    my $nester = Pod::Elemental::Transformer::Nester->new(
        {
            top_selector      => Pod::Elemental::Selectors::s_command('head1'),
            content_selectors => [
                Pod::Elemental::Selectors::s_flat(),
                Pod::Elemental::Selectors::s_command( [qw(head2 head3 head4 over item back pod cut)] ),
                sub($para) {
                    return $para && $para->isa("Pod::Elemental::Element::Pod5::Region") && $regions{ $para->format_name };
                }
            ],
        },
    );
    $nester->transform_node($doc);
    my @nodes = $doc->children->@*;

    my $sections = Hash::Ordered->new;
    for my $sec ( grep { Pod::Elemental::Selectors::s_command( head1 => $_ ) } @nodes ) {
        my $heading = fc( $sec->content );
        next if $sections->exists($heading);
        $sections->set( $heading => [$sec] );
    }

    for my $readme ( grep { Pod::Elemental::Selectors::s_command( begin => $_ ) && $_->format_name =~ /^:?readme$/ } @nodes ) {
        my ( $found, @children ) = $readme->children->@*;

        if ( Pod::Elemental::Selectors::s_command( head1 => $found ) ) {
            my $heading = fc( $found->content );
            next if $sections->exists($heading);
            unshift @children, $found unless $heading =~ /\A(?:append|prepend):/;
            $sections->set( $heading => \@children );
        }
    }

    my sub _get_section($heading) {
        if ( my $pod = $sections->get( fc $heading ) ) {
            return $pod->@*;
        }
        elsif ( my ($re) = $heading =~ m|\A/(.+)/\z| ) {
            my $check = sub($key) { return $key =~ qr/\A(?:${re})\z/i };
            for my $key ( $sections->keys ) {
              if  ( $check->($key) ) {
                if ( $pod = $sections->get($key) ) {
                  return $pod->@*;
                }
              }
            }
        }
        elsif ( $self->section_fallback ) {
            my $method = sprintf( '_generate_pod_for_%s', lc( $heading =~ s/\W+/_/gr ) );
            if ( $self->can($method) ) {
                my ($pod) = $self->$method or return;
                if ( my $pre = $sections->get( "prepend:" . fc($heading) ) ) {
                    unshift $pod->children->@*, $pre->@*;
                }
                if ( my $post = $sections->get( "append:" . fc($heading) ) ) {
                    push $pod->children->@*, $post->@*;
                }
                return ($pod);
            }
        }

        return;
    }

    my $preamble = "=encoding " . $self->encoding . "\n";
    return join(
        "\n",
        $preamble,                    #
        map { $_->as_pod_string }     #
          map { _get_section($_) }    #
          $self->sections->@*
    );
}

sub _fake_weaver_section( $self, $class, $args = { } ) {

    # Note: ideally we would add these as development requirements but by the time this is run (after building or
    # release), the requirements have already been finalized.

    # RECOMMEND PREREQ: Pod::Weaver
    use_module("Pod::Weaver");
    use_module($class);

    my $zilla = $self->zilla;

    my $doc = Pod::Elemental::Document->new;

    my $weaver  = Pod::Weaver->new_with_default_config;
    my $section = $class->new( plugin_name => ref($self), weaver => $weaver, logger => $zilla->logger );
    $section->weave_section( $doc, { zilla => $zilla, filename => $zilla->main_module->name, $args->%* } );

    return $doc->children->@*;
}

sub _generate_pod_for_version($self) {
  # RECOMMEND PREREQ: Pod::Weaver::Section::Version
  return $self->_fake_weaver_section( "Pod::Weaver::Section::Version", { version => $self->zilla->version } );
}

sub _generate_pod_for_installation($self) {
    return $self->_fake_weaver_section( "Pod::Weaver::Section::InstallationInstructions" );
}

sub _generate_pod_for_requirements($self) {
    my $file = $self->zilla->main_module;
    return $self->_fake_weaver_section(
        "Pod::Weaver::Section::Requirements",
        {
            ppi_document => $self->ppi_document_for_file($file),
        }
    );
}

sub _generate_pod_for_recent_changes($self) {
    return $self->_fake_weaver_section( "Pod::Weaver::Section::RecentChanges", { version => $self->zilla->version } );
}


sub BUILD( $self, $ ) {

    $self->log_fatal("Cannot use location='build' with phase='release'")
      if $self->location eq 'build' and $self->phase eq 'release';

}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::UsefulReadme - generate a README file with the useful bits

=head1 VERSION

version v0.4.2

=head1 SYNOPSIS

In the F<dist.ini>

    [UsefulReadme]
    type     = markdown
    filename = README.md
    phase    = build
    location = build
    section = name
    section = synopsis
    section = description
    section = requirements
    section = installation
    section = bugs
    section = source
    section = author
    section = copyright and license
    section = see also

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin to filter the main module POD to generate a F<README> file.  It allows developers to
determine which sections are incorporated into the F<README> rather than dumping the entire main module documentation.

This also supports including special sections for showing the most recent entry in the F<Changes> file, showing the
runtime requirements, and including installation instructions.

This was written as a successor to L<Pod::Readme> that works better with L<Pod::Weaver>.

=head1 CONFIGURATION OPTIONS

=head2 source

This is the path to the module that will be used for generating the F<README>.

It will default to the main module.

=head2 phase

This is the phase to generate the F<README>.

Allowed values are C<build> (default) or C<release>.

=head2 location

This is where the new F<README> will be saved.

Allowed values are C<build> (default) or the distribution C<root>.

=head2 encoding

The encoding of the POD. Defaults to C<utf8>.  See L<Encode::Supported>.

This was added in v0.2.0.

=head2 section_fallback

If one of the L</sections> does not exist in the POD, then generate one for the F<README>.
It is true by default but cal be disabled, e.g.

    fallback = 0

=head2 sections

This is a list of C<=head1> sections to be included in the L<README|/filename>.
It can be specified multiple times using the C<section> option.

This can either be a case-insensitive string, or a regex that implicitly matches the entire heading, surrounded by slashes.

The default is equivalent to specifying

    section = name
    section = synopsis
    section = description
    section = recent changes
    section = requirements
    section = installation
    section = /support|bugs/
    section = source
    section = /authors?/
    section = /contributors?/
    section = /copyright|license|copyright and license/
    section = see also

The C<version>, C<requirements>, C<installation> and C<recent changes> sections are special.
If they do not exist in the module POD, then default values will be used for them unless L</section_fallback> is false.

This will also include C<=head1> sections in L</regions> marked as C<readme>, normally used for L<Pod::Readme>:

    =begin :readme

    =head1 REQUIREMENTS

    This should only be visible in the README.

    =end :readme

If you want to amend one of the generated fallback sections akin to L<Pod::Weaver::Plugin::AppendPrepend>, you must
specify them inside of C<readme> regions.

To append something to the end of a generated section:

    =begin :readme

    =head1 append:INSTALLATION

    Remember to bring a towel.

    =end :readme

To prepend something to the beginning of a generated section:

    =begin :readme

    =head1 prepend:REQUIREMENTS

    This requires L<libexample|http://www.example.org> to be installed on your system.

    =end :readme

Note that multiple append and prepend blocks must be in separate region blocks.

=head2 type

This is the file to generate the F<README>.

Allowed values are C<pod>, C<text> (default), C<markdown>, C<gfm> (GitHub-flavoured markdown) or C<custom>.

Note that the L</filename> will have a different default, depending on the type.

If C<custom> is chosen, then you must specify a L</filename> and L</parser_class>.

=head2 parser_class

This is the POD parser class, based on the L</type>.

=head2 filename

This is the filename to use, e.g. F<README> or F<REAME.md>.

=head2 regions

This is a list of regions inside of C<=for> or C<=begin/=end> paragraphs to be included in any sections.

By default, it includes C<stopwords>, L<Pod::Coverage>, and L<Test::MixedScripts>.

You may need to override this to include other region types, e.g.

    type = markdown
    region = markdown
    region = stopwords
    region = Pod::Coverage

Note that this is not updated automatically from the L</type> because how regions are embedded in POD varies too widely
to assume that it is always safe to include arbitrary regions with the same name.

The C<readme> region is I<not> included since that has a special meaning to indicate sections that are included only in
the F<README> file.

This was added in v0.2.0.

=for Pod::Coverage BUILD after_build after_release gather_files mvp_aliases mvp_multivalue_args prune_files register_prereqs

=head1 SEE ALSO

L<Dist::Zilla>

L<Pod::Weaver>

L<Pod::Readme>

L<Dist::Zilla::Plugin::Readme::Brief>

L<Dist::Zilla::Plugin::ReadmeAnyFromPod>

=head1 SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.20 or later.  Future releases may only support Perl versions released in the last ten
years.

=head2 Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Dist-Zilla-Plugin-UsefulReadme/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see F<SECURITY.md> for instructions how to report security vulnerabilities.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Dist-Zilla-Plugin-UsefulReadme>
and may be cloned from L<git://github.com/robrwo/perl-Dist-Zilla-Plugin-UsefulReadme.git>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

Some of this code was adapted from similar code in L<Dist::Zilla::Plugin::ReadmeAnyFromPod> and
L<Dist::Zilla::Plugin::Readme::Brief>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Robert Rothenberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
