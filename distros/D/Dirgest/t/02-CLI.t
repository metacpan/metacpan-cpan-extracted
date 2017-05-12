
######################################################################
#
#   Directory Digest -- 02-CLI.t
#   Matthew Gream (MGREAM) <matthew.gream@pobox.com>
#   Copyright 2002 Matthew Gream. All Rights Reserved.
#   $Id: 02-CLI.t,v 0.90 2002/10/21 20:24:06 matt Exp matt $
#
#   Test dirgest.pl
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
BEGIN { plan tests => test_count();
        print STDERR "the script needs to run a few times: these tests may take some time (sorry!)\n"; }

###########################################################################

test_caller(\&test_preamble);
test_caller(\&test_specification);
test_caller(\&test_null);
test_caller(\&test_usage);
test_caller(\&test_help);
test_caller(\&test_version);
test_caller(\&test_command_types);
test_caller(\&test_command_options);
test_caller(\&test_command_create);
test_caller(\&test_command_show);
test_caller(\&test_command_compare);
test_caller(\&test_command_update);
test_caller(\&test_postamble);

###########################################################################

sub test_dirgest_cli_exec
{
    my($args) = @_; $args = "" if (not defined $args);
    return test_prog_exec(test_config_exec_cli(), $args);
}
sub test_dirgest_cli_code
{
    return test_prog_code(test_config_exec_cli());
}

###########################################################################

sub test_inspect_output_string
{
    my($o,$c_n,$c_s,$c_x) = @_;
    my($n) = 0;     
    my($s) = 0; 
    my($x) = 0;
    foreach (split('\n', $o)) {
        if (/^=/) { $n++; }
        elsif (/^#/) { $s++; }
        else { $x++; }
    }
print "n=$n [$c_n]; s=$s [$c_s]; x=$x\n";
    ( $c_n == $n ) || return 0;
    ( $c_s == $s ) || return 0;
    ( !defined $c_x || $c_x == $x ) || return 0;
    return 1;
}
sub test_inspect_output_file
{
    my($f,$c_n,$c_s) = @_;
    my($n) = 0; my($s) = 0; my($x) = 0;
    ( open FILE, "<$f" ) || return 0;
    while (<FILE>) {
        if (/^=/) { $n++; }
        elsif (/^#/) { $s++; }
        else { $x++; }
    }
    ( close FILE ) || return 0;
    ( unlink $f ) || return 0;
print "n=$n [$c_n]; s=$s [$c_s]; x=$x\n";
    ( $c_n == $n ) || return 0;
    ( $c_s == $s ) || return 0;
    ( 0 <= $x ) || return 0;
    return 1;
}
sub test_inspect_compare_string
{
    my($o,$c_i,$c_m,$c_r,$c_s,$c_e,$c_x) = @_;
    my($i) = 0;     
    my($m) = 0; 
    my($r) = 0;
    my($s) = 0;
    my($e) = 0;
    my($x) = 0;
    foreach (split('\n', $o)) {
        if (/^</) { $i++; }
        elsif (/^\!/) { $m++; }
        elsif (/^>/) { $r++; }
        elsif (/^=/) { $e++; }
        elsif (/^\?/) { $s++; }
        else { $x++; }
    }
print "i=$i [$c_i]; m=$m [$c_m]; r=$r [$c_r]; s=$s [$c_s]; e=$e [$c_e] x=$x\n";
    ( $c_i == $i ) || return 0;
    ( $c_m == $m ) || return 0;
    ( $c_r == $r ) || return 0;
    ( $c_s == $s ) || return 0;
    ( $c_e == $e ) || return 0;
    ( !defined $c_x || $c_x == $x ) || return 0;
    return 1;
}

###########################################################################

sub test_specification 
{ 
    test_title("specification => variables");

    test_atom_begin("specification - PROGRAM, VERSION, AUTHOR, RIGHTS, USAGE");
    my($s) = test_dirgest_cli_code();
    $_ = $s; ( m/\$PROGRAM[ \t]*=/g ) || return 0;
    $_ = $s; ( m/\$VERSION[ \t]*=/g ) || return 0;
    $_ = $s; ( m/\$AUTHOR[ \t]*=/g ) || return 0;
    $_ = $s; ( m/\$RIGHTS[ \t]*=/g ) || return 0;
    $_ = $s; ( m/\$USAGE[ \t]*=/g ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

sub test_null 
{
    test_title("null => something!");

    test_atom_begin("null - output w/ help");
    my($o) = test_dirgest_cli_exec();
    ( length($o) > 0 ) || return 0;
    $_ = $o; ( m/help/ig ) || return 0;
    test_atom_end();

    return 1;
}

###########################################################################

sub test_usage 
{ 
    test_title("usage => help,version");

    test_atom_begin("usage - assistance");
    my($o) = test_dirgest_cli_exec();
    $_ = $o; ( m/help/ig ) || return 0;
    $_ = $o; ( m/version/ig ) || return 0;
    test_atom_end();
    
    return 1; 
}

###########################################################################

sub test_help 
{
    test_title("help => help,ipr");

    test_atom_begin("help - begin");
    my($o) = test_dirgest_cli_exec("--help");
    test_atom_end();

    test_atom_begin("help - intellectual property rights");
    $_ = $o; ( m/copyright.*2002.*matthew gream/ig ) || return 0;
    $_ = $o; ( m/all rights reserved/ig ) || return 0;
    test_atom_end();

    test_atom_begin("help - assistance");
    $_ = $o; ( m/help/ig ) || return 0;
    $_ = $o; ( m/version/ig ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

sub test_version
{
    test_title("version => valid");

    test_atom_begin("version - begin");
    my($v) = test_config_version();
    test_atom_end();

    test_atom_begin("version - $v");
    my($o) = test_dirgest_cli_exec("--version");
    $_ = $o; ( m/$v/ig ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

sub test_command_types 
{ 
    test_title("command types => valid, invalid");

    test_atom_begin("command type - begin");
    my($v) = test_config_version();
    test_atom_end();

    test_atom_begin("command type invalid - empty,invalid");
    my($o) = test_dirgest_cli_exec("--noop dummy");
    $_ = $o; ( m/help/ig ) || return 0;
    $o = test_dirgest_cli_exec("--noop");
    $_ = $o; ( m/help/ig ) || return 0;
    test_atom_end();

    test_atom_begin("command type valid - show");
    $o = test_dirgest_cli_exec("--noop show");
    $_ = $o; ( ! m/help/ig ) || return 0;
    $_ = $o; ( m/copyright/ig ) || return 0;
    $_ = $o; ( m/v$v/ig ) || return 0;
    test_atom_end();

    test_atom_begin("command type valid - create");
    $o = test_dirgest_cli_exec("--noop create");
    $_ = $o; ( ! m/help/ig ) || return 0;
    $_ = $o; ( m/copyright/ig ) || return 0;
    $_ = $o; ( m/v$v/ig ) || return 0;
    test_atom_end();

    test_atom_begin("command type valid - compare");
    $o = test_dirgest_cli_exec("--noop compare");
    $_ = $o; ( ! m/help/ig ) || return 0;
    $_ = $o; ( m/copyright/ig ) || return 0;
    $_ = $o; ( m/v$v/ig ) || return 0;
    test_atom_end();

    test_atom_begin("command type valid - update");
    $o = test_dirgest_cli_exec("--noop update");
    $_ = $o; ( ! m/help/ig ) || return 0;
    $_ = $o; ( m/copyright/ig ) || return 0;
    $_ = $o; ( m/v$v/ig ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

sub test_command_options 
{ 
    test_title("options => generic - nothing!");

    test_atom_begin("options - quiet = nothing");
    my($o) = test_dirgest_cli_exec("--quiet show");
    ( length($o) == 0 ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

sub test_command_create 
{ 
    test_title("create => comp/link to file - details/summary [or show]");

    test_atom_begin("create - begin");
    my($c) = "t/temp/c";
    my($s) = "t/temp/s";
    my($t) = "t/temp/t";
    my($d) = "DIRGESTS";
    my(@i) = ( "t/test" ); my($i) = join(' ', @i);
    my(@e) = ( "t/test/3" ); my($e) = join(' ', @e);
    my(@x) = ( "t/test/2" ); my($x) = join(' ', @x);
    ( test_configure_create($c,\@i,\@e) ) || return 0;
    test_atom_end();

    test_atom_begin("create - compute with configure, filename / no_filename");
    my($o) = test_dirgest_cli_exec("--configure=$c create");
    $_ = $o; ( m/CREATING/ig ) || return 0;
    ( test_inspect_output_file($d,2,1) ) || return 0;
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s create");
    $_ = $o; ( m/CREATING/ig ) || return 0;
    ( test_inspect_output_file($s,2,1) ) || return 0;
    test_atom_end();

    test_atom_begin("create - compute with command line, filename / no_filename");
    $o = test_dirgest_cli_exec("create +$i -$e");
    $_ = $o; ( m/CREATING/ig ) || return 0;
    ( test_inspect_output_file($d,2,1) ) || return 0;
    $o = test_dirgest_cli_exec("--filename=$s create +$i -$e");
    $_ = $o; ( m/CREATING/ig ) || return 0;
    ( test_inspect_output_file($s,2,1) ) || return 0;
    $o = test_dirgest_cli_exec("create $i -$e");
    $_ = $o; ( m/CREATING/ig ) || return 0;
    ( test_inspect_output_file($d,2,1) ) || return 0;
    $o = test_dirgest_cli_exec("--filename=$s create $i -$e");
    $_ = $o; ( m/CREATING/ig ) || return 0;
    ( test_inspect_output_file($s,2,1) ) || return 0;
    test_atom_end();

    test_atom_begin("create - compute with configure + command line, filename / no_filename");
    $o = test_dirgest_cli_exec("--configure=$c create -$x");
    $_ = $o; ( m/CREATING/ig ) || return 0;
    ( test_inspect_output_file($d,1,1) ) || return 0;
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s create -$x");
    $_ = $o; ( m/CREATING/ig ) || return 0;
    ( test_inspect_output_file($s,1,1) ) || return 0;
    test_atom_end();

    test_atom_begin("create - fetch [+user/pass], filename / no_filename");
    test_dirgest_cli_exec("--configure=$c --filename=$t create");
    $o = test_dirgest_cli_exec("--fetch=file:$t --login=user:pass create");
    $_ = $o; ( m/CREATING/ig ) || return 0;
    ( test_inspect_output_file($d,2,1) ) || return 0;
    $o = test_dirgest_cli_exec("--fetch=file:$t --login=user:pass --filename=$s create");
    $_ = $o; ( m/CREATING/ig ) || return 0;
    ( test_inspect_output_file($s,2,1) ) || return 0;
    test_atom_end();

    test_atom_begin("create - quiet / no_quiet");
    $o = test_dirgest_cli_exec("--quiet --configure=$c --filename=$s create");
    $_ = $o; ( ! m/CREATING/ig ) || return 0;
    test_atom_end();

    test_atom_begin("create - show, nodetails, nosummary");
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s --show create");
    $_ = $o; ( m/CREATING/ig ) || return 0;
    ( test_inspect_output_string($o,2,1) ) || return 0;
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s --show --nodetails create");
    $_ = $o; ( m/CREATING/ig ) || return 0;
    ( test_inspect_output_string($o,0,1) ) || return 0;
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s --show --nosummary create");
    $_ = $o; ( m/CREATING/ig ) || return 0;
    ( test_inspect_output_string($o,2,0) ) || return 0;
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s --show --nodetails --nosummary create");
    $_ = $o; ( m/CREATING/ig ) || return 0;
    ( test_inspect_output_string($o,0,0) ) || return 0;
    test_atom_end();

    test_atom_begin("create - trim");
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s --show --trim=0 create");
    $_ = $o; ( m/CREATING/ig ) || return 0;
    $_ = $o; ( m/= [^ ]+ [0-9]+ t\/test\/2/ig ) || return 0;
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s --show --trim=1 create");
    $_ = $o; ( m/CREATING/ig ) || return 0;
    $_ = $o; ( m/= [^ ]+ [0-9]+ test\/2/ig ) || return 0;
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s --show --trim=2 create");
    $_ = $o; ( m/CREATING/ig ) || return 0;
    $_ = $o; ( m/= [^ ]+ [0-9]+ 2/ig ) || return 0;
    test_atom_end();

    test_atom_begin("create - show and quiet");
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s --quiet --show create");
    $_ = $o; ( ! m/CREATING/ig ) || return 0;
    ( test_inspect_output_string($o,2,1,0) ) || return 0;
    test_atom_end();

    test_atom_begin("create - end");
    ( test_configure_destroy($c) ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

sub test_command_show 
{ 
    test_title("show => comp/link - details/summary");

    test_atom_begin("show - begin");
    my($c) = "t/temp/c";
    my($t) = "t/temp/t";
    my(@i) = ( "t/test" ); my($i) = join(' ', @i);
    my(@e) = ( "t/test/3" ); my($e) = join(' ', @e);
    my(@x) = ( "t/test/2" ); my($x) = join(' ', @x);
    ( test_configure_create($c,\@i,\@e) ) || return 0;
    test_atom_end();

    test_atom_begin("show - compute with configure");
    my($o) = test_dirgest_cli_exec("--configure=$c show");
    $_ = $o; ( m/SHOWING/ig ) || return 0;
    ( test_inspect_output_string($o,2,1) ) || return 0;
    test_atom_end();

    test_atom_begin("show - compute with command line");
    $o = test_dirgest_cli_exec("show +$i -$e");
    $_ = $o; ( m/SHOWING/ig ) || return 0;
    ( test_inspect_output_string($o,2,1) ) || return 0;
    $o = test_dirgest_cli_exec("show $i -$e");
    $_ = $o; ( m/SHOWING/ig ) || return 0;
    ( test_inspect_output_string($o,2,1) ) || return 0;
    test_atom_end();

    test_atom_begin("show - compute with configure + command line");
    $o = test_dirgest_cli_exec("--configure=$c show -$x");
    $_ = $o; ( m/SHOWING/ig ) || return 0;
    ( test_inspect_output_string($o,1,1) ) || return 0;
    test_atom_end();

    test_atom_begin("show - fetch [+user/pass]");
    test_dirgest_cli_exec("--configure=$c --filename=$t create");
    $o = test_dirgest_cli_exec("--fetch=file:$t --login=user:pass show");
    $_ = $o; ( m/SHOWING/ig ) || return 0;
    ( test_inspect_output_string($o,2,1) ) || return 0;
    test_atom_end();

    test_atom_begin("show - quiet / no_quiet");
    $o = test_dirgest_cli_exec("--quiet --configure=$c show");
    $_ = $o; ( ! m/SHOWING/ig ) || return 0;
    ( test_inspect_output_string($o,2,1,0) ) || return 0;
    test_atom_end();

    test_atom_begin("show - nodetails, nosummary");
    $o = test_dirgest_cli_exec("--configure=$c --nodetails show");
    $_ = $o; ( m/SHOWING/ig ) || return 0;
    ( test_inspect_output_string($o,0,1) ) || return 0;
    $o = test_dirgest_cli_exec("--configure=$c --nosummary show");
    $_ = $o; ( m/SHOWING/ig ) || return 0;
    ( test_inspect_output_string($o,2,0) ) || return 0;
    $o = test_dirgest_cli_exec("--configure=$c --nodetails --nosummary show");
    $_ = $o; ( m/SHOWING/ig ) || return 0;
    ( test_inspect_output_string($o,0,0) ) || return 0;
    test_atom_end();

    test_atom_begin("show - trim");
    $o = test_dirgest_cli_exec("--configure=$c --trim=0 show");
    $_ = $o; ( m/SHOWING/ig ) || return 0;
    $_ = $o; ( m/= [^ ]+ [0-9]+ t\/test\/2/ig ) || return 0;
    $o = test_dirgest_cli_exec("--configure=$c --trim=1 show");
    $_ = $o; ( m/SHOWING/ig ) || return 0;
    $_ = $o; ( m/= [^ ]+ [0-9]+ test\/2/ig ) || return 0;
    $o = test_dirgest_cli_exec("--configure=$c --trim=2 show");
    $_ = $o; ( m/SHOWING/ig ) || return 0;
    $_ = $o; ( m/= [^ ]+ [0-9]+ 2/ig ) || return 0;
    test_atom_end();

    test_atom_begin("show - end");
    ( test_configure_destroy($c) ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

sub test_command_compare 
{ 
    test_title("compare => comp/link & file - details/summary/equals");

    test_atom_begin("compare - begin");
    my($c) = "t/temp/c";
    my($s) = "t/temp/s";
    my($z) = "t/test/z";
    my(@i) = ( "t/test" ); my($i) = join(' ', @i);
    my(@e) = ( "t/test/3" ); my($e) = join(' ', @e);
    my(@x) = ( "t/test/2" ); my($x) = join(' ', @x);
    ( test_configure_create($c,\@i,\@e) ) || return 0;
    ( test_dirgest_cli_exec("--configure=$c --filename=$s create") ) ||return 0;
    test_atom_end();

    test_atom_begin("compare - compute, same");
    my($o) = test_dirgest_cli_exec("--configure=$c --filename=$s compare");
    $_ = $o; ( m/COMPARING/ig ) || return 0;
    $_ = $o; ( m/differences.*0/ig ) || return 0;
    ( test_inspect_compare_string($o,0,0,0,0,0) ) || return 0;
    test_atom_end();

    test_atom_begin("compare - compute, added");
    test_file_insert_create();
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s compare");
    $_ = $o; ( m/COMPARING/ig ) || return 0;
    $_ = $o; ( m/differences.*2/ig ) || return 0;
    ( test_inspect_compare_string($o,1,0,0,1,0) ) || return 0;
    test_file_insert_destroy();
    test_atom_end();

    test_atom_begin("compare - compute, modified");
    test_file_modify_create();
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s compare");
    $_ = $o; ( m/COMPARING/ig ) || return 0;
    $_ = $o; ( m/differences.*2/ig ) || return 0;
    ( test_inspect_compare_string($o,0,1,0,1,0) ) || return 0;
    test_file_modify_destroy();
    test_atom_end();

    test_atom_begin("compare - compute, removed");
    test_file_remove_create();
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s compare");
    $_ = $o; ( m/COMPARING/ig ) || return 0;
    $_ = $o; ( m/differences.*2/ig ) || return 0;
    ( test_inspect_compare_string($o,0,0,1,1,0) ) || return 0;
    test_file_remove_destroy();
    test_atom_end();

    test_atom_begin("compare - computed, added, nosummary");
    test_file_insert_create();
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s --nosummary compare");
    $_ = $o; ( m/COMPARING/ig ) || return 0;
    $_ = $o; ( m/differences.*1/ig ) || return 0;
    ( test_inspect_compare_string($o,1,0,0,0,0) ) || return 0;
    test_file_insert_destroy();
    test_atom_end();

    test_atom_begin("compare - computed, added, nodetails");
    test_file_insert_create();
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s --nodetails compare");
    $_ = $o; ( m/COMPARING/ig ) || return 0;
    $_ = $o; ( m/differences.*1/ig ) || return 0;
    ( test_inspect_compare_string($o,0,0,0,1,0) ) || return 0;
    test_file_insert_destroy();
    test_atom_end();

    test_atom_begin("compare - computed, added, nodetails,nosummary");
    test_file_insert_create();
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s --nosummary --nodetails compare");
    $_ = $o; ( m/COMPARING/ig ) || return 0;
    $_ = $o; ( m/differences.*0/ig ) || return 0;
    ( test_inspect_compare_string($o,0,0,0,0,0) ) || return 0;
    test_file_insert_destroy();
    test_atom_end();

    test_atom_begin("compare - fetch => skipped");
    test_atom_end();

    test_atom_begin("compare - computed, added, equals");
    test_file_insert_create();
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s --show_equal compare");
    $_ = $o; ( m/COMPARING/ig ) || return 0;
    $_ = $o; ( m/differences.*2/ig ) || return 0;
    ( test_inspect_compare_string($o,1,0,0,1,2) ) || return 0;
    test_file_insert_destroy();
    test_atom_end();

    test_atom_begin("compare - computed, added, nosummary,equals");
    test_file_insert_create();
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s --show_equal --nosummary compare");
    $_ = $o; ( m/COMPARING/ig ) || return 0;
    $_ = $o; ( m/differences.*1/ig ) || return 0;
    ( test_inspect_compare_string($o,1,0,0,0,2) ) || return 0;
    test_file_insert_destroy();
    test_atom_end();

    test_atom_begin("compare - computed, added, nodetails,equals");
    test_file_insert_create();
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s --show_equal --nodetails compare");
    $_ = $o; ( m/COMPARING/ig ) || return 0;
    $_ = $o; ( m/differences.*1/ig ) || return 0;
    ( test_inspect_compare_string($o,0,0,0,1,0) ) || return 0;
    test_file_insert_destroy();
    test_atom_end();

    test_atom_begin("compare - computed, added, nodetails,nosummary,equals");
    test_file_insert_create();
    $o = test_dirgest_cli_exec("--configure=$c --filename=$s --show_equal --nodetails --nosummary compare");
    $_ = $o; ( m/COMPARING/ig ) || return 0;
    $_ = $o; ( m/differences.*0/ig ) || return 0;
    ( test_inspect_compare_string($o,0,0,0,0,0) ) || return 0;
    test_file_insert_destroy();
    test_atom_end();

    test_atom_begin("create - end");
    ( test_configure_destroy($c) ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

sub test_command_update 
{ 
    test_title("update => comp/link & file to file - details/summary/equals");

    test_atom_begin("update - begin");
    my($c) = "t/temp/c";
    my($s) = "t/temp/s";
    my($ss)= "t/temp/ss";
    my($sss)="t/temp/sss";
    my($z) = "t/test/z";
    my(@i) = ( "t/test" ); my($i) = join(' ', @i);
    my(@e) = ( "t/test/3" ); my($e) = join(' ', @e);
    my(@x) = ( "t/test/2" ); my($x) = join(' ', @x);
    ( test_configure_create($c,\@i,\@e) ) || return 0;
    ( test_dirgest_cli_exec("--configure=$c --filename=$s create") ) ||return 0;
    test_atom_end();

    test_atom_begin("update - compute, same");
    test_file_copy($s, $ss);
    my($o) = test_dirgest_cli_exec("--configure=$c --filename=$ss update");
    $_ = $o; ( m/UPDATING/ig ) || return 0;
    $_ = $o; ( m/differences.*0/ig ) || return 0;
    ( test_file_compare($s, $ss) ) || return 0;
    $o = test_dirgest_cli_exec("--configure=$c --filename=$sss create");
    ( test_file_compare($ss, $sss) ) || return 0;
    test_atom_end();

    test_atom_begin("update - compute, added");
    test_file_insert_create();
    test_file_copy($s, $ss);
    $o = test_dirgest_cli_exec("--configure=$c --filename=$ss update");
    $_ = $o; ( m/UPDATING/ig ) || return 0;
    $_ = $o; ( m/differences.*2/ig ) || return 0;
    ( ! test_file_compare($s, $ss) ) || return 0;
    $o = test_dirgest_cli_exec("--configure=$c --filename=$sss create");
    ( test_file_compare($ss, $sss) ) || return 0;
    test_file_insert_destroy();
    test_atom_end();

    test_atom_begin("update - compute, modified");
    test_file_modify_create();
    test_file_copy($s, $ss);
    $o = test_dirgest_cli_exec("--configure=$c --filename=$ss update");
    $_ = $o; ( m/UPDATING/ig ) || return 0;
    $_ = $o; ( m/differences.*2/ig ) || return 0;
    ( ! test_file_compare($s, $ss) ) || return 0;
    $o = test_dirgest_cli_exec("--configure=$c --filename=$sss create");
    ( test_file_compare($ss, $sss) ) || return 0;
    test_file_modify_destroy();
    test_atom_end();

    test_atom_begin("update - compute, removed");
    test_file_remove_create();
    test_file_copy($s, $ss);
    $o = test_dirgest_cli_exec("--configure=$c --filename=$ss update");
    $_ = $o; ( m/UPDATING/ig ) || return 0;
    $_ = $o; ( m/differences.*2/ig ) || return 0;
    ( ! test_file_compare($s, $ss) ) || return 0;
    $o = test_dirgest_cli_exec("--configure=$c --filename=$sss create");
    ( test_file_compare($ss, $sss) ) || return 0;
    test_file_remove_destroy();
    test_atom_end();

    test_atom_begin("update - fetch => skipped");
    test_atom_end();

    test_atom_begin("update - end");
    ( test_configure_destroy($c) ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

1;
