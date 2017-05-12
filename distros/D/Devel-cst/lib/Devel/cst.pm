package Devel::cst;
$Devel::cst::VERSION = '0.010';
use strict;
use warnings;
use XSLoader;

$^P = 0 if $^P == 0x73f && not defined &DB::DB && caller eq 'main' && keys %INC == 1;
XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

# ABSTRACT: C stacktraces for GNU systems

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::cst - C stacktraces for GNU systems

=head1 VERSION

version 0.010

=head1 SYNOPSIS

 perl -d:cst -e ...

=head1 DESCRIPTION

This module sets signal handlers for C<SIGSEGV>, C<SIGBUS>, C<SIGILL>, C<SIGFPE>, C<SIGTRAP>, C<SIGABRT> and C<SIGQUIT> that prints a stacktrace and some more information about the fault to stderr before dying. This enables debugging even without gdb being present.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
