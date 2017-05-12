package Dist::Zilla::Plugin::InlineModule;
our $VERSION = '0.07';

use Inline::Module();

use Moose;
extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';
with qw(Dist::Zilla::Role::AfterBuild Dist::Zilla::Role::FileGatherer);

has module => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    required => 1,
);

has stub => (
    is => 'ro',
    lazy => 1,
    builder => '_build_stub',
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    required => 0,
);

has ilsm => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    required => 0,
    default => sub { ['Inline::C'] },
);

has bundle => (
    is => 'ro',
    default => sub { 1 },
);

sub _build_stub {
    my ($self) = @_;
    return [ map "${_}::Inline", @{$self->module} ];
}

# Lets us pass the options more than once:
sub mvp_multivalue_args { qw(module stub ilsm) }

# Add lines to use Inline::Module to Makefile.PL
around _build_header => sub {
    return <<'...';

use lib 'inc';
use Inline::Module;

...
};

# Add list of modules to the postamble arguments.
around _build_WriteMakefile_args => sub {
    my $orig = shift;
    my $self = shift;

    my $make_args = $self->$orig(@_);
    $self->{inline_meta} =
    $make_args->{postamble}{inline} = {
        module => $self->module,
        stub => $self->stub,
        ilsm => $self->ilsm,
        bundle => $self->bundle,
    };

    return $make_args;
};

sub after_build {
    my ($self, $hash) = @_;

    my $meta = $self->{inline_meta};

    my $files_added = Inline::Module->add_to_distdir(
        $hash->{build_root}->stringify,
        $meta->{stub},
        Inline::Module->included_modules($meta),
    );

    # The following will make sure that Dist::Zilla knows about the written
    # files so that it can add them to the tarball.
    $self->add_file( Dist::Zilla::File::OnDisk->new( name => $_ ) )
        for @$files_added;
}

1;
