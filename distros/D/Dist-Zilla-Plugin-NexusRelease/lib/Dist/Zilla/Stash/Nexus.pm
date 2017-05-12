use strict;
use warnings;

package Dist::Zilla::Stash::Nexus;
$Dist::Zilla::Stash::Nexus::VERSION = '1.0.1';
# ABSTRACT: a stash of your Nexus credentials

use Moose;

use namespace::autoclean;


has username => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has password => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

with 'Dist::Zilla::Role::Stash::Login';
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Stash::Nexus - a stash of your Nexus credentials

=head1 VERSION

version 1.0.1

=head1 OVERVIEW

The Nexus stash is a L<Login|Dist::Zilla::Role::Stash::Login> stash used for uploading to Sonatype Nexus.

=head1 AUTHOR

Brad Macpherson <brad@teched-creations.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Brad Macpherson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
