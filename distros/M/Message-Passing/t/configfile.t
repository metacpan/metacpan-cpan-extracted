use strict;
use warnings;

use Test::More 0.88;
use File::Temp qw/ tempdir /;
use JSON qw/ encode_json decode_json /;
use File::Spec;

my $dir = tempdir( CLEANUP => 1 );
my $path = File::Spec->catfile($dir, 'config.json');
open(my $fh, '>', $path)
    or die $!;
print $fh encode_json({
    input => 'Null',
    output => 'Test',
    input_options => {
        foo => 'bar',
    },
});
close($fh);

use_ok 'Message::Passing';

my $i;
{
    local @ARGV = ('--configfile', $path);
    $i = Message::Passing->new_with_options;
}

ok $i;
is $i->input, 'Null';
is $i->output, 'Test';
is_deeply $i->input_options, {
        foo => 'bar',
    };

done_testing;

