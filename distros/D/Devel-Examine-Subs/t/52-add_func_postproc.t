#!/usr/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Devel::Examine::Subs;
use File::Copy;
use Test::More tests => 4;

my $file = 't/sample.data';
my $copy = 't/add_func_postproc.data';

my %params = (
    file            => $file,
    copy            => $copy,
    post_proc       => [ 'file_lines_contain' ],
    engine          => testing(),
);

#<des>
sub testing {

    return sub {

        my $p = shift;
        my $struct = shift;

        return $struct;
    };
}
#</des>

my $install = 1; # set this to true to install

if ($install) {
    my $des = Devel::Examine::Subs->new(copy => $copy);
    my $ret = $des->add_functionality(add_functionality => 'post_proc');
    is ($ret, 1, "add_functionality post_proc succeeded");
}
else {
    my $des = Devel::Examine::Subs->new(%params);
    my $struct = $des->run(\%params);
    print Dumper $struct;
}

open my $fh, '<', $copy or die $!;
my @file = <$fh>;
close $fh;

is ((grep { $_ =~ /testing =>/ } @file), 1, "dt updated ok");
is ((grep { $_ =~ /sub testing \{/ } @file), 1, "sub added correctly");

eval { unlink $copy or die $!; };
is ($@, '', "temp file removed ok");
