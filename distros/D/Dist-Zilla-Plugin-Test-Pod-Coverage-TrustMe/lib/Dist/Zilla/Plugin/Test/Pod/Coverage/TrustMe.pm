use v5.20;
use warnings;
use experimental qw(signatures postderef);
package Dist::Zilla::Plugin::Test::Pod::Coverage::TrustMe;

our $VERSION = 'v1.0.0';

{
    use Moose;
    use Moose::Util::TypeConstraints qw(
        as
        role_type
        subtype
        coerce
    );
}
use Dist::Zilla::File::InMemory;
use Data::Dumper ();

use namespace::clean;

use Data::Section 0.200002 -setup;

with (
    'Dist::Zilla::Role::PrereqSource',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [ ':InstallModules' ],
    },
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::TextTemplate',
);

sub mvp_multivalue_args { qw(
    modules
    options
    private
    also_private
    trust_methods
) }
sub mvp_aliases { {
    module => 'modules',
    option => 'options',
} }

sub register_prereqs ($self) {
    $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        'Test::Pod::Coverage::TrustMe' => '0',
    );
}

around dump_config => sub ($orig, $self) {
    my $config = $self->$orig;

    my $options = $self->options;

    my @options = map "$_ => $options->{$_}", sort keys %$options;

    $config->{+__PACKAGE__} = {
        finder => [ sort $self->finder->@* ],
        (
            map {
                my $value = $self->$_;
                ( $_ => [ map { re::is_re($_) ? "/$_/" : "$_" } @$value ] );
            }
            grep { my $method = "has_$_"; $self->$method }
            qw(
                modules
                private
                also_private
                trust_methods
            )
        ),
        (
            map +( $_ => ($self->$_ ? 1 : 0) ),
            grep { my $method = "has_$_"; $self->$method }
            qw(
                require_content
                trust_parents
                trust_roles
                trust_packages
                trust_pod
                require_link
                export_only
                ignore_imported
            )
        ),
        ( @options ? ( options => \@options ) : () ),
    };
    return $config;
};

has filename => (
    is => 'ro',
    default => 'xt/author/pod-coverage.t',
);

has _file => (
    is => 'ro',
    isa => role_type('Dist::Zilla::Role::File'),
    lazy => 1,
    default => sub ($self) {
        return Dist::Zilla::File::InMemory->new(
            name => $self->filename,
            content => ${$self->section_data('test-pod-coverage-trustme')},
        );
    },
);

has has_modules => (
    is => 'rw',
);

has modules => (
    is => 'bare',
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => {
        modules => 'sort',
    },
    lazy => 1,
    trigger => sub ($self, @) {
        $self->has_modules(1);
    },
    default => sub ($self) {
        return [
            map s{[/\\]}{::}gr,
            map s{\.pm\z}{}r,
            map s{\Alib[/\\]}{}r,
            grep m{\.pm\z},
            map $_->name,
            $self->found_files->@*
        ];
    },
);

my $RegexpOption = subtype as 'ArrayRef[RegexpRef]';
coerce $RegexpOption,
    'ArrayRef[Str]' => sub {
        [
            map {
                m{\A/(.*)/([msi]*)\z} ? ( $2 ? qr/(?$2)$1/ : qr/$1/ )
                                      : qr/\A\Q$_\E\z/
            } @$_
        ];
    },
;

has private => (
    is => 'ro',
    isa => $RegexpOption,
    coerce => 1,
    predicate => 'has_private',
);
has also_private => (
    is => 'ro',
    isa => $RegexpOption,
    coerce => 1,
    predicate => 'has_also_private',
);
has trust_methods => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    predicate => 'has_trust_methods',
);

has require_content => (
    is => 'ro',
    predicate => 'has_require_content',
);
has trust_parents => (
    is => 'ro',
    predicate => 'has_trust_parents',
);
has trust_roles => (
    is => 'ro',
    predicate => 'has_trust_roles',
);
has trust_packages => (
    is => 'ro',
    predicate => 'has_trust_packages',
);
has trust_pod => (
    is => 'ro',
    predicate => 'has_trust_pod',
);
has require_link => (
    is => 'ro',
    predicate => 'has_require_link',
);
has export_only => (
    is => 'ro',
    predicate => 'has_export_only',
);
has ignore_imported => (
    is => 'ro',
    predicate => 'has_ignore_imported',
);

my $Options = subtype as 'HashRef';
coerce $Options,
    'ArrayRef' => sub {
        +{
            map s/\A\s+//r,
            map s/\s+\z//r,
            map split(/=>?/, $_, 2),
            @$_
        };
    },
;

has options => (
    is => 'ro',
    isa => $Options,
    coerce => 1,
    default => sub { { } },
);

sub gather_files ($self) {
    $self->add_file( $self->_file );
}

sub _dumper ($value) {
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Trailingcomma = 1;
    Data::Dumper::Dumper($value) =~ s{\n\z}{}r;
}

sub munge_file ($self, $file) {
    return
        unless $file == $self->_file;

    $file->content(
        $self->fill_in_string(
            $file->content,
            {
                dist    => \($self->zilla),
                plugin  => \$self,
                dumper  => \\&_dumper,
                modules => [ $self->modules ],
                options => {
                    (
                        map +( $_ => $self->$_ ),
                        grep { my $method = "has_$_"; $self->$method }
                        qw(
                            private
                            also_private
                            trust_methods
                            require_content
                            trust_parents
                            trust_roles
                            trust_packages
                            trust_pod
                            require_link
                            export_only
                            ignore_imported
                        )
                    ),
                    %{ $self->options },
                },
            }
        )
    );
}

__PACKAGE__->meta->make_immutable;
1;

=pod

=encoding UTF-8

=for :stopwords Graham Knop

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/haarg/Dist-Zilla-Plugin-Test-Pod-Coverage-TrustMe/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Graham Knop <haarg@haarg.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Graham Knop.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ test-pod-coverage-trustme ]___
# This file was automatically generated by Dist::Zilla::Plugin::Test::Pod::Coverage::TrustMe {{ $plugin->VERSION }}
use strict;
use warnings;
use Test::More;
use Test::Pod::Coverage::TrustMe;

my $config = {{ $dumper->(\%options) }};
my $modules = {{ $dumper->(\@modules) }};

plan tests => scalar @$modules;

for my $module (@$modules) {
    pod_coverage_ok($module, $config);
}

done_testing;
__END__

=pod

=encoding UTF-8

=for Pod::Coverage gather_files munge_file mvp_aliases register_prereqs

=head1 NAME

Dist::Zilla::Plugin::Test::Pod::Coverage::TrustMe - An author test for Pod Coverage

=head1 SYNOPSIS

    # Add this line to dist.ini
    [Test::Pod::Coverage::TrustMe]

    # Run this in the command line to test for POD coverage:
    $ dzil test --release

=head1 DESCRIPTION


=head1 OPTIONS

=over 4

=item filename

The name of the test file to generate. Defaults to F<xt/author/pod-coverage.t>.

=item modules

The modules to check for coverage.

Aliased as C<module>.

=item finder

The L<file finder|https://metacpan.org/pod/Dist::Zilla::Role::FileFinderUser/default_finders>
used to find modules to check. Will only be used if a list of modules is not
given. Defaults to C<:InstallModules>.

To generate the list of modules, the output of this finder will be filtered to
only files ending in C<.pm> and will be transformed to module names after
stripping an initial C<lib/>.

=item private

Methods to treat as private, with their coverage not checked. Will be passed to
L<Test::Pod::Coverage::TrustMe>. String values can be passed directly. Regexp
values can be passed with the form C</.../>. Can be specified multiple times.

=item also_private

Exactly the same as L</private>, but adds to the list of default private methods
rather than replacing it.

=item trust_methods

A list of methods to always treat as covered. Will be passed to
L<Test::Pod::Coverage::TrustMe>. Can be specified multiple times.

=item require_content

=item trust_parents

=item trust_roles

=item trust_packages

=item trust_pod

=item require_link

=item export_only

=item ignore_imported

These options are all passed directly to L<Test::Pod::Coverage::TrustMe>.

=item options

Additional options to pass to L<Test::Pod::Coverage::TrustMe>. Options should
be specified like:

    options = extra_option = 1

=back

=cut
