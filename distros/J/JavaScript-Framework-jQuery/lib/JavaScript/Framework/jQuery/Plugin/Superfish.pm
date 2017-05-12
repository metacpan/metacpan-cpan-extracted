package JavaScript::Framework::jQuery::Plugin::Superfish;

use warnings;
use strict;

use Moose;
with 'JavaScript::Framework::jQuery::Role::Plugin';
use MooseX::Types::Moose qw( Bool Str );

our $VERSION = '0.05';

has 'options' => (
    is => 'ro',
    isa => Str,
    coerce => 1,
);

has 'use_supersubs' => (
    is => 'ro',
    isa => Bool,
    default => sub {0},
);

has 'supersubs_options' => (
    is => 'ro',
    isa => Str,
    coerce => 1,
);

no Moose;

=head1 NAME

JavaScript::Framework::jQuery::Plugin::Superfish - Support for jQuery Superfish plugin

=head1 SYNOPSIS

 my $plugin = JavaScript::Framework::jQuery::Plugin::Superfish->new(
    target_selector => 'ul.sf-menu',
    options =>
 'delay : 500,
 animation : { opacity : "show" },
 dropShadows : true',
     use_supersubs => 1,
     supersubs_options =>
 'minWidth : 12,
 maxWidth : 27,
 extraWidth : 1'
 );

 print $plugin->cons_statement;

 # $("ul.sf-menu").supersubs({
 # minWidth: 12,
 # maxWidth: 27,
 # extraWidth: 1
 # }).superfish({
 # delay: 500,
 # animation: { opacity : "show" },
 # dropShadows: true,
 # });

=head1 DESCRIPTION

This module implements the interface required to generate a jQuery constructor for
the jQuery Superfish plugin.

L<http://users.tpg.com.au/j_birch/plugins/superfish/>

=head1 CONSTRUCTOR PARAMETERS

The C<new> constructor, provided automatically by Moose (in case you're looking for it and
can't find it) is called from &JavaScript::Framework::jQuery::construct_plugin. The
arguments passed to this subroutine are validated by this module.

=cut

=head2 cons_statement( )

Return the text of the JavaScript statement that invokes the Superfish constructor.

=cut

sub cons_statement {
    my ( $self ) = @_;

    my @arg = $self->target_selector;

    my $supersubs_options;
    if ($self->use_supersubs) {
        if ($supersubs_options = $self->supersubs_options) {
            $supersubs_options = join "\n" => '{', $supersubs_options, '}';
            push @arg, [ 'supersubs', [ $supersubs_options ] ];
        }
        else {
            push @arg, [ 'supersubs', [ ] ];
        }
    }

    my $options;
    if ($options = $self->options) {
        $options = join "\n" => '{', $options, '}';
        push @arg, [ 'superfish', [ $options ] ];
    }
    else {
        push @arg, [ 'superfish', [ ] ];
    }

    return $self->mk_jQuery_method_call(@arg);
}

1;

__END__

 # need to be able to print this type of invocation chain
 # //<![CDATA[
 #     $(document).ready(function(){
 #         $("ul.sf-menu").supersubs({
 #             minWidth: 12,
 #             maxWidth: 27,
 #             extraWidth: 1
 #         }).superfish({
 #             delay: 500,
 #             animation: {opacity:'show'},
 #             dropShadows: true,
 #             pathClass:  'current'
 #         });
 #     });
 # //]]>


=head1 AUTHOR

David P.C. Wollmann E<lt>converter42 at gmail.comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2009 David P.C. Wollmann, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


