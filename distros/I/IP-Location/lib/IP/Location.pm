package IP::Location;

use 5.006000;
use strict;
use warnings;
use FileHandle;
use Encode;
use Encode::CNMap;
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use IP::Location ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

sub new {
    my ($class, @args) = @_;
    my $self = {
                    'CHAR_SET'        => 'GBK',
                    'IP_ENTRY_NUM'    => undef,
                    'VERSION'         => undef,
                    'QQWRY'           => undef,
                    'FIRST_INDEX_OFFSET' => undef,
                    'LAST_INDEX_OFFSET'  => undef,
    };

    bless($self, $class);

    $self->init(@args) if @args;
    
    return $self;
}

sub init {
    my ($self, $datafile, $char_set) = @_;
    my ($First_Index_Offset, $Last_Index_Offset);
    $self->{'QQWRY'} = FileHandle->new("< $datafile");
    binmode($self->{'QQWRY'});
    sysread($self->{'QQWRY'}, $First_Index_Offset, 4); 
    sysread($self->{'QQWRY'}, $Last_Index_Offset, 4);

    $First_Index_Offset = unpack("L", $First_Index_Offset); 
    $Last_Index_Offset  = unpack("L", $Last_Index_Offset); 

    $self->{FIRST_INDEX_OFFSET} = $First_Index_Offset;
    $self->{LAST_INDEX_OFFSET} = $Last_Index_Offset;
    $self->{IP_ENTRY_NUM} = ($Last_Index_Offset - $First_Index_Offset) / 7 + 1;

    $self->char_set($char_set) if $char_set;
}

sub locate {
    my ($self, $IP_Target) = @_;
    my ($IP_Entry_Cursor1, $IP_Entry_Cursor2, $IP_Entry_Cursor3);
    my $IP_Entry_Data;
    my $IP_Seek_Cursor;
    my $QQWRY = $self->{'QQWRY'};
    my $IP_Seek_Cursor_Tmp;
    my $Redirct_Flags;
    my ($IP_Target_Country, $IP_Target_Area, $IP_Target_Location);
    my @IP_Target = split(/\./, $IP_Target);
    
    $IP_Target = $IP_Target[0] * 16777216 + $IP_Target[1] * 65536 + $IP_Target[2] * 256 + $IP_Target[3];

    $IP_Entry_Cursor1 = 0;
    $IP_Entry_Cursor3 = $self->{IP_ENTRY_NUM};
   
    WHILE: 
    $IP_Entry_Cursor2 = int(($IP_Entry_Cursor1 + $IP_Entry_Cursor3)/2);
    
    seek($self->{'QQWRY'}, $self->{FIRST_INDEX_OFFSET} + $IP_Entry_Cursor2 * 7, 0);
    read($self->{'QQWRY'}, $IP_Entry_Data, 4);
         
    $IP_Entry_Data = unpack("L", $IP_Entry_Data);
    if ($IP_Target < $IP_Entry_Data) {
        $IP_Entry_Cursor3 = $IP_Entry_Cursor2;
        goto WHILE;
    }

    read($self->{'QQWRY'}, $IP_Seek_Cursor, 3); 
    $IP_Seek_Cursor = unpack("L", $IP_Seek_Cursor."\0");
    seek($self->{'QQWRY'}, $IP_Seek_Cursor, 0);
    read($self->{'QQWRY'}, $IP_Entry_Data, 4);
    $IP_Entry_Data = unpack("L", $IP_Entry_Data);

    if ($IP_Entry_Data < $IP_Target) {
        if ($IP_Entry_Cursor1 == $IP_Entry_Cursor2) {
        goto LAST;}
        $IP_Entry_Cursor1 = $IP_Entry_Cursor2;
        goto WHILE;
    }
    
    $/ = "\0";

    read($self->{'QQWRY'}, $Redirct_Flags, 1); 

    if ($Redirct_Flags eq "\1") {
        read($self->{'QQWRY'}, $IP_Seek_Cursor, 3);
        $IP_Seek_Cursor = unpack("L", $IP_Seek_Cursor."\0");
        
        seek($self->{'QQWRY'}, $IP_Seek_Cursor, 0);
        read($self->{'QQWRY'}, $Redirct_Flags, 1);
        if ($Redirct_Flags eq "\2") {
            $IP_Seek_Cursor_Tmp = $IP_Seek_Cursor;
            read($self->{'QQWRY'}, $IP_Seek_Cursor, 3);
            $IP_Seek_Cursor = unpack("L", $IP_Seek_Cursor."\0");
            seek($self->{'QQWRY'}, $IP_Seek_Cursor, 0);
            $IP_Target_Country=<$QQWRY>;      
            seek($self->{'QQWRY'}, $IP_Seek_Cursor_Tmp + 4, 0);
            read($self->{'QQWRY'}, $Redirct_Flags, 1);
            
            if ($Redirct_Flags eq "\2") {
                read($self->{'QQWRY'}, $IP_Seek_Cursor, 3);
                $IP_Seek_Cursor = unpack("L", $IP_Seek_Cursor."\0");
                seek($self->{'QQWRY'}, $IP_Seek_Cursor, 0);
                $IP_Target_Area=<$QQWRY>; 
            }
            else {

                $IP_Target_Area=<$QQWRY>;   
            } 
        }
        else {
            seek($self->{'QQWRY'}, -1, 1);
            $IP_Target_Country=<$QQWRY>;
            read($self->{'QQWRY'}, $Redirct_Flags, 1);
            if ($Redirct_Flags eq "\2") {
                read($self->{'QQWRY'}, $IP_Seek_Cursor, 3);
                $IP_Seek_Cursor = unpack("L", $IP_Seek_Cursor."\0");
                seek($self->{'QQWRY'}, $IP_Seek_Cursor, 0);
            }
            $IP_Target_Area=<$QQWRY>;             
        }
    }
    elsif ($Redirct_Flags eq "\2") {
        $IP_Seek_Cursor_Tmp = ($IP_Seek_Cursor + 8);
        read($self->{'QQWRY'}, $IP_Seek_Cursor, 3);
        $IP_Seek_Cursor = unpack("L", $IP_Seek_Cursor."\0");
        seek($self->{'QQWRY'}, $IP_Seek_Cursor, 0);
        $IP_Target_Country=<$QQWRY>;
        seek($self->{'QQWRY'}, $IP_Seek_Cursor_Tmp, 0);
        $IP_Target_Area=<$QQWRY>;
    } 
    else {
        seek($self->{'QQWRY'}, -1, 1);
        $IP_Target_Country=<$QQWRY>;

        read($self->{'QQWRY'}, $Redirct_Flags, 1);
        if ($Redirct_Flags eq "\2") {
            read($self->{'QQWRY'}, $IP_Seek_Cursor, 3);
            $IP_Seek_Cursor = unpack("L", $IP_Seek_Cursor."\0");
            seek($self->{'QQWRY'}, $IP_Seek_Cursor, 0);
        }
        else {
            seek($self->{'QQWRY'}, -1, 1);
        }
        $IP_Target_Area = <$QQWRY>;        
    }
    
    LAST:

    chomp($IP_Target_Country, $IP_Target_Area);
    $/ = "\n"; 

    $IP_Target_Area =~ s/CZ88\.NET//gi;
    $IP_Target_Location = "$IP_Target_Country $IP_Target_Area";    
    $IP_Target_Location =~ s/^\s*(.*)\s*$/$1/g;
    $IP_Target_Location = "未知区域" if ($IP_Target_Location =~ m/未知|http/i || $IP_Target_Location eq "");

    return $self->conv($IP_Target_Location);
}

sub conv {
    my ($self, $string) = @_;

    return simp_to_utf8($string) if $self->{'CHAR_SET'} eq 'UTF-8';
    return $string;
}

sub char_set {
    my ($self, $Char_Set) = @_;

    if ($Char_Set) {
        if ($Char_Set ne 'GBK' && $Char_Set ne 'UTF-8') {
            print "Error : CHAR_SET should be either \'GBK\' or \'UTF-8\'!";
            return;
        }
    
        $self->{CHAR_SET} = $Char_Set;
        return $self->conv($self->{CHAR_SET});
    }
    else {
        return $self->conv($self->{CHAR_SET});
    }
}

sub version {
    my $self = shift;

    return $self->locate("255.255.255.0");
}

sub info {
    my $self = shift;

    my $info1 = "QQWRY version        : ";
    my $info2 = "\n"
            . "Total Entries        : "
            . $self->{'IP_ENTRY_NUM'} 
            . "\n"
            . "IP::Location version : $VERSION\n";

    return $self->conv($info1) 
        . $self->locate("255.255.255.0") 
        . $self->conv($info2);
}
# Preloaded methods go here.

1;
__END__

=head1 NAME

IP::Location - Perl extension for getting the location of an IP. 

=head1 SYNOPSIS

  no warnings;
  use IP::Location;
  my $QQWRY = IP::Location->new("qqwry.dat");
  my $location = $QQWRY->locate("1.2.3.4");
  print "The location of 1.2.3.4 is $location\n";

=head1 DESCRIPTION

IP::Location is a perl extension for getting the location of an IP through
datafile or the Internet. When it works in the local mode, it queries the local
QQWry datafile, when it works in the network mode, it works as an interface to
the online IP location database. 

=head1 CONSTRUCTOR

=over 4

=item new ( [DATAFILE] [, CHAR_SET])

This is the constructor for a new IP::Location object. C<DATAFILE> is the name
of the QQWry datafile to which the queries use.

C<DATAFILE> is optional. This file is used when initializing a new
IP::Location object.

C<CHAR_SET> is optional. If C<CHAR_SET> is not given, then the object will use
GBK as the default character set. You can use the C<char_set> method to change
its value.

=back

=head1 METHODS

=over 4

=item init ( DATAFILE )

Initialize the new created IP::Location object with the given datafile.

=item locate ( IP_ADDRESS )

Returns the location of the given IP address.

=item char_set( [CHARACTER_SET] )

If the method is called without parameter, it returns the current
character set the module uses. If the method is called with a CHARACTER_SET
parameter, it will set the character set to the given value. The current
supported character set is GBK and UTF-8. GBK is used as the default value.

=item version

Return the version of the datafile and the module.

=item info

More verbose information about the datafile.

=back

=head1 SEE ALSO

The format of the QQWry datafile can be referred at
http://lumaqq.linuxsir.org/article/qqwry_format_detail.html.

The latest version of QQWry datafile can be found at http://www.cz88.net/fox/

=head1 AUTHOR

michael.wang, E<lt>ylzcylx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Michael Wang (loveky) 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
