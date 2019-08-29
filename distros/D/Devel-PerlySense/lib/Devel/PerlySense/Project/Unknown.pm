=head1 NAME

Devel::PerlySense::Project::Unknown - A Project null object.

=head1 SYNOPSIS




=head1 DESCRIPTION

A Project::Unknown indicates the lack of a project being defined.

=cut





package Devel::PerlySense::Project::Unknown;
$Devel::PerlySense::Project::Unknown::VERSION = '0.0220';
use base "Devel::PerlySense::Project";






use strict;
use warnings;
use Carp;
use Data::Dumper;
use utf8;





=head1 PROPERTIES

=head2 dirProject

The effective project root dir.

Readonly.

=cut
sub dirProject {
    return "";
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
