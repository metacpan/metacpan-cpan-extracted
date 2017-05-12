package FTN::Packet;

use strict;
use warnings;
use Carp qw( croak );

=head1 NAME

FTN::Packet - Reading or writing Fidonet Technology Networks (FTN) packets.

=head1 VERSION

VERSION 0.23

=cut

our $VERSION = '0.23';

=head1 DESCRIPTION

FTN::Packet is a Perl extension for reading or writing Fidonet Technology Networks (FTN) packets.

=cut

require Exporter;
require AutoLoader;

=head1 EXPORT

The following functions are available in this module:  read_ftn_packet(),
write_ftn_packet().

=cut

our @ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
our @EXPORT_OK = qw( &read_ftn_packet &write_ftn_packet
);

=head1 FUNCTIONS

=head2 read_ftn_packet

Syntax:  $messages = read_ftn_packet($pkt_file);

Read the messages in a Fidonet/FTN packet. It is passed the name and path of a
Fidonet/FTN packet file. Returns the messages in the packet as a reference to an
array of hashes, which can be read as follows:

    for $i ( 0 .. $#{$messages} ) {

        print "On message $i";

        $msg_area = ${$messages}[i]{area};
        $msg_date = ${$messages}[i]{ftscdate};
        $msg_tonode = ${$messages}[i]{tonode};
        $msg_from = ${$messages}[i]{from};
        $msg_to = ${$messages}[i]{to};
        $msg_subj = ${$messages}[i]{subj};
        $msg_msgid = ${$messages}[i]{msgid};
        $msg_replyid = ${$messages}[i]{replyid};
        $msg_body = ${$messages}[i]{body};
        $msg_ctrl = ${$messages}[i]{ctrlinfo};

        # Processing of the contents of the message.

    }

=cut

###############################################
# Read Messages from FTN packet 
###############################################
sub read_ftn_packet {

    my ($packet_file) = @_;

    my ($packet_version,$origin_node,$destination_node,$origin_net,$destination_net,$attribute,$cost,$buffer);
    my ($separator, $s, $date_time, $to, $from, $subject, $area, @lines, @kludges, $PKT,
        $from_node, $to_node, @messages, $message_body, $message_id, $reply_id, $origin,
        $mailer, $seen_by, $i, $k);

    # "$PKT" is a file pointer to the packet file being read
    open( $PKT, q{<}, $packet_file ) or croak("Problem opening packet file: $packet_file");
    binmode($PKT);

    # Ignore packet header
    read($PKT,$buffer,58);

    while (!eof($PKT)) {

        last if (read($PKT, $buffer, 14) != 14);

        ($packet_version, $origin_node, $destination_node, $origin_net, $destination_net, $attribute, $cost) = unpack("SSSSSSS",$buffer);

        #  not used for anything yet - 8/26/01 rjc
        undef $packet_version;

        #  not used for anything yet - 8/26/01 rjc
        undef $attribute;

        #  not used for anything yet - 12/15/01 rjc 
        undef $cost;

        $separator = $/;
        local $/ = "\0";

        $date_time = <$PKT>;
        if (length($date_time) > 20) {
             $to = substr($date_time,20);
        } else {
            $to = <$PKT>;
        }
        $from = <$PKT>;
        $subject = <$PKT>;

        $to   =~ tr/\200-\377/\0-\177/;     # mask hi-bit characters
        $to   =~ tr/\0-\037/\040-\077/;     # mask control characters
        $from =~ tr/\200-\377/\0-\177/;     # mask hi-bit characters
        $from =~ tr/\0-\037/\040-\077/;     # mask control characters
        $subject =~ tr/\0-\037/\040-\077/;     # mask control characters

        $s = <$PKT>;
        local $/ = $separator;

        $s =~ s/\x8d/\r/g;
        @lines = split(/\r/,$s);

        undef $s;

        next if ($#lines < 0);

        $area = shift(@lines);
        $_ = $area;

        # default netmail area name
        $area ="NETMAIL" if /\//i;

        # strip "area:"
        $area =~ s/.*://;

        # Force upper case ???
        $area =~ tr/a-z/A-Z/;

        @kludges = ();

        for ($i = $k = 0; $i <= $#lines; $i++) {

            if ($lines[$i] =~ /^\001/) {
                $kludges[$k++] = splice(@lines,$i,1);
                redo;
            }
        }

        for (;;) {
            $_ = pop(@lines);
            last if ($_ eq "");
            if (/ \* origin: /i) {
                $origin = substr($_,11);
                last;
            }
        if (/---/) {
                $mailer = $_;
        }
            if (/seen-by/i) {
                $seen_by=$_;
            }
        }

        if ( ! $mailer ) {
            $mailer = "---";
        }

        if ($#lines < 0) {
            @lines = ("[empty message]");
        }

        # get message body, ensuring that it starts empty
        $message_body = "";

        foreach my $s (@lines) {
            $s =~ tr/\0-\037/\040-\077/;     # mask control characters
            $s =~ s/\s+$//;
            $s=~tr/^\*/ /;
            $message_body .= "$s\n";
        }

        $message_body .= "$mailer\n" if ($mailer);
        $message_body .= " * Origin: $origin\n" if ($origin);

        # get control info, ensuring that it starts empty
        my $control_info = "";
        $control_info .= "$seen_by\n" if ($seen_by);
        foreach my $c (@kludges) {
            $c =~ s/^\001//;

            # If kludge starts with "MSGID:", stick that in a special 
            # variable.
            if ( substr($c, 0, 6) eq "MSGID:" ) {
                $message_id = substr($c, 7);
            }

            $control_info .= "$c\n";
        }

        if ( ! $message_id) {
            $message_id = "message id not available";
        }

        # get replyid from kludges? same way as get seenby?
        $reply_id = "reply id not available";

        # need to pull zone num's from pkt instead of defaulting 1 
        $from_node =  "1:$origin_net/$origin_node\n";
        $to_node = "1:$destination_net/$destination_node\n";

        my %message_info = (

            area => $area,

            ftscdate => $date_time,

            ## not useing this yet...
            #cost => $cost,

            fromnode => $from_node,
            tonode => $to_node,

            from => $from,
            to => $to,
            subj => $subject,

            msgid => $message_id,
            replyid => $reply_id,

            body => $message_body,

            ctrlinfo => $control_info

            );

            push(@messages, \%message_info);

    }   # end while

    return \@messages;

}   # end sub read_ftn_packet


=head2 write_ftn_packet

Syntax:  write_ftn_packet($OutDir, \%packet_info, \@messages);

Create a Fidonet/FTN packet, where:
    $OutDir is the directory where the packet is to be created
    \%packet_info is a reference to a hash containing the packet header
    \@messages is reference to an array of references to hashes containing the messages.

=cut

sub write_ftn_packet {

    my ($OutDir, $packet_info, $messages) = @_;

    my ($packet_file, $PKT, @lines, $serialno, $buffer, $nmsgs, $i, $k, $message_ref);

    my $EOL = "\n\r";

    # This part is a definition of an FTN Packet format per FTS-0001

    # PKT Header; initialized variable are constants; last comments are
    #             in pack() notation

    # ${$packet_info}{origNode}                              # S
    # ${$packet_info}{destNode}                             # S
    my ($year, $month, $day, $hour, $minutes, $seconds);    # SSSSSS
    my $Baud = 0;                                           # S
    my $packet_version = 2;                                 # S   Type 2 packet
    # ${$packet_info}{origNet}                               # S
    # ${$packet_info}{destNet}                              # S
    my $ProdCode = 0x1CFF;                                  # S   product code = 1CFF
    # ${$packet_info}{PassWord}                             # a8
    # ${$packet_info}{origZone}                              # S
    # ${$packet_info}{destZone}                             # S
    my $AuxNet = ${$packet_info}{origNet};                   # S
    my $CapWord = 0x100;                                    # S   capability word: Type 2+
    my $ProdCode2 = 0;                                      # S   ?
    my $CapWord2 = 1;                                       # S   byte swapped cap. word
    # ${$packet_info}{origZone}                              # S   (repeat)
    # ${$packet_info}{destZone}                             # S   (repeat)
    # ${$packet_info}{origPoint}                             # S
    #  config file for node info?
    # ${$packet_info}{destPoint}                            # S
    my $ProdSpec = 0;                                       # L   ?

    # MSG Header; duplicated variables are shown as comments to indicate
    #             the MSG Header structure

    # $packet_version                                   # S   (repeat)
    # ${$packet_info}{origNode}                          # S   (repeat)
    # ${$packet_info}{destNode}                         # S   (repeat)
    # ${$packet_info}{origNet}                           # S   (repeat)
    # ${$packet_info}{destNet}                          # S   (repeat)
    my $attribute = 0;                                  # S
    my $Cost = 0;                                       # S
    # ${$message_ref}{DateTime}                         # a20 (this is a local())
    # ${$message_ref}{To}                               # a? (36 max)
    # ${$message_ref}{From}                             # a? (36 max)
    # ${$message_ref}{Subj}                             # a? (72 max)

    #"AREA: "                                           # c6          }
    # ${$packet_info}{Area}                             # a? (max?)   } all this is actually part
    #possible kludges go here. 0x01<TAG>0x0D            } of the TEXT postions
    #TEXT goes here. (ends with 2 0x0D's ???)           }

    # ${$packet_info}{TearLine}
    my $Origin = " * Origin: ${$packet_info}{Origin}  (${$packet_info}{origZone}:${$packet_info}{origNet}/${$packet_info}{origNode}.1)$EOL";
    my $seen_by = "SEEN-BY: ${$packet_info}{origNet}/${$packet_info}{origNode}$EOL";
    my $Path = "\1PATH: ${$packet_info}{origNet}/${$packet_info}{origNode}$EOL\0";          # note the \0 in $Path

    # repeat MSG Headers/TEXT

    # null (S) to mark done

    # this is where a loop would go if more than one feed

    # PKT name as per FTS
    ($seconds, $minutes, $hour, $day, $month, $year) = localtime();
    $year += 1900;

    $packet_file = sprintf("%s/%02d%02d%02d%02d.pkt",$OutDir,$day,$hour,$minutes,$seconds);

    open( $PKT, q{>}, "$packet_file" ) or croak('Cannot open FTN packet file for writing.');

    binmode($PKT);

    # write packet header
    $buffer = pack("SSSSSSSSSSSSSa8SSSSSSSSSSL",
               ${$packet_info}{origNode}, ${$packet_info}{destNode},
               $year, $month, $day, $hour, $minutes, $seconds,
               $Baud, $packet_version,
               ${$packet_info}{origNet}, ${$packet_info}{destNet},
               $ProdCode, ${$packet_info}{PassWord},
               ${$packet_info}{origZone}, ${$packet_info}{destZone}, $AuxNet,
               $CapWord, $ProdCode2, $CapWord2,
               ${$packet_info}{origZone}, ${$packet_info}{destZone},
               ${$packet_info}{origPoint}, ${$packet_info}{destPoint}, $ProdSpec);
    syswrite($PKT,$buffer,58);

    # needs to iterate over the array of hashes representing the messages
    foreach my $message_ref ( @{$messages} ) {
    #while ( @{$messages} > 0) {
    #while ( @{$messages} ) {

        ## get next message hash reference
        #$message_ref = pop(@{$messages});

        # get text body, translate LFs to CRs

        @lines = ${$message_ref}{Body};
        @lines = grep { s/\n/\r/ } @lines;

        # kill leading blank lines

        shift(@lines) while ($lines[0] eq "\n");

        # informative only
        ++$nmsgs;

        # write message to $PKT file

        # Write Message Header	
        $buffer = pack("SSSSSSSa20",
                $packet_version,${$packet_info}{origNode},${$packet_info}{destNode},${$packet_info}{origNet},
                ${$packet_info}{destNet},$attribute,$Cost,${$message_ref}{DateTime});
        print $PKT $buffer;

        print $PKT "${$message_ref}{To}\0";
        print $PKT "${$message_ref}{From}\0";
        print $PKT "${$message_ref}{Subj}\0";
        print $PKT "AREA: ${$packet_info}{Area}$EOL";         # note: CR not nul

        $serialno = unpack("%16C*",join('',@lines));
        $serialno = sprintf("%lx",$serialno + time);
        print $PKT "\1MSGID: ${$packet_info}{origZone}:${$packet_info}{origNet}/${$packet_info}{origNode}.${$packet_info}{origPoint} $serialno$EOL";

        print $PKT @lines; 
        print $PKT $EOL,${$packet_info}{TearLine},$Origin,$seen_by,$Path;

        # all done with array (frees mem?)
        @lines = ();

    }

    # indicates no more messages
    print $PKT "\0\0";

    close($PKT);

    return 0;
}

1;
__END__

=head1 EXAMPLES

  use FTN:Packet;
  To be added...

=head1 AUTHORS

Robert James Clay, jame@rocasa.us

=head1 BUGS

Please report any bugs or feature requests via the web interface at
L<<http://sourceforge.net/p/ftnpl/ftn-packet/tickets/>. I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

Note that you can also report any bugs or feature requests to
C<bug-ftn-packet at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FTN-Packet>;
however, the FTN-Packet Issue tracker is preferred.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FTN::Packet

You can also look for information at:

=over 4

=item * FTN::Packet issue tracker

L<http://sourceforge.net/p/ftnpl/ftn-packet/tickets/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FTN-Packet>

=item * Search CPAN

L<http://search.cpan.org/dist/FTN-Packet/>

=back

=head1 ACKNOWLEDGEMENTS

Code for the read_ftn_packet function was initially derived from the newmsgs subroutine
in the set of scripts for reading FTN packets (pkt2txt.pl, pkt2xml.pl, etc) by
Russ Johnson L<mailto:airneil@users.sf.net> and Robert James Clay L<mailto:jame@rocasa.us>
available at the L<http://ftnpl.sourceforge.net>] project site. Initial code for
the write_ftn_packet function was derived from the bbs2pkt.pl of v0.1 of the bbsdbpl
scripts, also at the SourceForge project.

=head1 REPOSITORIES

L<http://sourceforge.net/p/ftnpl/ftn-packet/code>
L<https://github.com/ftnpl/FTN-Packet>

=head1 SEE ALSO

 L<FTN::Packet::Examples>, L<FTN::Packet::ToDo>, L<FTSCPROD.016>,
 L<FTS-0001.016|http://www.ftsc.org/docs/fts-0001.016>


=head1 COPYRIGHT & LICENSE

Copyright 2001-2014 Robert James Clay, all rights reserved.
Copyright 2001-2003 Russ Johnson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

