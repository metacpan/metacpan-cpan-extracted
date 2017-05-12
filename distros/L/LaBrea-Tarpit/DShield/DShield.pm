#!/usr/bin/perl
package LaBrea::Tarpit::DShield;
#
use strict;
#use diagnostics;

use vars qw($VERSION @ISA @EXPORT_OK *deliver2_DShield);
use Fcntl qw(:DEFAULT :flock);
use Net::Netmask;

$VERSION = do { my @r = (q$Revision: 0.08 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	chk_config
	deliver2_DShield
	process_Q
	move2_Q
	mail2_Q
);

*deliver2_DShield = \&process_Q;

=head1 NAME

LaBrea::Tarpit::DShield

=head1 SYNOPSIS

  use LaBrea::Tarpit::DShield qw ( .... );

=head1 DESCRIPTION - LaBrea::Tarpit::DShield

Module provides mail support to parse and send reports to B<dshield.org>

  $rv = chk_config(\%config);
  $rv = mail2_Q(\%config,\$message,[subject]);
  $rv = move2_Q(\$config);
  $rv = deliver2_DShield(\%config);
  $rv = process_Q(\%config);

=over 4

=item $rv = chk_config(\%config);

Check and adjust default configuration parameters.

Check for valid e-mail address formats and
add leading ./ to DShield file path if needed.

  input:	\%config
  returns:	false on success
		error msg on failure

  Note:	UserID is checked in move2_Q

  my $config = {
    'DShield'	=> 'tmp/DShield.cache',	# path/to/file
    'To'	=> 'test@dshield.org',  # or report@dshield.org
    'From'	=> 'john.doe@foo.com',
    'Reply-To'	=> 'john.doe@foo.com',	# optional
  # optional
    'Obfuscate'	=> 'complete or partial',
  # optional - ignore reports about this netblock
  #	when generating DShield reports
    'SrcIgnore'	=> ['10.11.12.0/23','10.11.16.0/23'],
  # either one or more working SMTP server's
    'smtp'	=> 'iceman.dshield.org,mail.euclidian.com',
  # or a sendmail compatible mail transport command
    'sendmail'	=> '/usr/lib/sendmail -t -oi',
 ############ used only by "move2_Q"
    'UserID'	=> '0',			# DShield UserID
  };

Called internally by all routines, it's error codes are returned by them.

=cut

sub chk_config {
  my ($cfg) = @_;
  return "missing DShield queue directory"
	unless $cfg->{DShield};
# add leading ./ if missing
  $cfg->{DShield} = './' . $cfg->{DShield}
	unless $cfg->{DShield} =~ m|/|;

  my $emailfmt = '^.+\@.+\..+';		# required e-mail format
  return "missing or invalid To: email format"
	unless $cfg->{To} && $cfg->{To} =~ /$emailfmt/;
  return "missing or invalid From: email format"
	unless $cfg->{From} && $cfg->{From} =~ /$emailfmt/;
  $cfg->{'Reply-To'} = $cfg->{From} unless exists $cfg->{'Reply-To'};
  return "invalid Reply-To: email format"
	unless defined $cfg->{'Reply-To'} &&
			$cfg->{'Reply-To'} =~ /$emailfmt/;
  return "unknown Obfuscate word: '$cfg->{Obfuscate}'"
	if $cfg->{Obfuscate} &&
	   ( $cfg->{Obfuscate} !~ /^partial$/i &&
	     $cfg->{Obfuscate} !~ /^complete$/i );
  return "missing mail agent"
	unless $cfg->{smtp} || $cfg->{sendmail};
  return "sendmail agent missing or not executable"
	if $cfg->{sendmail} &&
	   $cfg->{sendmail} =~ /^([\S]+)/ &&
	   ! -e $1 && 
	   ! -x $1;
  return undef;
}
  
=item $rv = mail2_Q(\%config,\$message,[subject]);

  Queue a mail message as specified by 
  To, From, Reply-To, etc...

  subject is optional

  Must run 'process_Q' or 'deliver2_DShield'
  to actually mail the message


=cut

sub mail2_Q {
  my ($cfg,$mp,$sub) = @_;
  return "no message content" unless $mp && $$mp =~ /\S/;
  $sub = 'not specified' unless $sub =~ /\S/;
  return $_ if ($_ = chk_config($cfg));
  my $f = $cfg->{DShield};
  $f =~ m|(.*/)|;
  my $dir = $1;  
  return "queue directory $dir not writable"
	unless -d $dir && -w $dir;
  local(*LOCK,*IN,*OUT);  
# open mail.q.tmp
  return $_ if ($_ = open_Q(*LOCK,*OUT,$dir . 'mail'));
# now format the Q file output
  print OUT qq|From: $cfg->{From}
To: $cfg->{To}
Reply-To: $cfg->{'Reply-To'}
X-mailer: LaBrea-DShield $VERSION
Subject: $sub

$$mp
|;
  close OUT;
  rename $dir . 'mail.q.tmp', $dir . 'qF'. time .'.'. $$ .'.'. 2;
  close LOCK;
  return undef;
}

# helper routine opens Q files
#
# input:	LOCK, OUT handle pointers, file name
# returns:	error message on failure
# returns:	undef on success
#
  
sub open_Q {
  my ($LOCK,$OUT,$f) = @_;
  return "failed to open lockfile ${f}.flock" unless
	sysopen $LOCK, $f . '.flock', O_RDWR|O_CREAT|O_TRUNC;
  unless (flock($LOCK,LOCK_SH)) {
	close $LOCK;
	return "failed to lock $f";
  }
  unless (open($OUT,'>'.${f}.'.q.tmp')) {
	close $LOCK;
	return "failed to open $f.q.tmp for write";
  }
  $_ = select $OUT;
  $| = 1;
  select $_;
  return undef;
}

=item $rv = move2_Q(\$config,$debug);

Prepare the DShield file for mailing and rename
as a B<Que's> file in preparation for mailing.

UserID, From, To, [Reply-To], and Subject are added to the file and it is
renamed qF_unique_string.

No queue file is generated if the list of connections are empty.
This could happen when using the SrcIgnore option.

  input:	\%config,$debug
  output:	false on success or no action
		true = error message

  NOTE:		do not use debug mode with the mail 
		address pointing to DShield, 
		point it to yourself

  $debug = missing	normal operation
  $debug = 0		normal operation
  $debug = 1		do not delete cache file
  $debug = 2		do not rename q-file

=cut

# $debug	= true, do not delete 'dshield.cache'
# $debug	> 1, as above and do not rename 'dshield.cache.q.tmp'
 
sub move2_Q {
  my ($cfg,$debug) = @_;
  return "missing DShield UserID"
	unless  exists $cfg->{UserID} &&
		defined $cfg->{UserID} &&
		$cfg->{UserID} !~ /\D/;
  my $tmp = chk_config($cfg);
  return $tmp if $tmp;		# return existing config errors
  my $f = $cfg->{DShield};
  return undef unless -e $f && -r $f;	# nothing to do
  return "$f not a plain file" unless -f $f;
  $f =~ m|(.*/)|;
  my $dir = $1;
  return "queue directory $dir not writable"
	unless -d $dir && -w $dir;
  local (*LOCK,*IN,*OUT);
  return $_ if ($_ = open_Q(*LOCK,*OUT,$f));
  unless (open(IN,$f)) {
	close OUT;
	close LOCK;
	return "failed to open $f for read"
  }

  my @SrcIgnoreBlocks = ();
  if ($cfg->{SrcIgnore}) {
      my($blockstr,$block);
      for $blockstr (@{$cfg->{SrcIgnore}}) {
	  return "failed to allocate Net::Netmask"
		unless $block = new Net::Netmask($blockstr);
	  push(@SrcIgnoreBlocks, $block);
      }
  }

# now format the Q file output
  print OUT qq|From: $cfg->{From}
To: $cfg->{To}
Reply-To: $cfg->{'Reply-To'}
X-mailer: LaBrea-DShield $VERSION
|;

  $tmp = 1;	# line count, flag
  my $ver = '';
  my $entries = 0;

DSLINE:
  while(my $in = <IN>) {
#					   $1        $2                $3              $4                  $5      $6
#                    date     time         tza       tzb            version   count   src         sp     1stQuad  dest      dp proto flags
    unless ($in =~ /[^\s]+\s+[^\s]+\s+([\+\-0-9]+):([0-9]+)\s+UserID([^\s]+)\s+\d+\s+([^\s]+)\s+[^\s]+\s+(\d+)\.([^\s]+)\s+[^\s]+\s+\w+\s+\w+/) {
      chop $in;
      close OUT;
      close IN;
      unlink ${f}.'.q.tmp';
      close LOCK;
      return "line $tmp corrupt: $in";
    }
    unless ( $ver ) {		# Subject printed yet??
      $ver = $3;		# nope, mark and print
      print OUT "Subject: FORMAT DSHIELD USERID $cfg->{UserID} TZ $1:$2 LaBrea_Tarpit_DShield ${ver}:$VERSION\n\n";
    }
    foreach my $block (@SrcIgnoreBlocks) {
	next DSLINE if $block->match($4);
    }
    if (exists $cfg->{Obfuscate}) {
      my $dest = $5 .'.'.$6;
      my $rplc = ($cfg->{Obfuscate} =~ /complete/i)
	? '10.0.0.1'		# complete
	: '10.' . $6;		# partial
      $in =~ s/$dest/$rplc/;
    }
# insert DShield ID
    $in =~ s/UserID${ver}/$cfg->{UserID}/;
    print OUT $in;
    $entries++;
  }
  close OUT;
  close IN;
  if ($entries) { # Only send mail if matching entries were found.
    rename ${f}.'.q.tmp', $dir . 'qF'. time .'.'. $$ .'.'. 0
	unless $debug && $debug > 1;
  } else {
    unlink ${f}.'.q.tmp' unless $debug && $debug > 1;
  }

  $debug = ($debug || unlink $f) ? 0
	: "cannot unlink $f: Operation not permitted";
  close LOCK;
  return $debug;
}

=item $rv = deliver2_DShield(\%config,$debug);

Alias for B<process_Q>

=item $rv = process_Q(\%config,$debug);

Attempts to deliver messages in queue using the configured mail agent. 
Failed attempts are left in the queue, successfull ones are deleted.

  input:	\%config
  returns:	last error message
		or false on success

  NOTE:		do not use debug mode with the mail 
		address pointing to the real target, 
		point it to yourself

  $debug = missing	normal operation
  $debug = 0		normal operation
  $debug = 1		generate mail file suffixed
			with .stmp or .sendmail as
			appropriate instead of sending
			real mail
  $debug = 2		do not delete input Q file

=cut

# input:	\$config, $debug
# returns:	error message
#		or false on success
#
#	$debug true will create a file called
#	dF{time.pid} . '.smtp'	containing the mail output
#	  or
#	dF{time.pid} . '.sendmail'
#
#	$debug > 1, will not delete queue files after processing
#
#	SEE: RFC-821 for SMTP codes
#
sub process_Q {
  my ($cfg,$debug) = @_;
  my $tmp = chk_config($cfg);
  return $tmp if $tmp;

# FOR NOW
my $me = 'localhost';

  $cfg->{DShield} =~ m|(.*/)|;
  my $dir = $1;
  return "$dir not a directory or not writable"
	unless -d $dir && -w $dir;
  local(*M,*QF);
  my $M = *M;
  return "could not open directory $dir"
	unless opendir($M,$dir);
  my @qfiles = grep(/^qF/,readdir(M));
  closedir $M;
  return undef unless @qfiles;		# punt if nothing to do

  my $smtp = ($cfg->{smtp}) ? 1 : 0;

  local $SIG{ALRM} = sub {die 'failed: 554 timeout ';};

## define valid SMTP response codes for each action
#
  my $resp = {
	'CONN'	=> [220],
	'HELO'	=> [250],
	'MAIL'	=> [250],
	'RCPT'	=> [250,251],
	'DATA'	=> [354],
	'ATAD'	=> [250],	# the "period" '.'
	'QUIT'	=> [221],
  };

  my $err;
  foreach my $qf (@qfiles) {
    if ($debug) {
      $tmp = ($smtp)
	? $dir . $qf . '.smtp'
	: $dir . $qf . '.sendmail';
      $tmp =~ s/qF/dF/;
      return "could not open debug file $tmp"
	unless open($M,'>'. $tmp);
    }
    elsif ( $smtp ) {			# is SMTP
      require LaBrea::NetIO;
      my @smtp_hosts = split(',',$cfg->{smtp});
      foreach (@smtp_hosts) {
        $tmp = LaBrea::NetIO::open_tcp($M,$_,25);
	last unless $tmp;
      }
      return $tmp if $tmp;		# punt if error
    }
    else {				# must be sendmail
      return "could not open sendmail"
	unless open($M,"|$cfg->{sendmail}");
    }

    $tmp = $dir . $qf;
    unless (open(QF,$tmp)) {		# sigh.... kill this loop
      close $M;
      next;
    }

# actually send the mail now
    eval {

      alarm 240;			# 4 minutes to complete task
      if ($smtp) {
	slurp($M,'CONN',$resp,$debug);	# connect

	syswrite($M,"HELO $me\n");
	slurp($M,'HELO',$resp,$debug);	# hello

        my $line = <QF>;		# LINE one, From:
	syswrite($M,'MAIL ' . $line);
	slurp($M,'MAIL',$resp,$debug);	# mail From:

	$line = <QF>;
	syswrite($M,'RCPT ' . $line);
	slurp($M,'RCPT',$resp,$debug);	# receipient To:

	syswrite($M,"DATA\n");		# rest of headers and message follow
	slurp($M,'DATA',$resp,$debug);

        while ($line = <QF>) {		# send the rest
	  syswrite($M,$line);		# 
	}
	syswrite($M,'.'."\n");		# terminate with period
	slurp($M,'ATAD',$resp,$debug);	# Got confirmation

	syswrite($M,"QUIT\n");
	slurp($M,'QUIT',$resp,$debug);
      }
      else {	# IT's sendmail or equivalent
	while (<QF>) {
	  syswrite($M,$_);
	}
      } # done
    };	# end eval
    alarm 0;
    close QF;
    close $M;
    if ($@) {
      $err = ( $@ =~ /^(failed:\s+\d+\s+\w+)/ )
	? $1 : $@; #'failed: 554 unknown';
    } else {
      unlink $dir . $qf unless $debug && $debug > 1;
    }
  }
  return $err;
}

# helper subroutine to get responses from SMTP servers
#
# input:	handle, action, \%valid_response, $debug
# returns:	true if OK to proceed
#		else DIES
sub slurp {
  my ($S,$act,$rsp,$debug) = @_;
  return 1 if $debug;		# skip
  my $buf;
  sysread($S,$buf,1024);	# better not be longer than this
  my $code;
  foreach(@{$rsp->{$act}}) {
    next unless $buf =~ /^(\d+)/;
    $code = $1;
    return $code if $code == $_;
  }
# bummer, didn't get a response
  if ( $act !~ /QUIT/i ) {	# don't wait on quit, won't do any good
    alarm 10;			# give it 10 seconds
    syswrite($S,"QUIT\n");
    sysread($S,$buf,1024);	# try to complete the transaction
  }
  $code = 554 unless $code;
  $code = sprintf("failed: %03d ",$code) . $act;
  die $code;
}

1;
__END__

=head1 EXPORT_OK

	chk_config
	deliver2_DShield
	move2_Q

=head1 COPYRIGHT

Copyright 2002, 2004 Michael Robinton & BizSystems
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or   
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 AUTHOR

Michael Robinton, michael@bizsystems.com

=head1 SEE ALSO

perl(1), LaBrea::Tarpit(3), LaBrea::Codes(3), LaBrea::Tarpit::Report(3),
LaBrea::Tarpit::Get(3), LaBrea::Tarpit::Util(3)

=cut
