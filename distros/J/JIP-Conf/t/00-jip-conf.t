#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp qw(tempfile);
use English qw(-no_match_vars);

plan tests => 4;

my $tmp_invalid     = build_tmp_file_for(invalid_config());
my $tmp_well_formed = build_tmp_file_for(well_formed_config());

subtest 'Require some module' => sub {
    plan tests => 2;

    use_ok 'JIP::Conf', '0.02';
    require_ok 'JIP::Conf';

    diag(
        sprintf 'Testing JIP::Conf %s, Perl %s, %s',
            $JIP::Conf::VERSION,
            $PERL_VERSION,
            $EXECUTABLE_NAME,
    );
};

subtest 'Make sure init() invocations with no args fail' => sub {
    plan tests => 4;

    eval { JIP::Conf::init() } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "path_to_file"}x;
    };

    eval { JIP::Conf::init(q{}) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "path_to_file"}x;
    };

    eval { JIP::Conf::init($tmp_well_formed->filename) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "path_to_variable"}x;
    };

    eval { JIP::Conf::init($tmp_well_formed->filename, q{}) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "path_to_variable"}x;
    };
};

subtest 'Fail if file not exists/well-formed' => sub {
    plan tests => 3;

    eval { JIP::Conf::init('./unexisting_file', 'Config::hash_ref') } or do {
        like $EVAL_ERROR, qr{^No \s such \s file \s "\.\/unexisting_file"}x;
    };

    eval { JIP::Conf::init($tmp_invalid->filename, 'Config::hash_ref') } or do {
        like $EVAL_ERROR, qr{^Can't \s parse \s config}x;
    };

    eval { JIP::Conf::init($tmp_well_formed->filename, 'Config::array_ref') } or do {
        like $EVAL_ERROR, qr{
            ^Invalid \s config. \s Can't \s fetch \s \$\{Config::array_ref\} \s from
        }x;
    };
};

subtest 'HASH from file' => sub {
    plan tests => 2;

    my $object = JIP::Conf::init(
        $tmp_well_formed->filename,
        'Config::hash_ref',
    );

    is $object->parent->child, 'tratata';

    cmp_ok $object->{'parent'}->{'child'}, 'eq', $object->parent->child;
};

undef $tmp_invalid;
undef $tmp_well_formed;

sub invalid_config {
    return <<CONF;
Invalid config.
CONF
}

sub well_formed_config {
    return <<CONF;
package Config;

use strict;
use warnings;

our \$hash_ref = {
    parent => {
        child => 'tratata',
    },
};

our \$array_ref = [];

1;
CONF
}

sub build_tmp_file_for {
    my $content = shift;

    my $fh = File::Temp->new(UNLINK => 1, SUFFIX => '.pm');
    autoflush $fh, 1;

    print $fh $content;

    return $fh;
}

