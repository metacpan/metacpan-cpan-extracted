package Dist::AutomationPolicy;

use v5.24;

use Moo;

use Carp qw( croak );
use File::ShareDir qw( dist_file );
use JSON ();
use JSON::Schema::Validate v0.7.0;
use Path::Tiny qw( path );
use PerlX::Maybe qw( maybe );

use namespace::clean;

use experimental qw( postderef signatures );

our $VERSION = 'v0.2.2';

# ABSTRACT: generate and parse distribution automation policies


has version => (
    is       => 'ro',
    default  => 1,
    required => 1,
);


has distribution => (
    is        => 'ro',
    predicate => 1,
);


has description => (
    is        => 'ro',
    predicate => 1,
);


has document => (
    is        => 'ro',
    predicate => 1,
);


has code_generation => (
    is       => 'ro',
    required => 1,
);


has automated_contributions => (
    is       => 'ro',
    required => 1,
);


has automated_actions => (
    is       => 'ro',
    required => 1,
);


has models => (
    is     => 'ro',
    coerce => sub($val) {
        return $val if ref($val) eq "ARRAY";
        return [$val];
    },
    builder => sub($self) { return [] },
);


has filename => (
    is      => 'lazy',
    default => 'CPAN-META/automation-policy.json',
);

my $json = JSON->new->utf8->pretty->canonical;

my $file = path( dist_file( __PACKAGE__ =~ s/::/-/gr, "automation-policy-schema.json" ) );

my $schema = JSON::Schema::Validate->new( $json->decode( $file->slurp_raw ), compile => 1, );


sub data($self) {
    #<<<
    return {
        version                 => $self->version,
        maybe distribution      => $self->distribution,
        maybe description       => $self->has_description ? $self->description : undef,
        maybe document          => $self->has_document    ? $self->document    : undef,
        code_generation         => $self->code_generation,
        automated_contributions => $self->automated_contributions,
        automated_actions       => $self->automated_actions,
        maybe models            => $self->models->[0] ? $self->models : undef,
    };
    #>>>
}


sub validate( $self, $data = undef ) {
    $data //= $self->data;
    return $schema->is_valid( $data );
}


sub to_json($self) {
    return $json->encode( $self->data );
}


sub BUILD( $self, $ ) {
    $schema->is_valid( $self->data ) or die $schema->error;
}


sub BUILDARGS( $, @args ) {

    if ( @args == 1 && !ref( $args[0] ) ) {
        unshift @args, "template";
    }

    my %args = ( @args == 1 && ref( $args[0] ) eq "HASH" ) ? $args[0]->%* : @args;

    if ( my $version = $args{version} ) {
        croak "unsupported version '${version}'" if $version ne 1;
    }


    if ( my $template = delete $args{template} ) {

        my %templates = (

            no_automation => {
                code_generation         => "toolchain",
                automated_contributions => "none",
                automated_actions       => "comment",
              },

              issues_only => {
                code_generation         => "toolchain",
                automated_contributions => "issue",
                automated_actions       => "issue",
              },

              human_supervised => {
                code_generation         => "machine_generated",
                automated_contributions => "code_request",
                automated_actions       => "code_request",
              },

              data_driven_updates => {
                code_generation         => "external_sources",
                automated_contributions => "issue",
                automated_actions       => "release",
              },

              full_automation => {
                code_generation         => "code_generation",
                automated_contributions => "code_request",
                automated_actions       => "release",
              },

        );

        if ( my $match = $templates{$template} ) {

            for my $attr ( keys $match->%* ) {
                $args{$attr} //= $match->{$attr};
            }

        }
        else {
            croak "Unsupported template: '${template}'";
        }


    }

    return \%args;
}


sub from_json( $class, @args ) {


    if ( @args == 1 && !ref( $args[0] ) ) {
        unshift @args, "json";
    }

    my %args = ( @args == 1 && ref( $args[0] ) eq "HASH" ) ? $args[0]->%* : @args;

    croak "json is required" unless defined $args{json};

    $args{json} = $json->decode( $args{json} ) unless ref( $args{json} );

    if ( my $res = $schema->validate( $args{json} ) ) {
        return $class->new( $args{json} );
    }
    else {
        croak $_ for $res->errors;
    }

}

1;

__END__

=pod

=encoding UTF-8

=for stopwords LLMs Duponchelle Legge Nilsen Rinaldo Rochelemagne Thibault Timmermans TypeScript minifiers preprocessors

=head1 NAME

Dist::AutomationPolicy - generate and parse distribution automation policies

=head1 VERSION

version v0.2.2

=head1 SYNOPSIS

To create an automation policy file:

    use Dist::AutomationPolicy;
    use Path::Tiny qw( path ) 0.130;

    my $pol = Dist::AutomationPolicy->new(
        distribution            => "Dist-AutomationPolicy-v0.1.0",
        code_generation         => "toolchain",
        automated_contributions => "issue",
        automated_actions       => "code_request",
        models                  => [ "claude-sonnet-4.6" ],
    );

    if ( $pol->validate ) {
        my $path = path( ".", $pol->filename ); # "CPAN-META/automation-policy.json"
        $path->parent->mkdir;
        $path->spew_raw( $pol->to_json );
    }

To read an automation policy file:

    my $path = path( "CPAN-META/automation-policy.json" );

    my $pol  = Dist::AutomationPolicy->from_json( json => $path->slurp_raw );

=head1 DESCRIPTION

This module allows package maintainers to specify machine-readable metadata about their policies regarding automation:
how code is generated,
whether automated contributions are allowed,
and whether there are automated actions run by the maintainers.

This is separate but complimentary to including an F<AI_POLICY.md> or F<CONTRIBUTING.md> file in the distribution.

=head1 ATTRIBUTES

=head2 version

  $pol->version(1);

This is the automation policy version. It defaults to C<1>, and that is the only version of the specification supported.

=head2 distribution

  $pol->distribution( "Dist-AutomationPolicy-v0.1.0" );

This is an optional name for the distribution that this applies to.

It accepts a distribution name with an optional version.

=head2 has_distribution

The predicate for L</distribution>.

=head2 description

This is an optional description.

=head2 has_description

The predicate for L</description>.

=head2 document

This is the name of a text document explaining this policy, e.g. F<AI_POLICY.md>.

The path is relative to the distribution root.

=head2 has_document

The predicate for L</document>.

=head2 code_generation

This outlines how automated tools will generate or update the code and documentation.

It accepts the following values:

=over

=item toolchain

This means that any code changes are made by the standard tools only,
e.g. generation of F<META.json>, F<README>, updates to the POD or
incrementing the version as part of the build and release process.

This implicitly includes dynamic code made by frameworks such as
L<Moose>, L<DBIx::Class> or by curried methods.

This implicitly includes preprocessors, e.g. CSS or JavaScript tools like SASS, TypeScript, or various minifiers.

No external databases are used to generate any code, nor are any included in the code.

No generative AI is used in this process.

=item external_sources

Code is generated or updated from external sources, e.g. the Olson timezone database, or data from schema.org.

This includes simply copying data files to be used via something like L<File::ShareDir> by an otherwise unchanged module.

This includes templates from external sources.

Data and templates that have been manually modified are still considered to be from external sources.

=item machine_generated

Some of the code has been generated by AI agents.

Code that has been manually modified is still considered to be from external sources.

Where possible, models should be documented in L</models>.

=back

Note: there is no "none" option because modern Perl distributions are not written entirely by hand.
There are some files in the distribution that are generated by tools.

=head2 automated_contributions

This refers to automated contributions from entities that are not controlled by or explicitly granted access by the maintainers,
e.g. a bot run by a third party identifies a bug and submits a report to the distribution.

It is assumed machine-generated contributions that are manually approved, edited or submitted by a person are "automated",
but it is up to project maintainers to decide whether this is an acceptable.

Note that it is up to the maintainers to decide on rate limits to contributions,
and how exceeding permissions or rate limits will be handled.

=over

=item none

Machine-generated contributions will not be accepted.

=item comment

Agents are allowed to post comments on existing issues or pull requests.

These may not require human moderation.

=item issue

Agents may create issues or submit security vulnerability reports.

These may not require human moderation.

=item code_request

Agents may submit patches or pull requests without human intervention.

These may not require human moderation.

When known, models should be documented in L</models>.

=back

Note that for contributions it is assumed that "code_change" and "release" are not relevant.

=head2 automated_actions

This refers to automated changes on code or documentation made by agents that are controlled or explicitly granted access by the project maintainers.

=over

=item none

There is no automation beyond changes made as part of the "toolchain" for L</code_generation>.

There are no scripted actions in the code repository, e.g. GitHub actions.

=item comment

There are scripted actions which may run tests, analyse or comment on issues or code changes (pull requests).

These may not require human moderation.

=item issue

Automated tools can create, modify or close issues.

These may not require human moderation.

=item code_request

Automated tools can create or update pull requests, but not merge then on their own.

These may not require human moderation.

Where possible, models should be documented in L</models>.

=item code_change

Automated tools can merge patches or pull requests.

These may not require human moderation.

Where possible, models should be documented in L</models>.

=item release

Automated tools can create and upload releases without human intervention.

Where possible, models should be documented in L</models>.

=back

=head2 models

This is an optional array reference of Model IDs used for L</automated_actions>, and (when known) L</automated_contributions>.

Model IDs should come from L<https://docs.aimlapi.com/api-references/model-database>, but it is not a requirement.

This was added in v0.2.0.

=head2 filename

This is the file path (relative to the project root) that the policy will be saved in.

=head2 template

This is a constructor-only attribute that is used to specify common use-case templates.

=over

=item no_automation

No code is generated beyond the toolchain.

No automated contributions are accepted.

No automated actions beyond basic scripting that might comment on issues or pull requests.

=item issues_only

No code is generated beyond the toolchain.

Automated contributions or actions may submit comments and issues.

=item human_supervised

Code may be generated by AI or LLMs,
and patches or pull requests may be submitted by contributors or agents run by the maintainers.

However, all code changes and releases must be reviewed and approved by the maintainers.

=item data_driven_updates

A use case for this is a cron job that checks for an updated external
database, adapts the data into a new version of a module, and uploads
a new release to CPAN.

Code is updated from external sources, and released automatically.

Automated contributions may post comments or issues.

=item full_automation

Code is generated by AI or LLMs,
automated contributions can submit patches or pull requests,
and agents operated by the maintainers can make changes to the code and release automatically.

This is discouraged.

=back

=head1 METHODS

=head2 data

  my %data = $pol->data->%*;

This returns a hash reference of the data used to generate the policy file.

=head2 validate

  if ( $pol->validate( \%data ) ) ...

The validates the data according to the schema.

If no C<\%data> is passed to it, then it validates the L</data>.

=head2 to_json

 my $json = $pol->to_json;

This returns the JSON form of the L</data>.

=head2 from_json

  my $pol = Dist::AutomationPolicy->from_json( $json );

or

  my $pol = Dist::AutomationPolicy->from_json( \%data );

This is an alternative constructor that accepts a JSON string or hash reference of L</data>.

=for Pod::Coverage BUILD

=for Pod::Coverage BUILDARGS

=head1 SEE ALSO

L<https://github.com/CPAN-Security/cpan-metadata-v3/blob/main/automation-policy.md>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Dist-AutomationPolicy>
and may be cloned from L<https://github.com/robrwo/perl-Dist-AutomationPolicy.git>

=head1 SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.24 or later.
Future releases may only support Perl versions released in the last ten (10) years.

=head2 Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Dist-AutomationPolicy/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see F<SECURITY.md> for instructions how to report security vulnerabilities.

=head1 AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

The ideas for this policy emerged from discussions at the 2026 Perl Toolchain Summit.

Thanks to
Leon Timmermans,
Nicolas Rochelemagne,
Salve J. Nilsen,
Thibault Duponchelle,
Timothy Legge
Todd Rinaldo,
and others for suggestions and feedback.

=head1 CONTRIBUTOR

=for stopwords Leon Timmermans

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
