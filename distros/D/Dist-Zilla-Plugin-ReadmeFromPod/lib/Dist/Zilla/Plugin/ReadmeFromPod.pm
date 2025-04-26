package Dist::Zilla::Plugin::ReadmeFromPod;
our $AUTHORITY = 'cpan:AVAR';
$Dist::Zilla::Plugin::ReadmeFromPod::VERSION = '0.39';
use v5.10.1;

use Moose;

use List::Util 1.33 qw( first none );
use IO::String;
use Moose::Util::TypeConstraints qw( enum );
use Pod::Readme v1.2.0;
use Path::Tiny 0.004;

with qw( Dist::Zilla::Role::AfterBuild
  Dist::Zilla::Role::AfterRelease
  Dist::Zilla::Role::FilePruner
);

has filename => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    builder => '_build_filename',
);

sub _build_filename {
    my $self = shift;
    # copied from Dist::Zilla::Plugin::ReadmeAnyFromPod
    my $pm = $self->zilla->main_module->name;
    (my $pod = $pm) =~ s/\.pm$/\.pod/;
    return -e $pod ? $pod : $pm;
}

my %FORMATS = (
    'gfm'      => { class => 'Pod::Markdown::Github' },
    'github'   => { class => 'Pod::Markdown::Github' },
    'html'     => { class => 'Pod::Simple::HTML' },
    'markdown' => { class => 'Pod::Markdown'     },
    'pod'      => { class => undef },
    'rtf'      => { class => 'Pod::Simple::RTF' },
    'text'     => { class => 'Pod::Simple::Text' },
);

has type => (
    is => 'ro',
    isa => enum( [ keys %FORMATS ] ),
    default => 'text',
);

has pod_class => (
    is => 'ro',
    isa => 'Maybe[Str]',
    lazy => 1,
    builder => '_build_pod_class',
);

sub _build_pod_class {
  my $self = shift;
  my $fmt  = $FORMATS{$self->type}
    or $self->log_fatal("Unsupported type: " . $self->type);
  $fmt->{class};
}

has readme => (
    is => 'ro',
    isa => 'Str',
);

has phase => (
    is      => 'ro',
    lazy    => 1,
    isa     => enum( [qw(build release)] ),
    default => 'build',
);

sub prune_files {
    my ($self) = @_;
    my $readme_file = first { $_->name =~ m{^README\z} } @{ $self->zilla->files };
    if ($readme_file and $readme_file->added_by =~ /Dist::Zilla::Plugin::Readme/) {
        $self->log_debug([ 'pruning %s', $readme_file->name ]);
        $self->zilla->prune_file($readme_file);
    }
}

sub after_build {
    my ($self) = @_;
    $self->_create_readme if $self->phase eq 'build';
}
sub after_release {
    my ($self) = @_;
    $self->_create_readme if $self->phase eq 'release';
}

sub _create_readme {
    my ($self) = @_;

    my $pod_class = $self->pod_class;
    my $readme_name = $self->readme;

    ## guess pod_class from exisiting file, like GitHub will have README.md created
    my $readme_file;
    if (not $readme_name) {
        my %ext = (
            'md'       => 'markdown',
            'mkdn'     => 'markdown',
            'markdown' => 'markdown',
            'html'     => 'html',
            'htm'      => 'html',
            'rtf'      => 'rtf',
            'txt'      => 'text',
            ''         => 'text',
            'pod'      => 'pod'
        );
        foreach my $e (keys %ext) {
            my $test_readme_file = path($self->zilla->root)->child($e ? "README.$e" : 'README');
            if (-e "$test_readme_file") {
                $readme_file = $test_readme_file;
                $pod_class = $FORMATS{ $ext{$e} }->{class};
                last;
            }
        }
    }

    my $source = first { $_->name eq $self->filename } @{ $self->zilla->files };

    my $content;
    my $prf = Pod::Readme->new(
      input_fh          => IO::String->new( $source->content ),
      translate_to_fh   => IO::String->new($content),
      translation_class => $pod_class,
      force             => 1,
      zilla             => $self->zilla,
    );
    $prf->run();

    if ($readme_file) {
        return $readme_file->spew_raw($content);
    }

    $readme_name ||= $prf->default_readme_file;
    my $file = first { $_->name eq $readme_name } @{ $self->zilla->files };
    if ( $file ) {
        $file->content( $content );
        $self->zilla->log("Override README from [ReadmeFromPod]");
    } else {
        require Dist::Zilla::File::InMemory;
        $file = Dist::Zilla::File::InMemory->new({
            content => $content,
            name    => "${readme_name}", # stringify, as it may be Path::Tiny
        });
        $self->add_file($file);
    }

    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;


=head1 NAME

Dist::Zilla::Plugin::ReadmeFromPod - dzil plugin to generate README from POD

=head1 SYNOPSIS

    # dist.ini
    [ReadmeFromPod]

    # or
    [ReadmeFromPod]
    filename = lib/XXX.pod
    type = markdown
    readme = READTHIS.md
    phase = build

=head1 DESCRIPTION

This plugin generates the F<README> from C<main_module> (or specified)
by L<Pod::Readme>.

=head1 ATTRIBUTES

The following options are supported:

=head2 filename

The name of the file to extract the F<README> from. This defaults to
the main module of the distribution.

=head2 type

The type of F<README> you want to generate. This defaults to "text".

Other options are "html", "pod", "markdown" and "rtf".

=head2 pod_class

This is the L<Pod::Simple> class used to translate a file to the
format you want. The default is based on the L</type> setting, but if
you want to generate an alternative type, you can set this option
instead.

=head2 readme

The name of the file, which defaults to one based on the L</type>.

=head2 phase

This indicates what phase to build the README file from. It is either C<build> (the default) or C<release>.

=head1 AUTHORS

Fayland Lam <fayland@gmail.com> and
E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

Robert Rothenberg <rrwo@cpan.org> modified this plugin to use
L<Pod::Readme>.

Some parts of the code were borrowed from L<Dist::Zilla::Plugin::ReadmeAnyFromPod>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2025 Fayland Lam <fayland@gmail.com> and E<AElig>var
ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
