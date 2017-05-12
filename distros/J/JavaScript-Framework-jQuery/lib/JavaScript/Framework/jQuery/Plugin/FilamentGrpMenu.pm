package JavaScript::Framework::jQuery::Plugin::FilamentGrpMenu;

use warnings;
use strict;

use Moose;
with 'JavaScript::Framework::jQuery::Role::Plugin';
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw( Str );

our $VERSION = '0.05';

has 'content_from' => (
    is => 'ro',
    isa => Str,
    required => 1,
);

has 'options' => (
    is => 'ro',
    isa => Str,
);

no Moose;

=head1 NAME

JavaScript::Framework::jQuery::Plugin::FilamentGrpMenu - Support for Filament Group jQuery menu plugin

=head1 SYNOPSIS

 my $plugin = JavaScript::Framework::jQuery::Plugin::FilamentGroupMenu->new(
    target_selector => '#menu-items',
    content => '$("#menu-items").html()',
    options =>
 'posX : "left",
 posY : "bottom",
 directionV : "down",
 showSpeed : 200,
 backLink : "false"'
 );

 print $plugin->cons_statement;

 # $('#menu-items').menu({
 # content: $("#menu-items").html(),
 # posX: "left",
 # posY: "bottom",
 # directionV: "down",
 # showSpeed: 200,
 # backLink: false
 # });

=head1 DESCRIPTION

This module implements the interface required to generate a jQuery constructor for
the Filament Group jQuery menu plugin.

L<http://www.filamentgroup.com/lab/jquery_ipod_style_and_flyout_menus/>

=cut

=head1 CONSTRUCTOR PARAMETERS

The C<new> constructor, provided automatically by Moose (in case you're looking for it and
can't find it) is called from &JavaScript::Framework::jQuery::construct_plugin. The
arguments passed to this subroutine are validated by this module.

=head2 content_from

Required

A string representing a jQuery selector expression.

=head2 options

A string representing a JavaScript object literal.

=cut

=head2 cons_statement( )

Return the text of the JavaScript statement that invokes the jQuery plugin constructor.

=cut

sub cons_statement {
    my ( $self ) = @_;

    my @arg = $self->target_selector;

    my $options = 'content : ' . $self->content_from;
    if (my $opts = $self->options) {
        $options = join ",\n" => $options, $opts;
    }
    $options = join "\n" => '{', $options, '}';

    push @arg, ['menu', [ $options ]];

    return $self->mk_jQuery_method_call(@arg);
}

1;

__END__

# $expected = q/$(document).ready(function (){
# $('#adminmenubtn').menu({
#     content: $("#menu-items").html(),
#     posX: "left",
#     posY: "bottom",
#     directionV: "down",
#     showSpeed: 200,
#     backLink: false
# });
# });/;

=head1 AUTHOR

David P.C. Wollmann E<lt>converter42 at gmail.comE<gt> 
=head1 COPYRIGHT & LICENSE

Copyright 2009 David P.C. Wollmann, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER

The author is not affiliated with Filament Group, Inc.
