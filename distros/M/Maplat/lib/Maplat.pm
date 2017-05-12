package Maplat;

use 5.010000;
use strict;
use warnings;

use base qw(Exporter);

our $VERSION = 0.995;



1;
__END__

=head1 NAME

Maplat - The MAPLAT Web Framework

=head1 SYNOPSIS

This Module is actually a stub (don't use it). The Maplat Framework is
divided into various parts, mainly Maplat::Helpers, Maplat::Worker and
Maplat::Web. Please see these modules for more detailed information

=head1 DESCRIPTION

There are currently three parts of the Framework.

Maplat::Web is the WebGUI system, i.e. the part of the framework that
helps you render the webbased graphical interface. Maplat::Web is based on
HTTP::Server::Simple::CGI and has (alpha level) support for SSL and preforking.

Maplat::Worker is the background system. All long-running tasks (more than a
second or so) should be done with one or more background worker.

Maplat::Helpers is a library of modules with various helper modules like special
date parsing, sendmail-a-file and things like that.

=head1 SEE ALSO

Maplat::Web
Maplat::Worker

Please, also take a look at the included example in the tarball available on CPAN.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

This library includes other open source software, mainly jQuery modules,
jQuery.sheet() and the FCKEditor. This programs are not a fork, they are
just included for convienience.

=cut
