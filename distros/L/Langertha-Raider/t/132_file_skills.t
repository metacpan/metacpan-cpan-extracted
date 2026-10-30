#!/usr/bin/env perl
# ABSTRACT: skills: entries of type file are loaded as skills, a bad entry croaks (k157, ADR 0019)
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::PP ();
use Langertha::Raider::Config;
use Langertha::Raider::Context;
use Langertha::Raider::CLI;

sub project { path(tempdir(CLEANUP => 1))->realpath }
sub put { my ( $base, $rel, $text ) = @_; $base->child($rel)->touchpath->spew_utf8($text) }

subtest 'Config: type file passes through, bad items croak' => sub {
  my $c = Langertha::Raider::Config->new(root => '' . project());
  is([ $c->normalize_skill_spec({ type => 'file', path => 'a.md' }) ], [ { type => 'file', path => 'a.md' } ], 'file');
  is([ $c->normalize_skill_spec('claude') ], [], 'profile keyword gives nothing');
  like(dies { $c->normalize_skill_spec({ type => 'url', path => 'x' }) }, qr/type 'url' is none of dir, claude, file/, 'unknown type');
  like(dies { $c->normalize_skill_spec({ type => 'file' }) }, qr/type file needs a path/, 'no path');
  like(dies { $c->normalize_skill_spec({ path => '' }) }, qr/type dir needs a path/, 'empty path');
  like(dies { $c->normalize_skill_spec(['x']) }, qr/Invalid skills/, 'a list');
};

subtest 'Context: a file skill is listed, loaded, relative to the root' => sub {
  my $p = project();
  put($p, 'docs/style.md', "Write short sentences. STYLE-BODY\n");
  put($p, 'docs/other.md', "---\ndescription: Other things\n---\nOTHER-BODY\n");
  my $ctx = Langertha::Raider::Context->new(root => "$p", skill_specs => [
    { type => 'file', path => 'docs/style.md' },
    { type => 'file', path => $p->child('docs/other.md')->stringify },
    { type => 'file', path => 'docs/gone.md' },
    { type => 'dir',  path => 'docs/style.md' },    # --skills FILE: the same file, read once
  ]);
  my @skills = $ctx->skill_catalog->skills;
  is([ map { $_->{name} } @skills ], [qw( style other )], 'named by file name, once');
  is($skills[0]{source}, 'docs/style.md', 'source');
  is($skills[0]{dir}, "$p/docs", 'base directory is the parent');
  like($ctx->skill_catalog->tool_text('style'), qr/\ABase directory for this skill: \Q$p\E\/docs\n\nWrite short sentences\. STYLE-BODY/, 'body');
  is($skills[1]{description}, 'Other things', 'frontmatter description');
  is([ map { { file => $_->{file}, reason => $_->{reason} } } $ctx->skill_catalog->problems ],
    [ { file => "$p/docs/gone.md", reason => 'skill file not found' } ], 'a missing file is reported');
  is($ctx->report->{skill_problems}, [ { file => "$p/docs/gone.md", reason => 'skill file not found' } ],
    'config explain shows it');
};

subtest 'Application: skills: [ { type: file } ] in the config file' => sub {
  my $p = project();
  put($p, 'docs/style.md', "Write short sentences.\n");
  put($p, '.raider/config.yml', "skills:\n  - type: file\n    path: docs/style.md\n");
  my $app = Langertha::Raider::CLI->new(root => "$p", engine => 'openai', api_key => 'x', trace => 0);
  is([ $app->loaded_skill_names ], ['style'], 'loaded');
  like($app->mission, qr/- style: Write short sentences\./, 'listed in the prompt');
  like($app->mission, qr/^  - skill\(skill, \[args\]\)$/m, 'skill tool mounted');

  my $bad = project();
  put($bad, '.raider/config.yml', "skills:\n  - type: bogus\n    path: x\n");
  like(dies { Langertha::Raider::CLI->new(root => "$bad", engine => 'openai', api_key => 'x', trace => 0)->mission },
    qr/Invalid skills: type 'bogus'/, 'an unknown type croaks');
};

done_testing;
