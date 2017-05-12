#
# This file is part of HTML-FormFu-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package HTML::FormFu::ExtJS::Element::ComboBox;
BEGIN {
  $HTML::FormFu::ExtJS::Element::ComboBox::VERSION = '0.090';
}

use base "HTML::FormFu::ExtJS::Element::Select";

use strict;
use warnings;
use utf8;

use JavaScript::Dumper;

sub render {
    my $class = shift;
    my $self  = shift;
    my $super = $class->SUPER::render($self);
    my $data;
    foreach my $option ( @{ $self->options } ) {
        push( @{$data}, [ $option->{value}, $option->{label} ] );
        if ( $option->{group} && ( my @groups = @{ $option->{group} } ) ) {
            foreach my $item (@groups) {
                push( @{$data}, [ $item->{value}, $item->{label} ] );
            }
        }
    }
    my $string = js_dumper( { fields => [ "value", "text" ], data => $data } );
    return {
        %{$super},

        editable => \1,
        store    => \( "new Ext.data.SimpleStore(" . $string . ")" ),
    };

}

1;


__END__
=pod

=head1 NAME

HTML::FormFu::ExtJS::Element::ComboBox

=head1 VERSION

version 0.090

=head1 DESCRIPTION

Creates an editable select box.

The default ExtJS setup is:

  "mode"           : "local",
  "editable"       : true,
  "displayField"   : "text",
  "valueField"     : "value",
  "autoWidth"      : false,
  "forceSelection" : true,
  "triggerAction"  : "all",
  "store"          : new Ext.data.SimpleStore( ... ),
  "xtype"          : "combo"

=head1 NAME

HTML::FormFu::ExtJS::Element::ComboBox - An editable select box

=head1 SEE ALSO

L<HTML::FormFu::Element::Select>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Moritz Onken, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

