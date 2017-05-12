#!/usr/bin/perl -w
use strict;

use lib './lib','../lib';
use Test::More tests => 4;

use File::Find::Rule::Type;
is_deeply( [ find( type => 'image/*', maxdepth => 2, in => 't' ) ],
           [
             't/happy-baby.JPG',
             't/files/blank.bmp',
             't/files/blank.gif',
             't/files/blank.jpg',
             't/files/blank.png',
             't/files/blank.tif',
           ] );

is_deeply ( [ find( type => '*/*zip*', maxdepth => 2, in => 't' ) ],
            [
              't/files/blank.zip',
              't/files/tarball.tar.bz2',
              't/files/tarball.tar.gz',
            ] );

is_deeply ( [ find( type => 'audio/x-wav', maxdepth => 2, in => 't/files' ) ],
            [ 't/files/rebound.wav' ] ); 

is_deeply ( [ find( type => '*/html', maxdepth => 2, in => 't/' ) ],
            [ 't/files/File-Type.html' ] );

