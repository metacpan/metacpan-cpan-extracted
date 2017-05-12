# Device::Modem::UsRobotics - control USR modems self mode
#
# Copyright (C) 2004-2005 Cosimo Streppone, cosimo@cpan.org
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Additionally, this is ALPHA software, still needs extensive
# testing and support for generic AT commads, so use it at your own risk,
# and without ANY warranty! Have fun.
#
# Portions of this code are adapted from TkUsr tcl program
# published with the GPL by Ludovic Drolez (ldrolez@free.fr).
# Here is his copyright and license statements:
#
#    TkUsr v0.80
#    
#    Copyright (C) 1998-2003 Ludovic Drolez (ldrolez@free.fr)
#   
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#    
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#    
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.       
#
#
# $Id$

package Device::Modem::UsRobotics;
$VERSION = sprintf '%d.%02d', q$Revision: 1.5 $ =~ /(\d)\.(\d+)/;

use strict;
use Device::Modem;

@Device::Modem::UsRobotics::ISA = 'Device::Modem';

use constant DLE => chr(0x10);
use constant SUB => chr(0x1A);
use constant ETX => chr(0x03);

our %CACHE;

sub dump_memory
{
    my($self, $memtype) = @_;
    $memtype = 2 unless defined $memtype;
    my $cmd = '';
    if( $memtype == 2 || $memtype eq 'messages' )
    {
        $cmd = 'MTM';
    }

    $cmd = 'AT+' . $cmd . Device::Modem::CR;
    $self->atsend($cmd);
    $self->wait(500);
    my $data = $self->answer();
    $self->log->write('info', 'dumped messages memory (length: '.length($data).')');
    return($data);
}

#sub dump_page
#{
#    my($self, $page) = @_;
#    $self->atsend( sprintf('AT+MTP=%d'.Device::Modem::CR, 0 + $page) );
#    $self->wait(500);
#    my $data = $self->answer();
#    $self->log->write('info', 'dumped memory page '.$page.' (length: '.length($data).')');
#    return($data);
#}

sub get_mem_page($)
{
    my($self, $page) = @_;

#
# get a memory page and cache it for fast retrieving
#
    return $CACHE{$page} if exists $CACHE{$page};

    # Download a page
    #set device(binary) 1
    #fconfigure $device(dev) -translation binary
    
    # Get the page
    $self->atsend( sprintf('AT+MTP=%d'.Device::Modem::CR, 0 + $page) );
    $self->wait(100);

    # Wait for data 
    my $data = $self->answer();

    #set device(buffer) ""
    # cache the page
    $CACHE{$page} = $data;

    ## cancel binary mode
    #fconfigure $device(dev) -translation auto
    #set device(binary) 0

    return $data;
}

sub mcc_get {

    my $self = $_[0];
    $self->atsend('AT+MCC?'.Device::Modem::CR);
    my @time;
    my($ok, @data) = $self->parse_answer();
    if( index($ok, 'OK') >= 0 )
    {
        @time = split ',', $data[0];
        $self->log->write('info', sprintf('MCC: %d days, %02d hrs, %02d mins, %02d secs after last clock reset', @time) );
        return wantarray ? @time : join(',',@time);
    }
    else
    {
        $self->log->write('warning', 'MCC: failed to get clock value');
        return undef;
    }

}

#
# Takes days,hrs,mins values and obtains a real time value
#
sub mcc_merge {
    my($self, $d, $h, $m) = @_;
    $_ += 0 for $d, $h, $m ;

    if( $d == $h && $h == $m && $m == 255 )
    {
        $self->log->write('warning', 'invalid time 255,255,255');
        return(time());
    }

    my $mcc_last = $self->mcc_last_saved();
    $mcc_last += 86400 * $d + 3600 * $h + 60 * $m;

    $self->log->write('info', "$d days, $h hours, $m mins is real time ".localtime($mcc_last));
    return($mcc_last);
}

sub mcc_last_saved {
    my $self = $_[0];
    my $dir = $self->_createSettingsDir();
    my $mcc_basetime = undef;

    if( ! -d $dir )
    {
        return undef;
    }
    elsif( open SETTINGS, "$dir/mcc_timer" )
    {
        chomp($mcc_basetime = <SETTINGS>);
    }

    $self->log->write('info', 'last mcc timer saved at '.localtime($mcc_basetime));
    return($mcc_basetime);
}

sub mcc_reset {
    my $self = $_[0];
    $self->atsend('AT+MCC'.Device::Modem::CR);
    my($ok, $ans) = $self->parse_answer();
    $self->log->write('info', 'internal timer reset to 00 days, 00 hrs, 00 mins');
    if( index($ok, 'OK') >= 0 )
    {
        # Create settings dir
        my $dir = $self->_createSettingsDir();
        if( -d $dir )
        {
            if( open SETTINGS, "> $dir/mcc_timer" )
            {
                print SETTINGS time(), "\n";
                $ok = close SETTINGS;
            }
        }
        else
        {
            $self->log->write('warning', 'Failed writing mcc timer settings in ['.$dir.']');
        }

    }
}

sub msg_status {
    my($self, $index) = @_;

    $self->atsend('AT+MSR=0'.Device::Modem::CR);
    my($ok, @data) = $self->parse_answer();
    if( index($ok,'OK') >= 0 ) {
        $self->log->write('info', 'MSR: '.join('/ ', @data));
        return wantarray ? @data : join("\n", @data);
    }
    else
    {
        $self->log->write('warning', 'MSR: Error in querying status');
        return undef;
    }
}

sub clear_memory
{
    my($self, $memtype) = @_;
    $memtype = 2 unless defined $memtype;
    my $cmd  = '';

    if( $memtype == 0 || $memtype eq 'all' )
    {
        $cmd = 'MEA';
    }
    elsif( $memtype == 1 || $memtype eq 'user' )
    {
        $cmd = 'MEU';
    }
    elsif( $memtype == 2 || $memtype eq 'messages' )
    {
        $cmd = 'MEM';
    }

    $cmd = 'AT+' . $cmd . Device::Modem::CR;
    $self->atsend($cmd);
    $self->wait(500);
    $self->log->write('info', 'cleared memory type '.$memtype);
    return(1);
}

sub fax_id_string
{
    my $self   = shift;
    my $result = '';

    if( @_ )
    {
        $self->atsend( sprintf('AT+MFI="%s"',$_[0]) . Device::Modem::CR );
        $self->wait(100);
        my($ok, $ans) = $self->parse_answer(); 
        $self->log->write('info', 'New Fax ID string set to ['.$_[0].']');
        $result = $ok;
    }
    else
    {
        # Retrieve current fax id string
        $self->atsend('AT+MFI?' . Device::Modem::CR);
        $self->wait(100);
        my($ok, $ans) = $self->parse_answer();
        $self->log->write('info', 'Fax ID string is ['.$ans.']');
        # Remove double quotes chars if present
        $ans = substr($ans, 1, -1) if $ans =~ /^".*"$/;
        $result = $ans;
    }

    $self->log->write('debug', 'fax_id_string answer is ['.$result.']');
    return($result);
}

sub messages_info {
    my $me = $_[0];
    $me->atsend('AT+MSR=0'.Device::Modem::CR);
    $me->wait(100);
    my $info_string = $me->answer();
    my @keys = qw(
        memory_size memory_used stored_voice_msg unreleased_voice_msg
        stored_fax_msg unreleased_fax_msg
    );
    my %data;
    my $n = 0;
    for( split ',', $info_string, 6 )
    {
        $data{$keys[$n++]} = 0 + $_;
    }

    $me->log->write('info', "Memory size is $data{memory_size} Mb. Used $data{memory_used}%");
    $me->log->write('info', "Voice messages: $data{unreleased_voice_msg}/$data{stored_voice_msg} unread");
    $me->log->write('info', "Fax   messages: $data{unreleased_fax_msg}/$data{stored_fax_msg} unread");

    return %data;
}

sub message_dump {
    my($me, $msg) = @_;
    my %info = $me->message_info($msg);

    if( exists $info{index} && $info{index} > 0 )
    {
        $me->log->write('info', sprintf('message %d starts at page %d address %x%x', $msg, $info{page}, $info{addresshigh}, $info{addresslow}));
        my $mem_page = $me->get_mem_page($info{page});
        my $offset   = $info{addresshigh} << 8 + $info{addresslow};
        $me->log->write('info', sprintf('offset in page %d is %d (%x)', $info{page}, $offset, $offset));
        $mem_page = substr($mem_page, $offset);
        $me->message_scan_page($mem_page);
    }

    return undef;
}

sub message_scan_page($\$)
{
    my($me, $page) = @_;

    my $block_len  = 32768;
    my $header_len = 32;
    my $pos = 0;
    my $len = length($page);

    while( $pos <= $len )
    {
        # Read next message
        # XXX
        #my $chksum  = substr($page, $pos, 2);
        #$pos += 2;
        my $chksum = 0;
        
        my $block   = substr($page, $pos, $block_len);
        $pos += $block_len;

        # Check checksum
        my $calc_chksum = 0;
        for( 0 .. length($block) )
        {
            $calc_chksum += ord(substr($block,$_,1));
            $calc_chksum &= 0xFF;
        }

        my $header = substr($block, 0, $header_len);

        print "Calculated checksum = ", $calc_chksum, "\n";
        print "Declared   checksum = ", hex($chksum), "\n";

        my @msg = unpack('CCCCCCCCA20CSCS', $header);
        my @fld = qw(index type info attrs recvstat days hours minutes sender p_page p_addr n_page n_addr);

        my %msg = map { $_ => shift(@msg) } @fld;

        foreach( @fld )
        {
            print "MESSAGGIO $_ = [", $msg{$_}, "]\n";
        }
        print "-" x 60, "\n";

    }

}

sub message_info {
    my($me, $msg) = @_;

    unless( $msg > 0 && $msg < 255 )
    {
        $me->log->write('warning', 'message_info(): message index must be 0 < x < 255');
        return undef;
    }

    # Send message info command
    $me->atsend("AT+MSR=$msg".Device::Modem::CR);
    $me->wait(100);
    my $info_string = $me->answer();
    my @keys = qw(
        index type information attributes status day hour minute
        callerid page addresshigh addresslow checksum
    );
    my %data;
    my $n = 0;
    for( split(',', $info_string, scalar @keys) )
    {
        $data{$keys[$n]} = $_;
        $me->log->write('info', 'Message '.$keys[$n].': '.$data{$keys[$n]});
        $n++;
    }

    return %data;
}

sub _createSettingsDir {
    my $self = $_[0];
    my $ok = 1;
    require File::Path;
    my $dir = $self->_settingsDir();
    if( ! -d $dir )
    {
        $ok = File::Path::mkpath( $dir, 0, 0700 );
    }
    return($ok ? $dir : undef);
}

sub _settingsDir {
    "$ENV{HOME}/.usrmodem"
}

#
# retrieve and save a message in GSM format
#
sub extract_voice_message($)
{
    my($self, $number) = @_;

    my $addr;
    my $d;
    my $data;
    my $end;
    my $header;
    my $startpage;

    # Check if this message is really a voice message (type==2)
    my %msg = $self->message_info($number);
    return undef unless %msg;
    return undef if $msg{type} != 2;

    # set startpage $stat($number.page) 
    $startpage = $msg{page};

    # Download the 1st page
    #set d [GetMemPage $startpage]
    $d = $self->get_mem_page($startpage);

    #set addr [expr $stat($number.hi)*256 + $stat($number.lo) + 2]
    $addr = 2 + $msg{addresslow} + ($msg{addresshigh} << 8);

    #set header [string range $d $addr [expr $addr+34]]
    #set data [string range $d [expr $addr+34] end]
    $header = substr $d, $addr, 34; #$addr + 34;
    $data   = substr $d, $addr + 34;

    #warn('header ['.$header.']'.(length($header)));

    # Extract the data from the header
    #binary scan $header cccccccca20cScS h_idx h_type h_info h_attr h_stat h_day h_hour h_min h_faxid h_ppage h_paddr h_npage h_naddr
    my @hdr = unpack('cccccccca20cncn', $header);
    my %hdr = map { $_ => shift @hdr } qw(idx type info attr stat day hour min faxid ppage paddr npage naddr);
    undef @hdr;

    # set h_naddr [expr ($h_naddr + 0x10000) % 0x10000]
    # set h_paddr [expr ($h_paddr + 0x10000) % 0x10000]
    #$hdr{naddr} = ($hdr{naddr} + 0x10000) % 0x10000;
    #$hdr{paddr} = ($hdr{paddr} + 0x10000) % 0x10000;
    $hdr{naddr} &= 0xFFFF; #($hdr{naddr} + 0x10000) % 0x10000;
    $hdr{paddr} &= 0xFFFF; #($hdr{paddr} + 0x10000) % 0x10000;

    #for (sort keys %hdr)
    #{
	#    warn("header $_ {$hdr{$_}}");
    #}

    # One or more pages ?
    if($startpage == $hdr{npage})
    {
	    # Only one page
    	$data = substr $data, 0, $hdr{naddr};
        #warn('1page datalen:'.(length($data)));
    }
    else
    {
	    # Get the following pages
    	$startpage++;
    	while( $startpage <= $hdr{npage} )
        {
	        #set d [GetMemPage $startpage]
            $d = $self->get_mem_page($startpage);

    	    # Remove the checksum
    	    if( $hdr{npage} == $startpage )
            {
        		# set end [expr $h_naddr - 1]
                $end = $hdr{naddr} - 1;
    	    }
            else
            {
        		#set end end
                #$end = $end;
    	    }
            
	        # append data [string range $d 2 $end]
            if( $end )
            {
                $data .= substr $d, 2, 2 + $end;
            }
            else
            {
                $data .= substr $d, 2;
            }

	        #warn('datalen:'.length($data));

    	    #incr startpage
            $startpage++;
	    }
    }

    # Unstuff data, $num should always be 1
    # set pages(0) ""
    my @pages = ();

    # set num [ByteUnstuff $data pages]
    my $num = $self->_byte_unstuff($data, \@pages);

    # Gsm messages have always 1 page
    #warn('length of final msg = '.length($pages[1]));
    return $pages[1];
}

sub _byte_stuff($)
{
    my($self, $data) = @_;

#
# Escape DLE (0x10) codes from data:
#   DLE DLE <= DLE
#   DLE SUB(0x1A) <= DLE DLE
#   DLE ETX(0x03) = end of page
# 
# I: data: data to decode
# R: escaped data
#
    # set out ""
    my $out = '';

    while (1)
    {
	    # set id [string first "\x10" $data]
        my $id = index($data, chr(0x10));
	    # if {$id == -1} break
        last if $id == -1;
    
    	#append out [string range $data 0 [expr $id - 1]]
        $out .= substr($data, 0, $id - 1);
        
    	#set nextchar [string index $data [expr $id+1]]
        my $nextchar = substr($data, $id + 1, 1);

    	#set data [string range $data [expr $id+2] end]
        $data = substr($data, $id + 2);
        
    	#switch $nextchar {
	    #    "\x10" { append out \x10\x1A }
    	#    default { append out \x10\x10$nextchar }
	    #}
        if( $nextchar eq chr(0x10) )
        {
            $out .= chr(0x10) . chr(0x1A);
        }
        else
        {
            $out .= chr(0x10) . chr(0x10) . $nextchar;
        }
    }
    
    # add end of data
    #append out $data\x10\x03
    $out .= $data . chr(0x10) . chr(0x03);

    return $out;
}

sub _byte_unstuff(@)
{

    #proc {ByteUnstuff} {data array} {
    #
    # Unescape DLE (0x10) codes from data:
    #   DLE DLE => DLE
    #   DLE SUB(0x1A) => DLE DLE
    #   DLE ETX(0x03) = end of page, the data is put in another hash
    # 
    # I: data: data to decode
    # O: array: contains one or more pages of data (array(1), array(2)...)
    # R: number of pages 
    #

    my($self, $data, $r_pages) = @_;
    $r_pages ||= [];

    my $numpage = 1;
    my $out = '';
    my $id;

    while (1)
    {
        # set id [string first "\x10" $data]
        $id = index($data, DLE);
	    last if $id == -1;

    	#append out [string range $data 0 [expr $id - 1]]
        $out .= substr($data, 0, $id);

	    #set nextchar [string index $data [expr $id+1]]
        my $nextchar = substr($data, $id + 1, 1);
        #set data [string range $data [expr $id+2] end]
        $data = substr($data, $id + 2);

    	#switch $nextchar {
	    #"\x10" { append out \x10 }
	    #"\x1A" { append out \x10\x10 }
	    #"\x03" { set adata($numpage) $out
		#    set out ""
		#    incr numpage
		#    # end of page 
	    #}	    
	    #default { append out \x10$nextchar }
	    #}
        if( $nextchar eq DLE )
        {
            $out .= DLE;
        }
        elsif( $nextchar eq SUB )
        {
            $out .= DLE . DLE;
        }
        elsif( $nextchar eq ETX )
        {
            $r_pages->[$numpage++] = $out;
            $out = '';
        }
        else
        {
            $out .= DLE . $nextchar;
        }

    }

    # Manage last page
	$r_pages->[$numpage] = $out . $data;

	return $numpage;
}


1;

=head1 NAME

Device::Modem::UsRobotics - USR modems extensions to control self-mode

=head1 SYNOPSIS

  use Device::Modem::UsRobotics;

  my $modem = new Device::Modem::UsRobotics( port => '/dev/ttyS1' );
  $modem->connect( baudrate => 9600 );
  my %info = $modem->messages_info();
  print "There are $info{unreleased_voice_msg} unread voice messages on $info{stored_voice_msg} total\n";
  print "There are $info{unreleased_fax_msg} unread fax messages on $info{stored_fax_msg} total\n";

  # Get details about message n. X
  my %msg = $modem->message_info(1);
        index type information attributes status day hour minute
        callerid page addresshigh addresslow checksum
  print 'This is a ', ($msg{type} == 2 ? 'voice' : 'fax'), 'message', "\n";
  print 'It came from no. ', $msg{callerid}, "\n";
  # ...

  # Now clear all messages
  $modem->clear_memory();

=head1 WARNING

This module is not documented yet, and it is a rough work in progress.
Until now, it correctly reads voice/fax messages information, but when
saving voice messages to disk, sometimes they are incorrectly decoded.

So, if you need a working program, check out the good old TkUsr by
Ludovic Drolez, unless you want to help develop Device::Modem::UsRobotics.

=head1 DOCS TO BE COMPLETED FROM NOW.....

Yes, I'm a bad boy :-)

=head1 DESCRIPTION

Bla Bla Bla...

=head1 METHODS

=head2 clear_memory()

Used to permanently clear the memory space of the modem. There are separate memory
spaces, one for voice/fax messages and one for user settings. Examples:

	$modem->clear_memory('user');     # or $modem->clear_memory(1)
    $modem->clear_memory('messages'); # or $modem->clear_memory(2)

To clear both, you can use:

    $modem->clear_memory('all');      # or $modem->clear_memory(0);

Parameters:

=over 4

=item C<$memtype>

String or integer that selects the type of memory to be cleared,
where C<0> is for C<all>, C<1> is for C<user> memory, C<2> is for C<messages>
memory.

=back


=head1 SUPPORT

Please feel free to contact me at my e-mail address L<cosimo@cpan.org>
for any information, to resolve problems you can encounter with this module
or for any kind of commercial support you may need.

=head1 AUTHOR

Cosimo Streppone, L<cosimo@cpan.org>

=head1 COPYRIGHT

(C) 2004-2005 Cosimo Streppone, L<cosimo@cpan.org>

This library is free software; you can only redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

Device::Modem,
perl

=cut

# vim: set ts=4 sw=4 tw=0 nowrap nu
