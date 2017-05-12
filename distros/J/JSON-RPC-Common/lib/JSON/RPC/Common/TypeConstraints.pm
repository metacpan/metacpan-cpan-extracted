#!/usr/bin/perl

package JSON::RPC::Common::TypeConstraints;
$JSON::RPC::Common::TypeConstraints::VERSION = '0.11';
# ABSTRACT: Type constraint library

use strict;
use warnings;

use MooseX::Types -declare => [qw(JSONDefined JSONValue JSONContainer)];
use MooseX::Types::Moose qw(Value ArrayRef HashRef Undef);

subtype JSONDefined, as Value|ArrayRef|HashRef;

subtype JSONValue, as Undef|Value|ArrayRef|HashRef;

subtype JSONContainer, as ArrayRef|HashRef;

__PACKAGE__

__END__

=pod

=head1 NAME

JSON::RPC::Common::TypeConstraints - Type constraint library

=head1 VERSION

version 0.11

=head1 SYNOPSIS

	use JSON::RPC::Common::TypeConstraints qw(JSONValue);

=head1 DESCRIPTION

See L<MooseX::Types>

=head1 TYPES

=over 4

=item JSONDefined

C<Value|ArrayRef|HashRef>

=item JSONValue

C<Undef|Value|ArrayRef|HashRef>

=item JSONContainer

C<ArrayRef|HashRef>

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman and others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
