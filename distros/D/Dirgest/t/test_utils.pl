
######################################################################
#
#   Directory Digest -- test_utils.pl
#   Matthew Gream (MGREAM) <matthew.gream@pobox.com>
#   Copyright 2002 Matthew Gream. All Rights Reserved.
#   $Id: test_utils.pl,v 0.90 2002/10/21 20:24:06 matt Exp matt $
#
#   Test utilities
#    
######################################################################



###########################################################################

use File::Find;
use Fcntl ':mode';

sub find_clean_erase
{ 
    my $file = $File::Find::name;
    my @stat = (stat($file));
    my $mode = (@stat)[2];
    if (S_ISDIR($mode)) { rmdir $file; }
    else { unlink $file; }
} 
sub test_clean
{
    my($d) = @_;
    if ( -d $d ) 
    {
        find({ wanted => \&find_clean_erase, 
            follow => 0, no_chdir => 1, bydepth => 1 }, $d);
    }
}

###########################################################################

sub test_preamble
{
    test_file_set_destroy("t/test");
    test_clean("t/temp");
    mkdir "t/temp", 0777;
    test_file_set_create("t/test");
    return 1;
}
sub test_postamble
{
    test_file_set_destroy("t/test");
    test_clean("t/temp");
    return 1;
}

###########################################################################

sub test_file_set_create
{
    my($d) = @_;
    mkdir "$d", 0777;
    open FILE, ">$d/1"; print FILE "file 1\n"; close FILE;
    open FILE, ">$d/2"; print FILE "file 2\n"; close FILE;
    mkdir "$d/3", 0777;
    open FILE, ">$d/3/a"; print FILE "file a\n"; close FILE;
    return 1;
}
sub test_file_set_destroy
{
    my($d) = @_;
    test_clean($d);
    return 1;
}

sub test_file_insert_create
{ open FILE, ">t/test/z"; print FILE "file z\n"; close FILE; }
sub test_file_insert_destroy
{ unlink "t/test/z"; }
sub test_file_modify_create
{ open FILE, ">t/test/2"; print FILE "file 2x\n"; close FILE; }
sub test_file_modify_destroy
{ open FILE, ">t/test/2"; print FILE "file 2\n"; close FILE; }
sub test_file_remove_create
{ unlink "t/test/2"; }
sub test_file_remove_destroy
{ open FILE, ">t/test/2"; print FILE "file 2\n"; close FILE; }

sub test_file_check
{ my($a) = @_; 
  ( open FILE, "<$a" ) || return 0;
  close FILE;
  return 1;
}
sub test_file_print
{ my($a) = @_; my($s)  = "";
  ( open FILE, "<$a" ) || return 0;
  while (<FILE>) { $s .= $_; }; close FILE;
  print "[[file => $a :: $s]]\n";
  return 1;
}
sub test_file_copy
{ my($a,$b) = @_; my($s) = "";
  ( open FILE, "<$a" ) || return 0;
  while (<FILE>) { $s .= $_; }; close FILE;
  ( open FILE, ">$b" ) || return 0;
  print FILE $s; close FILE; 
  return 1;
}
sub test_file_compare
{ my($a,$b) = @_; my($s_a) = ""; my($s_b) = "";
  ( open FILE, "<$a" ) || return 0;
  while (<FILE>) { $s_a .= $_; }; close FILE;
  ( open FILE, "<$b" ) || return 0;
  while (<FILE>) { $s_b .= $_; }; close FILE;
  ( $s_a eq $s_b ) || return 0;
  return 1;
}

###########################################################################

sub test_caller
{
    my($f) = @_;
    ok(1, \&$f);
}
sub test_title
{
    my($s) = @_;
    print "TEST-SUITE: ", $s, "\n";
}
sub test_atom_begin
{
    my($s) = @_;
    print "TEST-CASE: ", $s, "\n";
}
sub test_atom_end
{
    ok(1);
}

###########################################################################

sub test_configure_create
{
    my($c,$i,$e,$t) = @_;
    ( open FILE, ">$c" ) || return 0;
    foreach (@$i) {
        ( print FILE "+$_\n" ) || return 0;
    }
    foreach (@$e) { 
        ( print FILE "-$_\n" ) || return 0;
    }
    if ($t) {
        ( print FILE "!trim=$t\n") || return 0;
    }
    ( close FILE ) || return 0;
    return 1;
}
sub test_configure_destroy
{
    my($c) = @_;
    ( unlink $c ) || return 0;
    return 1;
}

###########################################################################

sub test_prog_exec
{
    my($prog,$args) = @_; 
    my($o) = "";
    if ( open(SCRIPT, "$prog $args 2>\&1 |") ) 
    {
        while (<SCRIPT>)
        { 
            $o .= $_; 
        }
        close(SCRIPT);
    }
    return $o;
}
sub test_prog_code
{
    my($prog) = @_;
    my($o) = "";
    if ( open(SCRIPT, "<$prog") ) 
    {
        while (<SCRIPT>)
        { 
            $o .= $_; 
        }
        close(SCRIPT);
    }
    return $o;
}

###########################################################################

1;
