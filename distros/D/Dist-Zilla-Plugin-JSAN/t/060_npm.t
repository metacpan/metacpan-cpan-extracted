use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Path::Class;
use JSON 2;

use Test::DZil;

{
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => 'test_data/Readme' },
    );

    $tzil->build;
    
    my $package = JSON->new->decode($tzil->slurp_file(file(qw(build package.json))) . "");
    
    ok($package->{ name } eq 'sample-dist', 'Correct package name');
    ok($package->{ version } eq '0.1.2', 'Leading zeros were stripped out');
    
    ok($package->{ author } eq 'Clever Guy <cleverguy@cpan.org>', 'Correct author');
    ok($package->{ contributors }->[ 0 ] eq 'Clever Guy2 <cleverguy2@cpan.org>', 'Correct contributors');
    
    ok($package->{ description } eq 'Some clever yet compact description', 'Correct description');
    
    ok($package->{ main } eq 'lib/Sample/Dist', 'Correct default main module');
    
    is_deeply($package->{ dependencies }, { 'foox-baz' => '1.0.0 - 2.9999.9999', 'barx-foo' => '<1.0.0 || >=2.3.1 <2.4.5 || >=2.5.2 <3.0.0' }, 'Correct dependencies');
    
    is_deeply($package->{ engines }, [ "node >=0.1.27 <0.1.30", "dode >=0.1.27 <0.1.30" ], 'Correct engines');
}

done_testing;
