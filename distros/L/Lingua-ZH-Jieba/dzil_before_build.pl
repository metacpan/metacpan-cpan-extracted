#!/usr/bin/env perl

use strict;
use warnings;

use File::Copy;
use File::Copy::Recursive qw(dircopy);
use File::Path;

# swig
system("swig -c++ -perl5 -I./cppjieba/include -I. Jieba.i");
move("Jieba.pm", "./lib/Lingua/ZH/");

# share dir
rmtree("./share");
dircopy("cppjieba/dict", "./share/dict");
