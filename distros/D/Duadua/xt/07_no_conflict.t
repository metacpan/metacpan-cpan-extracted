use Test::More;
eval "use File::Find::Rule::ConflictMarker;";
plan skip_all => "skip the no conflict test because $@" if $@;
my @files = File::Find::Rule->conflict_marker->in('lib', 't', 'xt');
ok( scalar(@files) == 0 )
    or die join("\t", map { "'$_' has conflict markers." } @files);
done_testing;
