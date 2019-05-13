package IPC::QWorker::WorkUnit;

use strict;
use warnings;
use utf8;

# ABSTRACT: work unit to process by IPC::QWorker
our $VERSION = '0.08'; # VERSION

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {
        'cmd' => undef,
		'params' => undef,
		@_
    };
    bless($self, $class);
    return($self);
}

1;

# vim:ts=2:expandtab:syntax=perl:

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::QWorker::WorkUnit - work unit to process by IPC::QWorker

=head1 VERSION

version 0.08

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Markus Benning <ich@markusbenning.de>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
