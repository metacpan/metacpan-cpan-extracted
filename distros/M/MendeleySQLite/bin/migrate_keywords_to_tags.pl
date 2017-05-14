#!/usr/bin/perl

use strict;
use warnings;

use MendeleySQLite;
use Data::Dumper;
use Getopt::Long;

# ABSTRACT: Migrate your keywords to tags
# PODNAME: migrate_keywords_to_tags.pl

my $rh_params = { };

GetOptions(
    $rh_params,
    'help',
    'dbfile:s' );

if ( $rh_params->{'help'} ){
    help_and_exit();
}

unless ( defined $rh_params->{'dbfile'} ){
    help_and_exit();
}

my $M = 
    MendeleySQLite->new( { dbfile => $rh_params->{'dbfile'} } );

my $ra_all_ids = $M->get_all_document_ids();

if ( ! scalar(@$ra_all_ids) ) {
    die "No documents found."
} else {
    printf "Found %d documents.\n", scalar(@$ra_all_ids);
}

foreach my $id ( @$ra_all_ids ) {
    
    my $ra_document_keywords = 
        $M->get_all_keywords_for_document( $id );
        
    if ( ! scalar(@$ra_document_keywords) ) {
        next;
    }
    
    foreach my $keyword ( @$ra_document_keywords ) {
        $M->set_tag_for_document( $id, $keyword );
    }
            
}

print "All done.\n";
    
#################################################################################
#################################################################################

sub help_and_exit {
    print << "END"
    
    $0 : Migrate all your keywords to tags in your library. For each document, each defined keyword
    will also be made a tag (unless it already exists). Existing tags and keywords will not be touched.
    
    --help    : print this help message and exit
    --dbfile  : path to SQLite database file
    
    **NOTE**  This script will actually write to your database. Make sure you have backup copy. **NOTE**
END
;
    
}
__END__
=pod

=head1 NAME

migrate_keywords_to_tags.pl - Migrate your keywords to tags

=head1 VERSION

version 0.002

=head1 AUTHOR

Spiros Denaxas <s.denaxas@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Spiros Denaxas.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

