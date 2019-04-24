package Limper::Engine;
$Limper::Engine::VERSION = '0.014';
use 5.10.0;
use strict;
use warnings;

1;

__END__

=head1 NAME

Limper::Engine - placeholder for the Limper::Engine namespace

=head1 VERSION

version 0.014

=head1 SYNOPSIS

Do not use this module directly. It currently does absolutely nothing, and likely never will.

=head1 DESCRIPTION

This namespace is specifically for plugins that connect L<Limper> to a
particular web server or protocol (like L<Limper::Engine::PSGI>), using
hooks L<Limper/request_handler> and L<Limper/response_handler>.

See L<Limper::Extending> for how to write L<Limper> plugins.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Ashley Willis E<lt>ashley+perl@gitable.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.
