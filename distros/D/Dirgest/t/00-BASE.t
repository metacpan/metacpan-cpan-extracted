
######################################################################
#
#   Directory Digest -- 00-BASE.t
#   Matthew Gream (MGREAM) <matthew.gream@pobox.com>
#   Copyright 2002 Matthew Gream. All Rights Reserved.
#   $Id: 00-BASE.t,v 0.90 2002/10/21 20:24:06 matt Exp matt $
#
#   Test BASE.pm
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

use Digest::Directory::BASE;

test_caller(\&test_preamble);
test_caller(\&test_specification);
test_caller(\&test_lifecycle);
test_caller(\&test_quiet);
test_caller(\&test_trim);
test_caller(\&test_include);
test_caller(\&test_exclude);
test_caller(\&test_configure);
test_caller(\&test_parse);
test_caller(\&test_digests);
test_caller(\&test_summary);
test_caller(\&test_compute);
test_caller(\&test_clear);
test_caller(\&test_string);
test_caller(\&test_print);
test_caller(\&test_save);
test_caller(\&test_load);
test_caller(\&test_fetch);
test_caller(\&test_compare);
test_caller(\&test_postamble);

###########################################################################

sub test_setup
{
    my $d = Digest::Directory::BASE->new;
    $d->quiet( test_config_quiet() );
    return $d;
}
sub test_setup_compute
{
    my $d = test_setup();
    my $n = "t/test";
    $d->include($n);
    $d->compute();
    return $d;
}
sub test_setup_save
{
    my $d = test_setup_compute();
    my $s = "t/temp/s";
    $d->save($s);
    return $d;
}

###########################################################################

sub test_compute_check
{
    my ($d, $n_r, $n_i, $n_e) = @_;
    $d->compute();
    my ($r) = $d->print();
    my %ss = $d->statistics();
print "r=$r [$n_r]; i=$ss{'include'} [$n_i]; e=$ss{'exclude'} [$n_e]\n";
    ( $r == $n_r ) || return 0;
    ( $ss{'include'} == $n_i && $ss{'exclude'} == $n_e ) || return 0;
    return 1;
}

###########################################################################

sub test_specification
{ 
    test_title("specification => variables");

    test_atom_begin("specification - PROGRAM,VERSION,AUTHOR,RIGHTS,USAGE");
    (defined $Digest::Directory::BASE::PROGRAM ) || return 0;
    (defined $Digest::Directory::BASE::VERSION ) || return 0;
    (defined $Digest::Directory::BASE::AUTHOR ) || return 0;
    (defined $Digest::Directory::BASE::RIGHTS ) || return 0;
    (defined $Digest::Directory::BASE::USAGE ) || return 0;
    test_atom_end();

    return 1;
}

###########################################################################

sub test_lifecycle 
{ 
    test_title("lifecycle => create");

    test_atom_begin("lifecycle - created alright");
    my $d = test_setup();
    ( defined $d ) || return 0;
    test_atom_end();

    return 1;
}

###########################################################################

sub test_quiet
{ 
    test_title("quiet => modes");

    test_atom_begin("quiet - set");
    my $d = test_setup();
    $d->quiet(1);
    my %ss = $d->statistics();
    ( $ss{'quiet'} == 1 ) || return 0;
    test_atom_end();

    test_atom_begin("quiet - unset");
    $d->quiet(0);
    %ss = $d->statistics();
    ( $ss{'quiet'} == 0 ) || return 0;
    test_atom_end();

    return 1;
}

###########################################################################

sub test_trim
{ 
    test_title("trim => numbers");

    test_atom_begin("trim - default");
    my $d1 = test_setup();
    my %ss1 = $d1->statistics();
    ( $ss1{'trim'} == 0 ) || return 0;
    test_atom_end();

    test_atom_begin("trim - 1");
    my $d2 = test_setup();
    $d2->trim(1);
    my %ss2 = $d2->statistics();
    ( $ss2{'trim'} == 1 ) || return 0;
    test_atom_end();

    test_atom_begin("trim - 4");
    my $d3 = test_setup();
    $d3->trim(4);
    %ss3 = $d3->statistics();
    ( $ss3{'trim'} == 4 ) || return 0;
    test_atom_end();

    return 1;
}


###########################################################################

sub test_include
{ 
    test_title("include => file+directory sets");

    test_atom_begin("include - directory");
    my $d1 = test_setup();
    my $n1 = "t/test/3";
    $d1->include($n1);
    ( test_compute_check($d1, 1, 1, 0) ) || return 0;
    test_atom_end();

    test_atom_begin("include - file");
    my $d2 = test_setup();
    my $n2 = "t/test/2";
    $d2->include($n2);
    ( test_compute_check($d2, 1, 1, 0) ) || return 0;
    test_atom_end();

    test_atom_begin("include - directory + file");
    my $d3 = test_setup();
    my $n3a = "t/test/2";
    my $n3b = "t/test/3";
    $d3->include($n3a);
    $d3->include($n3b);
    ( test_compute_check($d3, 2, 2, 0) ) || return 0;
    test_atom_end();

    return 1;
}

###########################################################################

sub test_exclude 
{ 
    test_title("exclude => file+directory sets");

    test_atom_begin("exclude file + exclude directory");
    my $n1 = "t/test";
    my $n2 = "t/test/3";
    my $d = test_setup();
    $d->include($n1);
    $d->exclude($n2);
    ( test_compute_check($d, 2, 1, 1) ) || return 0;
    test_atom_end();

    return 1;
}

###########################################################################

sub test_configure
{ 
    test_title("configure => read,content");

    {
    test_atom_begin("configure - read begin");
    my $d = test_setup();
    my $c = "t/temp/c";
    my $n1 = "t/test";
    my $n2 = "t/test/3";
    ( open FILE, ">$c" ) || return 0;
    ( print FILE "+$c\n" ) || return 0;
    ( print FILE "+$n1\n" ) || return 0;
    ( print FILE "-$n2\n" ) || return 0;
    ( close FILE ) || return 0;
    test_atom_end();

    test_atom_begin("configure - read");
    my $r = $d->configure($c);
    ( $r > 0 ) || return 0;
    ( test_compute_check($d, 3, 2, 1) ) || return 0;
    test_atom_end();

    test_atom_begin("configure - read end");
    ( unlink $c ) || return 0;
    test_atom_end();
    }


    {
    test_atom_begin("configure - begin");
    my $d = test_setup();
    my $c = "t/temp/c";
    my $f = <<_TEST_CONFIGURE_B_CONTENTS;
# nothing
!trim=4
!quiet=1
+ name_1a\n
+name_1b \n
+\tname_1c\n
 + name_1d \n
\t+ name_1e\n
  # nothing
- name_2a\n
-name_2b\n
-\tname_2c\n
 - name_2d\n
\t- name_2e\n
#nothing
_TEST_CONFIGURE_B_CONTENTS
    ( open FILE, ">$c" ) || return 0;
    ( print FILE $f ) || return 0;
    ( close FILE ) || return 0;
    test_atom_end();

    test_atom_begin("configure - read");
    my $r = $d->configure($c);
    ( $r > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("configure - contents");
    my %ss = $d->statistics();
    ( $ss{'include'} == 5 ) || return 0;
    ( $ss{'exclude'} == 5 ) || return 0;
    ( $ss{'quiet'} == 1 ) || return 0;
    ( $ss{'trim'} == 4 ) || return 0;
    test_atom_end();

    test_atom_begin("configure - end");
    ( unlink $c ) || return 0;
    test_atom_end();
    }

    return 1;
}

###########################################################################

sub test_parse 
{ 
    test_title("parse => skip");
    return 1;
}
sub test_digests 
{ 
    test_title("digests => skip");
    return 1;
}
sub test_summary 
{ 
    test_title("summary => skip");
    return 1;
}

###########################################################################

sub test_compute 
{ 
    test_title("compute => trim");

    test_atom_begin("compute - trim 0");
    my $n = "t/test";
    my $d1 = test_setup(); 
    $d1->include($n);
    $d1->trim(0);
    ( test_compute_check($d1, 3, 1, 0) ) || return 0;
    my $r1 = $d1->string();
    test_atom_end();

    test_atom_begin("compute - trim 1");
    my $d2 = test_setup(); 
    $d2->include($n);
    $d2->trim(1);
    ( test_compute_check($d2, 3, 1, 0) ) || return 0;
    my $r2 = $d2->string();
    test_atom_end();

    test_atom_begin("compute - trim 2");
    my $d3 = test_setup(); 
    $d3->include($n);
    $d3->trim(2);
    ( test_compute_check($d3, 3, 1, 0) ) || return 0;
    my $r3 = $d3->string();
    test_atom_end();

    test_atom_begin("compute - presence");
    ( $r1 =~ m@ t/test/[0-9]@ ) || return 0;
    ( $r2 =~ m@ test/[0-9]@ ) || return 0;
    ( $r3 =~ m@ [0-9]@ ) || return 0;
    test_atom_end();

    test_atom_begin("compute - equivalence");
    my @v1 = split('\n', $r1);
    my @v2 = split('\n', $r2);
    my @v3 = split('\n', $r3);
    my $x_c = scalar(@v1); my $x = 0;
    do {
        my @v1x = split(' ', $v1[$x]);
        my @v2x = split(' ', $v2[$x]);
        my @v3x = split(' ', $v3[$x]);
        my $y_c = scalar(@v1x); my $y = 0;
        if ($v1x[0] eq '=') { $y_c--; }
        if ($v1x[0] ne '#') 
        {   
            do {
            ( ($v1x[$y] eq $v2x[$y]) && ($v2x[$y] eq $v3x[$y]) ) || return 0;
            } while ++$y < $y_c;
        }
    } while ++$x < $x_c;
    test_atom_end();
    
    return 1; 
}

###########################################################################

sub test_clear 
{ 
    test_title("clear => all");

    test_atom_begin("clear - all");
    my $n = "t/test";
    my $d = test_setup_compute();
    $d->clear();
    ( ! $d->string() ) || return 0;
    test_atom_end();

    return 1;
}

###########################################################################

sub test_string
{ 
    test_title("string => length");

    test_atom_begin("string - length");
    my $d = test_setup_compute();
    my $r = $d->string();
    ( length($r) > 0 ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

sub test_print 
{ 
    test_title("print => length");

    test_atom_begin("print - length");
    my $d = test_setup_compute();
    my $r = $d->print();
    ( $r > 0 ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

sub test_save 
{
    test_title("save => contents");

    test_atom_begin("save - begin");
    my $s = "t/temp/s";
    my $d = test_setup_compute();
    my $r = $d->save($s);
    ( $r > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("save - contents");
    my $sc = "";
    ( open FILE, "<$s" ) || return 0;
    while(<FILE>) { $sc .= $_; }
    ( close FILE ) || return 0;
    ( length($sc) > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("save - end");
    ( unlink $s ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

sub test_load 
{ 
    test_title("load => contents");

    test_atom_begin("load - begin");
    my $s = "t/temp/s";
    my $d1 = test_setup_save();
    my $d2 = test_setup();
    my $r2 = $d2->load($s);
    ( $r2 > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("load - verify");
    my %s1 = $d1->statistics(); my %s2 = $d2->statistics();
    ( $s1{'digests'} == $s2{'digests'} ) || return 0;
    ( $d1->summary() eq $d2->summary() ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

sub test_fetch 
{ 
    test_title("fetch => contents");

    test_atom_begin("fetch - begin");
    my $s = "t/temp/s";
    my $d1 = test_setup_save();
    my $d2 = test_setup();
    my $r2 = $d2->fetch("file:" . $s, "nouser", "nopass");
    ( $r2 > 0 ) || return 0;
    test_atom_end();

    test_atom_begin("fetch - verify");
    my %s1 = $d1->statistics(); my %s2 = $d2->statistics();
    ( $s1{'digests'} == $s2{'digests'} ) || return 0;
    ( $d1->summary() eq $d2->summary() ) || return 0;
    test_atom_end();

    return 1; 
}

###########################################################################

sub test_compare 
{ 
    test_title("compare => added,modified,removed");

    test_atom_begin("compare - begin");
    my $x = "t/test/x";
    my $d1 = test_setup_compute();
    ( open FILE, ">$x" ) || return 0;
    ( print FILE "file x\n" ) || return 0; 
    ( close FILE ) || return 0;
    my $d2 = test_setup_compute();
    test_atom_end();

    test_atom_begin("compare - file added");
    my $r1 = $d1->compare($d2, 1, 1, 0);
    ( $r1 == 0 ) || return 0;
       $r1 = $d1->compare($d2, 0, 1, 0);
    ( $r1 == 1 ) || return 0;
       $r1 = $d1->compare($d2, 0, 0, 0);
    ( $r1 == 2 ) || return 0;
    test_atom_end();

    test_atom_begin("compare - file removed");
    my $r2 = $d2->compare($d1, 1, 1, 0);
    ( $r2 == 0 ) || return 0;
       $r2 = $d2->compare($d1, 0, 1, 0);
    ( $r2 == 1 ) || return 0;
       $r2 = $d2->compare($d1, 0, 0, 0);    
    ( $r2 == 2 ) || return 0;
    test_atom_end();

    test_atom_begin("compare - file modified");
    open FILE, ">$x"; print FILE "file x (v2)\n"; close FILE;
    my $d3 = test_setup_compute();  
    my $r3 = $d3->compare($d2, 1, 1, 0);
    ( $r3 == 0 ) || return 0;
       $r3 = $d3->compare($d2, 0, 1, 0);
    ( $r3 == 1 ) || return 0;
       $r3 = $d3->compare($d2, 0, 0, 0);    
    ( $r3 == 2 ) || return 0;
    test_atom_end();

    test_atom_begin("compare - end");
    ( unlink $x ) || return 0;
    test_atom_end();

    return 1;   
}

###########################################################################

1;
