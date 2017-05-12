package Minecraft::NBTReader;

use 5.016;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our $VERSION = '0.6';

use Config;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    
    if($Config{byteorder} =~ /^1/) {
        $self->{needswap} = 1;
    } else {
        $self->{needswap} = 0;
    }
    
    return $self;
}

sub readFile {
    my ($self, $filename) = @_;
    
    $self->{unnamedcount} = 0;
    
    my %data;
    
    my $filetype = $self->checkFileType($filename);
    
    my $newfname = $filename;
    
    if($filetype eq 'gzip') {
        $newfname = 'temp.dat';
        $self->DeZip($filename, $newfname);
    } elsif($filetype eq 'unknown') {
        die("File is of unknown type");
    } elsif($filetype eq 'plain') {
        print "File looks like an NBT file\n";
    }
    
    open(my $ifh, '<', $newfname) or die($!);
    binmode($ifh);
    
    $self->parseFile(\*$ifh, \%data);
    
    close $ifh;
    
    if($filename ne $newfname) {
        unlink $newfname;
    }
    
    return %data;
}

sub checkFileType {
    my ($self, $filename) = @_;
    
    open(my $ifh, '<', $filename) or die($!);
    my $buf;
    read($ifh, $buf, 1) or die($!);
    my $type = ord($buf);
    close $ifh;
    
    if($type == 10) {
        return 'plain';
    } elsif($type == 31) {
        return 'gzip';
    }
    
    return 'unknown';
}

sub DeZip {
    my ($self, $fname, $newfname) = @_;
    
    unlink $newfname;
    
    gunzip $fname => $newfname;
    
    if(!-f $newfname || $self->checkFileType($newfname) ne 'plain') {
        die("Gunzip failed!");
    }
    
    return;
}

sub parseFile {
    my ($self, $fh, $data) = @_;
    
    while(!eof($fh)) {
        my $buf;    
        read($fh, $buf, 1) or die($!);
        my $type = ord($buf);
        if($type == 0) {
            # TAG_end
            last;
        } elsif(($type >= 1 && $type <= 6) || $type == 8) {
            # TAG_byte, TAG_Short, TAG_Int, TAG_Long, TAG_Float, TAG_Double, TAG_String
            my $name = $self->readTagName($fh);
            my $val = $self->readValByType($fh, $type);
            $data->{$name} = $val;
        } elsif($type == 7) {
            # TAG_Byte_Array
            my $name = $self->readTagName($fh);
            my $count = $self->readInt($fh);
            my @vals;
            for(my $i = 0; $i < $count; $i++) {
                my $val = $self->readByte($fh);
                push @vals, $val;
            }
            $data->{$name} = \@vals;
        } elsif($type == 9) {
            # TAG_List
            my $name = $self->readTagName($fh);
            read($fh, $buf, 1) or die($!);
            my $listtype = ord($buf);
            my $count = $self->readInt($fh);
            my @vals;
            for(my $i = 0; $i < $count; $i++) {
                if(($listtype >= 1 && $listtype <= 6) || $listtype == 8) {
                    # simmple data types
                    my $val = $self->readValByType($fh, $listtype);
                    push @vals, $val;
                } elsif($listtype == 10) {
                    # unnamed compound
                    my %subdata;
                    $self->parseFile($fh, \%subdata);
                    push @vals, \%subdata;
                } else {
                    die("Unsupported type $listtype for TAG_List");
                }
            }
            $data->{$name} = \@vals;
        } elsif($type == 10) {
            # TAG_compound
            my $name = $self->readTagName($fh);
            my %tmp;
            $self->parseFile($fh, \%tmp);
            $data->{$name} = \%tmp;
        } else {
            die("Unknown type $type");
        }
    }
    
    return;
}

sub getNextPseudoName {
    my ($self) = @_;
    
    $self->{unnamedcount}++;
    
    my $val = '' . $self->{unnamedcount};
    while(length($val) < 7) {
        $val = '0' . $val;
    }
    return 'unnamed_' . $val;
}

sub readTagName {
    my ($self, $fh) = @_;
    
    my $len = $self->readStringLength($fh, 1);
    
    if(!$len) {
        return $self->getNextPseudoName();
    }
    
    my $name;
    read($fh, $name, $len) or die($!);
    return $name; 
}

sub readStringLength {
    my ($self, $fh, $allowzerolength) = @_;
    
    if(!defined($allowzerolength)) {
        $allowzerolength = 0;
    }
    
    my $buf;
    read($fh, $buf, 2) or die($!);
    
    my $len;
    if($self->{needswap}) {
        $len = unpack('S>', $buf);
    } else {
        $len = unpack('S', $buf);
    }
    
    die("The Fuck?") if(!$allowzerolength && !$len);
    
    return $len;
}

sub readValByType {
    my ($self, $fh, $type) = @_;
    
    if($type == 1) {
        return $self->readByte($fh);
    } elsif($type == 2) {
        return $self->readShort($fh);
    } elsif($type == 3) {
        return $self->readInt($fh);
    } elsif($type == 4) {
        return $self->readLong($fh);    
    } elsif($type == 5) {
        return $self->readFloat($fh);    
    } elsif($type == 6) {
        return $self->readDouble($fh);
    } elsif($type == 8) {
        return $self->readString($fh);
    }
    
    return;
}

sub readByte {
    my ($self, $fh) = @_;
    
    my $buf;
    read($fh, $buf, 1) or die($!);
    
    my $val = unpack('c', $buf);
    
    return $val;
}

sub readShort {
    my ($self, $fh) = @_;
    
    my $buf;
    read($fh, $buf, 2) or die($!);
    
    my $val;
    if($self->{needswap}) {
        $val = unpack('s>', $buf);
    } else {
        $val = unpack('s', $buf);
    }
    
    return $val;
}

sub readInt {
    my ($self, $fh) = @_;
    
    my $buf;
    read($fh, $buf, 4) or die($!);
    
    my $val;
    if($self->{needswap}) {
        $val = unpack('l>', $buf);
    } else {
        $val = unpack('l', $buf);
    }
    
    return $val;
}

sub readLong {
    my ($self, $fh) = @_;
    
    my $buf;
    read($fh, $buf, 8) or die($!);
    
    my $val;
    if($self->{needswap}) {
        $val = unpack('q>', $buf);
    } else {
        $val = unpack('q', $buf);
    }
    
    return $val;
}

sub readFloat {
    my ($self, $fh) = @_;
    
    my $buf;
    read($fh, $buf, 4) or die($!);
    
    my $val;
    if($self->{needswap}) {
        $val = unpack('f>', $buf);
    } else {
        $val = unpack('f', $buf);
    }
    
    return $val;
}

sub readDouble {
    my ($self, $fh) = @_;
    
    my $buf;
    read($fh, $buf, 8) or die($!);
    
    my $val;
    if($self->{needswap}) {
        $val = unpack('d>', $buf);
    } else {
        $val = unpack('d', $buf);
    }
    
    return $val;
}

sub readString {
    my ($self, $fh) = @_;
    
    my $val;
    my $len = $self->readStringLength($fh);
    
    read($fh, $val, $len) or die($!);
    
    return $val;
}

1;
__END__

=head1 NAME

Minecraft::NBTReader - Parse Minecraft NBT files

=head1 SYNOPSIS

  use Minecraft::NBTReader;

  my $reader = Minecraft::NBTReader->new();
  my %data = $reader->readFile("12345-12345-12345.dat"); # some playerdata file from server

  my @pos = @{$data{'unnamed_0000001'}->{Pos}};
  print "Player is at ", join(' / ', @pos), "\n";

=head1 DESCRIPTION

This module parses NBT files, as defined by Notch. Only plain and GZIP compression have been implemented at this time.

Please note that write support is not supported and not planned, this is for reading the files only at this point in time.

Values without a name (but expected to have one) will be given an auto-numbered named in the form of "unnamed_00000001".

=head1 Module doesn't work or doesn't install

Please test first if you get the error message "pack() does not support 64bit quads!" when running
"make test".

This indicates that your perl interpreter isn't compiled with 64 bit support or your operating system
doesn't support 64 bit. This is rather unfortunate, since NBT files can store 64 bit numbers. I'm open to any
suggestions on how to work around that problem.

=head1 WARNING

As currently implemented, gzipped files are unzipped to a temporary file "temp.dat" in the current working directory.

=head2 EXPORT

None by default.

=head1 SEE ALSO

This is based on the original description of the file format by Notch: 
L<http://web.archive.org/web/20110723210920/http://www.minecraft.net/docs/NBT.txt>. 
This distribution also contains the original test files provided by Notch for the automated test scripts.

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
