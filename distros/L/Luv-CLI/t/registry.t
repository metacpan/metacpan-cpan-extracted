use v5.38;
use Test::More;
use File::Temp qw(tempdir);

use Luv::CLI::Registry;

my $dir        = tempdir( CLEANUP => 1 );
my $cache_path = "$dir/registry.json";

my $sample_readme = <<'MD';
## Physics

- [baton](https://github.com/tesselode/baton) - Input handling library
- [bump](https://github.com/kikito/bump.lua) - Collision detection

## Audio

- [tesound](https://github.com/tanema/tesound) - Sound wrapper
MD

subtest 'parse_readme extracts entries' => sub {
    my $r = Luv::CLI::Registry->new( cache_path => $cache_path );
    $r->parse_readme($sample_readme);

    my $baton = $r->find('baton');
    ok $baton, 'baton found';
    is $baton->{url}, 'https://github.com/tesselode/baton',
        'baton url correct';
    is $baton->{category}, 'Physics', 'baton category correct';

    my $tesound = $r->find('tesound');
    is $tesound->{category}, 'Audio', 'tesound category correct';
};

subtest 'save and load round-trip' => sub {
    my $r = Luv::CLI::Registry->new( cache_path => $cache_path );
    $r->parse_readme($sample_readme);
    $r->save;

    ok -e $cache_path, 'cache file written';

    my $loaded = Luv::CLI::Registry->new( cache_path => $cache_path );
    $loaded->load;
    ok $loaded->find('bump'), 'bump persisted and reloaded';
};

subtest 'search matches name and description' => sub {
    my $r = Luv::CLI::Registry->new( cache_path => $cache_path );
    $r->parse_readme($sample_readme);

    my @by_name = $r->search('baton');
    is scalar(@by_name), 1, 'search by name finds one match';

    my @by_desc = $r->search('collision');
    is scalar(@by_desc), 1, 'search by description finds one match';
};

subtest 'all_entries returns everything' => sub {
    my $r = Luv::CLI::Registry->new( cache_path => $cache_path );
    $r->parse_readme($sample_readme);
    my @all = $r->all_entries;
    is scalar(@all), 3, 'all three sample entries returned';
};

done_testing;
