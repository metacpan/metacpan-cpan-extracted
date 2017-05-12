use I22r::Translate;
use Test::More;
use lib 't';

# exercise I22r::Translate with a trivial backend

I22r::Translate->config(
    'Test::Backend::Trivial' => {
	ENABLED => 1,
    }
);

my $r = I22r::Translate->translate_string(
    src => 'en', dest => 'ko', text => 'some text', return_type => 'object');
ok( $r, 'translate_string: got result');
ok( $r->text =~ /.some text./, 'translate_string: got correct result' );
ok( $r->otext eq 'some text', 'translate_string: got correct otext' );
ok( $r->olang eq 'en', 'translate_string: got correct olang' );
ok( $r->lang eq 'ko', 'translate_string: got correct lang' );
ok( $r->time >= $^T && $r->time <= time, 'translate_string: got correct time' );

my @r = I22r::Translate->translate_list(
    src => 'en', dest => 'tz', return_type => 'object',
    text => [
	'Who in the Perl community doesn\'t envy PHP\'s awesome features?',
	'This module will give you the features you\'ve always hoped and dreamed for!',
	'This is free software.',
	'You can redistribute it and/or modify it under the same terms as the Perl 5 programming language itself.'
    ] );
ok( @r == 4, 'translate_list: got all results' );
ok( $r[0]->text =~ /.Who in the Perl community/, 'translate_list: text' );
ok( $r[1]->otext =~ /^This module will give /, 'translate_list: otext' );
ok( $r[2]->lang eq 'tz', 'translate_list: lang' );
ok( $r[3]->olang eq 'en', 'translate_list: olang' );
ok( $r[0]->time >= $^T && $r[1]->time <= time, 'translate_list: time' );
ok( $r[2]->id, 'translate_list: id' );

my %r = I22r::Translate->translate_hash(
    src => 'ab', dest => 'cd', return_type => 'object',
    text => {
	timeout => 'Puts a deadline on the child process and causes the child to die if it has not completed by the deadline.',
	dir => 'Causes the child process to be run from a different directory than the parent.',
	env => 'Passes additional environment variables to a child process.',
	umask => 'Specifies the default permissions of files and directories created by the background process.',
	delay => 'Causes the child process to be spawned at some time in the future.',
	child_fh => 'Makes the child process\'s standard filehandles available to the parent.'
    }
);

ok( 0 != keys %r, 'translate_hash: got results' );
ok( $r{timeout}->text =~ /^\[cd\]Puts a deadline/, 'translate_hash: text' );
ok( $r{dir}->otext =~ /^Causes the child process/, 'translate_hash: otext' );
ok( $r{env}->lang eq 'cd', 'translate_hash: lang' );
ok( $r{umask}->olang eq 'ab', 'translate_hash: olang' );
ok( $r{delay}->id eq 'delay', 'translate_hash: id' );
ok( $r{child_fh}->time >= $^T && $r{child_fh}->time <= time,
     'translate_hash: time');

done_testing();
