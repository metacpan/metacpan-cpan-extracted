package Martian;

use 5.006;
use strict;
use warnings FATAL => 'all';


our $VERSION = '0.06';



1; # End of Martian

__END__

=pod

=encoding UTF-8

=head1 NAME

Martian

=head1 VERSION

version 0.06

=head1 SYNOPSIS

This is an extension of the Starman server that can be run via Starman by specifying
the server Martian.  It allows the server to kill the processes when they use
too much memory.  This is done between requests so that the web server isn't interrupted.
This is similar to the max requests parameter.

    starman phoenix-ui-admin.psgi --listen :5001 --server Martian --memory-limit 10000

The memory figure relates to the processes 'maximum shared memory or current resident set'
which shows up in top/htop as RES.  The figure is in KiB.

=head1 NAME

Martian - A more constrained Starman

=head1 VERSION

Version 0.06

=head1 AUTHOR
OpusVL, C<< <support at opusvl.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-martian at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Martian>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Martian

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2014 OpusVL.

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
