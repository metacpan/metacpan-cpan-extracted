use strict;
package File::Find::Rule::CVS;
use File::Find::Rule;
use Parse::CVSEntries;
use version;
use base 'File::Find::Rule';
use vars qw( $VERSION );
$VERSION = '0.01';

=head1 NAME

File::Find::Rule::CVS - find files based on CVS metadata

=head1 SYNOPSIS

 use File::Find::Rule::CVS;
 my @modified = find( cvs_modified => in => 'sandbox' );

=head1 DESCRIPTION

File::Find::Rule::CVS extends File::Find::Rule to add clauses based on
the contents of CVS/Entries files.

=head1 RULES

=cut

sub File::Find::Rule::_cvs_entry {
    my $self = shift;
    my ($file, $path) = @_;

    return $self->{_entries}{ $path }{ $file }
      if exists $self->{_entries}{ $path };

    my $parse = Parse::CVSEntries->new( "CVS/Entries" )
      or return;

    $self->{_entries}{ $path } = { map { $_->name => $_ } $parse->entries };
    return $self->{_entries}{ $path }{ $file };
}

=head2 cvs_modified

Matches a file which the cvs sandbox thinks is modified

=cut

sub File::Find::Rule::cvs_modified () {
    my $self = shift()->_force_object;
    my $sub = sub {
        my $entry = $self->_cvs_entry( @_ ) or return;
        return (stat $_)[9] > $entry->mtime;
    };
    $self->exec( $sub );
}


=head2 cvs_unknown

Matches an entry in a working directory that CVS doesn't know about

=cut

sub File::Find::Rule::cvs_unknown () {
    my $self = shift()->_force_object;
    my $sub = sub {
        return !$self->_cvs_entry( @_ );
    };
    $self->exec( $sub );
}


=head2 cvs_version( $test )

Matches files with versions that match $test.  $test is a
Number::Compare expression applied to a L<version> object.

=cut

sub File::Find::Rule::cvs_version {
    my $self = shift()->_force_object;
    my $test = Number::Compare->new( shift );

    my $sub = sub {
        my $entry = $self->_cvs_entry( @_ )
          or return;
        my $version = version->new( $entry->version );
        return $test->( $version );
    };
    $self->exec( $sub );
}


1;
__END__


=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright (C) 2003 Richard Clamp.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Parse::CVSEntries>, L<File::Find::Rule>

=cut
