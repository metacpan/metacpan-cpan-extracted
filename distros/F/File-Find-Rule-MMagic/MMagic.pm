# $Id: MMagic.pm 877 2002-10-29 11:16:05Z richardc $
package File::Find::Rule::MMagic;
use strict;

use File::Find::Rule;
use base qw( File::Find::Rule );
use vars qw( $VERSION @EXPORT );
@EXPORT  = @File::Find::Rule::EXPORT;
$VERSION = '0.02';

use File::MMagic;
use Text::Glob qw(glob_to_regex);

sub File::Find::Rule::magic {
    my $self = shift()->_force_object;
    my @patterns = map { ref $_ ? $_ : glob_to_regex $_ } @_;
    my $mm = new File::MMagic;
    $self->exec( sub {
                     my $type = $mm->checktype_filename($_);
                     for (@patterns) { return 1 if $type =~ m/$_/ }
                     return;
                 } );
}

1;
__END__

=head1 NAME

File::Find::Rule::MMagic - rule to match on mime types

=head1 SYNOPSIS

 use File::Find::Rule::MMagic;
 my @images = find( file => magic => 'image/*', in => '.' );

=head1 DESCRIPTION

File::Find::Rule::MMagic interfaces File::MMagic to File::Find::Rule
enabling you to find files based upon their mime type.  Text::Glob
is used so that the patter may be a simple globbing pattern.

=head2 ->magic( @patterns )

Match only things with the mime types specified by @patterns.  The
specification can be a glob pattern, as provided by L<Text::Glob>.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>, from an idea by Mark Fowler.

=head1 COPYRIGHT

Copyright (C) 2002 Richard Clamp.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<File::Find::Rule>, L<Text::Glob>, L<File::MMagic>

=cut
