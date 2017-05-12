use strict;
use Test::More 'no_plan';

use File::Find::Rule::Digest;

my @files = find(file => md5 => 'd3b07384d113edec49eaa6238ad5ff00', in => 't' );
is_deeply \@files, [ 't/foo' ];

@files = File::Find::Rule::Digest->file()
    ->md5('d3b07384d113edec49eaa6238ad5ff00')
    ->in('t');

is_deeply \@files, [ 't/foo' ];
