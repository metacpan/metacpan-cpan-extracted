
######################################################################
#
#   Directory Digest -- 03-CGI.t
#   Matthew Gream (MGREAM) <matthew.gream@pobox.com>
#   Copyright 2002 Matthew Gream. All Rights Reserved.
#   $Id: 03-CGI.t,v 0.90 2002/10/21 20:24:06 matt Exp matt $
#
#   Test dirgest.cgi
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
test_caller(\&test_operation_types);
test_caller(\&test_operation_options);
test_caller(\&test_operation_show);
test_caller(\&test_postamble);

###########################################################################

sub test_dirgest_cgi_exec
{
    my($args) = @_; $args = "" if (not defined $args);
    return test_prog_exec(test_config_exec_cgi(), $args);
}
sub test_dirgest_cgi_code
{
    return test_prog_code(test_config_exec_cgi());
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

###########################################################################

sub test_specification 
{ 
    test_title("specification => variables");

    test_atom_begin("specification - PROGRAM, VERSION, AUTHOR, RIGHTS, USAGE");
    my($s) = test_dirgest_cgi_code();
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

    test_atom_begin("null - output w/ help + cgi");
    my($o) = test_dirgest_cgi_exec();
    ( length($o) > 0 ) || return 0;
    $_ = $o; ( m/help/ig ) || return 0;
    $_ = $o; ( m/Content-Type:/ig ) || return 0;
    test_atom_end();

    return 1;
}

###########################################################################

sub test_usage 
{ 
    test_title("usage => help,version");

    test_atom_begin("usage - assistance");
    my($o) = test_dirgest_cgi_exec();
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
    my($o) = test_dirgest_cgi_exec("o=help");
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
    my($o) = test_dirgest_cgi_exec("o=version");
    $_ = $o; ( m/$v/ig ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

sub test_operation_types 
{ 
    test_title("command types => valid, invalid");

    test_atom_begin("command type - begin");
    my($v) = test_config_version();
    test_atom_end();

    test_atom_begin("command type invalid - empty,invalid");
    my($o) = test_dirgest_cgi_exec("o=dummy");
    $_ = $o; ( m/help/ig ) || return 0;
    $o = test_dirgest_cgi_exec("o=");
    $_ = $o; ( m/help/ig ) || return 0;
    $o = test_dirgest_cgi_exec("");
    $_ = $o; ( m/help/ig ) || return 0;
    test_atom_end();

    test_atom_begin("command type valid - show");
    $o = test_dirgest_cgi_exec("o=show");
    $_ = $o; ( ! m/help/ig ) || return 0;
    # $_ = $o; ( m/copyright/ig ) || return 0;
    # $_ = $o; ( m/v$v/ig ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

sub test_operation_options 
{ 
    test_title("options => generic - nothing!");

    test_atom_begin("options - begin");
    my($s) = test_dirgest_cgi_code();
    test_atom_end();

    test_atom_begin("options - secure = 1");
    $_ = $s; ( m/SECURE.*1/ig ) || return 0;
    test_atom_end();

    test_atom_begin("options - quiet = 1");
    $_ = $s; ( m/QUIET.*1/ig ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

sub test_operation_show 
{ 
    test_title("show => comp/link - details/summary");

    my($c) = "";
    my($t) = "t/temp/t";
    my(@i) = ( "t/test" ); my($i) = join(' ', @i);
    my(@e) = ( "t/test/3" ); my($e) = join(' ', @e);
    my(@x) = ( "t/test/2" ); my($x) = join(' ', @x);

    test_atom_begin("show - begin");
    my($s) = test_dirgest_cgi_code();
    $_ = $s; if (/CONFIGURE[^\n=]*=[^\n\"]*\"([^\n\"]*)\"/ig) { $c = $1; }; 
    ( length($c) > 0 ) || return 0;
    ( test_configure_create($c,\@i,\@e) ) || return 0;
    test_atom_end();

    test_atom_begin("show - compute");
    my($o) = test_dirgest_cgi_exec("o=show");
    ( test_inspect_output_string($o,2,1) ) || return 0;
    test_atom_end();

    test_atom_begin("show - end");
    ( test_configure_destroy($c) ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

1;
