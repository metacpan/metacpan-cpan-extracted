package LaTeX::Table::Types::Std;
use Moose;

with 'LaTeX::Table::Types::TypeI';

use version; our $VERSION = qv('1.0.6');

my $template = <<'EOT'
[%IF CONTINUED %]\addtocounter{table}{-1}[% END %][% DEFINE_COLORS_CODE %][% IF ENVIRONMENT %]\begin{[% IF SIDEWAYS %]sidewaystable[% ELSE %][% ENVIRONMENT %][% END %][% IF STAR %]*[% END %]}[% IF POSITION %][[% POSITION %]][% END %]
[% IF FONTSIZE %]\[% FONTSIZE %]
[% END %][% IF FONTFAMILY %]\[% FONTFAMILY %]family
[% END %][% RULES_WIDTH_GLOBAL_CODE %][% IF CENTER %]\centering
[% END %][% IF LEFT %]\raggedright
[% END %][% IF RIGHT %]\raggedleft
[% END %][% IF CAPTION_TOP %][% IF CAPTION %]\[% CAPTION_CMD %][% IF SHORTCAPTION %][[% SHORTCAPTION %]][% END %]{[% CAPTION %][% IF CONTINUED %] [% CONTINUEDMSG %][% END %]}
[% END %][% END %][% END %][% EXTRA_ROW_HEIGHT_CODE %][% RESIZEBOX_BEGIN_CODE %]\begin{[% TABULAR_ENVIRONMENT %]}[% IF WIDTH %]{[% WIDTH %]}[% END %]{[% COLDEF %]}
[% RULES_COLOR_GLOBAL_CODE %][% HEADER_CODE %][% DATA_CODE %]\end{[%
TABULAR_ENVIRONMENT %]}[% RESIZEBOX_END_CODE %][% IF ENVIRONMENT %][% UNLESS CAPTION_TOP %][% IF CAPTION %]
\[% CAPTION_CMD %][% IF SHORTCAPTION %][[% SHORTCAPTION %]][% END %]{[% CAPTION %][% IF CONTINUED %] [% CONTINUEDMSG %][% END %]}[% END %][% END %][%IF LABEL %]
\label{[% LABEL %]}[% END %]
\end{[% IF SIDEWAYS %]sidewaystable[% ELSE %][% ENVIRONMENT %][% END %][% IF STAR %]*[% END %]}[% END %]
EOT
    ;

has '+_tabular_environment' => ( default => 'tabular' );
has '+_template'            => ( default => $template );

1;

__END__

=head1 NAME

LaTeX::Table::Types::Std - Create standard LaTeX tables.

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
