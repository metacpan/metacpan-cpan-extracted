#!/usr/bin/perl -w
#
# $Id: ecs_status.pl,v 1.39 2010/09/03 20:25:32 jschneid Exp $
#
##########################################################################
# SCRIPT NAME:   ecs_status.pl
# DESCRIPTION:   CGI script to display ECS status via web
# PARAMETERS:    optional you can start it with user=...
#                e.g. localhost/ecs/ecs_status.pl?user=emdistest.
#                additional, see $THIS_NODE, $NODE_TBL, and
#                $NODE_TBL_LOCK, below
# OUTPUT:        ECS status, in HTML format
#
# DATE WRITTEN:  2004-07-01
# WRITTEN BY:    Joel Schneider
#
# REVISION HISTORY:  please refer to CVS
#
# Copyright (C) 2004-2012 National Marrow Donor Program.
# All rights reserved.
##########################################################################

use CGI::Pretty;
use CGI::Carp 'fatalsToBrowser';
use Fcntl qw(:DEFAULT :flock);
use File::Basename qw(basename);
use File::Copy;
use File::Spec::Functions qw(catdir catfile);
use EMDIS::ECS::LockedHash;
use Env qw(ECS_BIN_DIR ECS_DAEMON_CHECK ECS_DAEMON_USER ECS_IMAGE_DIR
           ECS_STATUS_CELLBG ECS_STATUS_RED ECS_STATUS_YELLOW ECS_ALL_RED
           ECS_PAGE_HEADER NODE_TBL NODE_TBL_LOCK THIS_NODE TMPDIR);

use strict;
use vars qw($node_tbl $content
            $cvs_header $current_time $timenow $page_header);

my( $err, $daemons_status, $ecs_scan_mail_status, 
   $ecs_chk_com_status );
$err = '';

# use values from environment variables to compute configuration options
my $opt_ecs_bin_dir   = compute_opt($ECS_BIN_DIR, '/usr/bin');
my $opt_daemon_check  = compute_opt($ECS_DAEMON_CHECK, 'YES');
my $opt_user          = compute_opt($ECS_DAEMON_USER, '');
my $opt_image_dir     = compute_opt($ECS_IMAGE_DIR, '/ecs/images');
my $opt_status_cellbg = compute_opt($ECS_STATUS_CELLBG, 'NO');
my $opt_status_red    = compute_opt($ECS_STATUS_RED, 50);
my $opt_status_yellow = compute_opt($ECS_STATUS_YELLOW, 5);
my $opt_all_red       = compute_opt($ECS_ALL_RED, 60*60*4);
my $opt_page_header   = compute_opt($ECS_PAGE_HEADER, '');
my $opt_node_tbl      = compute_opt($NODE_TBL, '');
my $opt_node_tbl_lock = compute_opt($NODE_TBL_LOCK, '');
my $opt_this_node     = compute_opt($THIS_NODE, '');
my $opt_tmpdir        = compute_opt($TMPDIR, '.');

die "THIS_NODE not specified."
    unless $opt_this_node;
die "NODE_TBL not specified."
    unless $opt_node_tbl;
die "NODE_TBL_LOCK not specified."
    unless $opt_node_tbl_lock;

my $result=new CGI;

# "user" CGI parameter can override $opt_user setting
if( defined($result->param("user")) ){
   $opt_user = $result->param("user");
}

if($opt_daemon_check =~ /YES/i) { 
   if ( ! $opt_user ) {
      $daemons_status = qx{$opt_ecs_bin_dir/ecs_pid_chk 2>&1};
   }
   else {
      $daemons_status = qx{$opt_ecs_bin_dir/ecs_pid_chk --user=$opt_user 2>&1};
   }

   if ( $daemons_status =~ /ERROR:\s*ecs_chk_com/ ){
      $ecs_chk_com_status = 'red';
   }
   else {
      $ecs_chk_com_status = 'green';
   }
   if ( $daemons_status =~ /ERROR:\s*ecs_scan_mail/){
      $ecs_scan_mail_status = 'red';
   }
   else {
      $ecs_scan_mail_status = 'green';
   }
   if ( $? && $? != 255*256 ) {
      $err .= "DAEMON STATUS ERROR $?: $!\n";
   }
}

$cvs_header = '$Header: /usr/local/cvs/rposdir/codebase/emdis/ecs/src/nmdp/web_status/ecs_status.pl,v 1.39 2010/09/03 20:25:32 jschneid Exp $ ';
$current_time = time();
$timenow = format_datetime($current_time);
$node_tbl = node_tbl_snapshot($opt_node_tbl, $opt_node_tbl_lock, $opt_user);

if (ref $node_tbl)
{
    $content = html_node_tbl($node_tbl, $daemons_status);
}
else
{
    $content = error_message($node_tbl);
}

$page_header = '';
if($opt_page_header eq 'REFRESH_INFO')
{
    $page_header = <<EOF;

<!--This section will force a refresh of web page.-->
<fieldset style="width: 630px; line-height: 22px; padding: 10px; font-family: arial; font-size: 14px;">

    This page will automatically refresh every 3 minutes.<br>

    To force a page refresh, <a href="javascript:void(0);" onClick="window.location.reload()" title="Click here to refresh the page.">click here</a>. <br>

    <!--Option of displaying environment variables.-->  
    ECS Path: $opt_ecs_bin_dir

</fieldset>

EOF
}

# generate HTML output
print <<EOF;
Content-type: text/html; charset=utf-8

<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
 "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>ECS Status $opt_user - $timenow</title>
<link rel="shortcut icon" href="$opt_image_dir/ecs_logo.ico" type="image/x-icon">
<meta http-equiv="refresh" content="180">
<style type="text/css">
 <!--
  /* document-level style sheet */
  .bold      { font-weight: bold; }
  .data      { font-family: monospace; }
  .disabled  { background-color: #eeeeee; }
  .enabled   { background-color: #ffffff; }
  .flagimg   { margin-bottom: 8px; border: 1px solid #dddddd; }
  .header    { font-size: x-large; font-weight: bold; }
  .label     { text-align: right; vertical-align: top; padding-right: 1ex; }
  .leftimg   { float:left; margin-right: 1em; border: 1px solid #dddddd; }
  .tiny      { font-size: x-small; }
  .tblhdr1   { font-weight: bold; text-align: center;
               background-color: #cccccc; }
  .tblhdr2   { font-weight: bold; text-align: center; vertical-align: center;
               background-color: #eeeeee; }
  .top       { vertical-align: top; }
  .topdata   { font-family: monospace; vertical-align: top; }
  .urgent    { font-weight: bold; text-decoration: underline; }
 -->
</style>
</head>
<body>
$page_header
<p class="header">
 <img class="leftimg" src="$opt_image_dir/60px/flag_$opt_this_node.png"
  alt="$opt_this_node" title="$opt_this_node flag">
 ECS Status $opt_user
</p>
$err
$content
</body>
</html>
EOF

exit 0;


# ----------------------------------------------------------------------
# return snapshot of NODE_TBL
sub node_tbl_snapshot
{
    my $NODE_TBL = shift;
    my $NODE_TBL_LOCK = shift;
    my $prefix = shift;
    my $fh;
    my $result = '';

    # work using copies of the node_tbl files, thereby avoiding the
    # need for public RW access to the actual production files

    # first, obtain lock on production lock file
    sysopen($fh, $NODE_TBL_LOCK, O_RDWR)
        or return "Unable to access lock file $NODE_TBL_LOCK: $!";
    lock($fh)
        or return "Unable to obtain lock on file $NODE_TBL_LOCK";

    # copy node_tbl files
    $prefix .= '_' if $prefix;
    copy("$NODE_TBL.dir", "$opt_tmpdir/${prefix}node_tbl.dat.dir")
        or return "Unable to perform file copy(): $!"; 
    copy("$NODE_TBL.pag", "$opt_tmpdir/${prefix}node_tbl.dat.pag")
        or return "Unable to perform file copy(): $!";

    my $ECS_NODE_TBL = new EMDIS::ECS::LockedHash("$opt_tmpdir/${prefix}node_tbl.dat",
                                           "$opt_tmpdir/${prefix}node_tbl.lock");
    if(!ref $ECS_NODE_TBL)
    {
        return "Unable to initialize LockedHash(" .
            "$opt_tmpdir/${prefix}node_tbl.dat, $opt_tmpdir/${prefix}node_tbl.lock)";
    }
    elsif(!$ECS_NODE_TBL->lock())
    {
        return "Unable to lock NODE_TBL: " . $ECS_NODE_TBL->ERROR;
    }
    else
    {
        $result = {};
        my @keys = $ECS_NODE_TBL->keys();
        for my $node_id (@keys)
        {
            my $this_node = $ECS_NODE_TBL->read($node_id);
            if(defined $this_node)
            {
                $result->{$node_id} = {(%$this_node)};
            }
            else
            {
                warn "Unable to read node '$node_id' from node_tbl!";
            }
        }
    }

    # release lock on production lock file
    flock($fh, LOCK_UN);

    return $result;
}

# ----------------------------------------------------------------------
# format $node_tbl as HTML
sub html_node_tbl
{
    my $node_tbl = shift;
    my @header = ();
    my @result = ();

    my @status_color = ('green', 'yellow', 'orange', 'red', 'grey');
    my $max_status_color_idx = 0;
    my $status_image;

   push @result, <<EOF;
<table border="1" cellpadding="5" cellspacing="0">
   <colgroup>
      <col width="70">
      <col width="120">
      <col width="120">
      <col width="120">
      <col width="140">
   </colgroup>
   <tr class="tblhdr1">
      <th>Node</th>
      <th>Outbound</th>
      <th>Inbound</th>
      <th>Queue</th>
      <th>Info</th>
   </tr>
EOF

    my @keys = sort keys %$node_tbl;
    my @all_red  = all_red ( \@keys );
    
    for my $node_id (@keys)
    {
        next if $opt_this_node eq $node_id;

        my $node = $node_tbl->{$node_id};
        my $in_seq_ack = bold_if_ne($node->{in_seq_ack}, $node->{in_seq});

        my $bgcolor_in = '';
        my $bgcolor_out = '';
        my $bgcolor_queue = '';
        if($opt_status_cellbg !~ /NO/i)
        {
           $bgcolor_in    = bgcolor( $node->{in_seq_ack}, $node->{in_seq}, 0);
           $bgcolor_out   = bgcolor( $node->{ack_seq}, $node->{out_seq},
                                     $node->{last_out});
           $bgcolor_queue = bgcolor( $node->{q_size}, 0 , 0);

           $bgcolor_in  = 'bgcolor="red"' if ( $all_red[0] == 1 );
           $bgcolor_out = 'bgcolor="red"' if ( $all_red[1] == 1 );
        }

        my $ack_seq = bold_if_ne($node->{ack_seq}, $node->{out_seq});
        my $last_in = format_timediff($current_time, $node->{last_in});
        my $last_out = format_timediff($current_time, $node->{last_out});
        my $q_size = $node->{q_size};

        $q_size = "<span class=\"bold\">$q_size</span>"
            if $q_size > 499;
        my $info = "";
        my $node_disabled = '';
        my $status_color_idx = 0;
        my $trclass = 'enabled';
        if($node->{node_disabled} =~ /^\s*(yes|true)\s*$/i)
        {
           $node_disabled = '<span class="tiny"><br/>node disabled</span>';
           $trclass = 'disabled';
           $info .= "Node disabled.<br/>";
           $status_color_idx = 4  # grey
              if $status_color_idx < 4;
        }
        if ( $current_time - $node->{last_in} > 24*60*60 ) {
           $info .= "Node silent!<br/>";
           $status_color_idx = 3  # red
              if $status_color_idx < 3;
        }
        my $diff = 0;
        $diff = $node->{q_min_seq} - $node->{in_seq} if $node->{q_min_seq};
        if ( $diff > 1 )
        {
           $diff -= 1;
           $info .= "$diff slow msg.<br/>";
           $status_color_idx = 2  # orange
              if $status_color_idx < 2;
        }
        $diff = $node->{in_seq} - $node->{in_seq_ack};
        if ( $diff > 0 ) {
           $info .= "Diff. In:&nbsp; $diff<br/>";
           $status_color_idx = 2  # orange
              if $status_color_idx < 2 and $diff >= $opt_status_red;
           $status_color_idx = 1  # yellow
              if $status_color_idx < 1 and $diff >= $opt_status_yellow;
        }
        $diff = $node->{out_seq} - $node->{ack_seq};
        if ( $diff > 0 ) {
           $info .= "Diff. Out: $diff<br/>";
           $status_color_idx = 2  # orange
              if $status_color_idx < 2 and $diff >= $opt_status_red;
           $status_color_idx = 1  # yellow
              if $status_color_idx < 1 and $diff >= $opt_status_yellow;
        }
        $status_image = $status_color[$status_color_idx];
        $max_status_color_idx = $status_color_idx
           if $max_status_color_idx < $status_color_idx
               and $status_color_idx < 4;
        $info = "Ok."
           unless $info;

        push @result, <<EOF;
 <tr class="$trclass">
  <td class="tblhdr2">
   <table align="right" border="0" cellspacing="0" cellpadding="0">
    <tr>
    <td align="center">
     $node_id<br/>
     <img class="flagimg" src="$opt_image_dir/22px/flag_$node_id.png"
      title="$node_id flag" alt="$node_id">
    </td>
    <td width="11">&nbsp;</td>
    <td>
     <img src="$opt_image_dir/led_vert_$status_image.png"
      alt="$status_image" title="$status_image status"
      height="24" width="12">
    </td>
    <td width="5">&nbsp;</td>
    </tr>
   </table>
  </td>
  <td class="top" $bgcolor_out>
   <table border="0" cellpadding="0" cellspacing="0">
    <tr><td class="label">Seqnum:</td><td class="data">$node->{out_seq}</td></tr>
    <tr><td class="label">Acked:</td><td class="data">$ack_seq</td></tr>
    <tr><td class="label" nowrap>Lastcom:</td><td class="data">$last_out</td></tr>
   </table>
  </td>
  <td class="top" $bgcolor_in>
   <table border="0" cellpadding="0" cellspacing="0">
    <tr><td class="label">Seqnum:</td><td class="data">$node->{in_seq}</td></tr>
    <tr><td class="label">Acked:</td><td class="data">$in_seq_ack</td></tr>
    <tr><td class="label" nowrap>Lastcom:</td><td class="data">$last_in</td></tr>
   </table>
  </td>
  <td class="top" $bgcolor_queue>
   <table border="0" cellpadding="0" cellspacing="0">
    <tr><td class="label">Size:</td><td class="data">$q_size</td></tr>
EOF

   if($node->{q_size})
   {
            push @result, <<EOF;
    <tr><td class="label" nowrap>Max:</td><td class="data">$node->{q_max_seq}</td></tr>
    <tr><td class="label">Min:</td><td class="data">$node->{q_min_seq}</td></tr>
EOF
   }

   push @result, <<EOF;
   </table>
  </td>
  <td class="topdata">$info</td>
 </tr>
EOF
    }

    push @result, <<EOF;
</table>
EOF

    my ($proc_msg, $proc_file);
    my $node = $node_tbl->{$opt_this_node};
    if($node->{proc_node})
    {
        $proc_msg = "$node->{proc_node}:$node->{proc_seq}";
        $proc_file = basename($node->{proc_file});
    }
    else
    {
        $proc_msg = 'Nothing';
        $proc_file = '';
    }
    if(defined $daemons_status)
    {
        if($max_status_color_idx < 3)
        {
            if($ecs_chk_com_status eq 'red'
                or $ecs_scan_mail_status eq 'red')
            {
                $max_status_color_idx = 3;  # red
            }
        }
    }
    $status_image = $status_color[$max_status_color_idx];
 
    push @header, <<EOF;
<table border="0" cellpadding="6" cellspacing="0">
   <colgroup>
       <col width="60">
       <col width="320">
       <col width="60">
       <col width="60">
   </colgroup>
   <tr>
      <td align="center">
       <img src="$opt_image_dir/led_square_$status_image.png"
        alt="$status_image" title="$status_image status"
        height="24" width="24">
      </td>
      <td>
         <span class="data">$timenow</span>
         <br/><span class="bold">$proc_msg</span> is currently being processed.
         <br/><span class="data">$proc_file</span>
      </td>
EOF
   if (defined $daemons_status) {      
      push @header, <<EOF;
      <td align="center" valign="middle">
         &nbsp;ecs_chk_com&nbsp;<br/>
         &nbsp;<img src="$opt_image_dir/led_horiz_$ecs_chk_com_status.png"
          alt="$ecs_chk_com_status" title="$ecs_chk_com_status status"
          height="12" width="24">&nbsp;
      </td>
      <td align="center" valign="middle">
         &nbsp;ecs_scan_mail&nbsp;<br/>
         &nbsp;<img src="$opt_image_dir/led_horiz_$ecs_scan_mail_status.png"
          alt="$ecs_scan_mail_status" title="$ecs_scan_mail_status status"
          height="12" width="24">&nbsp;
      </td>
EOF
   } 
   push @header, <<EOF;
   </tr>
</table>
<p class="tiny"></p>

EOF

    return join('', @header, @result);
}

# ----------------------------------------------------------------------
sub all_red
{
   my $keys = shift;

   my $red_in  = 0;  
   my $red_out = 0;
   my @all_red = ( 0 , 0 );
   # number of nodes in table without this_node
   my $length = scalar(@$keys) - 1;  


   foreach my $node_id ( @$keys ){
     next if $opt_this_node eq $node_id;
     my $node = $node_tbl->{$node_id};

     $red_out++ if ( ( $current_time - $node->{last_out}) > $opt_all_red );
     $red_in++  if ( ( $current_time - $node->{last_in})  > $opt_all_red );
   }

   $all_red[0] = 1 if ( $red_in  == $length );
   $all_red[1] = 1 if ( $red_out == $length );

   return @all_red;
}
# ----------------------------------------------------------------------
sub bold_if_ne
{
    my $value = shift;
    my $testval = shift;
    return $value if $value eq $testval;
    return "<span class=\"urgent\">$value</span>"
        if abs($value - $testval) > 499;
    return "<span class=\"bold\">$value</span>";
}

# ----------------------------------------------------------------------
sub bgcolor
{
    my $value = shift;
    my $testval = shift;
    my $time_last_node = shift;

    my $y_level = $opt_status_yellow;
    if ( ! defined $y_level || $y_level eq '' ) {
       $y_level = 5;
    }
    my $r_level = $opt_status_red;
    if ( ! defined $r_level || $r_level eq '' ) {
       $r_level = 10;
    }

    if( ( $time_last_node == 0 )
        || ( $current_time - $time_last_node > $opt_all_red ) )
    {
        return 'bgcolor="palegreen"'
            if abs( $value - $testval) < $y_level;
        return 'bgcolor="yellow"'
            if abs( $value - $testval) >= $y_level 
               && abs( $value - $testval) < $r_level;
        return 'bgcolor="red"'
            if abs( $value - $testval) >= $r_level;
    }
    elsif( $time_last_node != 0 )
    {
       return 'bgcolor="palegreen"'; 
    }

}

# ----------------------------------------------------------------------
# Format a datetime value
sub format_datetime
{
    my $datetime = shift;
    my $format = '%04d-%02d-%02d %02d:%02d:%02d';
    my ($seconds, $minutes, $hours, $mday, $month, $year, $wday, $yday,
        $isdst) = localtime($datetime);
    return sprintf($format, $year + 1900, $month + 1, $mday,
                   $hours, $minutes, $seconds);
}

# ----------------------------------------------------------------------
# Format a time difference
sub format_timediff
{
    my $time1 = shift;
    my $time2 = shift;
    my $timediff = $time1 - $time2;
    my $seconds = $timediff % 60;
    my $minutes = ($timediff/60) % 60;
    my $hours   = ($timediff/(60*60)) % 24;
    my $days    = int $timediff/(60*60*24);
    my $result = sprintf "%dd %02d:%02d:%02d",
        $days, $hours, $minutes, $seconds;
    $result = "<span class=\"bold\">$result</span>"
        if $days > 0;
    return $result;
}

# ----------------------------------------------------------------------
sub error_message
{
    my $errmsg = shift;
    return "<p>ERROR: $errmsg</p>";
}

# ----------------------------------------------------------------------
sub compute_opt
{
    my $input_value = shift;
    my $default_value = shift;

    return $input_value
        if defined $input_value and $input_value ne '';
    return $default_value;
}

# ----------------------------------------------------------------------
# lock file, with time limit
sub lock
{
    my $fh = shift;
    my $lock_timeout = 5;
    my $lock_type = LOCK_EX;
    my $result = 1;

    # set up "local" SIG_ALRM handler
    # (Note:  not using "local $SIG{PIPE}" because it ignores die())
    my $oldsigalrm = $SIG{ALRM};
    $SIG{ALRM} = sub {
        die "timeout - $lock_timeout second time limit exceeded\n";
    };

    # attempt to obtain lock, with time limit
    eval {
        alarm($lock_timeout);   # set alarm
        die "flock() failed: $!\n"
            unless flock($fh, $lock_type);
        alarm(0);  # turn off alarm
    };
    if($@) {
        alarm(0);  # turn off alarm
        $result = '';
    }

    # restore previous SIG_ALRM handler
    if(defined $oldsigalrm) { $SIG{ALRM} = $oldsigalrm; }
    else                    { delete $SIG{ALRM}; }

    return $result;
}

#= EOF =

__END__

2007-08-01
ZKRD - emdisadm@zkrd.de
Added different bgcolors for in | out | queue according to their status:
green (diff <= 5) yellow (diff > 5) red (diff > 10).
Added new row (Info) which contains further information about the status.
If there is a problem with a missing mail (in_seq < q_min_seq) a torn of rope
is shown in the info area.
The own node_id is now detected by the ecs.cfg.
The path to the node_tbl is now detected by the ecs.cfg.
The daemon status is visible in the header:
green (daemon is running) red (daemon is currently not running)
Added a favicon showing the ECS logo.
Added optional parameter to select a user. This fixes the problem of a wrong
positive runlevel status of the daemons caused by more than one running
instance of (perl) ECS.

