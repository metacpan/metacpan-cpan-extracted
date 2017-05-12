package KinoSearch1::Index::SegInfos;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

use constant FORMAT => -1;

BEGIN {
    __PACKAGE__->init_instance_vars(
        # members
        infos   => undef,
        counter => 0,
        version => undef,
    );
    __PACKAGE__->ready_get_set(qw( counter ));
}

use Time::HiRes qw( time );

sub init_instance {
    my $self = shift;
    $self->{infos} = {};
    $self->{version} ||= int( time * 1000 );
}

# Add a SegInfo to the collection.
sub add_info {
    my ( $self, $info ) = @_;
    $self->{infos}{"$info->{seg_name}"} = $info;
}

# Remove the info corresponding to a segment;
sub delete_segment {
    my ( $self, $seg_name ) = @_;
    confess("no segment named '$seg_name'")
        unless exists $self->{infos}{$seg_name};
    delete $self->{infos}{$seg_name};
}

# Return number of segments in invindex.
sub size { scalar keys %{ $_[0]->{infos} } }

# Retrieve all infos.
sub infos {
    sort { $a->{seg_name} cmp $b->{seg_name} } values %{ $_[0]->{infos} };
}

# Decode "segments" file.
sub read_infos {
    my ( $self, $invindex ) = @_;
    my $instream = $invindex->open_instream('segments');

    # support only recent index formats
    my $format = $instream->lu_read('i');
    croak("unsupported format: '$format'")
        unless $format == FORMAT;

    # read header
    @{$self}{ 'version', 'counter' } = $instream->lu_read('Qi');
    my $num_segs = $instream->lu_read('i');

    # build one SegInfo object for each segment
    if ($num_segs) {
        my @file_contents = $instream->lu_read( 'Ti' x $num_segs );
        while (@file_contents) {
            my ( $seg_name, $doc_count ) = splice( @file_contents, 0, 2 );
            $self->{infos}{$seg_name} = KinoSearch1::Index::SegInfo->new(
                seg_name  => $seg_name,
                doc_count => $doc_count,
                invindex  => $invindex,
            );
        }
    }
}

# Write "segments" file
sub write_infos {
    my ( $self, $invindex ) = @_;
    my $num_segs = scalar keys %{ $self->{infos} };
    my $tempname = 'segments.new';
    $invindex->delete_file($tempname) if $invindex->file_exists($tempname);
    my $outstream = $invindex->open_outstream($tempname);

    # prepare header
    $self->{version}++;
    my @outstuff = ( FORMAT, $self->{version}, $self->{counter}, $num_segs );

    # prepare data
    push @outstuff, map {
        ( $self->{infos}{$_}{seg_name}, $self->{infos}{$_}{doc_count} )
        }
        sort keys %{ $self->{infos} };

    # write it all out
    my $template = 'iQii' . ( 'Ti' x $num_segs );
    $outstream->lu_write( $template, @outstuff );
    $outstream->close;

    # clobber the old segments file
    $invindex->rename_file( $tempname, "segments" );
}

package KinoSearch1::Index::SegInfo;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor params / members
        seg_name  => '',
        doc_count => 0,
        invindex  => undef,
    );
    __PACKAGE__->ready_get(qw( seg_name doc_count invindex ));
}

1;

__END__

==begin devdocs

==head1 NAME

KinoSearch1::Index::SegInfos - manage segment statistical data

==head1 DESCRIPTION

SegInfos ties together the segments which make up an invindex.  It stores a
little information about each, plus some unifying information such as the
counter used to name new segments.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut
