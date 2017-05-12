package JavaScript::Framework::jQuery::Plugin::mcDropdown;

use warnings;
use strict;

use Moose;
with 'JavaScript::Framework::jQuery::Role::Plugin';
use MooseX::Types::Moose qw( Str );

our $VERSION = '0.05';

has 'source_ul' => (
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

JavaScript::Framework::jQuery::Plugin::mcDropdown - Support for jQuery mcDropdown plugin

=head1 SYNOPSIS

 my $plugin = JavaScript::Framework::jQuery::Plugin::mcDropdown->new(
    target_selector => '#inputid',
    source_ul => '#ulid',
    options =>
 'minRows : 12,
 openSpeed : 500',
    }
 );

 print $plugin->cons_statement;

 # $("#inputid").mcDropdown("#ulid");

=head1 DESCRIPTION

This module implements the interface required to generate a jQuery constructor for
the mcDropdown jQuery plugin (see :L<http://www.givainc.com/labs/mcdropdown_jquery_plugin.htm>).

=cut

=head1 METHODS

=cut

=head2 cons_statement( )

Return the text of the JavaScript statement that invokes the mcDropdown constructor.

=cut

sub cons_statement {
    my ( $self ) = @_;

    my @arg = $self->target_selector;
    my @opt = '"' . $self->source_ul . '"';
    if (my $options = $self->options) {
        $options = join "\n" => '{', $options, '}';
        push @opt, $options;
    }
    push @arg, ['mcDropdown', [ @opt ]];

    return $self->mk_jQuery_method_call(@arg);
}

1;

__END__

# $(document).ready(function (){
# $("#inputid").mcDropdown("#ulid");
# });

=head1 AUTHOR

David P.C. Wollmann E<lt>converter42 at gmail.comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2009 David P.C. Wollmann, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

