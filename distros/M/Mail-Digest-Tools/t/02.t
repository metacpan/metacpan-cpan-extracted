# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01.t'

# 02.t	# revised 06/07/2004

END {print "not ok 1\n" unless $loaded;}
use Test::Simple tests =>
68;
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
# see t.01

my (%pbml_config_in, %pbml_config_out);

my @intersect;
my ($k,$v);
while ( ($k, $v) = each %{$digest_structure{'pbml'}} ) {
    $pbml_config_in{$k} = $v;
}
while ( ($k, $v) = each %{$digest_output_format{'pbml'}} ) {
    $pbml_config_out{$k} = $v;
}

my ($digs, %log);
my ($pbml_digdir, $pbml_thrdir); 
$pbml_digdir = "$pbml_config_out{'dir_digest'}";
$pbml_thrdir = "$pbml_config_out{'dir_threads'}";
 
########## Test of process_new_digests() on pbml ###########

# predict names and number of threads files to be created
# (by observation)

my (@pbml_tp);
if ($unix{$^O}) {     # 3/11/2004 revision
    @pbml_tp = sort {lc($a) cmp lc($b)} (
        'grep over multiple lines.thr.txt',
        'How to $printHeader = \\&$fext::printHeader;.thr.txt',
        'HOW TO DO This.thr.txt',
        'how to get the current working directory.thr.txt',
        'newbie -> pattern matching.thr.txt',
        'One way to: $printHeader = \\&$fext::printHeader;.thr.txt',
        'Returning 2 file handles?.thr.txt',
        'Young and inexperienced.thr.txt',
    );
} elsif ($^O eq 'MSWin32') {
    @pbml_tp = sort {lc($a) cmp lc($b)} (
        'grep over multiple lines.thr.txt',
        'How to $printHeader = &$fextprintHeader;.thr.txt',
        'HOW TO DO This.thr.txt',
        'how to get the current working directory.thr.txt',
        'newbie - pattern matching.thr.txt',
        'One way to $printHeader = &$fextprintHeader;.thr.txt',
        'Returning 2 file handles.thr.txt',
        'Young and inexperienced.thr.txt',
    );
} else {
    die "Mail::Digest::Tools not available for operating system $^O: $!";
}

ok(@pbml_tp == 8, 'Predict 8 threads from pbml');# 2

# 0th element in value:  by observation, predict number of messages in 
# each thread file created
# 1st element in value:  by observation, predict number of paragraphs in each 
# message in each thread file created

my %pbml_tp = (
    $pbml_tp[0] => [ 3, [ 7, 9, 3 ] ],
    $pbml_tp[1] => [ 1, [ 7 ] ],
    $pbml_tp[2] => [ 4, [ 3, 4, 2, 18 ] ],
    $pbml_tp[3] => [ 2, [ 3, 6 ] ],
    $pbml_tp[4] => [ 3, [ 6, 5, 4 ] ],
    $pbml_tp[5] => [ 4, [ 5, 15, 5, 8 ] ],
    $pbml_tp[6] => [ 6, [ 3, 12, 5, 8, 4, 3 ] ],
    $pbml_tp[7] => [ 3, [ 5, 2, 2 ] ],
);

# predict message numbers found within each thread file created
# (by observation)

my %pbml_messp = ( 
    $pbml_tp[0] => [ qw|
      00001_0009
      00001_0010
      00001_0011
        | ],
    $pbml_tp[1] => [ qw|
      00001_0001
        | ],
    $pbml_tp[2] => [ qw|
      00002_0005
      00002_0006
      00002_0008
      00003_0004
        | ],
    $pbml_tp[3] => [ qw|
      00002_0007
      00003_0001
        | ],
    $pbml_tp[4] => [ qw|
      00002_0001
      00002_0002
      00002_0003
        | ],
    $pbml_tp[5] => [ qw|
      00001_0002
      00001_0003
      00001_0004
      00001_0006
        | ],
    $pbml_tp[6] => [ qw|
      00001_0005
      00001_0007
      00001_0008
      00002_0004
      00003_0002
      00003_0007
        | ],
    $pbml_tp[7] => [ qw|
      00003_0003
      00003_0005
      00003_0006
        | ],
);
# determine number of digests needing processing

opendir DIG, $pbml_digdir or die "Couldn't open directory $pbml_digdir: $!";
$log{'digs'} = scalar(
    grep { /$pbml_config_in{'grep_formula'}/ } readdir DIG);
closedir DIG or die "Couldn't close directory $pbml_digdir: $!";
ok($log{'digs'} == 3, '3 pbml digests found before processing'); # 3

# verify log files are empty or do not yet exist

my $dl  = $pbml_config_out{'digests_log'};
my $dr  = $pbml_config_out{'digests_read'};
my $drf = $pbml_config_out{'digests_read_flag'};
my $tt  = $pbml_config_out{'todays_topics'};

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

process_new_digests(\%pbml_config_in, \%pbml_config_out);

# test whether log files have grown in size

$log{'log'}{'size'}[1]    = (-s $dl);
$log{'read'}{'size'}[1]   = ( (-f $dr) and $drf) ? (-s $dr) : undef;
$log{'topics'}{'size'}[1] = (-s $tt);

ok($log{'log'}{'size'}[1] > $log{'log'}{'size'}[0], # 7
    'digests_log for pbml has grown');
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
   ), 'digests_read for pbml has grown'
);
ok($log{'topics'}{'size'}[1] > $log{'topics'}{'size'}[0],# 9
    'todays_topics for pbml has grown');

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
 
chdir $pbml_thrdir or die "Couldn't change to pbml threads dir: $!";
opendir DIR, $pbml_thrdir or die "Couldn't open dir: $!";
my @pbml_tc = sort {lc($a) cmp lc($b)} grep {/\.thr\.txt$/} readdir DIR;
closedir DIR or die "Couldn't close dir: $!";

ok(@pbml_tc == 8, '8 threads created from pbml');# 13

# test whether thread files have names predicted

ok($pbml_tp[0] eq $pbml_tc[0], 'grep over multiple lines.thr.txt');# 14
ok($pbml_tp[1] eq $pbml_tc[1], 'How to $printHeader = \\&$fext::printHeader;.thr.txt');# 15
ok($pbml_tp[2] eq $pbml_tc[2], 'HOW TO DO This.thr.txt');# 16
ok($pbml_tp[3] eq $pbml_tc[3], 'how to get the current working directory.thr.txt');# 17
ok($pbml_tp[4] eq $pbml_tc[4], 'newbie -> pattern matching.thr.txt');# 18
ok($pbml_tp[5] eq $pbml_tc[5], 'One way to: $printHeader = \\&$fext::printHeader;.thr.txt');# 19
ok($pbml_tp[6] eq $pbml_tc[6], 'Returning 2 file handles?.thr.txt');# 20
ok($pbml_tp[7] eq $pbml_tc[7], 'Young and inexperienced.thr.txt');# 21


@intersect = get_intersection(\@pbml_tp, \@pbml_tc);
ok(@intersect == @pbml_tp,              # 22
    'all pbml threads predicted have been created');

# test whether thread files have predicted message count
my $tmd = $pbml_config_out{'thread_msg_delimiter'};
ok(${$pbml_tp{$pbml_tp[0]}}[0] == verify_message_count(# 23
              $pbml_tc[0], $tmd));
ok(${$pbml_tp{$pbml_tp[1]}}[0] == verify_message_count(# 24
              $pbml_tc[1], $tmd));
ok(${$pbml_tp{$pbml_tp[2]}}[0] == verify_message_count(# 25
              $pbml_tc[2], $tmd));
ok(${$pbml_tp{$pbml_tp[3]}}[0] == verify_message_count(# 26
              $pbml_tc[3], $tmd));
ok(${$pbml_tp{$pbml_tp[4]}}[0] == verify_message_count(# 27
              $pbml_tc[4], $tmd));
ok(${$pbml_tp{$pbml_tp[5]}}[0] == verify_message_count(# 28
              $pbml_tc[5], $tmd));
ok(${$pbml_tp{$pbml_tp[6]}}[0] == verify_message_count(# 29
              $pbml_tc[6], $tmd));
ok(${$pbml_tp{$pbml_tp[7]}}[0] == verify_message_count(# 30
              $pbml_tc[7], $tmd));

# test whether messages in thread files are correct and appear in 
# predicted sequence

ok( compare_arrays(\@{$pbml_messp{$pbml_tp[0]}}, # 31
      get_message_numbers_created($pbml_tc[0], $tmd) ) );
ok( compare_arrays(\@{$pbml_messp{$pbml_tp[1]}}, # 32
      get_message_numbers_created($pbml_tc[1], $tmd) ) );
ok( compare_arrays(\@{$pbml_messp{$pbml_tp[2]}}, # 33
      get_message_numbers_created($pbml_tc[2], $tmd) ) );
ok( compare_arrays(\@{$pbml_messp{$pbml_tp[3]}}, # 34
      get_message_numbers_created($pbml_tc[3], $tmd) ) );
ok( compare_arrays(\@{$pbml_messp{$pbml_tp[4]}}, # 35
      get_message_numbers_created($pbml_tc[4], $tmd) ) );
ok( compare_arrays(\@{$pbml_messp{$pbml_tp[5]}}, # 36
      get_message_numbers_created($pbml_tc[5], $tmd) ) );
ok( compare_arrays(\@{$pbml_messp{$pbml_tp[6]}}, # 37
      get_message_numbers_created($pbml_tc[6], $tmd) ) );
ok( compare_arrays(\@{$pbml_messp{$pbml_tp[7]}}, # 38
      get_message_numbers_created($pbml_tc[7], $tmd) ) );

# test whether messages in thread files have predicted number of paragraphs

ok( compare_arrays(${$pbml_tp{$pbml_tp[0]}}[1], # 39
          get_paragraph_count($pbml_tp[0], $tmd) ) );
ok( compare_arrays(${$pbml_tp{$pbml_tp[1]}}[1], # 40
          get_paragraph_count($pbml_tp[1], $tmd) ) );
ok( compare_arrays(${$pbml_tp{$pbml_tp[2]}}[1], # 41
          get_paragraph_count($pbml_tp[2], $tmd) ) );
ok( compare_arrays(${$pbml_tp{$pbml_tp[3]}}[1], # 42
          get_paragraph_count($pbml_tp[3], $tmd) ) );
ok( compare_arrays(${$pbml_tp{$pbml_tp[4]}}[1], # 43
          get_paragraph_count($pbml_tp[4], $tmd) ) );
ok( compare_arrays(${$pbml_tp{$pbml_tp[5]}}[1], # 44
          get_paragraph_count($pbml_tp[5], $tmd) ) );
ok( compare_arrays(${$pbml_tp{$pbml_tp[6]}}[1], # 45
          get_paragraph_count($pbml_tp[6], $tmd) ) );
ok( compare_arrays(${$pbml_tp{$pbml_tp[7]}}[1], # 46
          get_paragraph_count($pbml_tp[7], $tmd) ) );

chdir $startdir or die "Couldn't change back to $startdir: $!";

# run Mail::Digest::Tools function reply_to_digest_message()

my $digest_number = 3;
my $digest_entry = 3;
my $directory_for_reply = "$startdir/t/samples/pbml/Threads";

my $full_reply_file = reply_to_digest_message(
    \%pbml_config_in, 
    \%pbml_config_out, 
    $digest_number, 
    $digest_entry, 
    $directory_for_reply,
);

# make sure appropriately named reply file was created and that it has the 
# correct number of paragraphs

my $rtsf = defined $pbml_config_in{'reply_to_style_flag'} ? 1 : 0;
my $reply_file_predicted = "$directory_for_reply/Young and inexperienced.reply.txt";
my $total_paragraphs_predicted = 3 + $rtsf;
my $text_paragraphs_replied_to_predicted = 4;
ok(-f $reply_file_predicted);           # 47
ok($total_paragraphs_predicted ==       # 48
    get_paragraph_count_reply($reply_file_predicted) );
ok($text_paragraphs_replied_to_predicted == # 49
    get_paragraphs_replied_to_count($reply_file_predicted, $rtsf) );

#######################################################################
# below:  tests of repair_message_order()

# problem for testing:  repair_message_order() overwrites its files
# so I'll have to store the wrongly-ordered files somewhere, make predictions 
# as to the outcome, then move the files into the directory where the function 
# will actually be called
# then, examine those new files to see if they match the predictions

my ($need_fix_dir, @need_fix_files, $dir_threads_orig, $repair_dir);
my (@pbml_fp, %pbml_fp, %pbml_fmessp);
my (@pbml_fc);

$need_fix_dir = "$startdir/t/needfix/pbml";
chdir $need_fix_dir or die "Couldn't change to $need_fix_dir: $!";
opendir DIR, $need_fix_dir or die "Couldn't open $need_fix_dir: $!";
@need_fix_files = grep {/\.fix\.thr\.txt$/} readdir DIR;
closedir DIR or die "Couldn't close $need_fix_dir: $!";
foreach my $nff (@need_fix_files) {
    copy $nff, "$startdir/t/repair/pbml/$nff" or die "Couldn't copy fix file: $!";
}
chdir $startdir or die "Couldn't change back to $startdir: $!";
$dir_threads_orig = $pbml_config_out{'dir_threads'};
$pbml_config_out{'dir_threads'} = "$startdir/t/repair/pbml";

@pbml_fp = ( qw|
    grep_over_multiple_lines.fix.thr.txt
    Young_and_inexperienced.fix.thr.txt
|);

%pbml_fp = (
    $pbml_fp[0] => [ 3, [ 7, 9, 3 ] ],
    $pbml_fp[1] => [ 3, [ 5, 2, 2 ] ],
);

%pbml_fmessp = (
    $pbml_fp[0] => [ qw|
      00001_0009
      00001_0010
      00001_0011
        | ],
    $pbml_fp[1] => [ qw|
      00003_0003
      00003_0005
      00003_0006
        | ], 
);

# run Mail::Digest::Tools function repair_message_order()

repair_message_order (
    \%pbml_config_in, 
    \%pbml_config_out,
    { year => 2000, month => 01, day => 01 },
);
 
# test whether correct number of threads files have been fixed

$repair_dir = "$startdir/t/repair/pbml";
 
chdir $repair_dir or die "Couldn't change to pbml threads dir: $!";
opendir DIR, $repair_dir or die "Couldn't open dir: $!";
@pbml_fc = sort {lc($a) cmp lc($b)} grep {/\.fix\.thr\.txt$/} readdir DIR;
closedir DIR or die "Couldn't close dir: $!";

# ok(@pbml_fc == 8, '8 threads fixed from pbml');
ok(@pbml_fc == 2, '2 threads fixed from pbml');# 50

# test whether fixed files have names predicted

ok($pbml_fp[0] eq $pbml_fc[0], 'grep_over_multiple_lines.fix.thr.txt');# 51
ok($pbml_fp[1] eq $pbml_fc[1], 'Young_and_inexperienced.fix.thr.txt');# 52
@intersect = get_intersection(\@pbml_fp, \@pbml_fc);
ok(@intersect == @pbml_fp,              # 53
    'all pbml fixed threads predicted have been created');

# test whether thread files have predicted message count
ok(${$pbml_fp{$pbml_fp[0]}}[0] == verify_message_count(# 54
              $pbml_fc[0], $tmd));
ok(${$pbml_fp{$pbml_fp[1]}}[0] == verify_message_count(# 55
              $pbml_fc[1], $tmd));

# test whether messages in thread files are correct and appear in 
# predicted sequence

ok( compare_arrays(\@{$pbml_fmessp{$pbml_fp[0]}}, # 56
      get_message_numbers_created($pbml_fc[0], $tmd) ) );
ok( compare_arrays(\@{$pbml_fmessp{$pbml_fp[1]}}, # 57
      get_message_numbers_created($pbml_fc[1], $tmd) ) );

# test whether messages in thread files have predicted number of paragraphs

ok( compare_arrays(${$pbml_fp{$pbml_fp[0]}}[1], # 58
          get_paragraph_count($pbml_fp[0], $tmd) ) );
ok( compare_arrays(${$pbml_fp{$pbml_fp[1]}}[1], # 59
          get_paragraph_count($pbml_fp[1], $tmd) ) );

chdir $startdir or die "Couldn't change back to $startdir: $!";

#######################################################################
# below:  tests of consolidate_threads_single()

my ($consol_in_dir, $consol_out_dir, @consol_test, $consol_predict, 
    @consol_tp, @consol_messp, @consol_tc, @consol_messc);

$consol_in_dir  = "$startdir/t/consol/in/pbml";
$consol_out_dir = "$startdir/t/consol/out/pbml";
$pbml_config_out{'dir_threads'} = $consol_out_dir;
@consol_test = (
        'grep_over_multiple_lines.thr.txt',
        'grep_over_multiple_lines_thank_you.thr.txt',
);

$consol_predict = 'grep_over_multiple_lines.thr.txt';

chdir $consol_in_dir or die "Couldn't change to $consol_in_dir: $!";
foreach my $orig (@consol_test) {
	copy $orig, "$consol_out_dir/$orig"
		or die "Could not copy $orig for test of consolidation: $!";
}

@consol_tp    = ( 3, [ 7, 9, 3 ] );
@consol_messp = ( qw|
      00001_0009
      00001_0010
      00001_0011
|);

# run Mail::Digest::Tools function consolidate_threads_single()

consolidate_threads_single(
	\%pbml_config_in,
	\%pbml_config_out,
	\@consol_test
);

chdir $consol_out_dir or die "Couldn't change to pbml threads dir: $!";
opendir DIR, $consol_out_dir or die "Couldn't open dir: $!";
@consol_tc = sort {lc($a) cmp lc($b)} grep {/\.thr\.txt$/} readdir DIR;
closedir DIR or die "Couldn't close dir: $!";

# test whether correct number of threads files have been fixed

ok(@consol_tc == 1, '1 thread consolidated from pbml');# 60

# test whether consolidated file has been correctly named

ok($consol_predict eq $consol_tc[0], 'grep over multiple lines.thr.txt');# 61

# test whether consolidated file has predicted message count

ok($consol_tp[0] == verify_message_count(# 62
              $consol_tc[0], $tmd));

# test whether messages in consolidated file have predicted number of paragraphs

ok( compare_arrays($consol_tp[1],       # 63
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

ok(@del_predicted == @del_created, 'correct number of deletables');# 64
ok(@del_created == 2, 'correct number of deletables');# 65

# test whether deletable files were correctly named

ok($del_predicted[0] eq $del_created[0]);# 66
ok($del_predicted[1] eq $del_created[1]);# 67

# run Mail::Digest::Tools function delete_deletables()

delete_deletables(\%pbml_config_out);

# verify that deletables have been deleted

opendir DIR, $consol_out_dir or die "Couldn't open dir: $!";
@del_verified = grep {/\.DELETABLE$/} readdir DIR;
closedir DIR or die "Couldn't close dir: $!";

ok(@del_verified == 0, 'no deletable files left');# 68

######################################################################
# restore original conditions

chdir $startdir or die "Couldn't change back to $startdir: $!";
$pbml_config_out{'dir_threads'} = $dir_threads_orig;

