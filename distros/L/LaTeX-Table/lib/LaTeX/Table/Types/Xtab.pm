package LaTeX::Table::Types::Xtab;
use Moose;

with 'LaTeX::Table::Types::TypeI';

use version; our $VERSION = qv('1.0.6');

my $template = <<'EOT'
{
[%IF CONTINUED %]\addtocounter{table}{-1}[% END %][% DEFINE_COLORS_CODE %][%
EXTRA_ROW_HEIGHT_CODE %][% RULES_WIDTH_GLOBAL_CODE %][% RULES_COLOR_GLOBAL_CODE %][%
 IF FONTSIZE %]\[% FONTSIZE %]
[% END %][% IF FONTFAMILY %]\[% FONTFAMILY %]family
[% END %][% IF SIDEWAYS %]\begin{landscape}[% END %][% IF CAPTION %][%IF CAPTION_TOP
%]\topcaption[% ELSE %]\bottomcaption[% END %][%IF SHORTCAPTION %][[% SHORTCAPTION %]][% END %]{[% CAPTION %][% IF CONTINUED %] [% CONTINUEDMSG %][% END %]}
[% END %][% IF XENTRYSTRETCH %]\xentrystretch{[% XENTRYSTRETCH %]}
[% END %][% IF LABEL %]\label{[% LABEL %]}
[% END %]
[% IF CAPTION_TOP && TABLEHEADMSG %]\tablefirsthead{[% HEADER_CODE %]}
\tablehead{\multicolumn{[% LT_NUM_COLUMNS %]}{c}{{ \normalsize \tablename\ \thetable: [% TABLEHEADMSG %]}}\\[\abovecaptionskip]
[% HEADER_CODE %]}
[% ELSE %]\tablehead{[% HEADER_CODE %]}
[% END %]\tabletail{[% TABLETAIL %][% LT_BOTTOM_RULE_CODE %]}
\tablelasttail{[% TABLELASTTAIL %]}
[% IF CENTER %]\begin{center}
[% END %][% IF LEFT %]\begin{flushleft}
[% END %][% IF RIGHT %]\begin{flushright}
[% END %][% RESIZEBOX_BEGIN_CODE %]\begin{[% TABULAR_ENVIRONMENT %][% IF STAR %]*[% END %]}[% IF WIDTH %]{[%WIDTH %]}[% END %]{[% COLDEF %]}
[% DATA_CODE %]\end{[% TABULAR_ENVIRONMENT %][% IF STAR %]*[% END %]}
[% RESIZEBOX_END_CODE %][% IF CENTER %]\end{center}[% END %][% IF LEFT
%]\end{flushleft}[% END %][% IF RIGHT %]\end{flushright}[% END %][% IF
SIDEWAYS %]\end{landscape}[% END %]
} 
EOT
    ;

has '+_tabular_environment' => ( default => 'xtabular' );
has '+_template'            => ( default => $template );
has '+_is_floating'         => ( default => 0 );

1;
__END__

=head1 NAME

LaTeX::Table::Types::Xtab - Create multi-page LaTeX tables with the xtabular package.

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
