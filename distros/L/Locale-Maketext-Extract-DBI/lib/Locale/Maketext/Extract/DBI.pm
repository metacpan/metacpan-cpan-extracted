package Locale::Maketext::Extract::DBI;

use strict;
use warnings;

use Locale::Maketext::Extract;
use DBI;
use Cwd;

our $VERSION = '0.01';

=head1 NAME

Locale::Maketext::Extract::DBI - Extract translation keys from a database

=head1 SYNOPSIS

    my $extractor = Locale::Maketext::Extract::DBI->new;
    $extract->extract( %options );

=head1 DESCRIPTION

This module extracts translation keys from a database table.

=head1 METHODS

=head2 new( )

Creates a new C<Locale::Maketext::Extract::DBI> instance.

=cut

sub new {
    my $class = shift;
    return bless {}, $class;
}

=head2 extract( %options )

The main method for extraction. Take a list of options to pass to
C<Locale::Maketext::Extract> and C<extract_dbi>.

=cut

sub extract {
    my $self    = shift;
    my %options = @_;

    my $extractor = Locale::Maketext::Extract->new;
    my $output    = $options{ o } || ( $options{ d } || 'messages' ) . '.po' ;
    my $cwd       = getcwd;

    $extractor->read_po( $output ) if -r $output and -s _;
    $self->extract_dbi( $extractor, %options );
    $extractor->compile;
 
    chdir( $options{ p } || '.' );
    $extractor->write_po( $output );   
    chdir $cwd;
}

=head2 extract_dbi( $extractor, %options )

Connects to the database, runs the query and stuffs the results in to
the C<$extractor>.

=cut

sub extract_dbi {
    my( $self, $extractor, %options ) = @_;
    
    my $dbh   = DBI->connect( ( map{ $options{ $_ } } qw( dsn username password ) ), { RaiseError => 1 } );
    my $query = $options{ query };
    
    my $results = $dbh->selectall_arrayref( $query );
    for( 0..@$results - 1 ) {
        $extractor->add_entry( $results->[ $_ ]->[ 0 ] => [ "dbi:$query", $_ + 1] );
    }
}

=head1 AUTHOR

=over 4 

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

=over 4 

=item * L<Locale::Maketext::Extract>

=back

=cut

1;