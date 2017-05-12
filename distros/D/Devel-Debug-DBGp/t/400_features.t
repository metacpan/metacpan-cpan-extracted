#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/variables.pl');

command_is(['feature_get', '-n', 'step_into'], {
    feature     => 'step_into',
    supported   => 1,
});

command_is(['feature_get', '-n', 'encoding'], {
    feature     => 'encoding',
    supported   => 1,
    value       => 'UTF-8',
});

command_is(['feature_get', '-n', 'language_name'], {
    feature     => 'language_name',
    supported   => 1,
    value       => 'Perl',
});

command_is(['feature_get', '-n', 'multiple_sessions'], {
    feature     => 'multiple_sessions',
    supported   => 0,
});

command_is(['feature_get', '-n', 'wrong'], {
    feature     => 'wrong',
    supported   => 0,
});

command_is(['feature_set', '-n', 'step_into', '-v', '0'], {
    feature => 'step_into',
    success => 0,
});

command_is(['feature_set', '-n', 'language_name', '-v', 'Python'], {
    feature => 'language_name',
    success => 0,
});

command_is(['feature_set', '-n', 'encoding', '-v', 'iso-8859-1'], {
    feature => 'encoding',
    success => 1,
});

command_is(['feature_set', '-n', 'encoding', '-v', 'wrong'], {
    feature => 'encoding',
    success => 0,
});

command_is(['feature_get', '-n', 'encoding'], {
    feature     => 'encoding',
    supported   => 1,
    value       => 'iso-8859-1',
});

command_is(['feature_set', '-n', 'wrong', '-v', 'some'], {
    feature   => 'wrong',
    success   => 0,
});

done_testing();
