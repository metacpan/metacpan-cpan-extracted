# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01.t'

# 03.t

END {print "not ok 1\n" unless $loaded;}
use Test::Simple tests =>
48;
use lib ("./t");
use Mail::Digest::Tools qw(:all); 
use Test::_Test_MDT;
use File::Copy;
use Cwd;
my $startdir = cwd(); # startdir is dir where Makefile.PL is located

$loaded = 1;
ok($loaded);                            # 1

use strict;
use warnings;

our (%digest_structure, %digest_output_format);
# variables imported from $data_file
our %unix = map {$_, 1} 
    qw| Unix linux darwin freebsd netbsd openbsd mirbsd cygwin solaris |;

my $data_file = 'samples/digest.data';
require $data_file;

# test of digests.data info and existence of key directories
# see 01.t

my (%pw32u_config_in, %pw32u_config_out);

my @intersect;
my ($k,$v);
while ( ($k, $v) = each %{$digest_structure{'pw32u'}} ) {
    $pw32u_config_in{$k} = $v;
}
while ( ($k, $v) = each %{$digest_output_format{'pw32u'}} ) {
    $pw32u_config_out{$k} = $v;
}

my ($digs, %log);
my ($pw32u_digdir, $pw32u_thrdir);
$pw32u_digdir = "$pw32u_config_out{'dir_digest'}";
$pw32u_thrdir = "$pw32u_config_out{'dir_threads'}";
  
########## Test of process_new_digests() on pw32u ##########

# predict names and number of threads files to be created
# (by observation)

my (@pw32u_tp);
if ($unix{$^O}) {     # 3/11/2004 revision
    @pw32u_tp = sort {lc($a) cmp lc($b)} (
        'Net::SSH::Perl.thr.txt',
        'Perl and delphi interaction query.thr.txt',
        'qx broken on Win98.thr.txt',
    );
} elsif ($^O eq 'MSWin32') {
    @pw32u_tp = sort {lc($a) cmp lc($b)} (
        'NetSSHPerl.thr.txt',
        'Perl and delphi interaction query.thr.txt',
        'qx broken on Win98.thr.txt',
    );
} else {
    die "Mail::Digest::Tools not available for operating system $^O: $!";
}

ok(@pw32u_tp == 3, 'Predict 3 threads from pw32u');# 2

# 0th element in value:  by observation, predict number of messages in 
# each thread file created
# 1st element in value:  by observation, predict number of paragraphs in each 
# message in each thread file created

my %pw32u_tp = (
    $pw32u_tp[0] => [ 7, [ 10, 6, 5, 6, 6, 4, 10 ] ],
    $pw32u_tp[1] => [ 4, [ 12, 6, 6, 6 ] ],
    $pw32u_tp[2] => [ 6, [  8, 6, 5, 6, 8, 8 ] ],
);

# predict message numbers found within each thread file created
# (by observation)

my %pw32u_messp = ( 
    $pw32u_tp[0] => [ qw|
      001_0001_0001
      001_0002_0001
      001_0002_0003
      001_0002_0004
      001_0002_0005
      001_0002_0006
      001_0002_0013
        | ],
    $pw32u_tp[1] => [ qw|
      001_0001_0002
      001_0001_0003
      001_0002_0002
      001_0002_0014
        | ],
    $pw32u_tp[2] => [ qw|
      001_0002_0007
      001_0002_0008
      001_0002_0009
      001_0002_0010
      001_0002_0011
      001_0002_0012
        | ],
);
# determine number of digests needing processing

opendir DIG, $pw32u_digdir or die "Couldn't open directory $pw32u_digdir: $!";
$log{'digs'} = scalar(
    grep { /$pw32u_config_in{'grep_formula'}/ } readdir DIG);
closedir DIG or die "Couldn't close directory $pw32u_digdir: $!";
ok($log{'digs'} == 2, '2 pw32u digests found before processing'); # 3

# verify log files are empty or do not yet exist

my $dl  = $pw32u_config_out{'digests_log'};
my $dr  = $pw32u_config_out{'digests_read'};
my $drf = $pw32u_config_out{'digests_read_flag'};
my $tt  = $pw32u_config_out{'todays_topics'};

$log{'log'}{'size'}[0]    = (-f $dl) ? (-s $dl) : 0;
$log{'read'}{'size'}[0]   = ( (-f $dr) and $drf) ? (-s $dr) : undef;
$log{'topics'}{'size'}[0] = (-f $tt) ? (-s $tt) : 0;

$log{'log'}{'records'}[0]    = (-f $dl) ? count_records($dl, "\n") : 0;
$log{'read'}{'records'}[0]   = ((-f $dr) and $drf) ? count_records($dr, "\n\n") : 0;
$log{'topics'}{'records'}[0] = (-f $tt) ? count_records($tt, "\n\n") : 0;

ok($log{'log'}{'records'}[0]    == 0, 'digests_log currently empty'); # 4
ok($log{'read'}{'records'}[0]   == 0, 'digests_read currently empty'); # 5
ok($log{'topics'}{'records'}[0] == 0, 'todays_topics currently empty'); # 6

# run Mail::Digest::tools function

process_new_digests(\%pw32u_config_in, \%pw32u_config_out);

# test whether log files have grown in size

$log{'log'}{'size'}[1]    = (-s $dl);
$log{'read'}{'size'}[1]   = ( (-f $dr) and $drf) ? (-s $dr) : undef;
$log{'topics'}{'size'}[1] = (-s $tt);

ok($log{'log'}{'size'}[1] > $log{'log'}{'size'}[0]);# 7
ok(                                     # 8
   ( 
    (
     ! defined $log{'read'}{'size'}[0] 
     and 
     ! defined $log{'read'}{'size'}[1]
    )
    or
    ( 
     (
      defined $log{'read'}{'size'}[0] 
      and 
      defined $log{'read'}{'size'}[1]
     )
     and
     (
      $log{'read'}{'size'}[1] > $log{'read'}{'size'}[0]
     )
    )
   ), 'digests read for pw32u has grown'
);
ok($log{'topics'}{'size'}[1] > $log{'topics'}{'size'}[0],# 9
    'todays topics for pw32u has grown');
 
# test whether log files have grown by correct number of records

$log{'log'}{'records'}[1]    = (-f $dl) ? count_records($dl, "\n") : 0;
$log{'read'}{'records'}[1]   = ((-f $dr) and $drf) ? count_records($dr, "\n\n") : 0;
$log{'topics'}{'records'}[1] = (-f $tt) ? count_records($tt, "\n\n") : 0;

ok($log{'log'}{'records'}[0] + $log{'digs'} == # 10
    $log{'log'}{'records'}[1], 
    'digests_log grew by predicted number of records');
ok(                                     # 11
   ( 
    (
     ! defined $log{'read'}{'size'}[0] 
     and 
     ! defined $log{'read'}{'size'}[1]
    )
    or
    ( 
     (
      defined $log{'read'}{'size'}[0] 
      and 
      defined $log{'read'}{'size'}[1]
     )
     and
     (
      $log{'read'}{'records'}[0] + $log{'digs'} + 1 == 
      $log{'read'}{'records'}[1]
     )
    )
   ), 'digests_read grew by predicted number of records'
);
ok($log{'topics'}{'records'}[0] + $log{'digs'} == # 12
    $log{'topics'}{'records'}[1], 
    'todays_topics grew by predicted number of records');

# test whether correct number of threads files have been created
 
chdir $pw32u_thrdir or die "Couldn't change to pw32u threads dir: $!";
opendir DIR, $pw32u_thrdir or die "Couldn't open dir: $!";
my @pw32u_tc = sort {lc($a) cmp lc($b)} grep {/\.thr\.txt$/} readdir DIR;
closedir DIR or die "Couldn't close dir: $!";

ok(@pw32u_tc == 3, '3 threads created from pw32u');# 13

# test whether thread files have names predicted

ok($pw32u_tp[0] eq $pw32u_tc[0], 'Net::SSH::Perl.thr.txt');# 14
ok($pw32u_tp[1] eq $pw32u_tc[1], 'Perl and delphi interaction query.thr.txt');# 15
ok($pw32u_tp[2] eq $pw32u_tc[2], 'qx broken on Win98.thr.txt');# 16

#my $lcpw = List::Compare->new(\@pw32u_tp, \@pw32u_tc);
#ok( ($lcpw->get_intersection()) == @pw32u_tp, 
#    'all pw32u threads predicted have been created');
@intersect = get_intersection(\@pw32u_tp, \@pw32u_tc);
ok(@intersect == @pw32u_tp,             # 17
    'all pw32u threads predicted have been created');

# test whether thread files have predicted message count
my $tmd = $pw32u_config_out{'thread_msg_delimiter'};
ok(${$pw32u_tp{$pw32u_tp[0]}}[0] == verify_message_count(# 18
               $pw32u_tc[0], $tmd));
ok(${$pw32u_tp{$pw32u_tp[1]}}[0] == verify_message_count(# 19
               $pw32u_tc[1], $tmd));
ok(${$pw32u_tp{$pw32u_tp[2]}}[0] == verify_message_count(# 20
               $pw32u_tc[2], $tmd));

# test whether messages in thread files are correct and appear in 
# predicted sequence

ok( compare_arrays(\@{$pw32u_messp{$pw32u_tp[0]}}, # 21
       get_message_numbers_created($pw32u_tc[0], $tmd) ) );
ok( compare_arrays(\@{$pw32u_messp{$pw32u_tp[1]}}, # 22
       get_message_numbers_created($pw32u_tc[1], $tmd) ) );
ok( compare_arrays(\@{$pw32u_messp{$pw32u_tp[2]}}, # 23
       get_message_numbers_created($pw32u_tc[2], $tmd) ) );

# test whether messages in thread files have predicted number of paragraphs

ok( compare_arrays(${$pw32u_tp{$pw32u_tp[0]}}[1], # 24
           get_paragraph_count($pw32u_tp[0], $tmd) ) );
ok( compare_arrays(${$pw32u_tp{$pw32u_tp[1]}}[1], # 25
           get_paragraph_count($pw32u_tp[1], $tmd) ) );
ok( compare_arrays(${$pw32u_tp{$pw32u_tp[2]}}[1], # 26
           get_paragraph_count($pw32u_tp[2], $tmd) ) );

chdir $startdir or die "Couldn't change back to $startdir: $!";

# run Mail::Digest::tools function reply_to_digest_message()

my $digest_number = 2;
my $digest_entry = 14;
my $directory_for_reply = "$startdir/t/samples/pw32u/Threads";

my $full_reply_file = reply_to_digest_message(
    \%pw32u_config_in, 
    \%pw32u_config_out, 
    $digest_number, 
    $digest_entry, 
    $directory_for_reply,
);

# make sure appropriately named reply file was created and that it has the 
# correct number of paragraphs

my $rtsf = defined $pw32u_config_in{'reply_to_style_flag'} ? 1 : 0;
my $reply_file_predicted = 
    "$directory_for_reply/Perl and delphi interaction query.reply.txt";
my $total_paragraphs_predicted = 3 + $rtsf;
my $text_paragraphs_replied_to_predicted = 5;
ok(-f $reply_file_predicted);           # 27
ok($total_paragraphs_predicted ==       # 28
    get_paragraph_count_reply($reply_file_predicted) );
ok($text_paragraphs_replied_to_predicted == # 29
    get_paragraphs_replied_to_count($reply_file_predicted, $rtsf) );
 
#######################################################################
# below:  tests of repair_message_order()

# problem for testing:  repair_message_order() overwrites its files
# so I'll have to store the wrongly-ordered files somewhere, make predictions 
# as to the outcome, then move the files into the directory where the function 
# will actually be called
# then, examine those new files to see if they match the predictions

my ($need_fix_dir, @need_fix_files, $dir_threads_orig, $repair_dir);
my (@pw32u_fp, %pw32u_fp, %pw32u_fmessp);
my (@pw32u_fc);

$need_fix_dir = "$startdir/t/needfix/pw32u";
chdir $need_fix_dir or die "Couldn't change to $need_fix_dir: $!";
opendir DIR, $need_fix_dir or die "Couldn't open $need_fix_dir: $!";
@need_fix_files = grep {/\.fix\.thr\.txt$/} readdir DIR;
closedir DIR or die "Couldn't close $need_fix_dir: $!";
foreach my $nff (@need_fix_files) {
    copy $nff, "$startdir/t/repair/pw32u/$nff" or die "Couldn't copy fix file: $!";
}
chdir $startdir or die "Couldn't change back to $startdir: $!";
$dir_threads_orig = $pw32u_config_out{'dir_threads'};
$pw32u_config_out{'dir_threads'} = "$startdir/t/repair/pw32u";

@pw32u_fp = ( qw|
        Perl_and_delphi_interaction_query.fix.thr.txt
        qx_broken_on_Win98.fix.thr.txt
|);

%pw32u_fp = (
    $pw32u_fp[0] => [ 4, [ 12, 6, 6, 6 ] ],
    $pw32u_fp[1] => [ 6, [  8, 6, 5, 6, 8, 8 ] ],
);

%pw32u_fmessp = (
    $pw32u_fp[0] => [ qw|
      001_0001_0002
      001_0001_0003
      001_0002_0002
      001_0002_0014
        | ],
    $pw32u_fp[1] => [ qw|
      001_0002_0007
      001_0002_0008
      001_0002_0009
      001_0002_0010
      001_0002_0011
      001_0002_0012
        | ],
);

# run Mail::Digest::Tools function repair_message_order()

repair_message_order (
    \%pw32u_config_in, 
    \%pw32u_config_out,
    { year => 2000, month => 01, day => 01 },
);
 
# test whether correct number of threads files have been fixed

$repair_dir = "$startdir/t/repair/pw32u";
 
chdir $repair_dir or die "Couldn't change to pw32u threads dir: $!";
opendir DIR, $repair_dir or die "Couldn't open dir: $!";
@pw32u_fc = sort {lc($a) cmp lc($b)} grep {/\.fix\.thr\.txt$/} readdir DIR;
closedir DIR or die "Couldn't close dir: $!";

ok(@pw32u_fc == 2, '2 threads fixed from pw32u');# 30

# test whether fixed files have names predicted

ok($pw32u_fp[0] eq $pw32u_fc[0], 'Perl_and_delphi_interaction_query.thr.txt');# 31
ok($pw32u_fp[1] eq $pw32u_fc[1], 'qx_broken_on_Win98.fix.thr.txt');# 32


@intersect = get_intersection(\@pw32u_fp, \@pw32u_fc);
ok(@intersect == @pw32u_fp,             # 33
    'all pw32u fixed threads predicted have been created');

# test whether thread files have predicted message count
ok(${$pw32u_fp{$pw32u_fp[0]}}[0] == verify_message_count(# 34
               $pw32u_fc[0], $tmd));
ok(${$pw32u_fp{$pw32u_fp[1]}}[0] == verify_message_count(# 35
               $pw32u_fc[1], $tmd));

# test whether messages in thread files are correct and appear in 
# predicted sequence

ok( compare_arrays(\@{$pw32u_fmessp{$pw32u_fp[0]}}, # 36
      get_message_numbers_created($pw32u_fc[0], $tmd) ) );
ok( compare_arrays(\@{$pw32u_fmessp{$pw32u_fp[1]}}, # 37
      get_message_numbers_created($pw32u_fc[1], $tmd) ) );

# test whether messages in thread files have predicted number of paragraphs

ok( compare_arrays(${$pw32u_fp{$pw32u_fp[0]}}[1], # 38
          get_paragraph_count($pw32u_fp[0], $tmd) ) );
ok( compare_arrays(${$pw32u_fp{$pw32u_fp[1]}}[1], # 39
          get_paragraph_count($pw32u_fp[1], $tmd) ) );

chdir $startdir or die "Couldn't change back to $startdir: $!";

#######################################################################
# below:  tests of consolidate_threads_single()

my ($consol_in_dir, $consol_out_dir, @consol_test, $consol_predict, 
    @consol_tp, @consol_messp, @consol_tc, @consol_messc);

$consol_in_dir  = "$startdir/t/consol/in/pw32u";
$consol_out_dir = "$startdir/t/consol/out/pw32u";
$pw32u_config_out{'dir_threads'} = $consol_out_dir;
@consol_test = (
        'qx_broken_on_Win98.thr.txt',
        'qx_broken_on_Win98_second_thread.thr.txt',
);

$consol_predict = 'qx_broken_on_Win98.thr.txt';

chdir $consol_in_dir or die "Couldn't change to $consol_in_dir: $!";
foreach my $orig (@consol_test) {
	copy $orig, "$consol_out_dir/$orig"
		or die "Could not copy $orig for test of consolidation: $!";
}

@consol_tp = ( 6, [  8, 6, 5, 6, 8, 8 ] );
@consol_messp = ( qw|
      001_0002_0007
      001_0002_0008
      001_0002_0009
      001_0002_0010
      001_0002_0011
      001_0002_0012
|);

# run Mail::Digest::Tools function consolidate_threads_single()

consolidate_threads_single(
	\%pw32u_config_in,
	\%pw32u_config_out,
	\@consol_test
);

chdir $consol_out_dir or die "Couldn't change to pw32u threads dir: $!";
opendir DIR, $consol_out_dir or die "Couldn't open dir: $!";
@consol_tc = sort {lc($a) cmp lc($b)} grep {/\.thr\.txt$/} readdir DIR;
closedir DIR or die "Couldn't close dir: $!";

# test whether correct number of threads files have been fixed

ok(@consol_tc == 1, '1 thread consolidated from pw32u');# 40

# test whether consolidated file has been correctly named

ok($consol_predict eq $consol_tc[0], 'qx broken on Win98.thr.txt');# 41

# test whether consolidated file has predicted message count

ok($consol_tp[0] == verify_message_count(# 42
              $consol_tc[0], $tmd));

# test whether messages in consolidated file have predicted number of paragraphs

ok( compare_arrays($consol_tp[1],       # 43
          get_paragraph_count($consol_tc[0], $tmd) ) );

#######################################################################
# below:  tests of delete_deletables()

my (@del_predicted, @del_created, @del_verified); 
foreach my $orig (@consol_test) {
	push(@del_predicted, $orig . '.DELETABLE');
};
@del_predicted = sort {lc($a) cmp lc($b)} @del_predicted;

opendir DIR, $consol_out_dir or die "Couldn't open dir: $!";
@del_created = sort {lc($a) cmp lc($b)} 
               map {"$consol_out_dir/$_"} 
               grep {/\.thr\.txt\.DELETABLE$/} 
               readdir DIR;
closedir DIR or die "Couldn't close dir: $!";

# test whether correct number of deletable files were created

ok(@del_predicted == @del_created, 'correct number of deletables');# 44
ok(@del_created == 2, 'correct number of deletables');# 45

# test whether deletable files were correctly named

ok($del_predicted[0] eq $del_created[0]);# 46
ok($del_predicted[1] eq $del_created[1]);# 47

# run Mail::Digest::Tools function delete_deletables()

delete_deletables(\%pw32u_config_out);

# verify that deletables have been deleted

opendir DIR, $consol_out_dir or die "Couldn't open dir: $!";
@del_verified = grep {/\.DELETABLE$/} readdir DIR;
closedir DIR or die "Couldn't close dir: $!";

ok(@del_verified == 0, 'no deletable files left');# 48

######################################################################
# restore original conditions

chdir $startdir or die "Couldn't change back to $startdir: $!";
$pw32u_config_out{'dir_threads'} = $dir_threads_orig;


