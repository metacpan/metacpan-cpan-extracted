use strict;
use warnings;
use Test::More 0.88;

use Path::Class;
use JSON 2;
use Dist::Zilla::Tester;

{
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => 'test_data/NPM-Package' },
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
    
    is_deeply($package->{ bin }, { 'do_this' => 'bin/do_that.js', 'do_that' => 'bin/do_this.js' }, 'Correct binaries');
}

done_testing;
