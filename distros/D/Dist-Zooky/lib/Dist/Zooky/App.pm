package Dist::Zooky::App;
$Dist::Zooky::App::VERSION = '0.22';
# ABSTRACT: Dist::Zooky's App::Cmd

use strict;
use warnings;
use App::Cmd::Setup 0.307 -app;

sub default_command { 'dist' }

qq[Meep];

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zooky::App - Dist::Zooky's App::Cmd

=head1 VERSION

version 0.22

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
