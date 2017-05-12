package JavaScript::Framework::jQuery::Role::Plugin;

use warnings;
use strict;

use Moose::Role;
use MooseX::Types::Moose qw( Str );
use JavaScript::Framework::jQuery::Subtypes qw( libraryAssets pluginAssets );

our $VERSION = '0.05';

has 'name' => (
    is => 'ro',
    isa => Str,
    required => 1,
);

has 'target_selector' => (
    is => 'ro',
    isa => Str,
    required => 1,
);

requires 'cons_statement';

no Moose::Role;

=head1 NAME

JavaScript::Framework::jQuery::Role::Plugin - Moose role for jQuery plugin modules

=head1 SYNOPSIS

 package mypackage;

 use Moose;
 with 'JavaScript::Framework::jQuery::Role::Plugin';

=head1 DESCRIPTION

This Moose role adds common jQuery framework methods and declarations.

=cut

=head1 METHODS

=cut

=head2 mk_jQuery_method_call( %params )

Example:

mk_jQuery_method_call('ul.sf-menu', ['supersubs', [ 'json text' ]], ['superfish', [ 'json text' ]]);

=cut

sub mk_jQuery_method_call {
    my $self = shift;
    my $selector = shift;
    my @method = @_;

    my $code = '';

    $code .= qq|\$("${selector}")|;

    for my $m (@method) {
        my $func = $m->[0];
        my @arg = @{$m->[1]};
        my $args;
        $args = join ', ' => @arg;
        $code .= qq|.${func}($args)|;
    }
    $code .= ';';

    return $code;
}

1;

=head1 AUTHOR

David P.C. Wollmann E<lt>converter42 at gmail.comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2009 David P.C. Wollmann, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

