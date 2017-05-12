package Dezi::Bot::Utils;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use Path::Class;

our $VERSION = '0.003';

=head1 NAME

Dezi::Bot::Utils - web crawler utilities

=head1 SYNOPSIS

 use Dezi::Bot::Utils;
 my $path = Dezi::Bot::Utils::file_cache_path( $base, $file );
 # $path isa Path::Class::File object

=head1 DESCRIPTION

The Dezi::Bot::Utils provides utility functions for Dezi::Bot.

=head1 FUNCTIONS

=head2 file_cache_path( I<base>, I<file> )

Returns a Path::Class::File object for I<file>
under I<base> directory path. Up to two subdirectory levels
are created between I<base> and I<file> in order
to spread out the file hierarchy, similar to L<File::Cache>
pattern.

=cut

sub file_cache_path {
    my ( $base, $file ) = @_;
    my $path;
    if ( my ( $first, $second ) = ( $file =~ m/^(.)(.)/ ) ) {
        $path = dir($base)->subdir( $first, $second )->file($file);
    }
    else {
        my ($first) = ( $file =~ m/^(.)/ );
        $path = dir($base)->subdir($first)->file($file);
    }
    return $path;
}

=head2 update_or_insert( I<dbix_inserthash>, I<args> )

Takes same I<args> as DBIx::InsertHash->update() 
but will make educated guess at whether to insert
or update the data.

Returns the row id if insert() was called, 
otherwise returns hash ref of the updated
row.

=cut

sub update_or_insert {
    my ( $dbix, $data, $vars, $where, $table, $dbh ) = @_;

    # object defaults
    if ( ref $dbix ) {
        $where ||= $dbix->where;
        $table ||= $dbix->table;
        $dbh   ||= $dbix->dbh;
    }
    my $up = $dbix->update( $data, $vars, $where, $table, $dbh );
    unless ( $up > 0 ) {
        my $id = $dbix->insert( $data, $table, $dbh );
        if ( $dbh->err ) {
            croak "can't insert data: " . dump($data);
        }
        return $id;
    }

    my @vars = ( $vars ? @$vars : () );
    my $sth = $dbh->prepare("SELECT * FROM $table WHERE $where");
    $sth->execute(@vars);
    return $sth->fetchrow_hashref;
}

1;

__END__

=head1 METHODS

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-bot at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-Bot>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::Bot


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-Bot>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-Bot>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-Bot>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi-Bot/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2013 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


