use strict;
package File::Path::Expand;
use User::pwent;
use Carp qw(croak);
use Exporter;
use base 'Exporter';
use vars qw( $VERSION @EXPORT @EXPORT_OK );

$VERSION   = '1.02';
@EXPORT    = qw( expand_filename );
@EXPORT_OK = qw( expand_filename  home_of );

sub expand_filename {
    my $path = shift;
    $path =~ s{^~(?=/|$)}{ $ENV{HOME} ? "$ENV{HOME}" : home_of( $> ) }e
      or $path =~ s{^~(.+?)(?=/|$)}{ home_of( $1 ) }e;
    return $path;
}

sub home_of {
    my $user = shift;
    my $ent = getpw($user)
      or croak "no such user '$user'";
    return $ent->dir;
}

1;
__END__

=head1 NAME

File::Path::Expand - expand filenames

=head1 SYNOPSIS

 use File::Path::Expand;
 print expand_filename("~richardc/foo"); # prints "/home/richardc/foo"

=head1 DESCRIPTION

File::Path::Expand expands user directories in filenames.  For the
simple case it's no more complex than s{^~/}{$HOME/}, but for other
cases it consults C<getpwent> and does the right thing.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright (c) 2003, Richard Clamp. All Rights Reserved.  This module
is free software. It may be used, redistributed and/or modified under
the same terms as Perl itself.

=cut
