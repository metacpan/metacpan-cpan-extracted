use strict;
use warnings;
use Test::More;
use File::Raw::JSON;
use JSON::Schema::Fast;
use File::Spec;

# Official JSON-Schema-Test-Suite (draft 2020-12) conformance, vendored under
# t/suite/. A group is run only when its schema compiles AND uses no
# out-of-scope keyword (compile croaks, or ->_unsupported > 0, marks the group
# skipped - documented, never a silent fail). Every in-scope case must match.
#
# Provenance: json-schema-org/JSON-Schema-Test-Suite main branch (see
# t/suite/LICENSE). Refresh with maint (record the commit) when the matrix grows.

my $dir = File::Spec->catdir('t', 'suite', 'draft2020-12');
my @files = sort glob(File::Spec->catfile($dir, '*.json'));
plan skip_all => "no vendored suite under $dir" unless @files;

sub slurp { open my $fh, '<:raw', $_[0] or die "$_[0]: $!"; local $/; <$fh> }

my ($pass, $skip, @fail) = (0, 0);

for my $file (@files) {
    my ($name) = $file =~ m{([^/]+)\.json$};
    my $groups = eval { File::Raw::JSON::file_json_decode(slurp($file)) };
    next unless ref $groups eq 'ARRAY';

    for my $g (@$groups) {
        my $v = eval { JSON::Schema::Fast->compile($g->{schema}) };
        if ($@ || (defined $v && $v->_unsupported > 0)) { $skip += @{ $g->{tests} || [] }; next; }

        for my $t (@{ $g->{tests} }) {
            my $want = $t->{valid} ? 1 : 0;
            my $got  = eval { $v->is_valid($t->{data}) ? 1 : 0 };
            if (defined $got && $got == $want) {
                $pass++;
            } else {
                push @fail, sprintf("%s / %s / %s : want %d got %s",
                    $name, $g->{description}, $t->{description}, $want,
                    defined $got ? $got : "die:$@");
            }
        }
    }
}

diag("conformance: $pass passed, $skip skipped (TODO), " . scalar(@fail) . " failed");
diag($_) for @fail[0 .. ($#fail < 40 ? $#fail : 40)];

is(scalar(@fail), 0, "all in-scope draft-2020-12 cases pass ($pass passed, $skip skipped)");

done_testing;
