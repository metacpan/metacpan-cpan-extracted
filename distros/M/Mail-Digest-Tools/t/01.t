# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01.t'

# 01.t does not test any Mail::Digest::Tools functions
# it only tests the entries in digest.data to make sure that the  
# directory structure needed for testing actually exists

END {print "not ok 1\n" unless $loaded;}
use Test::Simple tests =>
84;
use lib ("./t");
use Test::_Test_MDT;
# use Data::Dumper;
use Cwd;
my $startdir = cwd(); # startdir is dir where Makefile.PL is located

$loaded = 1;
ok($loaded);                            # 1

use strict;
use warnings;

# variables imported from $data_file
our (%digest_structure, %digest_output_format);

my $data_file = 'samples/digest.data';
require $data_file;

my ($archcount, $archref);  # used for Data::Dumper

# test of digests.data info

ok(exists $digest_structure{'pbml'});   # 2
ok(exists $digest_output_format{'pbml'});# 3
ok(exists $digest_structure{'pw32u'});  # 4
ok(exists $digest_output_format{'pw32u'});# 5

my (%pbml_config_in, %pbml_config_out);
my (%pw32u_config_in, %pw32u_config_out);
my (@need_emptying);
my @truncate_logs = ( qw|
    archived_today
    de_archived_today
    deleted_today
    digests_log
    digests_read
    todays_topics
    mimelog
|);


my ($k,$v);
while ( ($k, $v) = each %{$digest_structure{'pbml'}} ) {
    $pbml_config_in{$k} = $v;
}
while ( ($k, $v) = each %{$digest_output_format{'pbml'}} ) {
    $pbml_config_out{$k} = $v;
}
while ( ($k, $v) = each %{$digest_structure{'pw32u'}} ) {
    $pw32u_config_in{$k} = $v;
}
while ( ($k, $v) = each %{$digest_output_format{'pw32u'}} ) {
    $pw32u_config_out{$k} = $v;
}

ok(  defined $pbml_config_in{'grep_formula'});# 6
ok(  defined $pbml_config_in{'pattern_target'});# 7
ok(  defined $pbml_config_in{'topics_intro'});# 8
ok(  defined $pbml_config_in{'post_topics_delimiter'});# 9
ok(  defined $pbml_config_in{'source_msg_delimiter'});# 10
ok(  defined $pbml_config_in{'topics_intro'});# 11
ok(  defined $pbml_config_in{'message_style_flag'});# 12
ok(  defined $pbml_config_in{'from_style_flag'});# 13
ok(! defined $pbml_config_in{'org_style_flag'});# 14
ok(! defined $pbml_config_in{'to_style_flag'});# 15
ok(! defined $pbml_config_in{'cc_style_flag'});# 16
ok(  defined $pbml_config_in{'subject_style_flag'});# 17
ok(  defined $pbml_config_in{'date_style_flag'});# 18
ok(! defined $pbml_config_in{'reply_to_style_flag'});# 19
ok(  defined $pbml_config_in{'MIME_cleanup_flag'});# 20

ok(  defined $pbml_config_out{'title'});# 21
ok(  defined $pbml_config_out{'dir_digest'});# 22
ok(  defined $pbml_config_out{'dir_threads'});# 23
ok(  defined $pbml_config_out{'dir_archive_top'});# 24
ok(  defined $pbml_config_out{'archived_today'});# 25
ok(  defined $pbml_config_out{'de_archived_today'});# 26
ok(  defined $pbml_config_out{'deleted_today'});# 27
ok(  defined $pbml_config_out{'digests_log'});# 28
ok(  defined $pbml_config_out{'digests_read'});# 29
ok(  defined $pbml_config_out{'todays_topics'});# 30
ok(  defined $pbml_config_out{'mimelog'});# 31
ok(  defined $pbml_config_out{'id_format'});# 32
ok(  defined $pbml_config_out{'output_id_format'});# 33
ok(  defined $pbml_config_out{'MIME_cleanup_log_flag'});# 34
ok(  defined $pbml_config_out{'thread_msg_delimiter'});# 35
ok(  defined $pbml_config_out{'archive_kill_trigger'});# 36
ok(  defined $pbml_config_out{'archive_kill_days'});# 37
ok(  defined $pbml_config_out{'digests_read_flag'});# 38
ok(  defined $pbml_config_out{'archive_config'});# 39

ok(  defined $pw32u_config_in{'grep_formula'});# 40
ok(  defined $pw32u_config_in{'pattern_target'});# 41
ok(  defined $pw32u_config_in{'topics_intro'});# 42
ok(  defined $pw32u_config_in{'post_topics_delimiter'});# 43
ok(  defined $pw32u_config_in{'source_msg_delimiter'});# 44
ok(  defined $pw32u_config_in{'message_style_flag'});# 45
ok(  defined $pw32u_config_in{'from_style_flag'});# 46
ok(  defined $pw32u_config_in{'org_style_flag'});# 47
ok(  defined $pw32u_config_in{'to_style_flag'});# 48
ok(  defined $pw32u_config_in{'cc_style_flag'});# 49
ok(  defined $pw32u_config_in{'subject_style_flag'});# 50
ok(  defined $pw32u_config_in{'date_style_flag'});# 51
ok(  defined $pw32u_config_in{'reply_to_style_flag'});# 52
ok(  defined $pw32u_config_in{'MIME_cleanup_flag'});# 53

ok(  defined $pw32u_config_out{'title'});# 54
ok(  defined $pw32u_config_out{'dir_digest'});# 55
ok(  defined $pw32u_config_out{'dir_threads'});# 56
ok(  defined $pw32u_config_out{'dir_archive_top'});# 57
ok(  defined $pw32u_config_out{'archived_today'});# 58
ok(  defined $pw32u_config_out{'de_archived_today'});# 59
ok(  defined $pw32u_config_out{'deleted_today'});# 60
ok(  defined $pw32u_config_out{'digests_log'});# 61
ok(  defined $pw32u_config_out{'digests_read'});# 62
ok(  defined $pw32u_config_out{'todays_topics'});# 63
ok(  defined $pw32u_config_out{'mimelog'});# 64
ok(  defined $pw32u_config_out{'id_format'});# 65
ok(  defined $pw32u_config_out{'output_id_format'});# 66
ok(  defined $pw32u_config_out{'MIME_cleanup_log_flag'});# 67
ok(  defined $pw32u_config_out{'thread_msg_delimiter'});# 68
ok(  defined $pw32u_config_out{'archive_kill_trigger'});# 69
ok(  defined $pw32u_config_out{'archive_kill_days'});# 70
ok(  defined $pw32u_config_out{'digests_read_flag'});# 71
ok(  defined $pw32u_config_out{'archive_config'});# 72

# pbml:  analyze key directories; empty-out certain directories if they 
# already exist; create key directories if not already created
# truncate log files to 0

my ($pbml_digdir, $pbml_thrdir, $pbml_archtopdir); 
$pbml_digdir = "$pbml_config_out{'dir_digest'}";
$pbml_thrdir = "$pbml_config_out{'dir_threads'}";
$pbml_archtopdir = "$pbml_config_out{'dir_archive_top'}";

@need_emptying = (
    "$startdir/t/samples/pbml/Threads",
    "$startdir/t/repair/pbml",
    "$startdir/t/consol/out/pbml",
);
empty_as_needed(\@need_emptying);

truncate_as_needed(\%pbml_config_out, \@truncate_logs);

unless (-d $pbml_thrdir) {
    mkdir $pbml_thrdir or die "Unable to make threads directory:  $!";
}
unless (-d $pbml_archtopdir) {
    mkdir $pbml_archtopdir 
        or die "Unable to make top archive directory $pbml_archtopdir:  $!";
}
for ('a'..'z') {
    unless (-d "$pbml_archtopdir/$_") {
        mkdir "$pbml_archtopdir/$_" 
            or die "Unable to make archive subdirectory $_:  $!";
    }

}
unless (-d "$pbml_archtopdir/other") {
    mkdir "$pbml_archtopdir/other" 
        or die "Unable to make archive subdirectory other:  $!";
}
unless (-d "$startdir/t/consol/out") {
    mkdir "$startdir/t/consol/out"
        or die "Unable to make directory for consolidated files:  $!";
}
unless (-d "$startdir/t/consol/out/pbml") {
    mkdir "$startdir/t/consol/out/pbml"
        or die "Unable to make directory for consolidated files:  $!";
}
unless (-d "$startdir/t/repair") {
    mkdir "$startdir/t/repair"
        or die "Unable to make directory for repaired files:  $!";
}
unless (-d "$startdir/t/repair/pbml") {
    mkdir "$startdir/t/repair/pbml"
        or die "Unable to make directory for repaired files:  $!";
}

# pbml:  test for directory structure

ok(-d $pbml_digdir);                    # 73
ok(-d $pbml_thrdir);                    # 74
ok(-d $pbml_archtopdir);                # 75
ok(27 == test_archive_structure($pbml_archtopdir));# 76

ok(-d "$startdir/t/consol/out/pbml");   # 77
ok(-d "$startdir/t/repair/pbml");       # 78
 
# pw32u: analyze key directories; empty-out certain directories if they 
# already exist; create key directories if not already created
# truncate log files to 0

my ($pw32u_digdir, $pw32u_thrdir, $pw32u_archtopdir); 
$pw32u_digdir = "$pw32u_config_out{'dir_digest'}";
$pw32u_thrdir = "$pw32u_config_out{'dir_threads'}";
$pw32u_archtopdir = "$pw32u_config_out{'dir_archive_top'}";

@need_emptying = (
    "$startdir/t/samples/pw32u/Threads",
    "$startdir/t/repair/pw32u",
    "$startdir/t/consol/out/pw32u",
);
empty_as_needed(\@need_emptying);

truncate_as_needed(\%pw32u_config_out, \@truncate_logs);

unless (-d $pw32u_thrdir) {
    mkdir $pw32u_thrdir or die "Unable to make threads directory:  $!";
}
unless (-d $pw32u_archtopdir) {
    mkdir $pw32u_archtopdir 
        or die "Unable to make top archive directory $pw32u_archtopdir:  $!";
}
for ('a'..'z') {
    unless (-d "$pw32u_archtopdir/$_") {
        mkdir "$pw32u_archtopdir/$_" 
            or die "Unable to make archive subdirectory $_:  $!";
    }

}
unless (-d "$pw32u_archtopdir/other") {
    mkdir "$pw32u_archtopdir/other" 
        or die "Unable to make archive subdirectory other:  $!";
}
unless (-d "$startdir/t/consol/out/pw32u") {
    mkdir "$startdir/t/consol/out/pw32u"
        or die "Unable to make directory for consolidated files:  $!";
}
unless (-d "$startdir/t/repair/pw32u") {
    mkdir "$startdir/t/repair/pw32u"
        or die "Unable to make directory for repaired files:  $!";
}

# pw32u:  test for directory structure

ok(-d $pw32u_digdir);                   # 79
ok(-d $pw32u_thrdir);                   # 80
ok(-d $pw32u_archtopdir);               # 81
ok(27 == test_archive_structure($pw32u_archtopdir));# 82
ok(-d "$startdir/t/consol/out/pw32u");  # 83
ok(-d "$startdir/t/repair/pw32u");      # 84
 
