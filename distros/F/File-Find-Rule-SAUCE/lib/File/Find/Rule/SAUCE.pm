package File::Find::Rule::SAUCE;

=head1 NAME

File::Find::Rule::SAUCE - Rule to match on title, author, etc from a file's SAUCE record

=head1 SYNOPSIS

    use File::Find::Rule::SAUCE;

    # get all files where 'Brian' is the author
    my @files = find( sauce => { author => qr/Brian/ }, in => '/ansi' );

    # get all files without a SAUCE rec
    @files    = find( sauce => { has_sauce => 0 }, in => '/ansi' );


=head1 DESCRIPTION

This module will search through a file's SAUCE metadata (using File::SAUCE) and match on the
specified fields.

=cut

use strict;
use warnings;

use File::Find::Rule;
use base qw( File::Find::Rule );
use vars qw( @EXPORT $VERSION );

@EXPORT  = @File::Find::Rule::EXPORT;
$VERSION = '0.06';

use File::SAUCE;

=head1 METHODS

=head2 sauce( %options )

    my @files = find( sauce => { title => qr/My Ansi/ }, in => '/ansi' );

If more than one field is specified, it will only return the file if ALL of the criteria
are met. You can specify a regex (qr//) or just a string.

Matching on the comments field will search each line of comments for the requested string.

has_sauce is a special field which should be matched against true or false values (no regexes).
has_sauce => 1 is implied if not specified.

See File::SAUCE for a list of all the fields that can be matched.

=cut

sub File::Find::Rule::sauce {
    my $self = shift()->_force_object;

    # Procedural interface allows passing arguments as a hashref.
    my %criteria = UNIVERSAL::isa( $_[ 0 ], 'HASH' ) ? %{ $_[ 0 ] } : @_;

    $self->exec( sub {
        my $file = shift;

        return if -d $file;

        my $info = File::SAUCE->new( file => $file );

        # deal with files (not) having SAUCE records first
        if( exists $criteria{ has_sauce } ) {
            return 0 unless $info->has_sauce == $criteria{ has_sauce };
        }
        # if has_sauce was not specified, there's no point in continuing
        # when the file has no SAUCE record
        elsif( $info->has_sauce == 0 ) {
            return 0;
        }

        # passed has_sauce - check the other criteria
        for my $field ( keys %criteria ) {
            $field = lc( $field );
            next if $field eq 'has_sauce';

            if ( $field eq 'comments' ) {

                my $comments = $info->comments;

                if ( ref $criteria{ $field } eq 'Regexp' ) {
                    if ( scalar @$comments > 0 ) {
                        return unless grep( $_ =~ $criteria{ $field }, @{ $comments } );
                    }
                    else {
                        return unless '' =~ $criteria{ $field };
                    }
                }
                else {
                    if ( scalar @$comments > 0 ) {
                        return unless grep( $_ eq $criteria{ $field }, @{ $comments } );
                    }
                    else {
                        return unless $criteria{ $field } eq '';
                    }
                }    
            }
            elsif ( ref $criteria{ $field } eq 'Regexp' ) {
                return unless $info->$field =~ $criteria{ $field };
            }
            else {
                return unless $info->$field eq $criteria{ $field };
            }
        }
        return 1;
    } );
}

=head1 AUTHOR

=over 4 

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

=over 4 

=item * File::SAUCE

=item * File::Find::Rule

=item * File::Find::Rule::MP3Info

=back

=cut

1;
