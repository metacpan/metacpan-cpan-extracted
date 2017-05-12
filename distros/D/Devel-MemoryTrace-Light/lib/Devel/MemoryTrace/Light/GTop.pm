package Devel::MemoryTrace::Light::GTop;

use strict;
use warnings;

use GTop;

my $gtop = GTop->new();

sub get_mem {
	return $gtop->proc_mem($$)->resident;
}

# We forked? Re-init
sub forked {
	$gtop = GTop->new();
}

1;


=pod

=head1 NAME

Devel::MemoryTrace::Light::GTop - A L<GTop> memory provider

=head1 SYNOPSIS

Do not use this module directly. See L<Devel::MemoryTrace::Light>

=head1 DESCRIPTION

Provides a L<GTop> memory examiner to L<Devel::MemoryTrace::Light>

=head1 AUTHOR

Matthew Horsfall (alh) - <WolfSage@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Matthew Horsfall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
