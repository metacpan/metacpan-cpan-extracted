## no critic (ControlStructures::ProhibitPostfixControls)
package Dist::Zilla::Plugin::Test::Software::Policies;
use strict;
use warnings;
use 5.010;

# ABSTRACT: Tests to check your code against best practices
our $VERSION = '0.002';
use Moose;

use Moose::Util::TypeConstraints qw(
  role_type
);
use Dist::Zilla::File::InMemory;
use Sub::Exporter::ForMethods 'method_installer';
use Data::Section 0.004 { installer => method_installer }, '-setup';
use Data::Dumper ();
use namespace::autoclean;
use Path::Tiny         qw( path );
use List::Util         qw( any first );
use Software::Policies ();

with(
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [],
    },
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::TextTemplate',
    'Dist::Zilla::Role::PrereqSource',
);

has include_policy => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

has exclude_policy => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

has filepath_template => (
    is => 'ro',
    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    default => 'xt/author/policy_{{ $policy }}.t',
);

# Internal

has _project_policies => (
    is => 'ro',

    # isa => role_type('Software::Policies'),
    default => sub {
        Software::Policies->new;
    },
);

has _test_files => (
    is => 'ro',

    # isa => q{ArrayRef[role_type('Dist::Zilla::Role::File')]},
    lazy    => 1,
    default => sub {
        my $self  = shift;
        my $zilla = $self->zilla;

        # $zilla->log_debug( [ 'include_policy: %s', $self->include_policy() ] );
        my @policy_plugins = grep {
            $_->isa('Dist::Zilla::Plugin::Software::Policies')

              # Exclude the "General definitions"
              && $_->plugin_name ne 'Software::Policies'
        } @{ $zilla->plugins };
        my %check_policies;

        # Test::Software::Policies first checks if
        # 1) there is any include_policy config items. If there is, limit to those.
        # 2) If there is no include_policy,
        # look for [Software::Policies [/policy] ] configs and take all those.
        # 3) If there is no [Software::Policies [/policy] ] configs,
        # ask Software::Policies->list for all availabe and take all.
        # 4) If there is any exclude_policy config items
        # in [Test::Software::Policies]], remove those from the list.
        # 5) Now we have the complete list of policies which need to be checked.
        if ( @{ $self->include_policy() } ) {
            $zilla->log_debug( ['We have include_policies'] );
            foreach my $include_policy ( @{ $self->include_policy() } ) {
                $zilla->log_debug( [ 'Include policy %s from include_policy config item', $include_policy ] );
                $check_policies{$include_policy} = 1;
            }
        }
        elsif (@policy_plugins) {
            $zilla->log_debug( ['We check what [Software::Policies] plugins are in use'] );
            %check_policies = map { $_->plugin_name => 1 } @policy_plugins;
            $zilla->log_debug( [ 'We have the policies: %s', \%check_policies ] );
        }
        else {
            $zilla->log_debug( ['We take all [Software::Policies] which are available'] );
            %check_policies = map { $_ => 1 } keys %{ $self->_project_policies()->list() };
            $zilla->log_debug( [ 'We have the policies: %s', \%check_policies ] );
        }

        my @files;
        foreach my $policy ( keys %check_policies ) {
            my %args = $self->_get_policy_config( $policy, {} );
            $args{policy} = $policy;
            $self->zilla()
              ->log_debug(
                [ 'Looking for matching policy: %s:%s:%s:%s', $args{'policy'}, $args{'class'}, $args{'version'}, $args{'format'} ]
              );

            my @p = Software::Policies->new()->create(%args);
            if ( @p > 1 ) {
                foreach (@p) {
                    my $fn = $self->fill_in_string( $self->filepath_template(),
                        { policy => $policy . q{_} . ( $_->{'filename'} =~ s/[.]/_/grmsx ), } );

                    # Attach the ready made policy file content to the end of the file, in the __DATA__ section.
                    my $content = $self->fill_in_string(
                        ${ $self->section_data('test-policy') } . $_->{'text'},
                        { dumper => \\&_dumper, filepath => $_->{'filename'}, }
                    );
                    push @files, Dist::Zilla::File::InMemory->new( name => $fn, content => $content, );
                }
            }
            else {
                my $fn = $self->fill_in_string( $self->filepath_template(), { policy => $policy, } );

                # Attach the ready made policy file content to the end of the file, in the __DATA__ section.
                my $content = $self->fill_in_string(
                    ${ $self->section_data('test-policy') } . $p[0]->{'text'},
                    { dumper => \\&_dumper, filepath => $p[0]->{'filename'}, }
                );
                push @files, Dist::Zilla::File::InMemory->new( name => $fn, content => $content, );
            }

        }
        return \@files;
    },
);

sub mvp_multivalue_args {
    return qw(
      files include_policy exclude_policy
    );
}

around BUILDARGS => sub {
    my ( $orig, $class, @arg ) = @_;
    my $args  = $class->$orig(@arg);
    my %copy  = %{$args};
    my $zilla = delete $copy{zilla};
    $zilla->log_debug( 'copy=%s', \%copy );
    my $name = delete $copy{plugin_name};
    my %other;
    $other{'include_policy'}    = delete $copy{include_policy}    if $copy{include_policy};
    $other{'exclude_policy'}    = delete $copy{exclude_policy}    if $copy{exclude_policy};
    $other{'filepath_template'} = delete $copy{filepath_template} if $copy{filepath_template};
    $zilla->log_debug( [ 'Policy %s. Collected attributes: %s', $name, \%other ] );

    if (%copy) {
        $zilla->log_fatal( [ 'Unknown configuration option(s): %s', ( join q{,}, keys %copy ) ] );
    }
    return {
        zilla       => $zilla,
        plugin_name => $name,

        # _prereq     => \%copy,
        %other,
    };
};

sub gather_files {
    my $self = shift;
    foreach my $file ( @{ $self->_test_files() } ) {
        $self->add_file($file);
    }
    return;
}

sub register_prereqs {
    my $self = shift;

    return $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        'Software::Policies' => 0,
    );
}

sub _dumper {
    my ($value) = @_;
    local $Data::Dumper::Indent        = 1;
    local $Data::Dumper::Useqq         = 1;
    local $Data::Dumper::Terse         = 1;
    local $Data::Dumper::Sortkeys      = 1;
    local $Data::Dumper::Trailingcomma = 1;
    my $dump = Data::Dumper::Dumper($value);
    $dump =~ s{\n\z}{}msx;
    return $dump;
}

sub munge_file {
    my ( $self, $file ) = @_;
    my $zilla = $self->zilla;
    $zilla->log_debug( [ 'munge_file(%s)', $file->name ] );

    return $file;
}

sub _get_policy_config {
    my ( $self, $policy, $opt ) = @_;
    my $zilla = $self->zilla;

    # 1. "Default" values, taken from dist.ini
    my %args;
    my %attributes = (
        name     => $zilla->{'name'},
        abstract => $zilla->{'abstract'},
        authors  => $zilla->{'authors'},

        # license           => $zilla->{'license'},
        # main_module       => $zilla->{'main_module'},
        version => $zilla->version,
    );
    $zilla->log_debug( ['After 1.'] );
    $zilla->log_debug( [ 'args: %s',       \%args, ] );
    $zilla->log_debug( [ 'attributes: %s', \%attributes, ] );

    # 2. Config items applied to all policies.
    # Only "[Software::Policies]"
    my $plain_plugin = first { $_->isa('Dist::Zilla::Plugin::Software::Policies') && $_->plugin_name eq 'Software::Policies' }
      @{ $zilla->{'plugins'} };
    if ($plain_plugin) {
        $zilla->log_debug( ['Discovered general setting for Software::Policies'] );
        for my $key (qw( class version format dir filename )) {
            $args{$key} = $plain_plugin->{$key} if $plain_plugin->{$key};
        }
        my %policy_attributes = %{ $plain_plugin->{'policy_attribute'} };
        @attributes{ keys %policy_attributes } = @policy_attributes{ keys %policy_attributes };
    }
    $zilla->log_debug( ['After 2.'] );
    $zilla->log_debug( [ 'args: %s',       \%args, ] );
    $zilla->log_debug( [ 'attributes: %s', \%attributes, ] );

    # 3. Only one policy's config
    # Only "[Software::Policies / $policy]", plugin_name is changed in Plugin::S::p!
    my $this_plugin =
      first { $_->isa('Dist::Zilla::Plugin::Software::Policies') && $_->plugin_name =~ m/^ $policy $/msx } @{ $zilla->{'plugins'} };
    if ($this_plugin) {
        $zilla->log_debug( [ 'Discovered config for Software::Policies / %s: %s', $policy, $this_plugin->plugin_name ] );
        for my $key (qw( class version format dir filename )) {
            $args{$key} = $this_plugin->{$key} if $this_plugin->{$key};
        }
        my %policy_attributes = %{ $this_plugin->{'policy_attribute'} };
        @attributes{ keys %policy_attributes } = @policy_attributes{ keys %policy_attributes };
    }

    # 4. Config from the command line.
    for my $key (qw( class version format dir filename )) {
        $args{$key} = $opt->{$key} if $opt->{$key};
    }
    my %attrs = map { split qr/\s*=\s*/msx, $_, 2 } ( map { split qr/,/msx } $opt->{'attributes'} // q{} );
    @attributes{ keys %attrs } = @attrs{ keys %attrs };

    # Set attributes into %args.
    $args{attributes} = \%attributes;
    $zilla->log_debug( [ 'args: %s',       \%args, ] );
    $zilla->log_debug( [ 'attributes: %s', \%attributes, ] );

    return %args;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::Software::Policies - Tests to check your code against best practices

=head1 VERSION

version 0.002

=head1 SYNOPSIS

In your F<dist.ini>:

=head1 DESCRIPTION

This L<Dist::Zilla> plugin creates author test files for use during
the C<test> and C<release> runs of C<dzil>. Examples of these files:
F<xt/author/policy_contributing.t> and F<xt/author/policy_code_of_conduct.t>.

These tests will ensure that the file in question, e.g. F<CODE_OF_CONDUCT.md>,
is in the distribution, and is up to date
and matches with the information in the F<dist.ini> file.

To use this, make the changes to F<dist.ini>
above and run one of the following:

    dzil test
    dzil release

=for Pod::Coverage gather_files register_prereqs munge_file

=for stopwords LICENCE

=for test_synopsis BEGIN { die "SKIP: skip this pod!\n"; }

    [Test::Software::Policies]
    exclude_policy = CodeOfConduct

=head1 ATTRIBUTES

=head2 include_policy

=head2 include_policy

=head2 filepath_template

The file name of the test files to generate. Defaults to C<'xt/author/policy_{{ $policy }}.t'> as in F<xt/author/policy_contributing.t>.

Allowed characters: [A-Za-z0-9-_./{}$]

=head1 AUTHOR

Mikko Koivunalho <mikkoi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__[ test-policy ]__
#!perl

use strict;
use warnings;
use 5.010;

our $VERSION = 0.001;

use English qw( -no_match_vars ) ;  # Avoids regex performance
                                    # penalty in perl 5.18 and
                                    # earlieri
use Test2::V0;
use Test2::Plugin::BailOnFail;

use Path::Tiny qw( path );

ok(path('{{ $filepath }}')->is_file(), 'Policy file {{ $filepath }} exists');

# Read file and remove whitespace from the end.
my $policy = path('{{ $filepath }}')->slurp_utf8 =~ s/[[:space:]]+$//rmsx;

my (@policy_lines, @wanted_lines);
foreach (split qr{\R}msx, $policy) { push @policy_lines, $_; }
do {
    local $INPUT_RECORD_SEPARATOR = undef;
    my $wanted = <DATA>;
    # Remove whitespace from the end.
    $wanted =~ s/[[:space:]]+$//msx;
    foreach (split qr{\R}msx, $wanted) { push @wanted_lines, $_; }
};
    is(\@policy_lines, \@wanted_lines, 'Policy file {{ $filepath }} is current');

done_testing;

__DATA__
