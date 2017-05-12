package FSpot::DbTools::Tags;
use Moose::Role;
use MooseX::Params::Validate;

use 5.010000;
our $VERSION = '0.2';

=pod

=head1 NAME

FSpot::DbTools::Tags

=head1 SYNOPSIS

  use FSpot::DbTool;

  my $fsdb = FSpot::DbTool->new();
  $fsdb->load_tool( 'Tags' );

=head1 DESCRIPTION

Some useful methods for tagging

=head1 METHODS

=head2 tag_no_description( %params )

Tag all photos which don't have a description yet.

tag_name is optional.  If not define, it will be 'No description'

Usage:

  $fs->tag_no_description(   tag_name => $tag_name );

=cut
sub tag_no_description{
     my ( $self, %params ) = validated_hash(
                                            \@_,
                                            tag_name  => { isa => 'Str', default => 'No description'  },
                                           );
    # See if the tag name already exists, if not, create
    my @tags = $self->search( table    => 'tags',
                              search   => [[ 'name', '=', $params{tag_name} ]] );
    if( $#tags == -1 ){
        print "Tag '$params{tag_name}' does not exist - creating tag\n";
        $self->add_tag( 'name' => $params{tag_name} );
        @tags = $self->search( table   => 'tags',
                               search  => [[ 'name', '=', $params{tag_name} ]] );
    }
    my $tag_id = $tags[0]->{id};
    if( ! $tag_id ){
        die( "Could not find tag_id for $params{tag_name}\n" );
    }

    # Untag any images which may already be tagged
    $self->untag_all( $tag_id );

    my @photos = $self->search( table    => 'photos',
                                search   => [[ 'description', '=', '' ]] );

    # Replace the part of the path, and write changes to the database
    foreach my $photo ( @photos ){
        $self->tag_photo( photo_id => $photo->{id},
                          tag_id   => $tag_id );
    }
}


1;

__END__


=head1 AUTHOR

Robin Clarke C<perl@robinclarke.net>

=cut
