use strict;
use warnings;
use Test::More;
use File::Raw::JSON;
use JSON::Schema::Fast;
use File::Spec;

# Official JSON-Schema-Test-Suite (draft 2020-12) conformance, vendored under
# t/suite/. Every case whose schema is in scope must match. Two kinds of
# non-failure are tracked explicitly (never silently):
#
#   * SKIP  - the schema uses an out-of-scope keyword, detected by compile
#             croaking or ->_unsupported > 0.
#   * TODO  - a case that compiles but does not yet pass, listed in %KNOWN_TODO
#             below with the roadmap item that will fix it. These shrink to zero
#             as the remaining features land; the build stays green meanwhile.
#
# Only an UNEXPECTED failure (a case that is neither skipped nor known-todo)
# fails the build. Provenance: json-schema-org/JSON-Schema-Test-Suite main (see
# t/suite/LICENSE).

# keyed "file / group description / test description" => roadmap note.
# Empty: the full mandatory draft 2020-12 suite passes with no known-todos.
my %KNOWN_TODO;

my $dir = File::Spec->catdir('t', 'suite', 'draft2020-12');
my @files = sort glob(File::Spec->catfile($dir, '*.json'));
plan skip_all => "no vendored suite under $dir" unless @files;

sub slurp { open my $fh, '<:raw', $_[0] or die "$_[0]: $!"; local $/; <$fh> }

# The suite references remote documents: http://localhost:1234/... (vendored
# under t/suite/remotes/) and the draft 2020-12 meta-schemas at json-schema.org
# (vendored under t/suite/metaschemas/). The resolver maps both to the vendored
# files; chained loads (a meta-schema referencing its vocabularies) resolve the
# same way. A trailing ".json" is appended when the exact path is absent.
my $remotes = File::Spec->catdir('t', 'suite', 'remotes');
my $metas   = File::Spec->catdir('t', 'suite', 'metaschemas', '2020-12');
my $resolver = sub {
    my ($uri) = @_;
    $uri =~ s/#.*//;
    my $path;
    if    ($uri =~ m{^https?://localhost:1234/(.+)$})              { $path = File::Spec->catfile($remotes, split m{/}, $1) }
    elsif ($uri =~ m{^https?://json-schema\.org/draft/2020-12/(.+)$}) { $path = File::Spec->catfile($metas, split m{/}, $1) }
    else  { return undef }
    $path .= '.json' unless -f $path;
    return -f $path ? eval { File::Raw::JSON::file_json_decode(slurp($path)) } : undef;
};

my ($pass, $skip, $todo, @fail) = (0, 0, 0);

for my $file (@files) {
    my ($name) = $file =~ m{([^/]+)\.json$};
    my $groups = eval { File::Raw::JSON::file_json_decode(slurp($file)) };
    next unless ref $groups eq 'ARRAY';

    for my $g (@$groups) {
        my $v = eval { JSON::Schema::Fast->compile($g->{schema}, resolver => $resolver) };
        if ($@ || (defined $v && $v->_unsupported > 0)) { $skip += @{ $g->{tests} || [] }; next; }

        for my $t (@{ $g->{tests} }) {
            my $want = $t->{valid} ? 1 : 0;
            my $got  = eval { $v->is_valid($t->{data}) ? 1 : 0 };
            if (defined $got && $got == $want) {
                $pass++;
            }
            elsif ($KNOWN_TODO{"$name / $g->{description} / $t->{description}"}) {
                $todo++;
            }
            else {
                push @fail, sprintf("%s / %s / %s : want %d got %s",
                    $name, $g->{description}, $t->{description}, $want,
                    defined $got ? $got : "die:$@");
            }
        }
    }
}

diag("conformance: $pass passed, $skip skipped, $todo known-todo, "
     . scalar(@fail) . " unexpected");
diag($_) for @fail[0 .. ($#fail < 40 ? $#fail : 40)];

# 100% of the mandatory draft 2020-12 suite: nothing skipped, nothing todo,
# nothing failing.
is(scalar(@fail), 0, "no draft-2020-12 failures ($pass passed)");
is($skip, 0,         "no out-of-scope skips");
is($todo, 0,         "no known-todos");

done_testing;
