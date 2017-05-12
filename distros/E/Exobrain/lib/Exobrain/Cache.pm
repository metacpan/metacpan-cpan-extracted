package Exobrain::Cache;

use v5.10.0;
use strict;
use warnings;

use parent qw(CHI);

# ABSTRACT: Cache class for Exobrain
our $VERSION = '1.08'; # VERSION


__PACKAGE__->config({
    defaults => {
        driver   => 'File',
        root_dir => "$ENV{HOME}/.exobrain/cache",
    }
});

1;

__END__

=pod

=head1 NAME

Exobrain::Cache - Cache class for Exobrain

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    my $cache = Exobrain->cache;

=head1 DESCRIPTION

This provides a ready-made cache for any code using the Exobrain framework.

This directly inherits from the fantastic L<CHI> system. See its documentation
for more details.

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
