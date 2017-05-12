
# $Id: config.t,v 1.1 2003/06/21 20:07:05 lem Exp $

use IO::File;
use Test::More;


my $config = './config.' . $$;
my $tests = 10;

plan tests => $tests;

sub write_config
{
    my $fh = new IO::File $config, "w";
    return undef unless $fh;
    return undef unless print $fh <<EOF;
# Sample test config

foo: bar
key.dot: .
foo-bar: 1
dummy value: baz
# comment: 7

EOF
    ;
    return $fh->close;
}

END { unlink $config; }

eval { use Mail::Abuse::Report; $loaded = 1; };

SKIP:
{

    skip 'Mail::Abuse::Report failed to load (FATAL)', $tests,
	unless $loaded;

    skip "Failed to create dummy config $config: $!\n", $tests,
	unless write_config;

    my $rep = new Mail::Abuse::Report (text => \ "Contents of text",
				       config => $config);
    isa_ok($rep, 'Mail::Abuse::Report');

    ok(exists $rep->config->{'foo'}, "simple key exists");
    is($rep->config->{'foo'}, 'bar', "proper value for simple key");

    ok(exists $rep->config->{'dummy value'}, "key with space exists");
    is($rep->config->{'dummy value'}, 'baz', 
       "proper value for key with space");

    ok(exists $rep->config->{'foo-bar'}, "key with dash exists");
    is($rep->config->{'foo-bar'}, 1, "proper value for key with dash");

    ok(exists $rep->config->{'key.dot'}, "key with dot exists");
    is($rep->config->{'key.dot'}, '.', "proper value for key with dot");

    ok(! exists $rep->config->{'comment'}, "commented key does not exist");
}

