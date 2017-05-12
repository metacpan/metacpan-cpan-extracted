# $Id: MMagic.pm 877 2002-10-29 11:16:05Z richardc $
package File::Find::Object::Rule::MMagic;

use strict;
use warnings;

use 5.008;

use File::Find::Object::Rule;
use parent qw( File::Find::Object::Rule );
use vars qw( $VERSION @EXPORT );
@EXPORT  = @File::Find::Object::Rule::EXPORT;
$VERSION = '0.0.4';

use File::MMagic;
use Text::Glob qw(glob_to_regex);

sub File::Find::Object::Rule::magic {
    my $self = shift()->_force_object;
    my @patterns = map { ref $_ ? $_ : glob_to_regex $_ } @_;
    my $mm = new File::MMagic;
    $self->exec( sub {
                     my (undef, undef, $path) = @_;
                     my $type = $mm->checktype_filename($path);
                     for my $pat (@patterns)
                     {
                         return 1 if $type =~ m/$pat/
                     }
                     return;
                 } );
}

1;
__END__

=head1 NAME

File::Find::Object::Rule::MMagic - rule to match on mime types

=head1 SYNOPSIS

 use File::Find::Object::Rule::MMagic;
 my @images = find( file => magic => 'image/*', in => '.' );

=head1 DESCRIPTION

File::Find::Object::Rule::MMagic interfaces L<File::MMagic> to
L<File::Find::Object::Rule> enabling you to find files based upon their mime
type.  L<Text::Glob> is used so that the pattern may be a simple globbing
pattern.

=head2 ->magic( @patterns )

Match only things with the mime types specified by @patterns.  The
specification can be a glob pattern, as provided by L<Text::Glob>.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>, from an idea by Mark Fowler.

Adapted to L<File::Find::Object::Rule::MMagic> by Shlomi Fish. All rights
disclaimed.

=head1 COPYRIGHT

Copyright (C) 2002 Richard Clamp.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<File::Find::Object::Rule>, L<Text::Glob>, L<File::MMagic>

Originally derived from L<File::Find::Rule::MMagic>

=cut
