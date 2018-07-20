#!/usr/bin/perl

#
# Copyright (C) 2018 Joelle Maslak
# All Rights Reserved - See License
#

use strict;
use warnings;
use autodie;

use v5.10;

use Carp;

use Test2::V0;

use File::ByLine;

my $arraylike = overloadarray->new();
my $codelike  = overloadcode->new();

my $byline = File::ByLine->new();

ok dies { $byline->header_handler("not code") }, "String dies";
ok dies { $byline->header_handler( [] ) }, "Arrayref dies";

ok lives { $byline->header_handler($codelike) }, "Overloaded coderef lives";
ok dies { $byline->header_handler($arraylike) }, "Overloaded arrayref dies";

done_testing();

# DONE - below are the packages used

package overloadcode;

use overload '&{}' => \&mysub;

sub new {
    my $self = {};
    bless $self;
    return $self;
}

sub mysub {
    return sub { return 1 };
}

package overloadarray;

use overload '@{}' => \&myarr;

sub new {
    my $self = {};
    bless $self;
    return $self;
}

sub myarr {
    return [];
}
