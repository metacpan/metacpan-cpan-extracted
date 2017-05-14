#!/usr/bin/perl

use strict;
use warnings;

package MendeleySQLite;

use Data::Dumper;
use DBI;
use SQL::Abstract;

# ABSTRACT: A collection of tools for working with Mendeley Desktop's SQLite backend.


sub new {
    my $class     = shift;
    my $rh_params = shift;
    my $self      = { };
    
    unless ( defined $rh_params->{dbfile} && -e $rh_params->{dbfile} ){
        die "Specify the path to the SQLite database using the dbfile parameter."
    }
    
    $self->{dbh} = 
        DBI->connect("dbi:SQLite:dbname=$rh_params->{dbfile}","","");
        
    unless ( $self->{dbh} ) {
        die "Could not connect to $rh_params->{dbfile}."
    }
    
    $self->{sql} = SQL::Abstract->new();
    
    return bless $self, $class;
}


sub get_all_keywords {
    my $self = shift;    
    
    my $sql_all_keywords = 
        'SELECT keyword,COUNT(*) AS n from DocumentKeywords GROUP BY keyword';
    
    my $sth = $self->_execute_sql( $sql_all_keywords );
    
    my $ra_all = $sth->fetchall_arrayref();
    
    my $rh_out = { };
    
    foreach my $ra ( @$ra_all ) {
        $rh_out->{$ra->[0]} = $ra->[1];
    }
    
    return $rh_out;    
    
}


sub get_all_tags {
    my $self = shift;
    
    my $sql_all_tags = 
        'SELECT tag,COUNT(*) AS n from DocumentTags GROUP BY tag';
    
    my $sth = $self->_execute_sql( $sql_all_tags );
    
    my $ra_all = $sth->fetchall_arrayref();
    
    my $rh_out = { };
    
    foreach my $ra ( @$ra_all ) {
        $rh_out->{$ra->[0]} = $ra->[1];
    }
    
    return $rh_out;    
    
}


sub get_all_tags_for_document {
    my $self = shift;
    my $document_id = shift;
    
    return undef if ( ! defined $document_id );
    
    my $ra_output = [ ];
        
    my ( $sql, $ra_bind ) = 
        $self->_create_sql( 'select', 'DocumentTags', [ 'tag' ], { documentId => $document_id } );
    
    my $sth = $self->_execute_sql( $sql, $ra_bind );
  
    my $ra_all = $sth->fetchall_arrayref();
    
    unless ( scalar(@$ra_all) ) {
        return $ra_output;
    }    
    
    foreach my $ra ( @$ra_all ) {
        push( @$ra_output, $ra->[0] );
    }

    return $ra_output;
}


sub get_all_keywords_for_document {
    my $self        = shift;
    my $document_id = shift;
    
    return undef if ( ! defined $document_id );
    
    my $ra_output = [ ];
        
    my ( $sql, $ra_bind ) = 
        $self->_create_sql( 'select', 'DocumentKeywords', [ 'keyword' ], { documentId => $document_id } );
    
    my $sth = $self->_execute_sql( $sql, $ra_bind );
  
    my $ra_all = $sth->fetchall_arrayref();
    
    unless ( scalar(@$ra_all) ) {
        return $ra_output;
    }    
    
    foreach my $ra ( @$ra_all ) {
        push( @$ra_output, $ra->[0] );
    }

    return $ra_output;
}


sub set_keyword_for_document {
    my $self    = shift;
    my $id      = shift;
    my $keyword = shift;
    
    return undef
        if ( ! defined $id || ! defined $keyword );
    
    my $ra_keywords = 
        $self->get_all_keywords_for_document( $id );
    
    my %keywords = map { $_ => 1 } @$ra_keywords;
    
    ## If the keyword exists already, do not try to re-insert it as the query
    ## will fail the referential constraint set by the table's schema.
    
    if ( exists $keywords{$keyword} ) {
        return 1;
    }
    
    my ( $sql, $ra_bind ) =
            $self->_create_sql( 'insert', 'DocumentKeywords', { 'documentId' => $id, 'keyword' => $keyword } );

    return $self->_execute_sql( $sql, $ra_bind );
}


sub set_tag_for_document {
    my $self    = shift;
    my $id      = shift;
    my $tag = shift;
    
    return undef
        if ( ! defined $id || ! defined $tag );
    
    my $ra_tags = 
        $self->get_all_tags_for_document( $id );
    
    my %tags = map { $_ => 1 } @$ra_tags;
    
    ## If the tag exists already, do not try to re-insert it as the query
    ## will fail the referential constraint set by the table's schema.
    
    if ( exists $tags{$tag} ) {
        return 1;
    }
    
    my ( $sql, $ra_bind ) =
            $self->_create_sql( 'insert', 'DocumentTags', { 'documentId' => $id, 'tag' => $tag } );

    return $self->_execute_sql( $sql, $ra_bind );
}



sub get_document {
    my $self = shift;
    my $id   = shift;
    
    return undef if ( ! defined $id );
    
    my ( $sql, $ra_bind ) =
        $self->_create_sql( 'select', 'Documents', [ '*' ], { id => $id } );
    
    my $sth = $self->_execute_sql( $sql, $ra_bind );

    my $rhh = $sth->fetchall_hashref('id');
        
    my $rh_document = $rhh->{ $id };
    
    if ( ! defined $rh_document ) {
        return undef;
    }
    
    my $ra_keywords = $self->get_all_keywords_for_document( $id );
    
    if ( scalar(@$ra_keywords) ) {
        $rh_document->{keywords} = $ra_keywords;
    }
    
    my $ra_tags = $self->get_all_tags_for_document( $id );
    
    if ( scalar(@$ra_tags) ) {
        $rh_document->{tags} = $ra_tags
    }
    
    return $rh_document;
    
}


sub get_all_document_ids {
    my $self = shift;
    
    my $ra_out = [ ];
    
    my ( $sql, $ra_bind ) =
        $self->_create_sql( 'select', 'Documents', [ 'id' ], {  } );
    
    my $sth = $self->_execute_sql( $sql, $ra_bind );
    
    my $raa = $sth->fetchall_arrayref();
    
    foreach my $ra ( @$raa ) {
        push(@$ra_out, $ra->[0]);
    }
    
    return $ra_out;    
}

sub _create_sql {
    my $self      = shift;
    my $op        = shift;
    my $table     = shift;
    my $r_fields  = shift;
    my $r_params  = shift;
    
    my $stmt;
    my @bind;
    
    if ( $op eq 'select' ) {
        ( $stmt, @bind ) =
            $self->{sql}->select( $table, $r_fields, $r_params );
    } 
    
    elsif ( $op eq 'insert' ) {
        ( $stmt, @bind ) =
            $self->{sql}->insert( $table, $r_fields );        
    }
            
    return ( $stmt, \@bind );
}

sub _execute_sql {
    my $self = shift;
    my $sql  = shift;
    my $ra_params = shift || [ ];
        
    my $sth = 
        $self->{dbh}->prepare( $sql );
        
    $sth->execute( @$ra_params );
    
    return $sth;    
    
}


1;
__END__
=pod

=head1 NAME

MendeleySQLite - A collection of tools for working with Mendeley Desktop's SQLite backend.

=head1 VERSION

version 0.002

=head2 new

Returns a new instance of the class.

    my $rh = { 'dbfile' => 'path/to/db' };
    my $M = MendeleySQLite->new( $rh );

=head2 get_all_keywords

Get all keywords associated with documents from your library. Returns a reference to a hash
with the keywords and their frequency.

    my $rh_keywords = $M->get_all_keywords();    

=head2 get_all_tags

Get all tags associated with documents from your library. Returns a reference to a hash
with the tags and their frequency.

    my $rh_tags = $M->get_all_tags();    

=head2 get_all_tags_for_document

Get all tags associated with a document in your library. Returns a reference to an array.
This method returns undef on error.

    my $ra_tags = $M->get_all_tags_for_document( $documentid );

=head2 get_all_keywords_for_document

Get all keywords associated with a document in your library. Returns a reference to an array.
This method returns undef on error.

    my $ra_keywords = $M->get_all_keywords_for_document( $documentid );

=head2 set_keyword_for_document

Associate the specified keyword with the supplied focument id. If the keyword already exists, nothing will be done.
This function returns true on success and undef on error.

    my $rv = $M->set_keyword_for_document(1,'Moo');

=head2 set_tag_for_document

Associate the specified tag with the supplied focument id. If the tag already exists, nothing will be done.
This function returns true on success and undef on error.

    my $rv = $M->set_tag_for_document(1,'MooMooMoo');

=head2 get_document()

Retrieves a document from your library matching the supplied document id. Returns a reference to a hash.
The document tags and keywords are denormalized and the original values are supplied under the keys 'tags' and 'keywords' respectively.

This method returns undef on error.

    my $rh_document = $M->get_document( $id );

=head2 get_all_document_ids()

Returns a reference to an array of document id's in the library. 

    my $ra_ids = $M->get_all_document_ids()

=head1 AUTHOR

Spiros Denaxas <s.denaxas@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Spiros Denaxas.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

