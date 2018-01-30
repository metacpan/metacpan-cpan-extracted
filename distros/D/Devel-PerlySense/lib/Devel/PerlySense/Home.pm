=head1 NAME

Devel::PerlySense::Home - A User Home root directory


=head1 DESCRIPTION

The User Home is the place where User specific settings/cache,
etc. are kept.

=cut





use strict;
use warnings;
use utf8;

package Devel::PerlySense::Home;
$Devel::PerlySense::Home::VERSION = '0.0219';


use Spiffy -Base;
use Carp;
use Data::Dumper;
use File::Basename;
use File::Path;
use Path::Class;

use Devel::PerlySense::Util;





=head1 PROPERTIES

=head2 aDirHomeCandidate

List of candidates for User Home root dirs.

Readonly.

=cut
sub aDirHomeCandidate {
    return(
        grep { $_ } (
            $ENV{APPDATA},
            $ENV{ALLUSERSPROFILE},
            $ENV{USERPROFILE},
            $ENV{HOME},
            $ENV{TEMP},
            $ENV{TMP},
            "/",
        ),
    );
}





=head2 dirHome

The User Home root dir, or "" if no home dir could be identified.

Readonly.

=cut
sub dirHome {

    for my $dirHome( $self->aDirHomeCandidate ) {
        my $dir = dir($dirHome, ".PerlySense");
        mkpath([$dir]);
        -d $dir and return $dir;
    }

    return "";
}





=head2 dirHomeCache

The User Home cache dir, or "" if no home dir could be identified.

Readonly.

=cut
sub _dirSubHomeCreate {
    my ($dirSub) = @_;

    my $dirHome = $self->dirHome or return "";
    my $dir = dir($dirHome, $dirSub);
    mkpath([$dir]);
    -d $dir or return "";

    return $dir;    
}
sub dirHomeCache {
    $self->_dirSubHomeCreate("cache");
}





=head2 dirHomeLog

The User Home log dir, or "" if no home dir could be identified.

Readonly.

=cut
sub dirHomeLog {
    $self->_dirSubHomeCreate("log");
}





1;





__END__

=encoding utf8

=head1 AUTHOR

Johan Lindstrom, C<< <johanl@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-devel-perlysense@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-PerlySense>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
