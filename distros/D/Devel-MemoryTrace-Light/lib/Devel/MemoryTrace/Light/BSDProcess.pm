package Devel::MemoryTrace::Light::BSDProcess;

use strict;
use warnings;

use BSD::Process;

my $mem = BSD::Process->new();

sub get_mem {
	$mem->refresh;

	return $mem->maxrss * 1024;
}

# We forked? Re-init
sub forked {
	$mem = BSD::Process->new();
}

1;


=pod

=head1 NAME

Devel::MemoryTrace::Light::BSDProcess - A L<BSD::Process> memory provider

=head1 SYNOPSIS

Do not use this module directly. See L<Devel::MemoryTrace::Light>

=head1 DESCRIPTION

Provides a L<BSD::Process> memory examiner to L<Devel::MemoryTrace::Light>

=head1 AUTHOR

Matthew Horsfall (alh) - <WolfSage@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Matthew Horsfall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
