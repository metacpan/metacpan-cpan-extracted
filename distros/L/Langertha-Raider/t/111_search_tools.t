#!/usr/bin/env perl
# ABSTRACT: The search tools glob and grep, with ripgrep and with the Perl code
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use File::Which ();
use JSON::MaybeXS ();
use Langertha::Raider::SearchTools;

# Every behaviour is checked with the Perl code (rg => 0, independent of the
# host) and, where ripgrep is installed, with ripgrep: both must answer the same.

my $root = Path::Tiny->tempdir;
sub put {
  my ( $rel, $content, $age ) = @_;
  my $f = $root->child($rel);
  $f->touchpath->spew_raw($content);
  my $t = time - $age;
  utime $t, $t, "$f";
}
put( 'a.pm',            "package A;\nsub one {}\n# TODO fix a\nsub two {}\n",         500 );
put( 'lib/B.pm',        "package B;\nuse strict;\nsub three {}\n# TODO: b\n",           300 );
put( 'lib/deep/C.js',   "function c() {\n  // todo later\n  return 1;\n}\n",            100 );
put( 'lib/deep/D.pm',   "package D;\nsub four { 1 }\n",                                  50 );
put( 'README.md',       "# Title\n\nSome TODO text.\n",                                  10 );
put( '.hidden.txt',     "TODO hidden\n",                                                 20 );
put( '.git/config',     "TODO in git\n",                                                 20 );
put( 'bin.dat',         "TODO\0binary\n",                                                20 );
put( 'sub dir/x y.txt', "TODO spaces\n",                                                 30 );
symlink "$root/lib", "$root/linkdir";
symlink "$root/a.pm", "$root/linkfile.pm";

my $outside = Path::Tiny->tempdir;
$outside->child('secret.txt')->spew("TODO secret\n");
symlink "$outside", "$root/escape";

my @engines = ( [ perl => 0 ] );
push @engines, [ ripgrep => scalar File::Which::which('rg') ] if File::Which::which('rg');

sub search {
  my ( $rg, %o ) = @_;
  return Langertha::Raider::SearchTools->new( root => "$root", rg => $rg, %o );
}

for my $e (@engines) {
  my ( $name, $rg ) = @$e;
  my $s = search($rg);

  subtest "$name: glob" => sub {
    is( $s->glob({ pattern => '**/*.pm' }), "lib/deep/D.pm\nlib/B.pm\na.pm", 'newest first, any depth, symlinks not followed' );
    is( $s->glob({ pattern => '*.pm' }), 'a.pm', 'no slash: one level' );
    is( $s->glob({ pattern => 'lib/*.pm' }), 'lib/B.pm', 'one directory' );
    is( $s->glob({ pattern => 'lib/**' }), "lib/deep/D.pm\nlib/deep/C.js\nlib/B.pm", 'trailing ** is everything below' );
    is( $s->glob({ pattern => '**/deep/*.{js,pm}' }), "lib/deep/D.pm\nlib/deep/C.js", 'braces' );
    is( $s->glob({ pattern => '[ab].pm' }), 'a.pm', 'character class' );
    is( $s->glob({ pattern => '[!a].pm' }), 'No files found', 'negated class' );
    is( $s->glob({ pattern => '?.pm' }), 'a.pm', 'single character' );
    is( $s->glob({ pattern => '*.pm', path => 'lib/deep' }), 'lib/deep/D.pm', 'path: the pattern is relative to it, the result to the root' );
    is( $s->glob({ pattern => '.*' }), '.hidden.txt', 'hidden files are found, .git is not entered' );
    is( $s->glob({ pattern => 'sub dir/*' }), 'sub dir/x y.txt', 'spaces' );
    is( $s->glob({ pattern => './a.pm' }), 'a.pm', 'leading ./' );
    is( $s->glob({ pattern => '**/*.rb' }), 'No files found', 'nothing' );
    unlike( $s->glob({ pattern => '**/*' }), qr/\.git|linkdir|linkfile|escape/, 'no .git, no symbolic link' );
    is( $s->glob({ pattern => '**/*.pm', path => 'lib' }), "lib/deep/D.pm\nlib/B.pm", 'path as a directory below the root' );
  };

  subtest "$name: glob limits and errors" => sub {
    my $small = search( $rg, default_limit => 2 );
    like( $small->glob({ pattern => '**/*.pm' }), qr{\Alib/deep/D\.pm\nlib/B\.pm\n\n\(Showing the newest 2 of 3 files}, 'truncated, says so' );
    like( dies { $s->glob({ pattern => '/etc/*' }) }, qr/relative to the search directory/, 'absolute pattern' );
    like( dies { $s->glob({ pattern => '../*' }) }, qr/relative to the search directory/, '.. in the pattern' );
    like( dies { $s->glob({ pattern => '' }) }, qr/pattern is required/, 'no pattern' );
    like( dies { $s->glob({ pattern => 'a{b' }) }, qr/unbalanced/, 'unbalanced brace' );
    like( dies { $s->glob({ pattern => '*', path => '..' }) }, qr/path escapes root/, 'path above the root' );
    like( dies { $s->glob({ pattern => '*', path => '/etc' }) }, qr/path escapes root/, 'absolute path outside' );
    like( dies { $s->glob({ pattern => '*', path => 'escape' }) }, qr/path escapes root/, 'symlink out of the root' );
    like( dies { $s->glob({ pattern => '*', path => 'nope' }) }, qr/no such path/, 'missing path' );
    like( dies { $s->glob({ pattern => '*', path => 'a.pm' }) }, qr/not a directory/, 'a file is no directory' );
  };

  subtest "$name: grep modes" => sub {
    is( $s->grep({ pattern => 'TODO' }), join( "\n", 'README.md', '.hidden.txt', 'sub dir/x y.txt', 'lib/B.pm', 'a.pm' ),
      'files_with_matches (default): newest first; binary, .git, symlinks left out' );
    is( $s->grep({ pattern => 'TODO', output_mode => 'count' }),
      join( "\n", '.hidden.txt:1', 'README.md:1', 'a.pm:1', 'lib/B.pm:1', 'sub dir/x y.txt:1' ), 'count: by path' );
    is( $s->grep({ pattern => 'sub \w+', output_mode => 'content', path => 'a.pm' }),
      "a.pm:2:sub one {}\na.pm:4:sub two {}", 'content: path:line:text for a single file' );
    is( $s->grep({ pattern => 'sub \w+', output_mode => 'content', path => 'a.pm', '-n' => 0 }),
      "a.pm:sub one {}\na.pm:sub two {}", 'without line numbers' );
    is( $s->grep({ pattern => 'sub (one|three)', output_mode => 'count' }), "a.pm:1\nlib/B.pm:1", 'count of lines' );
    is( $s->grep({ pattern => 'zzz_nothing' }), 'No matches found', 'no match' );
  };

  subtest "$name: grep filters" => sub {
    is( $s->grep({ pattern => 'TODO', '-i' => 1, glob => '*.js' }), 'lib/deep/C.js', '-i with a glob at any depth' );
    is( $s->grep({ pattern => 'Todo' }), 'No matches found', 'case sensitive by default' );
    is( $s->grep({ pattern => 'sub', glob => 'lib/*.pm' }), 'lib/B.pm', 'glob with a directory is anchored' );
    is( $s->grep({ pattern => 'sub', glob => '*.{pm,js}', output_mode => 'count' }), "a.pm:2\nlib/B.pm:1\nlib/deep/D.pm:1", 'braces' );
    is( $s->grep({ pattern => 'package', type => 'perl', output_mode => 'count' }), "a.pm:1\nlib/B.pm:1\nlib/deep/D.pm:1", 'type' );
    is( $s->grep({ pattern => 'function', type => 'js' }), 'lib/deep/C.js', 'type js' );
    is( $s->grep({ pattern => 'sub', type => 'perl', glob => 'lib/**', output_mode => 'count' }),
      "lib/B.pm:1\nlib/deep/D.pm:1", 'type and glob together' );
    is( $s->grep({ pattern => 'TODO', path => 'lib' }), 'lib/B.pm', 'path: a directory' );
    is( $s->grep({ pattern => 'one', path => 'a.pm' }), 'a.pm', 'path: a file' );
  };

  subtest "$name: grep context" => sub {
    is( $s->grep({ pattern => 'use strict', output_mode => 'content', '-A' => 1, path => 'lib/B.pm' }),
      "lib/B.pm:2:use strict;\nlib/B.pm-3-sub three {}", '-A' );
    is( $s->grep({ pattern => 'use strict', output_mode => 'content', '-B' => 1, path => 'lib/B.pm' }),
      "lib/B.pm-1-package B;\nlib/B.pm:2:use strict;", '-B' );
    is( $s->grep({ pattern => 'use strict', output_mode => 'content', '-C' => 1, path => 'lib/B.pm' }),
      "lib/B.pm-1-package B;\nlib/B.pm:2:use strict;\nlib/B.pm-3-sub three {}", '-C' );
    is( $s->grep({ pattern => 'use strict', output_mode => 'content', context => 1, path => 'lib/B.pm' }),
      $s->grep({ pattern => 'use strict', output_mode => 'content', '-C' => 1, path => 'lib/B.pm' }), 'context is -C' );
    is( $s->grep({ pattern => 'package|TODO', output_mode => 'content', path => 'lib/B.pm', '-C' => 1 }),
      "lib/B.pm:1:package B;\nlib/B.pm-2-use strict;\nlib/B.pm-3-sub three {}\nlib/B.pm:4:# TODO: b",
      'context groups that touch are one group' );
    is( $s->grep({ pattern => 'package|four', output_mode => 'content', path => 'lib/deep/D.pm', '-A' => 0 }),
      "lib/deep/D.pm:1:package D;\nlib/deep/D.pm:2:sub four { 1 }", 'no context: no separators' );
    is( $s->grep({ pattern => 'package|TODO', output_mode => 'content', path => 'a.pm', '-A' => 0, '-B' => 0 }) =~ tr/\n//, 1, 'two matches, no separator' );
    is( $s->grep({ pattern => 'package A|sub two', output_mode => 'content', path => 'a.pm', '-A' => 1 }),
      "a.pm:1:package A;\na.pm-2-sub one {}\n--\na.pm:4:sub two {}", 'groups apart are separated by --' );
    is( $s->grep({ pattern => 'package', output_mode => 'content', path => 'lib', '-A' => 1, glob => '*.pm' }),
      "lib/B.pm:1:package B;\nlib/B.pm-2-use strict;\n--\nlib/deep/D.pm:1:package D;\nlib/deep/D.pm-2-sub four { 1 }", 'files are separated by --' );
  };

  subtest "$name: grep multiline" => sub {
    is( $s->grep({ pattern => 'sub one \{\}\n# TODO', multiline => 1, output_mode => 'content', path => 'a.pm' }),
      "a.pm:2:sub one {}\na.pm:3:# TODO fix a", 'a pattern across lines shows every line it touches' );
    like( dies { $s->grep({ pattern => 'sub one \{\}\n# TODO', output_mode => 'content', path => 'a.pm' }) },
      qr/literal "\\n" is not allowed/, 'a newline in the pattern needs multiline' );
    is( $s->grep({ pattern => 'package A;.*TODO', multiline => 1, output_mode => 'files_with_matches' }), 'a.pm', '. matches a newline' );
  };

  subtest "$name: grep limits" => sub {
    my %q = ( pattern => 'package|sub|use|TODO', output_mode => 'content', glob => '*.pm' );
    my @all = split /\n/, $s->grep({ %q, head_limit => 0 });
    ok( @all > 5, 'enough lines to cut' ) or diag scalar @all;
    my $cut = $s->grep({ %q, head_limit => 3 });
    is( [ split /\n/, $cut ]->[0], $all[0], 'head_limit: first line' );
    like( $cut, qr/\n\n\(Showing 3 of \d+ lines from offset 0\./, 'says it was cut' );
    is( [ ( split /\n/, $s->grep({ %q, head_limit => 2, offset => 2 }) )[ 0, 1 ] ], [ @all[ 2, 3 ] ], 'offset' );
    like( $s->grep({ %q, offset => 500 }), qr/No matches found at this offset \(there are \d+ lines\)/, 'offset past the end' );
    is( search( $rg, default_limit => 2 )->grep({ %q }) =~ s/\n\n.*//sr, join( "\n", @all[ 0, 1 ] ), 'default_limit' );
    put( 'long.txt', 'TODO ' . ( 'x' x 3000 ) . "\n", 1 );
    like( $s->grep({ pattern => 'TODO x', output_mode => 'content', path => 'long.txt' }), qr/\Along\.txt:1:TODO x{1900,}.* \[line cut\]\z/s, 'long lines are cut' );
    $root->child('long.txt')->remove;
  };

  subtest "$name: grep errors" => sub {
    like( dies { $s->grep({ pattern => '(' }) }, qr/invalid (?:regular expression|search)/, 'invalid regex' );
    like( dies { $s->grep({ pattern => '' }) }, qr/pattern is required/, 'no pattern' );
    like( dies { $s->grep({ pattern => 'a', output_mode => 'lines' }) }, qr/unknown output_mode: lines/, 'bad mode' );
    like( dies { $s->grep({ pattern => 'a', type => 'cobol' }) }, qr/unknown type: cobol \(known: c, cpp/, 'bad type' );
    like( dies { $s->grep({ pattern => 'a', '-A' => -1 }) }, qr/after must be a non-negative integer/, 'negative context' );
    like( dies { $s->grep({ pattern => 'a', path => '../x' }) }, qr/no such path|path escapes root/, 'path above the root' );
    like( dies { $s->grep({ pattern => 'TODO', path => 'escape' }) }, qr/path escapes root/, 'symlink out of the root' );
    like( dies { $s->grep({ pattern => 'a', glob => '/abs/*' }) }, qr/relative to the search directory/, 'absolute glob' );
  };

  subtest "$name: the server" => sub {
    my %tool = map { $_->name => $_ } @{ $s->server->tools };
    is( [ sort keys %tool ], [ 'glob', 'grep' ], 'two tools' );
    my $call = sub { my ( $n, $in ) = @_; $tool{$n}->code->( $tool{$n}, $in ) };
    my $ok = $call->( glob => { pattern => '*.md' } );
    is( $ok->{content}[0]{text}, 'README.md', 'glob result' );
    ok( !$ok->{isError}, 'not an error' );
    my $bad = $call->( grep => { pattern => '(' } );
    ok( $bad->{isError}, 'an invalid pattern is an error result' );
    like( $bad->{content}[0]{text}, qr/\AError: invalid (?:regular expression|search)/, 'with the message' );
    unlike( $bad->{content}[0]{text}, qr/ at \S+ line \d+/, 'without a source location' );
    ok( $call->( glob => { pattern => '*', path => '..' } )->{isError}, 'path escape is an error result' );
  };
}

subtest 'the engines answer alike' => sub {
  plan skip_all => 'ripgrep is not installed' unless @engines > 1;
  my ( $perl, $rg ) = map { search( $_->[1] ) } @engines;
  my @calls = (
    { pattern => 'TODO' }, { pattern => 'TODO', output_mode => 'count' },
    { pattern => 'sub|package', output_mode => 'content', '-C' => 2 },
    { pattern => 'sub|package', output_mode => 'content', '-B' => 1, glob => '*.pm' },
    { pattern => '^#', output_mode => 'content', '-i' => 1, '-n' => 0 },
    { pattern => 'a.*c', multiline => 1, output_mode => 'content' },
    { pattern => 'e', type => 'perl', head_limit => 4, offset => 1, output_mode => 'content' },
  );
  is( $rg->grep($_), $perl->grep($_), "same output for " . JSON::MaybeXS->new( canonical => 1 )->encode($_) )
    for @calls;
  is( $rg->engine, 'ripgrep', 'engine name' );
  is( $perl->engine, 'perl', 'engine name' );
};

subtest 'binary and big files are skipped, and search stays inside the root' => sub {
  my $s = search(0);
  is( $s->grep({ pattern => 'binary', path => 'bin.dat' }), 'No matches found', 'a NUL byte: binary' );
  my $big = search( 0, max_file_size => 12 );
  is( $big->grep({ pattern => 'TODO fix a', path => 'a.pm' }), 'No matches found', 'too big' );
  like( $big->grep({ pattern => 'TODO', output_mode => 'count' }), qr/\.hidden\.txt:1/, 'small enough' );
  ok( !( grep { $_ eq 'escape' } map { s{/.*}{}r } split /\n/, $s->glob({ pattern => '**/*' }) ), 'the symlink out of the root is not walked' );
};

done_testing;
