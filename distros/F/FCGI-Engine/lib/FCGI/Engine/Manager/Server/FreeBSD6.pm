package FCGI::Engine::Manager::Server::FreeBSD6;
use Moose;

our $VERSION   = '0.22'; 
our $AUTHORITY = 'cpan:STEVAN';

extends 'FCGI::Engine::Manager::Server';

override 'construct_command_line' => sub {
    my @command_line = super();
    pop @command_line;
    return (
        "/usr/sbin/daemon",
        "sh", "-c",
        (join " " => @command_line)
    );
};

1;

__END__

=pod

=head1 NAME

FCGI::Engine::Manager::Server::FreeBSD6 - A subclass of FCGI::Engine::Manager::Server specific to FreeBSD 6.*

=head1 DESCRIPTION

This may not even be needed anymore, but at one time it was. This works 
around the fact that L<FCGI::ProcManager> didn't like to be dameonized
on FreeBSD 6.*. I suspect that now that I have switched this to use 
L<FCGI::Engine::ProcManager> that it is no longer an issue. But at this 
point I have not have the opportunity to test this theory, so I am 
leaving this here for historical purposes and as an example of subclassing
L<FCGI::Engine::Manager::Server>.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut




