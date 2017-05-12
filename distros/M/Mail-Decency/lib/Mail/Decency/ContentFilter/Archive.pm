package Mail::Decency::ContentFilter::Archive;

use Moose;
extends 'Mail::Decency::ContentFilter::Core';

use version 0.74; our $VERSION = qv( "v0.1.4" );

use mro 'c3';
use Data::Dumper;
use File::Path qw/ make_path /;
use File::Basename qw/ fileparse /;
use File::Temp qw/ tempfile /;
use File::Copy qw/ copy /;
use Mail::Decency::Core::Exception;

=head1 NAME

Mail::Decency::ContentFilter::Archive

=head1 DESCRIPTION

Archive module. Write a copy of the passing mail to archive directory on disk.

=head1 CONFIG

    ---
    
    disable: 0
    
    # possible variables are:
    #   * recipient_domain .. eg recipient.tld
    #   * recipient_prefix .. eg username
    #   * recipient_address .. eg username@recipient.tld
    #   * sender_domain .. eg username@recipient.tld
    #   * sender_prefix .. eg username@domain.tld
    #   * sender_adress .. eg username@domain.tld
    #   * ymd .. eg 2010-05-24
    #   * hm  .. eg 21-26 (= 21:26h)
    archive_dir: '/var/archive/%recipient_domain%/%recipient_prefix%/%ymd%/%hm%/'
    #archive_dir: '/var/archive/%ymd%/%recipient_domain%/%recipient_prefix%'
    
    # wheter to drop the mail after archiving .. means: will not be
    #   reinjected for delivery.
    drop: 0

=head1 CLASS ATTRIBUTES


=head2 archive_dir : Str

Archive directory where the mails are stored in.

=cut

has archive_dir => ( is => 'rw', isa => 'Str' );

=head2 drop : Bool

If true, drop mails after archiving (do not forward them)

=cut

has drop => ( is => 'rw', isa => 'Bool', default => 0 );


=head1 METHODS


=head2 init

=cut

sub init {
    my ( $self ) = @_;
    
    # init base, assure we get mime encoded
    $self->next::method();
    
    foreach my $meth( qw/
        drop
        archive_dir
    / ) {
        $self->$meth( $self->config->{ $meth } )
            if $self->config->{ $meth };
    }
    
    die "Require 'archive_dir' (full path for saving mails)\n"
        unless $self->archive_dir;
    
    $self->logger->info( "Mail archive dir: ". $self->archive_dir );
}


=head2 handle

Archive file into archive folder

=cut


sub handle {
    my ( $self ) = @_;
    
    # perform archive
    $self->archive_mail();
    
    # die here with drop exception, if don't want to keep
    Mail::Decency::Core::Exception::Drop->throw( { message => "Drop after archive" } )
        if $self->drop;
    
    return ;
}


=head2 archive_mail

Write mail to archive directory.

=cut

sub archive_mail {
    my ( $self ) = @_;
    
    # get directory, split into file and dir path
    my ( $file, $dir ) = fileparse( $self->build_dir );
    $file ||= "mail";
    
    # try make directory, die on error
    make_path( $dir, { mode => 0700 } ) unless -d $dir;
    die "Could not create archive directory '$dir'" unless -d $dir;
    
    # make a temp file within (assure it is unique)
    my ( $th, $full_path )
        = tempfile( "$dir$file-". time(). "-XXXXXX", UNLINK => 0, SUFFIX => ".eml" );
    close $th;
    
    # copy actual file to archive folder
    copy( $self->file, $full_path );
    $self->logger->debug0( "Stored mail in '$full_path' ". ( -f $full_path ? "OK" : "ERROR" ) );
}


=head2 build_dir

Builds dir based on variables.

=cut

sub build_dir {
    my ( $self ) = @_;
    
    my $dir = $self->archive_dir;
    
    # parse recipient_*
    if ( $dir =~ /\%recipient/ ) {
        my $recipient_address = $self->normalize_str( $self->to || "unknown\@unknown" );
        my ( $recipient_prefix, $recipient_domain ) = split( /@/, $recipient_address, 2 );
        $recipient_prefix ||= "unknown";
        $recipient_domain ||= "unknown";
        $dir =~ s/\%recipient_address\%/$recipient_address/g;
        $dir =~ s/\%recipient_prefix\%/$recipient_prefix/g;
        $dir =~ s/\%recipient_domain\%/$recipient_domain/g;
    }
    
    # parse sender_*
    if ( $dir =~ /\%sender/ ) {
        my $sender_address = $self->normalize_str( $self->from || "unknown\@unknown" );
        my ( $sender_prefix, $sender_domain ) = split( /@/, $sender_address, 2 );
        $sender_prefix ||= "unknown";
        $sender_domain ||= "unknown";
        $dir =~ s/\%sender_address\%/$sender_address/g;
        $dir =~ s/\%sender_prefix\%/$sender_prefix/g;
        $dir =~ s/\%sender_domain\%/$sender_domain/g;
    }
    
    # parse time
    if ( $dir =~ /\%(ymd|hm)\%/ ) {
        my @date = localtime(); # 0: sec, 1: min, 2: hour, 3: day, 4: month, 5: year
        $date[4]++;
        $date[5] += 1900;
        
        my $ymd = sprintf( '%04d-%02d-%02d', @date[ 5, 4, 3 ] );
        my $hm  = sprintf( '%02d-%02d', @date[ 2, 1 ] );
        
        $dir =~ s/\%ymd\%/$ymd/g;
        $dir =~ s/\%hm\%/$hm/g;
    }
    
    return $dir;
}


=head2 normalize_str

Replace not allowed characters ..

=cut

sub normalize_str {
    my ( $self, $str ) = @_;
    $str =~ s/[^\p{L}\d\-_\.@\+]/_/gms;
    $str =~ s/__/_/g;
    return $str;
}

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut


1;
