use strict;
use warnings;

use Test::More tests => 3;

use Path::Tiny;
use HiD;
use HiD::Generator::Sass;

use Test::MockObject;

my $dest = 't/output';

my @output;

my $mock_hid = Test::MockObject->new
->set_always( config => {
    sass => {
        sources => [ 't/corpus/src/sass/test.scss' ],
        output => 'css',
    }
})
->set_always( destination => $dest )
->set_true('INFO')
->mock( add_object => sub{ push @output, $_[1] }); 

HiD::Generator::Sass->generate($mock_hid);

is scalar @output, 1, "now we should have a bogus css page...";

my $file = shift @output;

is $file->output_filename => "$dest/css/test.css";

like $file->content => qr/\.this\s*{\s*color:\s*#fff/, 'with the right content';
