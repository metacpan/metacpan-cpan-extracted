#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

use Path::Class;

BEGIN {
    use_ok('Forest::Tree');
    use_ok('Forest::Tree::Reader::SimpleTextFile');
    use_ok('Forest::Tree::Writer');
    use_ok('Forest::Tree::Writer::SimpleASCII');
    use_ok('Forest::Tree::Writer::SimpleHTML');
}

my $file = Path::Class::File->new('031_Tree_Writer_to_disk.tree');
$file->touch;

my $reader = Forest::Tree::Reader::SimpleTextFile->new;
$reader->read(\*DATA);

{
    my $w = Forest::Tree::Writer::SimpleASCII->new(tree => $reader->tree);
    isa_ok($w, 'Forest::Tree::Writer::SimpleASCII');

    isa_ok($w->tree, 'Forest::Tree');
    
    my $fh = $file->openw;
    $w->write($fh);
    $fh->close;

    is($file->slurp, 
q{1.0
    1.1
    1.2
        1.2.1
2.0
    2.1
3.0
4.0
    4.1
        4.1.1
}, '.... got the right output');

}

$file->remove;
$file->touch;

{    
    my $w = Forest::Tree::Writer::SimpleHTML->new(tree => $reader->tree);
    isa_ok($w, 'Forest::Tree::Writer::SimpleHTML');

    isa_ok($w->tree, 'Forest::Tree');

    my $fh = $file->openw;
    $w->write($fh);
    $fh->close;

    is($file->slurp,
    q{<ul>
    <li>1.0</li>
    <ul>
        <li>1.1</li>
        <li>1.2</li>
        <ul>
            <li>1.2.1</li>
        </ul>
    </ul>
    <li>2.0</li>
    <ul>
        <li>2.1</li>
    </ul>
    <li>3.0</li>
    <li>4.0</li>
    <ul>
        <li>4.1</li>
        <ul>
            <li>4.1.1</li>
        </ul>
    </ul>
</ul>
}, '.... got the right output');
}

$file->remove;

__DATA__
1.0
    1.1
    1.2
        1.2.1
2.0
    2.1
3.0
4.0
    4.1
        4.1.1
