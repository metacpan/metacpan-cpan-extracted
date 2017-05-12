package Mail::Decency::Core::ExportImport;

use Moose::Role;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Data::Dumper;
use Archive::Tar qw/ COMPRESS_GZIP /;
use File::Temp qw/ tempfile /;
use IO::File;
use IO::YAML;
use Carp qw/ croak confess /;

=head1 NAME

Mail::Decency::Core::ExportImport

=head1 DESCRIPTION

Export / import module databases from/to CSV.

Can be used to deploy changes in a distributed environment.

=cut


=head1 METHODS

=head2 export $export_file

Exports databases contents to a tarred compressed YAML (stream) file

=over

=item * $export_file

Path to an export file (gzip compressed tar). The file will be overwritten. 
"-" instead of a filename will print to STDOUT

=back

=cut

sub export_database {
    my ( $self, $export_file ) = @_;
    
    my ( $tar, @temp_files );
    my $stdout = $export_file eq '-';
    
    # remove existing file
    unless ( $stdout ) {
        unlink $export_file if -f $export_file;
        croak "Cannot remove export file '$export_file'"
            if -f $export_file;
    
        # create new tar
        $tar = Archive::Tar->new();
    }
    
    # go throgh all modules
    foreach my $module( @{ $self->childs } ) {
        next unless $module->can( 'schema_definition' );
        
        while ( my ( $schema, $tables_ref ) = each %{ $module->schema_definition } ) {
            while ( my ( $table, $cols_ref ) = each %{ $tables_ref } ) {
                
                # temp file
                my ( $th, $tn );
                unless ( $stdout ) {
                    ( $th, $tn ) = tempfile( UNLINK => 0 );
                    push @temp_files, $tn;
                }
                else {
                    $th = \*STDOUT;
                }
                
                my $io = IO::YAML->new( $th )
                    or croak "Cannot file handle with YAML: $!";
                $io->auto_terminate( 1 );
                
                # get columns
                my @col_names = sort grep { !/^\-/ } keys %{ $cols_ref };
                
                # get search result and read method
                my ( $handle, $read_meth )
                    = $module->database->search_read( $schema => $table => {} );
                
                # read all records
                $| = 1;
                print STDERR "Exporting $schema / $table: " unless $stdout;
                my $count = 0;
                while ( my $row_ref = $handle->$read_meth ) {
                    print STDERR "." unless $stdout;
                    
                    # build row ..
                    my $data_ref = { map {
                        ( $_ => $row_ref->{ $_ } || "" )
                    } @col_names };
                    
                    # print yaml ..
                    print $io $data_ref
                        or confess "Could not print to YAML filehandle: $!";
                    
                    $count++;
                }
                close $io;
                
                # add table to result
                if ( $tn ) {
                    close $th;
                    $tar->add_files( $tn );
                    $tn =~ s#^/##;
                    $tar->rename( $tn => "$module/${schema}_${table}.yml" );
                }
                
                print STDERR " Done ($count)\n\n" unless $stdout;
            }
        }
    }
    
    unless ( $stdout ) {
        # write to export
        $tar->write( $export_file, COMPRESS_GZIP );
        
        # cleanup
        undef $tar;
        unlink $_ for @temp_files;
    }
    
    return;
}


=head2 import_database

=cut

sub import_database {
    my ( $self, $import_file, $args_ref ) = @_;
    $args_ref ||= { replace => 0 };
    
    # open tar file
    my $tar = Archive::Tar->new( $import_file, COMPRESS_GZIP )
        or croak "Cannot open import file '$import_file' for read: $!\n";
    
    # go throgh all modules
    foreach my $module( @{ $self->childs } ) {
        next unless $module->can( 'schema_definition' );
        
        while ( my ( $schema, $tables_ref ) = each %{ $module->schema_definition } ) {
            while ( my ( $table, $cols_ref ) = each %{ $tables_ref } ) {
                
                # determine file to be extracted
                my $file = "$module/${schema}_${table}.yml";
                
                # if tar does not contain file -> ignore
                next unless $tar->contains_file( $file );
                
                # create tempfile
                my ( $th, $tn ) = tempfile( UNLINK => 0, SUFFIX => ".yml" );
                
                # extract tar
                $tar->extract_file( $file => $tn );
                
                # read file
                reset $th;
                my $io;
                eval {
                    $io = IO::YAML->new( $th );
                };
                croak "Errro: $@" if $@;
                $io->auto_load( 1 );
                
                $| = 1;
                print STDERR "Importing $schema / $table: ";
                my $count = 0;
                while( my $row_ref = $io->next ) {
                    print STDERR ".";
                    $module->database->set( $schema => $table => $row_ref => $row_ref );
                    $count++;
                }
                print STDERR " Done ($count)\n\n";
                
                # cleanup
                $io->close;
                close $th;
                unlink( $tn );
            }
        }
    }
    
}




=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut




1;
