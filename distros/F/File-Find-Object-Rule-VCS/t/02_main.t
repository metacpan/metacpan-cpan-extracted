#!/usr/bin/perl

# Testing for File::Find::Rule::VCS

use strict;
BEGIN {
        $|  = 1;
        $^W = 1;
}

use Test::More tests => 5;
use File::Find::Object::Rule      ();
use File::Find::Object::Rule::VCS ();
use constant FFOR => 'File::Find::Object::Rule';

# Check the methods are added
ok( FFOR->can('ignore_vcs'), '->ignore_vcs method exists' );
ok( FFOR->can('ignore_cvs'), '->ignore_cvs method exists' );
ok( FFOR->can('ignore_svn'), '->ignore_svn method exists' );
ok( FFOR->can('ignore_bzr'), '->ignore_bzr method exists' );

# Make an object containing all of them, to ensure there are no errors
my $Rule = File::Find::Object::Rule->new
                           ->ignore_cvs
                           ->ignore_svn
                           ->ignore_bzr
                           ->ignore_vcs('')
                           ->ignore_vcs('cvs')
                           ->ignore_vcs('svn')
                           ->ignore_vcs('bzr');
isa_ok( $Rule, 'File::Find::Object::Rule' );
