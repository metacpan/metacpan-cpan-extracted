package Exporter::Declare::Magic::Sub;
use strict;
use warnings;

use base 'Exporter::Declare::Export::Sub';

sub inject {
    my $self = shift;
    my ($class, $name) = @_;

    $self->SUPER::inject( $class, $name );

    return unless $self->parser;

    my $parser_sub = $self->exported_by->export_meta->parsers_get( $self->parser );

    if ( $parser_sub ) {
        require Devel::Declare;
        Devel::Declare->setup_for(
            $class,
            { $name => { const => $parser_sub } }
        );
    }
    else {
        require Devel::Declare::Interface;
        require Exporter::Declare::Magic::Parser;
        Devel::Declare::Interface::enhance(
            $class,
            $name,
            $self->parser,
        );
    }
}

sub parser {
    my $self = shift;
    return $self->_data->{parser};
}

1;

=head1 NAME

Exporter::Declare::Magic::Sub - Export class for subs which are exported.

=head1 DESCRIPTION

Export class for subs which are exported. Overrides inject() in order to hook
into L<Devel::Declare> on parsed exports.

=head1 OVERRIDEN METHODS

=over 4

=item $export->inject( $class, $name );

Inject the sub, and apply the L<Devel::Declare> magic.

=back

=head1 NEW METHODS

=over 4

=item $parser_name = export->parser()

Get the name of the parse this sub should use with L<Devel::Declare> empty when
no parse should be used.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Exporter-Declare is free software; Standard perl licence.

Exporter-Declare is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.
