
######################################################################
#
#   Directory Digest -- 01-API.t
#   Matthew Gream (MGREAM) <matthew.gream@pobox.com>
#   Copyright 2002 Matthew Gream. All Rights Reserved.
#   $Id: 01-API.t,v 0.90 2002/10/21 20:24:06 matt Exp matt $
#
#   Test API.pm
#    
######################################################################

use Test;

require 't/test_config.pl';
require 't/test_utils.pl';

###########################################################################

sub test_count { 
    my($c) = 0; if (open(FILE, "<$0")) { 
    while(<FILE>) { if (/test_atom_begin|test_caller/g) { $c++; } } 
    close (FILE); }; return $c - 1;
}
BEGIN { plan tests => test_count(); }

###########################################################################

use Digest::Directory::API;

test_caller(\&test_preamble);
test_caller(\&test_specification);
test_caller(\&test_lifecycle);
test_caller(\&test_configure);
test_caller(\&test_create);
test_caller(\&test_show);
test_caller(\&test_compare);
test_caller(\&test_update);
test_caller(\&test_postamble);

###########################################################################

sub test_setup
{
    my $d = Digest::Directory::API->new;
    $d->quiet( test_config_quiet() );
    return $d;
}
sub test_setup_configure
{ 
    my $d = test_setup();
    my @i = ( "t/test" );
    $d->configure("",\@i);
    return $d;
}   
sub test_setup_create_begin
{ 
    my $d = test_setup();
    my @i = ( "t/test" );
    my($s) = @_;

    my $r = $d->configure("",\@i);
    ( $r > 0 ) || return 0;

    $r = $d->create("", "", "", $s, 1, 1);
    ( $r > 0 ) || return 0;

    return 1;
}   
sub test_setup_create_end
{ 
    my($s) = @_;

    my $sc = "";
    ( open FILE, "<$s" ) || return 0;
    while(<FILE>) { $sc .= $_; }
    ( close FILE ) || return 0;
    ( length($sc) > 0 ) || return 0;
    ( unlink $s ) || return 0;

    return 1; 
}

###########################################################################

sub test_specification
{ 
    test_title("specification => variables");

    test_atom_begin("specification - PROGRAM,VERSION,AUTHOR,RIGHTS,USAGE");
    (defined $Digest::Directory::API::PROGRAM ) || return 0;
    (defined $Digest::Directory::API::VERSION ) || return 0;
    (defined $Digest::Directory::API::AUTHOR ) || return 0;
    (defined $Digest::Directory::API::RIGHTS ) || return 0;
    (defined $Digest::Directory::API::USAGE ) || return 0;
    test_atom_end();

    return 1;
}

###########################################################################

sub test_lifecycle 
{ 
    test_title("lifecycle => create");

    test_atom_begin("lifecycle - created correctly");
    my $d = test_setup();
    ( defined $d ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

sub test_configure 
{ 
    test_title("configure => default,file,options");

    test_atom_begin("configure - begin");
    my $c = "t/temp/c";
    my $n1 = "t/test";
    my $n2 = "t/test/3";
    ( open FILE, ">$c" ) || return 0;
    ( print FILE "+$c\n" ) || return 0;
    ( print FILE "+$n1\n" ) || return 0;
    ( print FILE "-$n2\n" ) || return 0;
    ( close FILE ) || return 0;
    test_atom_end();

    test_atom_begin("configure - test default");
    my $d1 = test_setup();
    my $r1 = $d1->configure();
    ( $r1 > 0 ) || return 0;
    my %s1 = $d1->dirgest()->statistics();
    ( $s1{'include'} == 0 && $s1{'exclude'} == 0 &&
      $s1{'quiet'} == test_config_quiet() ) || return 0;
    test_atom_end();

    test_atom_begin("configure - test from file");
    my $d2 = test_setup();
    my $r2 = $d2->configure($c);
    ( $r2 > 0 ) || return 0;
    my %s2 = $d2->dirgest()->statistics();
    ( $s2{'include'} == 2 && $s2{'exclude'} == 1 &&
      $s2{'quiet'} == test_config_quiet() ) || return 0;
    test_atom_end();

    test_atom_begin("configure - with options");
    my $d3 = test_setup();
    my @i = ( "t/test/1", "t/test/2" );
    my @e = ( "t/test/3", "t/test/3/a" );
    my $r3 = $d3->configure("",\@i,\@e);
    ( $r3 > 0 ) || return 0;
    my %s3 = $d3->dirgest()->statistics();
    ( $s3{'include'} == 2 && $s3{'exclude'} == 2 &&
      $s3{'quiet'} == test_config_quiet() ) || return 0;
    test_atom_end();

    return 1;
}

###########################################################################

sub test_create
{ 
    test_title("create => compute,fetch");

    test_atom_begin("create - begin");
    my $s = "t/temp/s";
    my $r1 = test_setup_create_begin($s);
    ( $r1 > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("create - end");
    $r1 = test_setup_create_end($s);
    ( $r1 > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("create - begin");
    my $r2 = test_setup_create_begin($s);
    ( $r2 > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("create - fetch");
    my $d = test_setup();
    $r2 = $d->create("file:$s", "user", "pass", "$s.txt");
    ( $r2 > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("create - end");
    $r2 = test_setup_create_end($s);
    ( $r2 > 0 ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

sub test_show
{
    test_title("show => compute,fetch");

    test_atom_begin("show - compute");
    my $d1 = test_setup_configure();
    my $r1 = $d1->show("", "", "");
    ( $r1 > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("show - begin");
    my $s = "t/temp/s";
    my $r2 = test_setup_create_begin($s);
    ( $r2 > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("show - fetch");
    my $d3 = test_setup();
    my $r3 = $d1->show("file:$s", "user", "pass");
    ( $r3 > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("show - end");
    $r4 = test_setup_create_end($s);
    ( $r4 > 0 ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

sub test_compare
{ 
    test_title("compare => compute,fetch");

    {
    test_atom_begin("compare - begin");
    my $s = "t/temp/s";
    my $r = test_setup_create_begin($s);
    ( $r > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("compare - insert");
    my $x = "t/test/x";
    ( open FILE, ">$x" ) || return 0;
    ( print FILE "file x\n" ) || return 0;
    ( close FILE ) || return 0;
    test_atom_end();

    test_atom_begin("compare - compute");
    my $d1 = test_setup_configure();
    my $r1 = $d1->compare("", "", "", $s);
    ( $r1 > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("compare - end");
    ( unlink $x ) || return 0;
    test_atom_end();

    test_atom_begin("compare - remove file");
    $r = test_setup_create_end($s);
    ( $r > 0 ) || return 0;
    test_atom_end();
    }

    {
    test_atom_begin("compare - begin");
    my $s1 = "t/temp/s1";
    my $r1 = test_setup_create_begin($s1);
    ( $r1 > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("compare - insert file");
    my $x = "t/test/x";
    ( open FILE, ">$x" ) || return 0;
    ( print FILE "file x\n" ) || return 0;
    ( close FILE ) || return 0;
    test_atom_end();

    test_atom_begin("compare - create");
    my $s2 = "t/temp/s2";
    my $r2 = test_setup_create_begin($s2);
    ( $r2 > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("compare - fetch");
    my $d = test_setup();
    my $r = $d->compare("file:$s1", "user", "pass", $s2);
    ( $r > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("compare - end");
    ( unlink $x ) || return 0;
    test_atom_end();

    test_atom_begin("compare - remove file");
    $r1 = test_setup_create_end($s1);
    ( $r1 > 0 ) || return 0;
    $r2 = test_setup_create_end($s2);
    ( $r2 > 0 ) || return 0;
    test_atom_end();
    }

    return 1; 
}

###########################################################################

sub test_update
{ 
    test_title("update => compute,fetch");

    {
    test_atom_begin("update - begin");
    my $s1 = "t/temp/s1";
    my $r1 = test_setup_create_begin($s1);
    ( $r1 > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("update - insert file");
    my $x = "t/test/x";
    ( open FILE, ">$x" ) || return 0;
    ( print FILE "file x\n" ) || return 0;
    ( close FILE ) || return 0;
    test_atom_end();

    test_atom_begin("update - create");
    my $s2 = "t/temp/s2";
    my $r2 = test_setup_create_begin($s2);
    ( $r2 > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("update - fetch");
    my $dx = test_setup();
    my $rx = $dx->update("file:$s1", "user", "pass", $s2);
    ( $rx > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("update - compare");
    my $dy = test_setup();
    my $ry = $dy->compare("file:$s1", "user", "pass", $s2);
    ( $ry == 0 ) || return 0;
    test_atom_end();

    test_atom_begin("update - end");
    ( unlink $x ) || return 0;
    test_atom_end();

    test_atom_begin("update - remove file");
    $r1 = test_setup_create_end($s1);
    ( $r1 > 0 ) || return 0;
    $r2 = test_setup_create_end($s2);
    ( $r2 > 0 ) || return 0;
    test_atom_end();
    }

    {
    test_atom_begin("update - begin");
    my $s = "t/temp/s";
    my $r = test_setup_create_begin($s);
    ( $r > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("update - insert file");
    my $x = "t/test/x";
    ( open FILE, ">$x" ) || return 0;
    ( print FILE "file x\n" ) || return 0;
    ( close FILE ) || return 0;
    test_atom_end();

    test_atom_begin("update - compute");
    my $dx = test_setup_configure();
    my $rx = $dx->update("", "", "", $s);
    ( $rx > 0 ) || return 0;
    test_atom_end();
    test_atom_begin("update - compare");
    my $dy = test_setup_configure();
    my $ry = $dy->compare("", "", "", $s);
    ( $ry == 0 ) || return 0;
    test_atom_end();

    test_atom_begin("update - end");
    ( unlink $x ) || return 0;
    test_atom_end();

    test_atom_begin("update - remove file");
    $r = test_setup_create_end($s);
    ( $r > 0 ) || return 0;
    test_atom_end();
    }

    return 1; 
}

###########################################################################

1;
