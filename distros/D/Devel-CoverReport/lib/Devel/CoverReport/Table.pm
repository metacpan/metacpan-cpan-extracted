# Copyright 2009-2011, Bartłomiej Syguła (perl@bs502.pl)
#
# This is free software. It is licensed, and can be distributed under the same terms as Perl itself.
#
# For more, see my website: http://bs502.pl/

package Devel::CoverReport::Table;

use strict;
use warnings;

our $VERSION = "0.05";

use Carp::Assert::More qw( assert_defined );
use Params::Validate qw( :all );

=encoding UTF-8

=head1 DESCRIPTION

Helper object, that works as a data container for L<Devel::CoverReport> and L<Devel::CoverReport::Formatter>.

=head1 WARNING

Consider this module to be an early ALPHA. It does the job for me, so it's here.

This is my first CPAN module, so I expect that some things may be a bit rough around edges.

The plan is, to fix both those issues, and remove this warning in next immediate release.

=head1 API

=over

=item new

Constructor for C<Devel::CoverReport::Table>.

=cut
sub new { # {{{
    my $class  = shift;
    my %params = @_;

    validate(
        @_,
        {
            label         => { type=>SCALAR },
            headers       => { type=>HASHREF },
            headers_order => { type=>ARRAYREF },
        }
    );

    my $self = {
        label         => $params{'label'},
        headers       => $params{'headers'},
        headers_order => $params{'headers_order'},

        rows    => [],
        summary => [],
    };

    bless $self, $class;

    # Make sure, that headers are sane.
    foreach my $header_id (@{ $params{'headers_order'} }) {
        assert_defined($self->{'headers'}->{$header_id},              'Missing header: '. $header_id);
        assert_defined($self->{'headers'}->{$header_id}->{'caption'}, 'Caption undefined!');

        if (not defined $self->{'headers'}->{$header_id}->{'f'}) {
            $self->{'headers'}->{$header_id}->{'f'} = q{%s};
        }

        if (not defined $self->{'headers'}->{$header_id}->{'fs'}) {
            $self->{'headers'}->{$header_id}->{'fs'} = q{%s};
        }
    }

    return $self;
} # }}}

=item add_row

Append data row to the table.

=cut
sub add_row { # {{{
    my ( $self, $row ) = @_;

    return scalar push @{ $self->{'rows'} }, $row;
} # }}}

=item add_summary

Append summary row to the table

=cut
sub add_summary { # {{{
    my ( $self, $row ) = @_;

    return scalar push @{ $self->{'summary'} }, $row;
} # }}}

=item get_headers

Return reference to headers structure, currently configured in the table object.

Changing this structure WILL affect the table, so be carefull, or better - do not do it ;)

=cut
sub get_headers { # {{{
    my ( $self ) = @_;

    return $self->{'headers'};
} # }}}

=item get_headers_order

Return arrayref, containing header keys, ordered, as they should be.

=cut
sub get_headers_order { # {{{
    my ( $self ) = @_;

    return $self->{'headers_order'};
} # }}}

=item get_rows

Return data rows stored in the table.

=cut
sub get_rows { # {{{
    my ( $self ) = @_;

    return $self->{'rows'};
} # }}}

=item get_summary

Get summary rows stored in the table.

=cut
sub get_summary { # {{{
    my ( $self ) = @_;

    return $self->{'summary'};
} # }}}

=back

=head1 LICENCE

Copyright 2009-2011, Bartłomiej Syguła (perl@bs502.pl)

This is free software. It is licensed, and can be distributed under the same terms as Perl itself.

For more, see my website: http://bs502.pl/

=cut

# vim: fdm=marker
1;
