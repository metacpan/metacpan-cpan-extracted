#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Basename;

use MVC::Neaf::X::Files;

my $xfiles = MVC::Neaf::X::Files->new(
    root => dirname(__FILE__), dir_index => 1);

my $ret = $xfiles->serve_file('');

is ref $ret->{list}, 'ARRAY', "List of files present";
is ref $ret->{-template}, 'SCALAR', "In-memory template present";
isa_ok $ret->{-view}, "MVC::Neaf::View", "In-place view present";

is scalar( grep { $_->{name} eq basename(__FILE__) } @{ $ret->{list} })
    , 1, "This file inside";

my ($html) = $ret->{-view}->render( $ret );

like $html, qr#directory\s+index#i, "heading present";
like $html, qr#[-\w]+\.t#, "some files present";

done_testing;
