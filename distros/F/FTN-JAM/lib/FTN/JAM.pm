# FTN::JAM

package FTN::JAM;

use warnings;
use strict;

use Carp;
use Time::Local;
use Time::Zone;

=head1 NAME

FTN::JAM - A Perl extension for handleing JAM messagebases.

=head1 VERSION

Version 0.30

=cut

our $VERSION = '0.30';

=head1 SYNOPSIS

This module can be used for operations related to JAM messagebases, including the following:
creating or removing a messagebase, listing the contents of a messagebase, adding a
message to a messagebase, reading a message in a messagebase, changing a message in a 
messagebase, or finding a user in a messagebase.

Here is an example of how it can being used:

    use FTN::JAM;

    my $mb = $ARGV[0];
    my $basemsgnum = $ARGV[1];

    my $handle = FTN::JAM::CreateMB($mb,$basemsgnum);

    FTN::JAM::CloseMB($handle);
    ...


=head1 EXPORT

The following functions are available in the module:  OpenMB, CreateMB, CloseMB,
RemoveMB, LockMB, UnlockMB, ReadMBHeader, WriteMBHeader, GetMBSize, ReadMessage,
ChangeMessage, AddMessage, Crc32, FindUser, GetLastRead, SetLastRead, TimeToLocal,
and LocalToTime.

The global variable $Errnum is used for returning error numbers from functions 
and can be accessed as $FTN::JAM::Errnum. It defaults to undefined.

=cut

our $Errnum;

=head1 FUNCTIONS

=head2 OpenMB

Syntax: $handle = FTN::JAM::OpenMB($jampath)

=cut

sub OpenMB {

    my ($jampath) = @_ or croak 'OpenMB requires a base file name and path as a parameter.';

    my ($JHR, $JDX, $JDT, $JLR);

    my $jhrres = open( $JHR, q{+<}, $jampath . ".jhr" );
    my $jdxres = open( $JDX, q{+<}, $jampath . ".jdx" );
    my $jdtres = open( $JDT, q{+<}, $jampath . ".jdt" );
    my $jlrres = open( $JLR, q{+<}, $jampath . ".jlr" );

    if ( !$jhrres || !$jdxres || !$jdtres || !$jlrres ) {
        if ($jhrres) {
            close($JHR);
        }
        if ($jdxres) {
            close($JDX);
        }
        if ($jdtres) {
            close($JDT);
        }
        if ($jlrres) {
            close($JLR);
        }

        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    binmode($JHR);
    binmode($JDX);
    binmode($JDT);
    binmode($JLR);

    my $old;

    $old = select($JHR);
    local $|   = 1;
    select($old);
    $old = select($JDX);
    local $|   = 1;
    select($old);
    $old = select($JDT);
    local $|   = 1;
    select($old);
    $old = select($JLR);
    local $|   = 1;
    select($old);

    my %filehash;

    $filehash{jhr} = *$JHR;
    $filehash{jdx} = *$JDX;
    $filehash{jdt} = *$JDT;
    $filehash{jlr} = *$JLR;

    return \%filehash;
}

=head2 CreateMB

Syntax: $handle = FTN::JAM::CreateMB($jampath,$basemsg)

=cut

sub CreateMB {
    if ( $#_ != 1 ) {
        croak "Wrong number of arguments for FTN::JAM::CreateMB";
    }

    my $jampath = $_[0];
    my $basemsg = $_[1];

    my $hasjdx = ( -e $jampath . ".jdx" );
    my $hasjhr = ( -e $jampath . ".jhr" );
    my $hasjdt = ( -e $jampath . ".jdt" );
    my $hasjlr = ( -e $jampath . ".jlr" );

    if ( $hasjdx or $hasjhr or $hasjdt or $hasjlr ) {
        $Errnum = $FTN::JAM::Errnum::BASE_EXISTS;
        return;
    }

    my ($JHR, $JDX, $JDT, $JLR);

    my $jhrres = open( $JHR, q{+>}, $jampath . ".jhr" );
    my $jdxres = open( $JDX, q{+>}, $jampath . ".jdx" );
    my $jdtres = open( $JDT, q{+>}, $jampath . ".jdt" );
    my $jlrres = open( $JLR, q{+>}, $jampath . ".jlr" );

    if ( !$jhrres || !$jdxres || !$jdtres || !$jlrres ) {
        if ($jhrres) {
            close($JHR);
        }
        if ($jdxres) {
            close($JDX);
        }
        if ($jdtres) {
            close($JDT);
        }
        if ($jlrres) {
            close($JLR);
        }

        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    binmode($JHR);
    binmode($JDX);
    binmode($JDT);
    binmode($JLR);

    my $old;

    $old = select($JHR);
    local $|   = 1;
    select($old);
    $old = select($JDX);
    local $|   = 1;
    select($old);
    $old = select($JDT);
    local $|   = 1;
    select($old);
    $old = select($JLR);
    local $|   = 1;
    select($old);

    my %filehash;

    $filehash{jhr} = *$JHR;
    $filehash{jdx} = *$JDX;
    $filehash{jdt} = *$JDT;
    $filehash{jlr} = *$JLR;

    my %header;

    $header{DateCreated} = TimeToLocal(time);
    $header{PasswordCRC} = 0xffffffff;
    $header{BaseMsgNum}  = $basemsg;

    if ( !LockMB( \%filehash, 0 ) ) {
        CloseMB( \%filehash );
        return;
    }

    if ( !WriteMBHeader( \%filehash, \%header ) ) {
        CloseMB( \%filehash );
        return;
    }

    UnlockMB( \%filehash );

    return \%filehash;
}

=head2 CloseMB

Syntax: FTN::JAM::CloseMB($handle)

=cut

sub CloseMB {

    my ($handleref) = @_ or croak 'CloseMB requires a hash reference parameter.';

    close( $$handleref{jdx} ) or croak "Unable to close: $!";
    close( $$handleref{jhr} ) or croak "Unable to close: $!";
    close( $$handleref{jdt} ) or croak "Unable to close: $!";
    close( $$handleref{jlr} ) or croak "Unable to close: $!";

    return 1;
}

=head2 RemoveMB

Syntax: FTN::JAM::RemoveMB($jampath)

=cut

sub RemoveMB {

    my ($jampath) = @_ or croak 'RemoveMB requires a base file name and path as a parameter.';

    my $hasjdx = ( -e $jampath . ".jdx" );
    my $hasjhr = ( -e $jampath . ".jhr" );
    my $hasjdt = ( -e $jampath . ".jdt" );
    my $hasjlr = ( -e $jampath . ".jlr" );

    if ($hasjdx) {
        if ( !unlink( $jampath . ".jdx" ) ) {
            $Errnum = $FTN::JAM::Errnum::IO_ERROR;
            return;
        }
    }

    if ($hasjhr) {
        if ( !unlink( $jampath . ".jhr" ) ) {
            $Errnum = $FTN::JAM::Errnum::IO_ERROR;
            return;
        }
    }

    if ($hasjdt) {
        if ( !unlink( $jampath . ".jdt" ) ) {
            $Errnum = $FTN::JAM::Errnum::IO_ERROR;
            return;
        }
    }

    if ($hasjlr) {
        if ( !unlink( $jampath . ".jlr" ) ) {
            $Errnum = $FTN::JAM::Errnum::IO_ERROR;
            return;
        }
    }

    return 1;
}

=head2 LockMB

Syntax: $success = FTN::JAM::LockMB($handle,$timeout)

=cut

sub LockMB {
    if ( $#_ != 1 ) {
        croak "Wrong number of arguments for FTN::JAM::LockMB";
    }

    my $handleref = $_[0];
    my $timeout   = $_[1];

    if ( $$handleref{locked} ) {
        return 1;
    }

    if ( flock( $$handleref{jhr}, 6 ) ) {
        $$handleref{locked} = 1;
        return 1;
    }

    for ( my $i = 0 ; $i < $timeout ; $i++ ) {
        sleep(1);

        if ( flock( $$handleref{jhr}, 6 ) ) {
            $$handleref{locked} = 1;
            return 1;
        }
    }

    $Errnum = $FTN::JAM::Errnum::BASE_NOT_LOCKED;
    return;
}

=head2 UnlockMB

Syntax: FTN::JAM::UnlockMB($handle)

=cut

sub UnlockMB {

    my ($handleref) = @_ or croak 'UnlockMB requires a reference to a file hash as a parameter.';

    if ( $$handleref{locked} ) {
        flock( $$handleref{jhr}, 8 );
        delete $$handleref{locked};
    }
    return 1;
}

=head2 ReadMBHeader

Syntax: $success = FTN::JAM::ReadMBHeader($handle,\%header)

=cut

sub ReadMBHeader {
    if ( $#_ != 1 ) {
        croak "Wrong number of arguments for FTN::JAM::ReadMBHeader";
    }

    my $handleref = $_[0];
    my $headerref = $_[1];

    my $buf;
    my @data;

    if ( !seek( $$handleref{jhr}, 0, 0 ) ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    if ( read( $$handleref{jhr}, $buf, 1024 ) != 1024 ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    @data = unpack( "Z[4]LLLLL", $buf );

    if ( $data[0] ne "JAM" ) {
        $Errnum = $FTN::JAM::Errnum::BASEHEADER_CORRUPT;
        return;
    }

    %$headerref = ();

    $$headerref{Signature}   = $data[0];
    $$headerref{DateCreated} = $data[1];
    $$headerref{ModCounter}  = $data[2];
    $$headerref{ActiveMsgs}  = $data[3];
    $$headerref{PasswordCRC} = $data[4];
    $$headerref{BaseMsgNum}  = $data[5];

    return 1;
}

=head2 WriteMBHeader

Syntax: $success = FTN::JAM::WriteMBHeader($handle,\%header) 

=cut

sub WriteMBHeader {
    if ( $#_ != 1 ) {
        croak "Wrong number of arguments for FTN::JAM::WriteMBHeader";
    }

    my $handleref = $_[0];
    my $headerref = $_[1];

    if ( !defined( $$headerref{DateCreated} ) ) {
        $$headerref{DateCreated} = 0;
    }
    if ( !defined( $$headerref{ModCounter} ) ) { $$headerref{ModCounter} = 0; }
    if ( !defined( $$headerref{ActiveMsgs} ) ) { $$headerref{ActiveMsgs} = 0; }
    if ( !defined( $$headerref{PasswordCRC} ) ) {
        $$headerref{PasswordCRC} = 0;
    }
    if ( !defined( $$headerref{BaseMsgNum} ) ) { $$headerref{BaseMsgNum} = 0; }

    if ( !$$handleref{locked} ) {
        $Errnum = $FTN::JAM::Errnum::BASE_NOT_LOCKED;
        return;
    }

    $$headerref{Signature} = "JAM";
    $$headerref{ModCounter}++;

    if ( !seek( $$handleref{jhr}, 0, 0 ) ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    my $printres = print { $$handleref{jhr} } pack(
        "Z[4]LLLLLx[1000]",
        $$headerref{Signature},   $$headerref{DateCreated},
        $$headerref{ModCounter},  $$headerref{ActiveMsgs},
        $$headerref{PasswordCRC}, $$headerref{BaseMsgNum}
    );

    if ( !$printres ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    return 1;
}

=head2 GetMBSize

Syntax: $success = FTN::JAM::GetMBSize($handle,\$num)

=cut

sub GetMBSize {
    if ( $#_ != 1 ) {
        croak "Wrong number of arguments for FTN::JAM::GetMBSize";
    }

    my $handleref = $_[0];
    my $numref    = $_[1];

    my $buf;
    my @data;

    if ( !seek( $$handleref{jdx}, 0, 2 ) ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    my $offset = tell( $$handleref{jdx} );

    if ( $offset == -1 ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    $$numref = $offset / 8;

    return 1;
}

=head2 ReadMessage

Syntax: $success = FTN::JAM::ReadMessage($handle,$msgnum,\%header,\@subfields,\$text)

=cut

sub ReadMessage {
    if ( $#_ != 4 ) {
        croak "Wrong number of arguments for FTN::JAM::ReadMessage";
    }

    my $handleref    = $_[0];
    my $msgnum       = $_[1];
    my $headerref    = $_[2];
    my $subfieldsref = $_[3];
    my $textref      = $_[4];

    my $buf;
    my @data;
    my %mbheader;

    if ( !ReadMBHeader( $handleref, \%mbheader ) ) {
        return;
    }

    if ( !seek( $$handleref{jdx}, ( $msgnum - $mbheader{BaseMsgNum} ) * 8, 0 ) )
    {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    if ( read( $$handleref{jdx}, $buf, 8 ) != 8 ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    @data = unpack( "LL", $buf );

    if ( $data[0] == 0xffffffff and $data[1] == 0xffffffff ) {
        $Errnum = $FTN::JAM::Errnum::MSG_DELETED;
        return;
    }

    if ( !seek( $$handleref{jhr}, $data[1], 0 ) ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    if ( read( $$handleref{jhr}, $buf, 76 ) != 76 ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    @data = unpack( "Z[4]SSLLLLLLLLLLLLLLLLL", $buf );

    if ( $data[0] ne "JAM" ) {
        $Errnum = $FTN::JAM::Errnum::MSGHEADER_CORRUPT;
        return;
    }

    if ( $data[1] != 1 ) {
        $Errnum = $FTN::JAM::Errnum::MSGHEADER_UNKNOWN;
        return;
    }

    %$headerref = ();

    $$headerref{Signature}     = $data[0];
    $$headerref{Revision}      = $data[1];
    $$headerref{ReservedWord}  = $data[2];
    $$headerref{SubfieldLen}   = $data[3];
    $$headerref{TimesRead}     = $data[4];
    $$headerref{MsgIdCRC}      = $data[5];
    $$headerref{ReplyCRC}      = $data[6];
    $$headerref{ReplyTo}       = $data[7];
    $$headerref{Reply1st}      = $data[8];
    $$headerref{ReplyNext}     = $data[9];
    $$headerref{DateWritten}   = $data[10];
    $$headerref{DateReceived}  = $data[11];
    $$headerref{DateProcessed} = $data[12];
    $$headerref{MsgNum}        = $data[13];
    $$headerref{Attributes}    = $data[14];
    $$headerref{Attributes2}   = $data[15];
    $$headerref{TxtOffset}     = $data[16];
    $$headerref{TxtLen}        = $data[17];
    $$headerref{PasswordCRC}   = $data[18];
    $$headerref{Cost}          = $data[19];

    if ($subfieldsref) {
        if (
            read( $$handleref{jhr}, $buf, $$headerref{SubfieldLen} ) !=
            $$headerref{SubfieldLen} )
        {
            $Errnum = $FTN::JAM::Errnum::IO_ERROR;
            return;
        }

        @$subfieldsref = ();

        while ($buf) {
            @data = unpack( "LL", $buf );
            push( @$subfieldsref, $data[0] );
            push( @$subfieldsref, substr( $buf, 8, $data[1] ) );
            $buf = substr( $buf, 8 + $data[1] );
        }
    }

    if ($textref) {
        if ( !seek( $$handleref{jdt}, $$headerref{TxtOffset}, 0 ) ) {
            $Errnum = $FTN::JAM::Errnum::IO_ERROR;
            return;
        }

        if (
            read( $$handleref{jdt}, $$textref, $$headerref{TxtLen} ) !=
            $$headerref{TxtLen} )
        {
            $Errnum = $FTN::JAM::Errnum::IO_ERROR;
            return;
        }
    }

    return 1;
}

=head2 ChangeMessage

Syntax: $success = FTN::JAM::ChangeMessage($handle,$msgnum,\%header)

=cut

sub ChangeMessage {
    if ( $#_ != 2 ) {
        croak "Wrong number of arguments for FTN::JAM::ChangeMessage";
    }

    my $handleref = $_[0];
    my $msgnum    = $_[1];
    my $headerref = $_[2];

    if ( !defined( $$headerref{Signature} ) ) {
        $$headerref{Signature} = "JAM";
    }
    if ( !defined( $$headerref{Revision} ) ) { $$headerref{Revision} = 1; }
    if ( !defined( $$headerref{ReservedWord} ) ) {
        $$headerref{ReservedWord} = 0;
    }
    if ( !defined( $$headerref{SubfieldLen} ) ) {
        $$headerref{SubfieldLen} = 0;
    }
    if ( !defined( $$headerref{TimesRead} ) ) { $$headerref{TimesRead} = 0; }
    if ( !defined( $$headerref{MsgIdCRC} ) ) {
        $$headerref{MsgIdCRC} = 0xffffffff;
    }
    if ( !defined( $$headerref{ReplyCRC} ) ) {
        $$headerref{ReplyCRC} = 0xffffffff;
    }
    if ( !defined( $$headerref{ReplyTo} ) )   { $$headerref{ReplyTo}   = 0; }
    if ( !defined( $$headerref{Reply1st} ) )  { $$headerref{Reply1st}  = 0; }
    if ( !defined( $$headerref{ReplyNext} ) ) { $$headerref{ReplyNext} = 0; }
    if ( !defined( $$headerref{DateWritten} ) ) {
        $$headerref{DateWritten} = 0;
    }
    if ( !defined( $$headerref{DateReceived} ) ) {
        $$headerref{DateReceived} = 0;
    }
    if ( !defined( $$headerref{DateProcessed} ) ) {
        $$headerref{DateProcessed} = 0;
    }
    if ( !defined( $$headerref{MsgNum} ) )     { $$headerref{MsgNum}     = 0; }
    if ( !defined( $$headerref{Attributes} ) ) { $$headerref{Attributes} = 0; }
    if ( !defined( $$headerref{Attributes2} ) ) {
        $$headerref{Attributes2} = 0;
    }
    if ( !defined( $$headerref{TxtOffset} ) ) { $$headerref{TxtOffset} = 0; }
    if ( !defined( $$headerref{TxtLen} ) )    { $$headerref{TxtLen}    = 0; }
    if ( !defined( $$headerref{PasswordCRC} ) ) {
        $$headerref{PasswordCRC} = 0xffffffff;
    }
    if ( !defined( $$headerref{Cost} ) ) { $$headerref{Cost} = 0; }

    if ( !$$handleref{locked} ) {
        $Errnum = $FTN::JAM::Errnum::BASE_NOT_LOCKED;
        return;
    }

    my $buf;
    my @data;
    my %mbheader;

    if ( !ReadMBHeader( $handleref, \%mbheader ) ) {
        return;
    }

    if ( ( $$headerref{Attributes} & $FTN::JAM::Attr::DELETED ) ) {
        my %oldheader;

        if ( !ReadMessage( $handleref, $msgnum, \%oldheader, 0, 0 ) ) {
            return;
        }

        if ( !( $oldheader{Attributes} & $FTN::JAM::Attr::DELETED ) ) {
            if ( $mbheader{ActiveMsgs} ) {
                $mbheader{ActiveMsgs}--;
            }
        }
    }

    if ( !seek( $$handleref{jdx}, ( $msgnum - $mbheader{BaseMsgNum} ) * 8, 0 ) )
    {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    if ( read( $$handleref{jdx}, $buf, 8 ) != 8 ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    @data = unpack( "LL", $buf );

    if ( !seek( $$handleref{jhr}, $data[1], 0 ) ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    my $printres = print { $$handleref{jhr} } pack(
        "Z[4]SSLLLLLLLLLLLLLLLLL",
        $$headerref{Signature},     $$headerref{Revision},
        $$headerref{ReservedWord},  $$headerref{SubfieldLen},
        $$headerref{TimesRead},     $$headerref{MsgIdCRC},
        $$headerref{ReplyCRC},      $$headerref{ReplyTo},
        $$headerref{Reply1st},      $$headerref{ReplyNext},
        $$headerref{DateWritten},   $$headerref{DateReceived},
        $$headerref{DateProcessed}, $$headerref{MsgNum},
        $$headerref{Attributes},    $$headerref{Attributes2},
        $$headerref{TxtOffset},     $$headerref{TxtLen},
        $$headerref{PasswordCRC},   $$headerref{Cost}
    );

    if ( !$printres ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    if ( !WriteMBHeader( $handleref, \%mbheader ) ) {
        return;
    }

    return 1;
}

=head2 AddMessage

Syntax: $success = FTN::JAM::AddMessage($handle,\%header,\@subfields,\$text)

=cut

sub AddMessage {
    if ( $#_ != 3 ) {
        croak "Wrong number of arguments for FTN::JAM::AddMessage";
    }

    my $handleref    = $_[0];
    my $headerref    = $_[1];
    my $subfieldsref = $_[2];
    my $textref      = $_[3];

    my %mbheader;
    my $printres;

    if ( !$headerref ) {
        if ( !ReadMBHeader( $handleref, \%mbheader ) ) {
            return;
        }

        if ( !seek( $$handleref{jdx}, 0, 2 ) ) {
            $Errnum = $FTN::JAM::Errnum::IO_ERROR;
            return;
        }

        my $jdxoffset = tell( $$handleref{jdx} );

        if ( $jdxoffset == -1 ) {
            $Errnum = $FTN::JAM::Errnum::IO_ERROR;
            return;
        }

        print { $$handleref{jdx} } pack( "LL", 0xffffffff, 0xffffffff );

        if ( !$printres ) {
            $Errnum = $FTN::JAM::Errnum::IO_ERROR;
            return;
        }

        return $jdxoffset / 8 + $mbheader{BaseMsgNum};
    }

    if ( !defined( $$headerref{Signature} ) ) {
        $$headerref{Signature} = "JAM";
    }
    if ( !defined( $$headerref{Revision} ) ) { $$headerref{Revision} = 1; }
    if ( !defined( $$headerref{ReservedWord} ) ) {
        $$headerref{ReservedWord} = 0;
    }
    if ( !defined( $$headerref{SubfieldLen} ) ) {
        $$headerref{SubfieldLen} = 0;
    }
    if ( !defined( $$headerref{TimesRead} ) ) { $$headerref{TimesRead} = 0; }
    if ( !defined( $$headerref{MsgIdCRC} ) ) {
        $$headerref{MsgIdCRC} = 0xffffffff;
    }
    if ( !defined( $$headerref{ReplyCRC} ) ) {
        $$headerref{ReplyCRC} = 0xffffffff;
    }
    if ( !defined( $$headerref{ReplyTo} ) )   { $$headerref{ReplyTo}   = 0; }
    if ( !defined( $$headerref{Reply1st} ) )  { $$headerref{Reply1st}  = 0; }
    if ( !defined( $$headerref{ReplyNext} ) ) { $$headerref{ReplyNext} = 0; }
    if ( !defined( $$headerref{DateWritten} ) ) {
        $$headerref{DateWritten} = 0;
    }
    if ( !defined( $$headerref{DateReceived} ) ) {
        $$headerref{DateReceived} = 0;
    }
    if ( !defined( $$headerref{DateProcessed} ) ) {
        $$headerref{DateProcessed} = 0;
    }
    if ( !defined( $$headerref{MsgNum} ) )     { $$headerref{MsgNum}     = 0; }
    if ( !defined( $$headerref{Attributes} ) ) { $$headerref{Attributes} = 0; }
    if ( !defined( $$headerref{Attributes2} ) ) {
        $$headerref{Attributes2} = 0;
    }
    if ( !defined( $$headerref{TxtOffset} ) ) { $$headerref{TxtOffset} = 0; }
    if ( !defined( $$headerref{TxtLen} ) )    { $$headerref{TxtLen}    = 0; }
    if ( !defined( $$headerref{PasswordCRC} ) ) {
        $$headerref{PasswordCRC} = 0xffffffff;
    }
    if ( !defined( $$headerref{Cost} ) ) { $$headerref{Cost} = 0; }

    if ( !$$handleref{locked} ) {
        $Errnum = $FTN::JAM::Errnum::BASE_NOT_LOCKED;
        return;
    }

    my $buf;
    my @data;

    if ( !ReadMBHeader( $handleref, \%mbheader ) ) {
        return;
    }

    $$headerref{TxtOffset} = 0;
    $$headerref{TxtLen}    = 0;

    if ( $textref and length($$textref) ) {
        if ( !seek( $$handleref{jdt}, 0, 2 ) ) {
            $Errnum = $FTN::JAM::Errnum::IO_ERROR;
            return;
        }

        my $jdtoffset = tell( $$handleref{jdt} );

        if ( $jdtoffset == -1 ) {
            $Errnum = $FTN::JAM::Errnum::IO_ERROR;
            return;
        }

        $$headerref{TxtOffset} = $jdtoffset;
        $$headerref{TxtLen}    = length($$textref);

        $printres = print { $$handleref{jdt} } $$textref;

        if ( !$printres ) {
            $Errnum = $FTN::JAM::Errnum::IO_ERROR;
            return;
        }
    }

    $$headerref{SubfieldLen} = 0;
    $$headerref{MsgIdCRC}    = 0xffffffff;
    $$headerref{ReplyCRC}    = 0xffffffff;
    my $usercrc = 0xffffffff;

    for ( my $i = 0 ; $i <= $#$subfieldsref ; $i = $i + 2 ) {
        if ( $$subfieldsref[$i] == $FTN::JAM::Subfields::RECVRNAME ) {
            $usercrc = Crc32( $$subfieldsref[ $i + 1 ] );
        }

        if ( $$subfieldsref[$i] == $FTN::JAM::Subfields::MSGID ) {
            $$headerref{MsgIdCRC} = Crc32( $$subfieldsref[ $i + 1 ] );
        }

        if ( $$subfieldsref[$i] == $FTN::JAM::Subfields::REPLYID ) {
            $$headerref{ReplyCRC} = Crc32( $$subfieldsref[ $i + 1 ] );
        }

        $$headerref{SubfieldLen} += 8 + length( $$subfieldsref[ $i + 1 ] );
    }

    if ( !seek( $$handleref{jdx}, 0, 2 ) ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    my $jdxoffset = tell( $$handleref{jdx} );

    if ( $jdxoffset == -1 ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    $$headerref{MsgNum}    = $jdxoffset / 8 + $mbheader{BaseMsgNum};
    $$headerref{Signature} = "JAM";
    $$headerref{Revision}  = 1;

    if ( !seek( $$handleref{jhr}, 0, 2 ) ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    my $jhroffset = tell( $$handleref{jhr} );

    if ( $jhroffset == -1 ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    $printres = print { $$handleref{jhr} } pack(
        "Z[4]SSLLLLLLLLLLLLLLLLL",
        $$headerref{Signature},     $$headerref{Revision},
        $$headerref{ReservedWord},  $$headerref{SubfieldLen},
        $$headerref{TimesRead},     $$headerref{MsgIdCRC},
        $$headerref{ReplyCRC},      $$headerref{ReplyTo},
        $$headerref{Reply1st},      $$headerref{ReplyNext},
        $$headerref{DateWritten},   $$headerref{DateReceived},
        $$headerref{DateProcessed}, $$headerref{MsgNum},
        $$headerref{Attributes},    $$headerref{Attributes2},
        $$headerref{TxtOffset},     $$headerref{TxtLen},
        $$headerref{PasswordCRC},   $$headerref{Cost}
    );

    if ( !$printres ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    for ( my $i = 0 ; $i <= $#$subfieldsref ; $i = $i + 2 ) {
        $printres =
          print { $$handleref{jhr} }
          pack( "LL", $$subfieldsref[$i], length( $$subfieldsref[ $i + 1 ] ) ),
          $$subfieldsref[ $i + 1 ];

        if ( !$printres ) {
            $Errnum = $FTN::JAM::Errnum::IO_ERROR;
            return;
        }
    }

    $printres = print { $$handleref{jdx} } pack( "LL", $usercrc, $jhroffset );

    if ( !$printres ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    if ( !( $$headerref{Attributes} & $FTN::JAM::Attr::DELETED ) ) {
        $mbheader{ActiveMsgs}++;
    }

    if ( !FTN::JAM::WriteMBHeader( $handleref, \%mbheader ) ) {
        return;
    }

    return $$headerref{MsgNum};
}

=head2 Crc32

Syntax: $crc32 = FTN::JAM::Crc32($data)

=cut

sub Crc32 {

    my ($data) = @_ or croak 'Crc32 requires the data to be checked as a parameter.';

    my $crc;
    my @table;
    my $i;
    my $j;

    for ( $i = 0 ; $i < 256 ; $i++ ) {
        $crc = $i;

        for ( $j = 8 ; $j > 0 ; $j-- ) {
            if ( $crc & 1 ) {
                $crc = ( $crc >> 1 ) ^ 0xedb88320;
            }
            else {
                $crc >>= 1;
            }
        }

        $table[$i] = $crc;
    }

    $crc = 0xffffffff;

    for ( $i = 0 ; $i < length($data) ; $i++ ) {
        $crc =
          ( ( $crc >> 8 ) & 0x00ffffff )
          ^ $table[ ( $crc ^ ord( lc( substr( $data, $i, 1 ) ) ) ) & 0xff ];
    }

    return $crc;
}

=head2 FindUser

Syntax: $msgnum = FTN::JAM::FindUser($handle,$usercrc,$start)

=cut

sub FindUser {
    if ( $#_ != 2 ) {
        croak "Wrong number of arguments for FTN::JAM::FindUser";
    }

    my $handleref = $_[0];
    my $usercrc   = $_[1];
    my $start     = $_[2];

    my %mbheader;

    if ( !ReadMBHeader( $handleref, \%mbheader ) ) {
        return;
    }

    if ( !seek( $$handleref{jdx}, ( $start - $mbheader{BaseMsgNum} ) * 8, 0 ) )
    {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    my $msgnum = $start;

    my $buf;
    my @data;

    while (1) {
        if ( read( $$handleref{jdx}, $buf, 8 ) != 8 ) {
            if ( eof( $$handleref{jdx} ) ) {
                $Errnum = $FTN::JAM::Errnum::USER_NOT_FOUND;
            }
            else {
                $Errnum = $FTN::JAM::Errnum::IO_ERROR;
            }

            return;
        }

        @data = unpack( "LL", $buf );

        if ( $data[0] == $usercrc ) {
            return $msgnum;
        }

        $msgnum++;
    }
    return;
}

=head2 GetLastRead

Syntax: $success = FTN::JAM::GetLastRead($handle,$usernum,\%lastread)

=cut

sub GetLastRead {
    if ( $#_ != 2 ) {
        croak "Wrong number of arguments for FTN::JAM::GetLastRead";
    }

    my $handleref   = $_[0];
    my $usernum     = $_[1];
    my $lastreadref = $_[2];

    if ( !seek( $$handleref{jlr}, 0, 0 ) ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    my $buf;
    my @data;

    while ( read( $$handleref{jlr}, $buf, 16 ) == 16 ) {
        @data = unpack( "LLLL", $buf );

        if ( $data[1] == $usernum ) {
            %$lastreadref = ();

            $$lastreadref{UserCRC}     = $data[0];
            $$lastreadref{UserID}      = $data[1];
            $$lastreadref{LastReadMsg} = $data[2];
            $$lastreadref{HighReadMsg} = $data[3];

            return 1;
        }
    }

    if ( eof( $$handleref{jlr} ) ) {
        $Errnum = $FTN::JAM::Errnum::USER_NOT_FOUND;
    }
    else {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
    }

    return;
}

=head2 SetLastRead

Syntax: $success = FTN::JAM::SetLastRead($handle,$usernum,/%lastread)

=cut

sub SetLastRead {
    if ( $#_ != 2 ) {
        croak "Wrong number of arguments for FTN::JAM::SetLastRead";
    }

    my $handleref   = $_[0];
    my $usernum     = $_[1];
    my $lastreadref = $_[2];

    if ( !defined( $$lastreadref{UserCRC} ) ) { $$lastreadref{UserCRC} = 0; }
    if ( !defined( $$lastreadref{UserID} ) )  { $$lastreadref{UserID}  = 0; }
    if ( !defined( $$lastreadref{LastReadMsg} ) ) {
        $$lastreadref{LastReadMsg} = 0;
    }
    if ( !defined( $$lastreadref{HighReadMsg} ) ) {
        $$lastreadref{HighReadMsg} = 0;
    }

    if ( !seek( $$handleref{jlr}, 0, 0 ) ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    my $buf;
    my @data;

    while ( read( $$handleref{jlr}, $buf, 16 ) == 16 ) {
        @data = unpack( "LLLL", $buf );

        if ( $data[1] == $usernum ) {
            if ( !seek( $$handleref{jlr}, -16, 1 ) ) {
                $Errnum = $FTN::JAM::Errnum::IO_ERROR;
                return;
            }

            my $printres = print { $$handleref{jlr} } pack( "LLLL",
                $$lastreadref{UserCRC},     $$lastreadref{UserID},
                $$lastreadref{LastReadMsg}, $$lastreadref{HighReadMsg} );

            if ( !$printres ) {
                $Errnum = $FTN::JAM::Errnum::IO_ERROR;
                return;
            }

            return 1;
        }
    }

    if ( !eof( $$handleref{jlr} ) ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
    }

    my $printres = print { $$handleref{jlr} } pack( "LLLL",
        $$lastreadref{UserCRC},     $$lastreadref{UserID},
        $$lastreadref{LastReadMsg}, $$lastreadref{HighReadMsg} );

    if ( !$printres ) {
        $Errnum = $FTN::JAM::Errnum::IO_ERROR;
        return;
    }

    return 1;
}

=head2 TimeToLocal

Syntax $local = FTN::JAM::TimeToLocal($time)

=cut

sub TimeToLocal {
    if ( $#_ != 0 ) {
        croak "Wrong number of arguments for FTN::JAM::TimeToLocal";
    }

    return $_[0] - timegm( 0, 0, 0, 1, 0, 70 ) + tz_local_offset();
}

=head2 LocalToTime

Syntax $time = FTN::JAM::LocalToTime($local)

=cut

sub LocalToTime {
    if ( $#_ != 0 ) {
        croak "Wrong number of arguments for FTN::JAM::LocalToTime";
    }

    return $_[0] + timegm( 0, 0, 0, 1, 0, 70 ) - tz_local_offset();
}

=head1 AUTHOR

Robert James Clay, C<< <jame at rocasa.us> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ftn-jam at rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ftn-jam>.  I will be notified, and
then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FTN::JAM

You can also look for information at:

=over 4

=item * FTN::JAM Home Page

L<http://ftnpl.sourceforge.net/ftnpljam.html>

=item * Browse the FTN::JAM GIT repository at SourceForge

L<http://sourceforge.net/p/ftnpl/ftn-jam/code>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ftn-jam>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ftn-jam>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ftn-jam>

=item * Search CPAN

L<http://search.cpan.org/dist/ftn-jam>

=back

=head1 ACKNOWLEDGEMENTS

Originally based on the public domain Perl::JAM module by Johan Billing, which
can be found at L<https://bitbucket.org/johanbilling/jampm/overview>.

=head1 SEE ALSO

 L<FTN::JAM>, L<FTN::JAM::Examples>

=head1 COPYRIGHT & LICENSE

Copyright 2010-2012 Robert James Clay, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of FTN::JAM
