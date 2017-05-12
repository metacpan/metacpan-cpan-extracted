package File::HStore;

use strict;
use warnings;
use Digest::SHA;
use File::Copy;
use File::Path;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw(

            )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.10';

sub new {

    my ( $this, $path, $digest, $prefix ) = @_;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;

    if ( defined($path) ) {
        $self->{path} = $path;
    }
    else {
        $self->{path} = "~/.hstore";
    }

    if ( defined($digest) ) {
        $self->{digest} = $digest;
    }
    else {
        $self->{digest} = "SHA1";
    }

    if ( defined($prefix) ) {
        $self->{prefix} = $prefix;
    }
    else {
        $self->{prefix} = "freearchive";
    }

    if ( !( -e $self->{path} ) ) {
        mkdir( $self->{path} )
            or die "Unable to create directory : $self->{path}";
    }

    return $self;
}

sub add {

    my ( $self, $filename ) = @_;
    my $ldigest;
    my $lSubmitDate;

    if ( $self->{digest} eq "FAT" ) {
        $ldigest = "SHA2";
    }
    else {
        $ldigest = $self->{digest};
    }
    my $localDigest = _DigestAFile( "$filename", $ldigest )
        or die "Unable to digest the file $filename";

    my $SSubDir;

    if ( !( $self->{digest} eq "FAT" ) ) {
        my $localSubDir = substr( $localDigest, 0, 2 );
        $SSubDir = $self->{path} . "/" . $localSubDir;

    }
    else {

        $lSubmitDate = _SubmitDate();
        $lSubmitDate =~ s/-/\//g;
        $SSubDir = $self->{path} . "/" . $self->{prefix} . "/" . $lSubmitDate;

    }

    if ( !( -e $SSubDir ) ) {

        mkpath($SSubDir) or die "Unable to create subdirectoris $SSubDir in the hstore";
    }

    my $destStoredFile = $SSubDir . "/" . $localDigest;

    if ( !( $self->{digest} eq "FAT" ) ) {
        copy( $filename, $destStoredFile )
        or die "Unable to copy file into hstore as $destStoredFile";
    } else {
        mkpath($destStoredFile);
        copy( $filename, $destStoredFile);
    }

    if ( !( $self->{digest} eq "FAT" ) ) {
        return $localDigest;
    }
    else {
        $lSubmitDate =~ s/\//-/g;
        return $self->{prefix} . "-" . $lSubmitDate . "-" . $localDigest;
    }
}

sub remove {

    my ( $self, $id ) = @_;

    my $destStoredFile;

    #    if (!(defined($id))) {die "hash to be removed not defined";}

    if ( !( defined($id) ) ) { return undef; }

    if ( !( $self->{digest} eq "FAT" ) ) {
        my $localSubDir = substr( $id, 0, 2 );
        my $SSubDir = $self->{path} . "/" . $localSubDir;
        $destStoredFile = $SSubDir . "/" . $id;
    }
    else {
        $id =~ s/-/\//g;
        $destStoredFile = $self->{path} . "/" . $id;
    }

    if ( -e $destStoredFile ) {

        if ( !( $self->{digest} eq "FAT" ) ) {
            unlink($destStoredFile) or return undef;
        }
        else {
            rmtree($destStoredFile) or return undef;
        }

        #die "Unable to delete file from hstore named $destStoredFile";
        #return undef;
    }
    else {
        return;
    }

}

sub getpath {

    my ( $self, $id ) = @_;

    my $destStoredFile;

    if ( !( $self->{digest} eq "FAT" ) ) {
        my $localSubDir = substr( $id, 0, 2 );
        my $SSubDir = $self->{path} . "/" . $localSubDir;
        $destStoredFile = $SSubDir . "/" . $id;
    }
    else {
        $id =~ s/-/\//g;
        $destStoredFile = $self->{path} . "/" . $id;
    }

    if ( -e $destStoredFile ) {
	return $destStoredFile;
    } else {
	return;
    }
}

sub _printPath {
    my ($self) = @_;

    return $self->{path};

}

sub _DigestAFile {

    my $file      = shift;
    my $digestdef = shift;
    my $sha;
    open( FILED, "$file" ) or die "Unable to open file $file";
    if ( $digestdef eq "SHA1" ) {
        $sha = Digest::SHA->new("sha1");
    }
    elsif ( $digestdef eq "SHA2" ) {
        $sha = Digest::SHA->new("sha256");
    }
    else {
        print "unknown digest method";
    }
    $sha->addfile(*FILED);
    close(FILED);
    return my $digest = $sha->hexdigest;

}

# Used only for the Free Archive Toolkit mixed-"hash" format
#
# FAT is following this format :
#
# prefix-year-mm-dd-hh-mm-ss-hash
#
# The format is represented on disk with the following format :
#
# prefix/year/mm/dd/hh/mm/ss/hash

# return the date in FAT format

sub _SubmitDate {

    my ( $sec, $min, $hour, $day, $month, $year ) =
        (localtime)[ 0, 1, 2, 3, 4, 5 ];

    return sprintf(
        "%04d-%02d-%02d-%02d-%02d-%02d",
        $year + 1900,
        $month + 1, $day, $hour, $min, $sec
    );

}

1;
__END__

=head1 NAME

File::HStore - Perl extension to store files  on a filesystem using a
    very simple hash-based storage.

=head1 SYNOPSIS

  use File::HStore;
  my $store = File::HStore ("/tmp/.mystore");
  
  # Add a file in the store
  my $id = $store->add("/foo/bar.txt");

  # Return the filesystem location of an id
  my $location = $store->getpath($id);

  # Remove a file by its id from the store
  $store->remove("ff3b73dd85beeaf6e7b34d678ab2615c71eee9d5")

=head1 DESCRIPTION

File-HStore  is a very  minimalist perl  library to  store files  on a
filesystem using a very simple hash-based storage.

File-HStore  is nothing  more than  a  simple wrapper  interface to  a
storage containing a specific directory structure where files are hold
based on  their hashes. The  name of the  directories is based  on the
first two  bytes of the  hexadecimal form of  the digest. The  file is
stored and named  with its full hexadecimal form  in the corresponding
prefixed directory.

The  current version  is supporting  the  SHA-1 and  SHA-2 (256  bits)
algorithm. The FAT (Free Archive Toolkit) format is also supported and
it is  composed of the date  of submission plus the  SHA-2 real digest
part.

=head1 METHODS

The object  oriented interface to C<File::HFile> is  described in this
section.  

The following methods are provided:

=over 4

=item $store = File::HStore->new($path,$digest,$prefix)

This constructor  returns a new C<File::HFile>  object encapsulating a
specific store. The path specifies  where the HStore is located on the
filesystem.  If the  path  is  not specified,  the  path ~/.hstore  is
used. The digest specifies the algorithm to be used (SHA-1 or SHA-2 or
the  submission   date  called  FAT).  If  not   specified,  SHA-1  is
used. Various digest can be mixed  in the same path but the utility is
somewhat limited.  The $prefix is only  an extension used  for the FAT
(Free Archive Format) format to specify the archive unique name.

=item $store->add($filename)

The $filename is  the file to be added in the  store. The return value
is the hash value ($id) of the $filename stored. Return undef on error.

=item $store->getpath($id)

Return the filesystem location of the file specified by its hash value.

Return undef on error.

=item $store->remove($hashvalue)

The $hashvalue is the file to be removed from the store. 

Return false on success and undef on error.

=back

=head1 SEE ALSO

There  is a  web page  for the  File::HStore module  at  the following
location : http://www.foo.be/hstore/

If you  plan to  use a hash-based  storage (like  File::HStore), don't
forget  to read  the following  paper and  check the  impact  for your
application :

An Analysis of Compare-by-hash -
http://www.usenix.org/events/hotos03/tech/full_papers/henson/henson.pdf

Please  also   consider  the  security  impact   in  your  application
concerning  the  statement made  by  the  NIST  regarding the  overall
security impact  of the  SHA-1 vulnereability. In  the use  of storage
and unique identifier only , the impact is somewhat very limited.

http://csrc.nist.gov/news-highlights/NIST-Brief-Comments-on-SHA1-attack.pdf

=head1 AUTHOR

Alexandre "adulau" Dulaunoy, E<lt>adulau@foo.beE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2008 by Alexandre Dulaunoy <adulau@uucp.foo.be>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
