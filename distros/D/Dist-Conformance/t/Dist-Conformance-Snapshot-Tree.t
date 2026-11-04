#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;

use Dist::Conformance::Snapshot::Tree();

subtest new => sub {
    like(
        dies {
            Dist::Conformance::Snapshot::Tree->new( fetch => sub { } )
        },
        qr/paths\ must\ be/,
        'paths is required'
    );
    like(
        dies {
            Dist::Conformance::Snapshot::Tree->new( paths => [], fetch => sub { } )
        },
        qr/paths\ must\ be/,
        'paths must be a hash'
    );
    like( dies { Dist::Conformance::Snapshot::Tree->new( paths => {} ) }, qr/fetch\ must\ be/, 'fetch is required' );
};

subtest content => sub {
    my %calls;
    my $snapshot = Dist::Conformance::Snapshot::Tree->new(
        paths => { 'CLAUDE.md' => 'sha-1', 'empty' => 'sha-2' },
        fetch => sub ($path) { $calls{$path}++; return $path eq 'empty' ? q{} : "text of $path" },
    );
    is( $snapshot->content('CLAUDE.md'), 'text of CLAUDE.md',              'a listed path comes from fetch' );
    is( $snapshot->content('CLAUDE.md'), 'text of CLAUDE.md',              'and a second time too' );
    is( $snapshot->content('empty'),     q{},                              'an empty file is empty, not missing' );
    is( $snapshot->content('empty'),     q{},                              'and stays so' );
    is( $snapshot->content('nope'),      undef,                            'an unlisted path is undef' );
    is( \%calls,                         { 'CLAUDE.md' => 1, empty => 1 }, 'fetch ran once for each listed path, and never for an unlisted one' );
    ok( !$snapshot->writable, 'a tree cannot be written' );
};

done_testing;
