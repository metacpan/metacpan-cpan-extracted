#!/usr/bin/env perl
# PODNAME: githooks.pl
# ABSTRACT: Git::Hooks driver script

use v5.16.0;
use warnings;
use Git::Hooks;

run_hook($0, @ARGV);

__END__

=pod

=encoding UTF-8

=head1 NAME

githooks.pl - Git::Hooks driver script

=head1 VERSION

version 3.2.0

=head1 AUTHOR

Gustavo L. de M. Chaves <gnustavo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by CPQD <www.cpqd.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
