package Dist::Zilla::Plugin::EnsureSQLSchemaVersionedTest;

our $DATE = '2017-07-07'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with 'Dist::Zilla::Role::AfterBuild';

sub after_build {
    my ($self) = @_;

    my $prereqs_hash = $self->zilla->prereqs->as_string_hash;
    my $rr_prereqs = $prereqs_hash->{runtime}{requires} // {};

    # XXX should've checked found_files instead, to handle generated files
    if (defined($rr_prereqs->{"SQL::Schema::Versioned"}) &&
            !(-f "xt/author/sql_schema_versioned.t") &&
            !(-f "xt/release/sql_schema_versioned.t")
        ) {
        $self->log_fatal(["SQL::Schema::Versioned is in prereq, but xt/{author,release}/sql_schema_versioned.t has not been added, please make sure that your schema is tested by adding that file"]);
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Make sure that xt/author/sql_schema_versioned.t is present

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::EnsureSQLSchemaVersionedTest - Make sure that xt/author/sql_schema_versioned.t is present

=head1 VERSION

This document describes version 0.03 of Dist::Zilla::Plugin::EnsureSQLSchemaVersionedTest (from Perl distribution Dist-Zilla-Plugin-EnsureSQLSchemaVersionedTest), released on 2017-07-07.

=head1 SYNOPSIS

In dist.ini:

 [EnsureSQLSchemaVersionedTest]

=head1 DESCRIPTION

This plugin checks if L<SQL::Schema::Versioned> is in the RuntimeRequires
prereq. If it is, then the plugin requires that
C<xt/author/sql_schema_versioned.t> exists, to make sure that the dist author
has added a test for schema creation/upgrades.

Typical C<xt/author/sql_schema_versioned.t> is as follow (identifiers in
all-caps refer to project-specific names):

 #!perl

 use PROJ::MODULE;
 use Test::More 0.98;
 use Test::SQL::Schema::Versioned;
 use Test::WithDB::SQLite;

 sql_schema_spec_ok(
     $PROJ::MODULE::DB_SCHEMA_SPEC,
     Test::WithDB::SQLite->new,
 );
 done_testing;

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-EnsureSQLSchemaVersionedTest>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-EnsureSQLSchemaVersionedTest>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-EnsureSQLSchemaVersionedTest>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<SQL::Schema::Versioned>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
