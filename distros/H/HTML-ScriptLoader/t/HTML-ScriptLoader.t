# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-ScriptLoader.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('HTML::ScriptLoader') };

#########################

my %scripts = (
    'other-script'  => {
        'uri'           => 'http://example.com/other-script.js'
    },
    'myscript'      => {
        'uri'           => '/static/js/myscript.js',
        'deps'          => ['other-script'],
        'params'        => {
            'apikey'        => 'very-secret',
        },
    },
);

my $loader = HTML::ScriptLoader->new(\%scripts);
ok($loader);

is(scalar keys %{ $loader->available }, 2, "The number of available scripts");
is(scalar @{ $loader->scripts }, 0, "The number of loaded scripts is 0 to begin with");

$loader->add_script(qw/myscript/);
is(scalar @{ $loader->scripts }, 2, "The number of loaded scripts is 2 after loading myscript (dep on other-script)");

my $otherscript = $loader->scripts->[0];
is($otherscript->{'url'}, 'http://example.com/other-script.js', "Assemble the other-script URL");

my $myscript = $loader->scripts->[1];
is($myscript->{'url'}, '/static/js/myscript.js?apikey=very-secret', "Assemble the myscript URL with params");
