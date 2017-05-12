package FSpot::DbTools::Paths;
use Moose::Role;
use MooseX::Params::Validate;

use YAML::Any qw/Dump/;

use File::Util;
use File::Spec::Functions;
use Cwd qw(abs_path);
use File::Copy;

use 5.010000;
our $VERSION = '0.2';

=pod

=head1 NAME

FSpot::DbTools::Paths

=head1 SYNOPSIS

  use FSpot::DbTool;

  my $fs = FSpot->new();
  my $db_tool = $fs->db_tool();
  $db_tool->load_tool( 'Paths' );

=head1 DESCRIPTION

Some useful methods for path manipulation

=head1 METHODS

=head2 replace_path( %params )

Replace one path with another in the database.
Useful if you move all your photos to a new location and want to replace all the old paths

Usage:

  $fs->replace_path( from   => $from_path,
                     to     => $to_path, );

=cut
sub replace_path{
     my ( $self, %params ) = validated_hash(
                                            \@_,
                                            from  => { isa => 'Str' },
                                            to    => { isa => 'Str' }
                                           );
    $self->logger->debug( "replace_path called with\n" . Dump( %params ) );

    # Get a list of the entries from the photos and photo_versions tables which have to be processed
    my @photos_array = $self->search_base_uri( path     => $params{from},
                                               wildcard => 1 );

    $self->logger->debug( "Found " . scalar( @photos_array ) . " photos with paths to replace" );

    # Replace the part of the path, and write changes to the database
    foreach my $photo ( @photos_array ){
        $photo->{base_uri} =~ s/$params{from}/$params{to}/;
        if( $photo->{id} ){
            $self->update_photo( photo_id  => $photo->{id},
                                 details   => { 'base_uri' => $photo->{base_uri} } );
        }else{
            $self->update_photo_version( photo_id   => $photo->{photo_id},
                                         version_id => $photo->{version_id},
                                         details => { 'base_uri' => $photo->{base_uri} } );
        }
    }
}

=head2 move_dir( %params )

Move all files in a directory from one location to another, and make the changes in the database too.

Usage:

  $fs->replace_path( from   => $from_path,
                     to     => $to_path,
                     rename => 1,
                     merge  => 1 );

rename and merge are optional, and default to 0

rename   if enabled will cause files to be renamed by adding a counter to the end of the filename (before extension)
         in the target directory.
e.g. if My_Picture.jpg is to be moved to a directory where My_Picture.jpg already exists, it will be renamed to
My_Picture_1.jpg

merge    if enabled it will allow files to be merged into an existing directory.

Changes are only made in the database (for each file) if the move for that file was successful.

=cut
sub move_dir{
    my ( $self, %params ) = validated_hash(
                                           \@_,
                                           from   => { isa => 'Str' },
                                           to     => { isa => 'Str' },
                                           merge  => { isa => 'Int', default => 0 },
                                           rename => { isa => 'Int', default => 0 },
                                          );
    my $f = File::Util->new();

    # Make complete paths from the from/to and check they are defined
    foreach( qw/from to/ ){
        $params{$_} = abs_path( $params{$_} );
    }

    # The source must be defined
    if( ! -d $params{from} ){
        die( "$params{from} is not a directory\n" );
    }

    # See if target is defined, maybe make dir
    if( -d $params{to} && ! $params{merge} ){
        die( "Directory $params{to} exists, but merge not defined\n" );
    }elsif( ! -d $params{to} ){
#        print "Making dir $params{to}\n";
        if( ! $f->make_dir( $params{to} ) ){
            die( "Could not make directory $params{to}: $!\n" );
        }
    }

    # Get a list of the entries from the photos and photo_versions tables which have to be processed
    my @photos_array = $self->search_base_uri( path => $params{from} );

#    print "Found " . scalar( @photos_array ) .  " entries to process\n";
    my $photos;
    foreach( @photos_array ){
        my $id = $_->{id} || $_->{photo_id};
        if( $photos->{$id} ){
            push( @{ $photos->{$id}->{entries} }, $_ );
        }else{
            $photos->{$id}->{entries} = [ $_ ];
        }
    }

    foreach my $id( keys( %$photos ) ){
        # make a map of source/target combinations
        my @entries = @{ $photos->{$id}->{entries} };
        foreach my $photo( @entries ){
            # Generate the source path, and make sure it exists
            my $from_path = $photo->{base_uri} . $photo->{filename};
            $from_path =~ s/file:\/\///;
            $from_path = &_decode( $from_path );

            # Skip processing if it's an entry from photo_versions
            if( ! -f $from_path ){
#                print "Skipping processing for file (does not exist): $from_path\n";
                next;
            }

            $photo->{base_uri} =~ s/$params{from}/$params{to}/;
            my $to_path = undef;
            my $to_filename = undef;
            my $counter = 0;
            # Try and find a suitable to_path.  If the file already exists, and the parameter rename
            # is enabled, it will loop trying to find a suitable path
            do{
                if( $counter == 0 ){
                    $to_path = $photo->{base_uri} . $photo->{filename};
                    $to_filename = $photo->{filename};
                }else{
                    $photo->{filename} =~ m/^(.*)(\..*?)$/;
                    my( $prefix, $ext ) = ( $1, $2 );
                    $to_filename = $prefix . "_$counter" . $ext;
                    $to_path = $photo->{base_uri} . $to_filename;
                }
                $to_path =~ s/file:\/\///;
                ##FIXME Should replace all encoded characters, not just space
                $to_path = &_decode( $to_path );
                $counter++;
                if( -f $to_path ){
                    if( $counter == 1 && ! $params{rename} ){
                        die( "Automatic renaming not enabled, and file ($to_path) already exists.\n" );
                    }
                    $to_path = undef;
                }
            }while( ! $to_path && $counter < 100000 );
            # Make sure the path was found, and endless-loop didn't occur
            if( ! $to_path ){
                die( "Couldn't find an automatic rename path for $from_path\n ");
            }
            $photo->{filename}  = $to_filename;
            $photo->{from_path} = $from_path;
            $photo->{to_path}  = $to_path;
        }

        my %moved;
        foreach my $photo( @entries ){
            # If the from_path exists and it has not been moved yet, move it
            if( $photo->{from_path} && ! $moved{ $photo->{from_path}} ){
                # Try and move the file
                if( -f $photo->{to_path} ){
                    die( "Something went wrong... $photo->{to_path} already exists" );
                }
                if( ! move( $photo->{from_path}, $photo->{to_path} ) ){
                    warn( "Move failed:\n  From: $photo->{from_path}\n  To:   $photo->{to_path}\n  Error: $!\n" );
                }else{
                    $moved{$photo->{from_path}} = 1;
                }
            }

            # If the move was successful, write changes to the database
            if( $moved{$photo->{from_path}} ){
                if( $photo->{id} ){
                    $self->update_photo( photo_id => $photo->{id},
                                         details  => { 'base_uri' => $photo->{base_uri},
                                                       'filename' => $photo->{filename} } );
                }else{
                    $self->update_photo_version( photo_id   => $photo->{photo_id},
                                                 version_id => $photo->{version_id},
                                                 details    => { 'base_uri' => $photo->{base_uri},
                                                                 'filename' => $photo->{filename} } );
                }
            }
        }
    }

    # Now check if the source dir is empty, and if so, remove it
    my @files_left = $f->list_dir( $params{from}, '--no-fsdots' );
    if( scalar( @files_left ) ){
        warn( "Source dir $params{from} is not empty - not removing\n" );
    }else{
#        print "Removing source directory $params{from}\n";
        if( ! rmdir( $params{from} ) ){
            die( "Could not remove directory ($params{from}): $!\n" );
        }
    }
}

=head2 find_lost_files( %params )

Find files which exist in the filesystem, but do not exist in the database
Returns ArrayRef of lost files

Usage:

  my $lost_files = $fs->lost_files( path => $path );

=cut
sub find_lost_files{
    my ( $self, %params ) = validated_hash(
                                           \@_,
                                           path   => { isa => 'Path' },
                                          );

    my $path = abs_path( $params{path} );

    my @files_disk = &_recursive_file_list( $path );
    my @photos_db = $self->search_base_uri( path => $path, wildcard => 1 );

    my $db_hash;
    foreach my $photo( @photos_db ){
        my $path = $photo->{base_uri};
        $path =~ s/^file:\/\///;
        $path .= $photo->{filename};
        $path = _decode( $path );
        $db_hash->{$path} = 1;
    }

    my %lost_files;
    foreach my $path( @files_disk ){
        if( ! $db_hash->{$path } ){
            $lost_files{$path} = 1;
        }
    }
    return { keys( %lost_files ) };
}

=head2 find_orphans( %params )

Find orphaned files (files which exist in in the database, but not on the filesystem)
Returns HashRef of database entries for orphans

Usage:

  my $orphans = $fs->find_orphans();

=cut
sub find_orphans{
    my( $self ) = @_;

    my @photos = $self->search( table => 'photo_versions' );
    push( @photos, $self->search( table => 'photos' ) );
    my $orphans = {};
    print "Found " . scalar( @photos ) . " photos\n";
    foreach my $photo( @photos ){
        my $id = $photo->{id} || $photo->{photo_id};

        my $path = $photo->{base_uri};
        $path =~ s/^file:\/\///;
        $path = catfile( $path, $photo->{filename} );
        $path = _decode( $path );
        if( ! -f $path ){
            $photo->{_path} = $path;
            $orphans->{$id} = $photo;
        }
    }
    print "Found " . scalar( keys( %{ $orphans } ) ) . " orphans\n";
    return $orphans;
}


=head2 search_base_uri( %params )

Search for photos with a given base_uri.

wildcard is optional and defaults to 0 if not defined

Usage:

  $fs->seacrh_base_uri(  path     => $path,
                         wildcard => 1 );

=cut
sub search_base_uri{
    my ( $self, %params ) = validated_hash(
                                           \@_,
                                           path     => { isa => 'Str' },
                                           wildcard => { isa => 'Int', default => 0 }
                                           );
    if( $params{wildcard} ){
        $params{path} .= '%';
    }else{
        $params{path} .= '/';
    }

    my @photos_array = $self->search( table    => 'photo_versions',
                                      search   => [[ 'base_uri', 'LIKE', "file://$params{path}"]]  );
    push( @photos_array, $self->search( table  => 'photos',
                                        search => [[ 'base_uri', 'LIKE', "file://$params{path}"]]  ) );
    return @photos_array;
}

=head2 clean_trailing_slashes( %params )

Cleans the trailing slashes from paths

Usage:

  $fs->clean_trailing_slashes();

=cut
sub clean_trailing_slashes{
     my ( $self ) = @_;

    # Get a list of the entries from the photos and photo_versions tables which have to be processed
    my @photos_array = $self->search( table    => 'photo_versions',
                                      search   => [[ 'base_uri', 'LIKE', "%/"]]  );
    push( @photos_array, $self->search( table  => 'photos',
                                        search => [[ 'base_uri', 'LIKE', "%/"]]  ) );


    $self->logger->debug( "Found " . scalar( @photos_array ) . " photos with paths with trailing slashes" );

    # Replace the part of the path, and write changes to the database
    foreach my $photo ( @photos_array ){
        $photo->{base_uri} =~ s/^(.*)\//$1/;
        if( $photo->{id} ){
            $self->update_photo( photo_id  => $photo->{id},
                                 details   => { 'base_uri' => $photo->{base_uri} } );
        }else{
            $self->update_photo_version( photo_id   => $photo->{photo_id},
                                         version_id => $photo->{version_id},
                                         details => { 'base_uri' => $photo->{base_uri} } );
        }
    }
}


# get list of files (no directories!)... recursively!  Because it's not possible to do it
# in one step with File::Util
sub _recursive_file_list{
    my( $path ) = @_;
    my $f = File::Util->new();
    my @dirs = $f->list_dir( $path, '--recurse', '--dirs-only', '--no-fsdots', '--with-paths' );
    push( @dirs, $path );
    my @files;
    foreach( @dirs ){
        push( @files, $f->list_dir( $_, '--files-only', '--no-fsdots', '--with-paths' ) );
    }
    return @files;
}

# Encode uri's for the database
sub _encode{
    my $in = shift;
    $in =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
    return $in;
}

# Decode uri's for the database
sub _decode{
    my $str = shift;
    $str =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
    return $str;
}

1;

__END__


=head1 AUTHOR

Robin Clarke C<perl@robinclarke.net>

=cut
