package FSpot::DbTool;
use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;

use File::Util;
use File::HomeDir;
use File::Copy;
use DBI;
use Data::Dumper;
use YAML::Any qw/Dump/;
use Log::Log4perl;

use 5.010000;
our $VERSION = '0.02';

=pod

=head1 NAME

FSpot::DbTool - An interface to the F-Spot database

=head1 SYNOPSIS

  use FSpot::DbTool;
  my $fsdb = FSpot::DbTool->new( 'db_file' => '~/.config/f-spot/photos.db' );

Parameters:

  db_file            Override the default location for the database file
  ignore_db_version  Normally this module is designed to work with a specific
                     version of the FSpot database. If your version is different
                     but you are sure you want to continue anyway, set this parameter.

=head1 DESCRIPTION
Interface to FSpot database =head1 PROPERTIES

=cut


# The version of the database for which this module is designed to work
has 'designed_for_db_version' => ( is       => 'ro',
                                   isa      => 'Int',
                                   required => 1,
                                   lazy     => 1,
                                   default  => 18 );


# Give the ability to ignore conflicting database version
has 'ignore_db_version' => ( is       => 'ro',
                             isa      => 'Int',
                             required => 1,
                             default  => 0 );

# Location of the FSpot database file
has 'db_file'         => ( is       => 'ro',
                           isa      => 'Str',
                           required => 1,
                           default  => sub{ File::HomeDir->my_home . '/.config/f-spot/photos.db' },
                           );


# Database handler - It's lazy, so it should only connect to the database when necessary
has 'dbh'             => ( is       => 'ro',
                           isa      => 'DBI::db',
                           required => 1,
                           lazy     => 1,
                           default  => sub{ my $self = shift;
                                            if( ! -f $self->db_file ){
                                                die( sprintf "Database file [%s] does not exist\n", $self->db_file() );
                                            }
                                            my $dbh = DBI->connect('dbi:SQLite:dbname=' . $self->db_file(),'','');
                                            if( ! $dbh ){
                                                die( "Could not connect to the database: $!" );
                                            }
                                            if( ! $self->ignore_db_version ){
                                                my $sth = $dbh->prepare( 'SELECT data FROM meta WHERE name=?' );
                                                $sth->execute( 'F-Spot Database Version' );
                                                my $row = $sth->fetchrow_hashref();
                                                if( ! $row ){
                                                    die( "Could not identify the F-Spot Database version from the meta table\n" );
                                                }
                                                if( $row->{data} ne $self->designed_for_db_version ){
                                                    die( "This interface is designed to work with version " . $self->designed_for_db_version .
                                                         " of the FSpot database but you have $row->{data}.\n" .
                                                         "If you want to continue anyway, set the ignore_db_version parameter\n" );
                                                }
                                                $sth->finish();
                                            }
                                            return $dbh;
                                        } );

# Hard-coded reference for the tables and columns which exist in the f-spot database
# Would be better to get these dynamically from the database!
has 'db_columns'    =>  ( is        => 'ro',
                          isa       => 'HashRef',
                          required  => 1,
                          lazy      => 1,
                          default   => sub{ return { exports         => [ qw/id image_id image_version_id export_type export_token/ ],
                                                     jobs            => [ qw/id job_type job_options run_at job_priority/ ],
                                                     meta            => [ qw/id name data/ ],
                                                     photo_tags      => [ qw/photo_id tag_id/ ],
                                                     photo_versions  => [ qw/photo_id version_id name base_uri filename import_md5 protected/ ],
                                                     photos          => [ qw/id time base_uri filename description roll_id default_version_id rating/ ],
                                                     rolls           => [ qw/id time/ ],
                                                     sqlite_sequence => [ qw/name seq/ ],
                                                     tags            => [ qw/id name category_id is_category set_priority icon/ ],
                                                   } } );

# A list of the tools loaded
has 'tools'         => ( is     => 'ro',
                         isa    => 'ArrayRef',
                         required => 1,
                         default  => sub{ [] }, );


has 'logger'          => ( is       => 'rw',
                           isa      => 'Log::Log4perl::Logger', 
                           default  => sub{ Log::Log4perl->get_logger('fspot') },
                           required => 1 );


# A search entry is always an arrayref with a column, comparator, and value
subtype 'SearchEntry'
  => as 'ArrayRef'
  => where { $_->[1] =~ m/^(like|>|>=|<|<=|<>|=)$/i and scalar( @{ $_ } ) == 3 }
  => message { "Not an valid search entry" };

# A Path must exist
subtype 'Path'
  => as 'Str'
  => where { -f $_ or -d $_ }
  => message { "Not a path" };

# A Path must exist
subtype 'NonEmptyHashRef'
  => as 'HashRef'
  => where { scalar( keys( %{ $_ } ) ) > 0  }
  => message { "Not a non-empty HashRef" };

=head1 METHODS

=head2 new()

Object constructor.

=head2 load_tool( $tool_name )

Loads a tool (Moose::Role) which brings special database manipulation methods with it

=cut
sub load_tool{
    my ( $self, %params ) = validated_hash(
                                           \@_,
                                           tool  => { isa => 'Str' },
                                          );
    if( $params{tool} !~ m/^\w*$/ ){
        die( "Not a valid tool name: $params{tool}\n" );
    }

    # See if the tool is already loaded
    foreach( @{ $self->tools() } ){
        if( $_ eq $params{tool} ){
            $self->logger->debug( "I've already loaded this tool - not loading again!: $params{tool}" );
            return 1;
        }
    }
    $self->logger->debug( "Loading tool: $params{tool}" );

    eval{
        with 'FSpot::DbTools::' . $params{tool};
    };
    if( $@ ){
        warn( "Couldn not load tool $params{tool}\n$@\n" );
        return 0;
    }
    push( @{ $self->{tools} }, $params{tool} );
}

=head2 compact_db()

Compacts the database with the VACUUM command

Usage:

  $fs->compact_db();

=cut
sub compact_db{
    my ( $self ) = @_;
    my $sth = $self->dbh->prepare( 'VACUUM' );
    $self->logger->debug( "Compacting database" );
    $sth->execute;
    $self->logger->debug( "Finished compacting database" );
    $sth->finish;
}

=head2 backup_db( %params )

Backs up the database.  If target is defined, it will write to there, otherwise like this:

Original:

  ~/.config/f-spot/photos.db

Backup: 

  ~/.config/f-spot/photos.db.bak.0

Usage:

  $fs->backup_db();

=cut
sub backup_db{
    my ( $self, %params ) = validated_hash(
                                           \@_,
                                           target  => { isa => 'Str', optional => 1 },
                                          );
    # First see if the db_file is defined and exists
    if( ! -f $self->db_file ){
        die( "Cannot backup db, when db_file does not exist...\n" );
    }

    my $target = $params{target};
    # If target wasn't defined, try and find 
    if( ! $target ){
        my $counter = 0;
        do{
            if( $counter == 0 ){
                $target = $self->db_file() . '.bak';
            }else{
                $target = $self->db_file() . '.bak.' . $counter;
            }
            $counter++;
            if( -f $target ){
                $target = undef;
            }
        }while( ! $target and $counter < 1000 );
        if( ! $target ){
            die( "Could not find a target to backup db to\n" );
        }
    }
    $self->logger->debug( "Backing up database from " . $self->db_file() . " to $target" );

    if( ! copy( $self->db_file(), $target ) ){
        die( "Could not backup db_file: $!\n" );
    }
}

=head2 search( %params )

 Returns (an array of) rows (all columns) of matching entries

Usage:

  $fs->search( table  => $table,
               search => [ [ 'filename', 'LIKE', '%123%' ], [ .... ] ] );

=cut
sub search{
    my ( $self, %params ) = validated_hash(
                                           \@_,
                                           table  => { isa => 'Str' },
                                           search => { isa => 'ArrayRef[SearchEntry]', optional => 1 }
                                          );

    my( @where, @vals, %ids );
    foreach my $entry( @{ $params{search} } ){
        $self->column_must_exist( table   => $params{table},
                                  column  => $entry->[0] );

        push( @where, "$entry->[0] $entry->[1] ?" );
        push( @vals, $entry->[2] );
    }

    # Get the entries from the photos table
    my $sql = "SELECT * FROM $params{table}";
    if( $#where >= 0 ){
        $sql .= " WHERE " . join( ' AND ', @where );
    }

    my $sth = $self->dbh->prepare( $sql );
    $sth->execute( @vals );

    my( $row, @results );
    while( $row = $sth->fetchrow_hashref ){
        push( @results, $row );
    }
    $sth->finish();
    return @results;
}

=head2 update_photo( %params )

Update a photo in the database

Usage:
  $details = { 'filename' => $newname,
               'base_uri' => $new_base_uri };
  $fs->update_photo_version( photo_id   => $id,
                             details    => $details );

=cut
sub update_photo{
    my ( $self, %params ) = validated_hash(
                                           \@_,
                                           photo_id    => { isa   => 'Int' },
                                           details     => { isa   => 'NonEmptyHashRef' },
                                          );
    my( @cols, @vals );
    foreach my $column( keys( %{ $params{details} } ) ){
        $self->column_must_exist( table  => 'photos',
                                  column => $column );
        push( @cols, "$column=?" );
        push( @vals, $params{details}->{$column} );
    }
    my $sql = 'UPDATE photos SET ' . join( ', ', @cols ) . " WHERE id=?;";
    push( @vals, $params{photo_id} );

    $self->logger->debug( "Updating photo $params{photo_id} with details:\n " . Dump( $params{details} ) );

    my $sth = $self->dbh->prepare( $sql );
    $sth->execute( @vals );
    $sth->finish();
}

=head2 update_photo_version( %params )

Update a version of a photo in the database

Usage:
  $details = { 'filename' => $newname,
               'base_uri' => $new_base_uri };
  $fs->update_photo_version( photo_id   => $id,
                             version_id => $version_id,
                             details    => $details );

=cut
sub update_photo_version{
    my ( $self, %params ) = validated_hash(
                                           \@_,
                                           photo_id    => { isa   => 'Int' },
                                           version_id  => { isa   => 'Int' },
                                           details     => { isa   => 'NonEmptyHashRef' },
                                          );

    my( @cols, @vals );
    foreach my $column( keys( %{ $params{details} } ) ){
        $self->column_must_exist( table  => 'photo_versions',
                                  column => $column );
        push( @cols, "$column=?" );
        push( @vals, $params{details}->{$column} );
    }

    my $sql = 'UPDATE photo_versions SET ' . join( ', ', @cols ) . 
      " WHERE photo_id=? AND version_id=?;";
    push( @vals, $params{photo_id}, $params{version_id} );
    my $sth = $self->dbh->prepare( $sql );
    $self->logger->debug( "Updating photo_version $params{photo_id} with details:\n " . Dump( $params{details} ) );

    $sth->execute( @vals );
    $sth->finish();
}

=head2 add_tag( %params )

Add a tag.
Parent name is optional.  If not defined, the tag will be attached to the root.

Usage: 

  $fs->add_tag( name        => $name,
                parent_name => $parent_name );

=cut
sub add_tag{
     my ( $self, %params ) = validated_hash(
                                            \@_,
                                            name        => { isa => 'Str' },
                                            parent_name => { isa => 'Str', optional => 1 },
                                           );

    # If the parent was defined, try and find it
    my $parent;
    if( $params{parent_name} ){
        my @result_parent = $self->search( table  => 'tags',
                                           search => [ [ 'name', '=', $params{parent_name} ] ] );

        if( scalar( @result_parent ) == 0 ){
            die( "Parent tag ($params{parent_name}) does not exist\n" );
        }
        $parent = $result_parent[0];
    }

    # If we found a parent, find the ID, otherwise just create it as a "root" tag
    my( $sql, @vals );
    if( $parent ){
        if( $self->search( table  => 'tags',
                           search => [ [ 'name', '=', $params{name} ], [ 'category_id', '=', $parent->{id} ] ] ) ){
            die( "Tag ($params{name}) already exists as a child of $params{parent_name}\n" );
        }else{
            $sql = 'INSERT INTO tags ( name, category_id, is_category, sort_priority ) VALUES( ?, ?, 1, 0 )';
            @vals = ( $params{name}, $parent->{id} );
        }
    }else{
        $sql = 'INSERT INTO tags ( name, category_id, is_category, sort_priority ) VALUES( ?, 0, 1, 0 )';
        @vals = ( $params{name} );
    }

    my $sth = $self->dbh->prepare( $sql );
    $sth->execute( @vals );
    $sth->finish();
}

=head2 tag_photo( %params )

Tag a photo

Usage:

  $fs->tag_photo( photo_id => $photo_id,
                  tag_id   => $tag_id );

=cut
sub tag_photo{
     my ( $self, %params ) = validated_hash(
                                            \@_,
                                            photo_id  => { isa => 'Int' },
                                            tag_id    => { isa => 'Int' },
                                           );
    # First confirm it isn't already tagged
    my $sql = 'SELECT * FROM photo_tags WHERE photo_id=? AND tag_id=?';
    my $sth = $self->dbh->prepare( $sql );
    $sth->execute( $params{photo_id}, $params{tag_id} );

    # Not tagged, so add tag
    if( ! $sth->fetchrow_hashref ){
        $sql = 'INSERT INTO photo_tags ( photo_id, tag_id ) VALUES( ?, ? )';
        $sth = $self->dbh->prepare( $sql );
        $sth->execute( $params{photo_id}, $params{tag_id} );
    }
    $sth->finish();
}

=head2 untag_all( %params )

Remove all of these tag links

Usage:

  $fs->untag_all( tag_id => $tag_id );

=cut
sub untag_all{
     my ( $self, %params ) = validated_hash(
                                            \@_,
                                            tag_id  => { isa => 'Int' },
                                           );
    my $sql = 'DELETE FROM photo_tags WHERE tag_id=?';
    my $sth = $self->dbh->prepare( $sql );
    $sth->execute( $params{tag_id} );
    $sth->finish();
}

=head2 column_exists( %params )

Test if the column exists for this table
Returns 1 if it does, undef if not

Usage:

  $fs->column_exists( table  => $table,
                      column =>  $column );

=cut
sub column_exists{
     my ( $self, %params ) = validated_hash(
                                            \@_,
                                            table  => { isa => 'Str' },
                                            column => { isa => 'Str' },
                                           );
    if( $self->db_columns->{$params{table}} ){
        foreach( @{ $self->db_columns->{$params{table}} } ){
            if( $_ eq $params{column} ){
                return 1;
            }
        }
    }
    return undef;
}

=head2 column_must_exist( %params )

Returns 1 if the table/column exists, dies if it doesn't

Usage:

  $fs->column_must_exist( table  => $table,
                          column =>  $column );

=cut
sub column_must_exist{
    my( $self, %params ) = @_;
    if( ! $self->column_exists( %params ) ){
        die( "Column $params{table}/$params{column} does not exist!\n" );
    }
    return 1;
}


1;
__END__

=head1 AUTHOR

Robin Clarke C<perl@robinclarke.net>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FSpot::DbTool


You can also look for information at:

=over 4

=item * Repository on Github

L<https://github.com/robin13/FSpot--DbTool>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Git-Demo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Git-Demo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Git-Demo>

=item * Search CPAN

L<http://search.cpan.org/dist/Git-Demo/>

=back

=head1 ACKNOWLEDGEMENTS

L<http://f-spot.org/>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Robin Clarke.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
