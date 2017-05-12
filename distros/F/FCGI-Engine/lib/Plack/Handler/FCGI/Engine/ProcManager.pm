package Plack::Handler::FCGI::Engine::ProcManager;
use Moose;

our $VERSION   = '0.22';
our $AUTHORITY = 'cpan:STEVAN';

extends 'FCGI::Engine::ProcManager';

has 'pidfile' => (
    init_arg => 'pid_fname',
    is       => 'rw',
    isa      => 'MooseX::Daemonize::Pid::File',
    coerce   => 1,
);

# FCGI::ProcManager compat

sub pm_manage        { (shift)->manage( @_ )        }
sub pm_pre_dispatch  { (shift)->pre_dispatch( @_ )  }
sub pm_post_dispatch { (shift)->post_dispatch( @_ ) }

sub notify {
    my ($self, $msg) = @_;
    $msg =~ s/\s*$/\n/;
    print STDERR "FastCGIEngine: " . $self->role() . " (pid $$): " . $msg;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Plack::Handler::FCGI::Engine::ProcManager - A process manager for Plack::Handler::FCGI::Engine

=head1 DESCRIPTION

A subclass of L<FCGI::Engine::ProcManager> that is compatiable with
L<Plack::Handler::FCGI::Engine> and L<Plack::Handler::FCGI>.

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
