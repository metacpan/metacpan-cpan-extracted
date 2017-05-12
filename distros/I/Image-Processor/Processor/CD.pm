package Image::Processor::CD;

use strict;
use base ( 'Image::Processor::Base' );

# this module handles interaction with the
# KodakCD format CD that you can get with
# your photos.  It is added to allow for
# people that haven't taken advatage of the
# Kodak online service

sub cd_type {
    my ($self,$set) = @_;
    return $self->{'cd_type'} if !$set;
    $self->{'cd_type'} = $set;
}

sub read_info_cd {
    my ($self) = @_;
    # should be something like
    #Disc = KODAK PICTURE CD
    #NumberOfImagesSession2 = 25
    #LabIdentifier = ORK1
    #MachineId = ORL-KCDFS2
    #BatchId = 002137
    #OrderId = 263577
    #Date = 2000:08:28 13:41:45
    #AccessCode =  NONE
    if (!$self->cdrom) { return };
    my $file_to_open;

    if (-e $self->cdrom . "/INFO.CD") {
        $file_to_open = $self->cdrom . "/INFO.CD";
        $self->cd_type('kodak');
    }
    if (-e $self->cdrom . "/order.txt") {
        $file_to_open = $self->cdrom . "/order.txt";
        $self->cd_type('wal-mart');
    }
    
    open(INFO,$file_to_open) or $self->graceful_exit( "\nI had a problem opening the info file\n" . $! );
    print "Accessing CD information\n";
    while (<INFO>) {
        $_ =~ s/\s+$//;
        my ($k,$v) = split/\s?=\s?/,$_;
        $k = lc($k);
        $self->{$k} = $v;
    }
    if ($self->{'orderid'} eq '') {
        $self->bad_info();
    }     
}

sub bad_info {
    my ($self) = @_;
    print "The CD was not valid, please try another drive or CD\n\n";
    if ($self->running_in eq 'console') {
        $self->console_get_drive();
    } else {
        
    }
}

1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Image::Processor::KodakCD - Perl extension for Woking with disk stores of images

=head1 SYNOPSIS

  use Image::Processor::KodakCD;
  Part of the Image::Processor module

=head1 DESCRIPTION

Image::Processor::KodakCD

=head2 EXPORT

None this is all OOP.

=head2 METHODS

    'read_info_cd' accepts the following
            'bad_info' accepts the following
        


=head1 AUTHOR

Aaron Johnson E<lt>solution@gina.netE<gt>


=head1 SEE ALSO

L<perl>.

=cut
