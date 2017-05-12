#!/usr/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Devel::Examine::Subs;
use File::Copy;
use Test::More tests => 2;

my $file = 't/sample.data';
my $copy = 't/add_func_engine.data';

my %params = (
    file            => $file,
    copy            => $copy,
    post_proc       => [ 'file_lines_contain' ],
    #engine          => testing(),
);

#<des>
1;
#</des>

my $install = 1; # set this to true to install

if ($install) {
    my $des = Devel::Examine::Subs->new(file => $file, copy => $copy);
    eval { $des->add_functionality(add_functionality => 'engine'); };
    
    like ($@,
        qr/couldn't extract the sub name/,
        "with a malformed sub def line, we croak"
    );
}

eval { unlink $copy or die $!; };
is ($@, '', "temp file removed ok");
