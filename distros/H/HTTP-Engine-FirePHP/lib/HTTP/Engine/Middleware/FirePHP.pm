package HTTP::Engine::Middleware::FirePHP;

use strict;
use warnings;
use HTTP::Engine::FirePHP;

our $VERSION = '0.02';

1;

__DATA__

=head1 NAME

HTTP::Engine::Middleware::FirePHP - Middleware adapter for HTTP::Engine::FirePHP

=head1 SYNOPSIS

    my $mw = HTTP::Engine::Middleware->new;
    $mw->install(qw/ HTTP::Engine::Middleware::FirePHP /);
    HTTP::Engine->new(
        interface => {
            module => 'YourFavoriteInterfaceHere',
            request_handler => $mw->handler( \&handler ),
        }
    )->run;

=head1 DESCRIPTION

This module is an adapter for L<HTTP::Engine::FirePHP> so it can be used with
L<HTTP::Engine::Middleware>. It doesn't actually do anything except load
L<HTTP::Engine::FirePHP>, but it just seemed that that module should be
loadable using the Middleware syntax, so here it is.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see L<http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

The development version lives at
L<http://github.com/hanekomu/http-engine-firephp/>. Instead of sending
patches, please fork this project using the standard git and github
infrastructure.

=head1 AUTHORS

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

