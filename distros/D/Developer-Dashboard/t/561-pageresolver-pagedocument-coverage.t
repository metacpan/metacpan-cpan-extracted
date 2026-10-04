#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageResolver;

{

    package Local::Pages;
    sub new { return bless { list => $_[1] }, $_[0] }
    sub list_saved_pages { return @{ $_[0]{list} } }
    sub load_saved_page  { die "Page '$_[1]' not found\n" }

    package Local::Paths;
    sub new { return bless { root => $_[1] }, $_[0] }
    sub current_project_root { return $_[0]{root} }
    sub home                 { return '/h' }
    sub runtime_root         { return '/r' }
    sub dashboards_root      { return '/d' }
    sub config_root          { return '/c' }
    sub config_layers        { return () }

    package Local::Config;
    sub new { return bless { providers => $_[1] }, $_[0] }
    sub merged { return { providers => $_[0]{providers} } }
    sub providers { return $_[0]{providers} }
}

sub resolver {
    my ( $saved, $root, $providers ) = @_;
    my $r = Developer::Dashboard::PageResolver->new(
        config  => Local::Config->new($providers),
        pages   => Local::Pages->new($saved),
        paths   => Local::Paths->new($root),
        actions => bless( {}, 'Local::Actions' ),
    );
    no warnings 'redefine';
    local *Developer::Dashboard::PageResolver::providers = sub { return $providers };
    return $r;
}

my $providers = [ { id => 'plain', body => 'b' }, { id => 'project-context', kind => 'builtin' } ];
my $r = resolver( [ 'saved-one' ], '/proj', $providers );
{
    no warnings 'redefine';
    local *Developer::Dashboard::PageResolver::providers = sub { return $providers };
    is_deeply( [ $r->list_pages ], [ 'plain', 'project-context', 'saved-one' ], 'saved pages are listed with providers' );
    my $page = $r->load_named_page('plain');
    is( $page->{title}, 'plain', 'a provider without a title uses its id' );
    like( $r->load_named_page('project-context')->{layout}{body}, qr{/proj}, 'project-context shows the project root' );
    $r->{paths} = Local::Paths->new(undef);
    like( $r->load_named_page('project-context')->{layout}{body}, qr{\(none\)}, 'project-context shows (none) without a root' );
}

my $doc = Developer::Dashboard::PageDocument->new( id => 'x', title => 'T', meta => { codes => [ { body => 'no id' }, { id => 'CODE1', body => 'ok' } ] } );
my $text = $doc->legacy_instruction;
like( $text, qr/CODE1: ok/, 'a code block with an id is serialized' );
unlike( $text, qr/no id/, 'a code block without an id is skipped' );

done_testing;

__END__

=pod

=head1 NAME

t/561-pageresolver-pagedocument-coverage.t - covers PageResolver saved-page listing and fallbacks and PageDocument id-less code blocks

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It drives PageResolver list_pages and the provider fallbacks, and the legacy serializer skipping code blocks without an id.

=head1 WHY IT EXISTS

It exists because lib/ must reach 100 percent coverage with no C<# uncoverable> annotations, so every reachable operand of these fallbacks needs a real test.

=head1 WHEN TO USE

Use this file when you change PageResolver provider page assembly or PageDocument legacy serialization.

=head1 HOW TO USE

Run C<prove -lv t/561-pageresolver-pagedocument-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run.

=head1 WHAT USES IT

It is used by developers during TDD, by the full test suite, by the Devel::Cover coverage gate, and by release verification.

=head1 EXAMPLES

Example 1:

  prove -lv t/561-pageresolver-pagedocument-coverage.t

Run this coverage-gap test by itself.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/561-pageresolver-pagedocument-coverage.t

Confirm the fallback operands are reported as covered.

=cut
