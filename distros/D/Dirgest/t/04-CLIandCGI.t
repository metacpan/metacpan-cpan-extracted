
######################################################################
#
#   Directory Digest -- 04-CLIandCGI.t
#   Matthew Gream (MGREAM) <matthew.gream@pobox.com>
#   Copyright 2002 Matthew Gream. All Rights Reserved.
#   $Id: 04-CLIandCGI.t,v 0.90 2002/10/21 20:24:06 matt Exp matt $
#
#   Test dirgest.cgi + dirgest.pl interaction
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

test_caller(\&test_preamble);
test_caller(\&test_dirgest_replicate);
test_caller(\&test_postamble);

###########################################################################

sub test_dirgest_cli_exec
{
    my($args) = @_; $args = "" if (not defined $args);
    return test_prog_exec(test_config_exec_cli(), $args);
}
sub test_dirgest_cgi_exec
{
    my($args) = @_; $args = "" if (not defined $args);
    return test_prog_exec(test_config_exec_cgi(), $args);
}

###########################################################################

sub test_dirgest_replicate
{
    test_title("cli+cgi => replicate");

    test_atom_begin("replicate - cli configure");
    my($c) = "t/temp/c";
    my($s) = "t/temp/s";
    my(@i) = ( "t/test" ); my($i) = join(' ', @i);
    my(@e) = ( );
    my($t) = 2;
    ( test_configure_create($c,\@i,\@e,$t) ) || return 0;
    test_atom_end();

    test_atom_begin("replicate - cli generate");
    ( test_file_check($s) == 0 ) || return 0;
    my($o1) = test_dirgest_cli_exec("--configure=$c --filename=$s create");
    ( test_file_check($s) >  0 ) || return 0;
    test_atom_end();

    test_atom_begin("replicate - create");
    ( test_file_set_create("t/test_2") ) || return 0;
    test_atom_end();

    test_atom_begin("replicate - cgi configure");
    my($cc) = "dirgest.conf";
    my($ss) = "t/temp/ss";
    my(@ii) = ( "t/test_2" ); my($ii) = join(' ', @ii);
    my(@ee) = ( );
    my($tt) = 2;
    ( test_configure_create($cc,\@ii,\@ee,$tt) ) || return 0;
    test_atom_end();

    test_atom_begin("replicate - cgi generate");
    my($o2) = test_dirgest_cgi_exec("o=show");
    ( length($o2) > 0 ) || return 0;    
    open FILE, ">$ss"; print FILE $o2; close FILE;
    test_atom_end();

    test_atom_begin("replicate - cli+cgi compare");
    my($o3) = test_dirgest_cli_exec("--filename=$s --fetch=file:$ss --nodetails compare");
    $_ = $o3; ( m/differences.*0/ig ) || return 0;
    test_atom_end();

    test_atom_begin("replicate - cgi cleanup");
    ( test_configure_destroy($cc) ) || return 0;
    test_atom_end();

    test_atom_begin("replicate - destroy");
    ( test_file_set_destroy("t/test_2") ) || return 0;
    test_atom_end();

    return 1;
}

###########################################################################

1;
