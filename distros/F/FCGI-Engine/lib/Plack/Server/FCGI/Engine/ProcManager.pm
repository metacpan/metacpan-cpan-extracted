package Plack::Server::FCGI::Engine::ProcManager;
use Moose;

our $VERSION   = '0.22';
our $AUTHORITY = 'cpan:STEVAN';

extends 'Plack::Handler::FCGI::Engine::ProcManager';

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Plack::Server::FCGI::Engine::ProcManager - DEPRECATED use Plack::Handler::FCGI::Engine::ProcManager

=head1 DESCRIPTION

B<DEPRECATED> use Plack::Handler::FCGI::Engine::ProcManager

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
