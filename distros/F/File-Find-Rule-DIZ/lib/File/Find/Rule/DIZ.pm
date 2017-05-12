package File::Find::Rule::DIZ;

=head1 NAME

File::Find::Rule::DIZ - Rule to match the contents of a FILE_ID.DIZ

=head1 SYNOPSIS

    use File::Find::Rule::DIZ;

    my @files = find( diz => { text => qr/stuff and things/ }, in => '/archives' );

=head1 DESCRIPTION

This module will search through a ZIP archive, specifically the contents of the FILE_ID.DIZ
file in the archive.

=cut

use strict;
use warnings;

use File::Find::Rule;
use base qw( File::Find::Rule );
use vars qw( @EXPORT $VERSION );

@EXPORT  = @File::Find::Rule::EXPORT;
$VERSION = '0.06';

use Archive::Zip;

=head1 METHODS

=head2 diz( %options )

    my @files = find( diz => { text => qr/stuff and things/ }, in => '/archives' );

For now, all you can do is search the text using a regex. Yehaw.

=cut

sub File::Find::Rule::diz {
    my $self = shift->_force_object;

    # Procedural interface allows passing arguments as a hashref.
    my %criteria = UNIVERSAL::isa( $_[ 0 ], 'HASH' ) ? %{ $_[ 0 ] } : @_;

    $self->exec( sub {
        my $file = shift;

        # is it a binary file?
        return unless -B $file;

        # is it a zip file?
        my $zip = Archive::Zip->new( $file );
        return unless $zip;

        # does it contain a file_id.diz?
        my $member = $zip->memberNamed( 'FILE_ID.DIZ' );
        return unless $member;

        # does it match the desired data?
        my $diz = $member->contents;
        return unless $diz =~ $criteria{ text };

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

=item * File::Find::Rule

=item * File::Find::Rule::MP3Info

=back

=cut

1;
