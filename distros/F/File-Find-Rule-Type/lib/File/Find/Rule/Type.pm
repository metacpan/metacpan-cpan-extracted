package File::Find::Rule::Type;
use strict;

use File::Find::Rule;
use base qw( File::Find::Rule );
use vars qw( $VERSION @EXPORT );
@EXPORT  = @File::Find::Rule::EXPORT;
$VERSION = '0.05';

use File::Type;
use Text::Glob qw(glob_to_regex);

sub File::Find::Rule::type {
    my $self = shift()->_force_object;
    my @patterns = map { ref $_ ? $_ : glob_to_regex $_ } @_;
    my $ft = new File::Type;
    $self->exec( sub {
                     my $type = $ft->checktype_filename($_);
                     for (@patterns) { return 1 if $type =~ m/$_/ }
                     return;
                 } );
}

1;
__END__

=head1 NAME

File::Find::Rule::Type - rule to match on mime types

=head1 SYNOPSIS

 use File::Find::Rule::Type;
 my @images = find( file => type => 'image/*', in => '.' );

=head1 DESCRIPTION

File::Find::Rule::Type allows you to build Find::File::Rule searches
that are limited by MIME type, using the File::Type module. Text::Glob
is used so that the pattern may be a globbing pattern.

=head2 ->type( @patterns )

Match only things with the mime types specified by @patterns.  The
specification can be a glob pattern, as provided by L<Text::Glob>.

=head1 AUTHOR

Paul Mison <cpan@husk.org>. Shamelessly based on Richard Clamp's
L<File::Find::Rule::MMagic>, itself an idea of Mark Fowler.

=head1 COPYRIGHT

Copyright (C) 2003 Paul Mison.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<File::Find::Rule>, L<Text::Glob>, L<File::Type>, 
L<Find::File::Rule::MMagic>

=cut
