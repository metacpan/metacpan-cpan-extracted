use Test::More;
eval "use File::Find::Rule::BOM;";
plan skip_all => "skip the no BOM test because $@" if $@;
my @foo = File::Find::Rule->bom->in('lib', 't', 'xt');
ok(scalar(@foo) == 0, 'No BOM')
    or diag(join("\t", map { "'$_' has BOM." } @foo));
done_testing;
