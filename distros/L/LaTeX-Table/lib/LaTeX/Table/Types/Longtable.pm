package LaTeX::Table::Types::Longtable;
use Moose;

with 'LaTeX::Table::Types::TypeI';

use version; our $VERSION = qv('1.0.6');

my $template = <<'EOT'
{
[% IF CONTINUED %]\addtocounter{table}{-1}[% END 
%][% DEFINE_COLORS_CODE %][% EXTRA_ROW_HEIGHT_CODE %][%
RULES_WIDTH_GLOBAL_CODE %][% RULES_COLOR_GLOBAL_CODE %][% IF FONTSIZE %]\[% FONTSIZE %]
[% END %][% IF FONTFAMILY %]\[% FONTFAMILY %]family
[% END %][% IF SIDEWAYS %]\begin{landscape}[% END 
%][% RESIZEBOX_BEGIN_CODE %]\begin{[% TABULAR_ENVIRONMENT %][% IF STAR %]*[% END %]}[% IF CENTER %][c][% END %][% IF LEFT %][l][% END %][% IF RIGHT %][r][% END %]{[% COLDEF %]}
[% IF CAPTION %][%IF CAPTION_TOP %]\caption[%IF SHORTCAPTION %][[%
SHORTCAPTION %]][% END %]{[% CAPTION %][% IF CONTINUED %] [% CONTINUEDMSG %][%
END %][% IF LABEL %]\label{[% LABEL %]}[% END %]}\\
[% END %][% END %][% HEADER_CODE %]\endfirsthead
[% IF CAPTION %][% IF CAPTION_TOP %][% IF TABLEHEADMSG %]\caption[]{[% TABLEHEADMSG %]}\\
[% END %][% END %][% END %]
[% HEADER_CODE %]\endhead
[% TABLETAIL %][% LT_BOTTOM_RULE_CODE %]\endfoot
[% TABLELASTTAIL %]
[% IF CAPTION %][% UNLESS CAPTION_TOP %]\caption[%IF SHORTCAPTION %][[%
SHORTCAPTION %]][% END %]{[% CAPTION %][% IF CONTINUED %] [% CONTINUEDMSG %][%
END %][% IF LABEL %]\label{[% LABEL %]}[% END %]}\\
[% END %][% END %]\endlastfoot
[% DATA_CODE %]\end{[% TABULAR_ENVIRONMENT %][% IF STAR %]*[% END %]}[% RESIZEBOX_END_CODE %][% IF
SIDEWAYS %]\end{landscape}[% END %]
}
EOT
    ;

has '+_tabular_environment' => ( default => 'longtable' );
has '+_template'            => ( default => $template );
has '+_is_floating'         => ( default => 0 );

# longtable only supports tabularx with LTXtable package, we don't need the
# width here. Set to an arbitrary true value, we don't output it in the
# template anyway.
before '_check_options' => sub {
    my ($self) = @_;
    if ( $self->_table_obj->get_width_environment eq 'tabularx'
        && !$self->_table_obj->get_width )
    {
        $self->_table_obj->set_width(1);
    }
};

sub _get_tabular_environment {
    my ($self) = @_;
    my $tbl = $self->_table_obj;

    return $tbl->get_custom_tabular_environment
        ? $tbl->get_custom_tabular_environment
        : $self->_tabular_environment;
}

1;
__END__

=head1 NAME

LaTeX::Table::Types::Longtable - Create multi-page LaTeX tables with the longtable package.

=head1 INTERFACE

=over

=item C<generate_latex_code>

=back

=head1 SEE ALSO

L<LaTeX::Table>, L<LaTeX::Table::Types::TypeI>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2010 C<< <limaone@cpan.org> >> 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
