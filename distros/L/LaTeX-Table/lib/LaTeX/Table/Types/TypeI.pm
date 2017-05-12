package LaTeX::Table::Types::TypeI;

use strict;
use warnings;

use Moose::Role;
use Template;

use version; our $VERSION = qv('1.0.6');

use Carp;

has '_table_obj' => ( is => 'rw', isa => 'LaTeX::Table', required => 1 );
has '_tabular_environment' => ( is => 'ro', required => 1 );
has '_template'            => ( is => 'ro', required => 1 );
has '_is_floating'         => ( is => 'ro', default  => 1, required => 1 );

sub generate_latex_code {
    my ($self) = @_;

    $self->_check_options();

    my $tbl   = $self->_table_obj;
    my $theme = $tbl->get_theme_settings;

    if ( !$tbl->get_tabletail() ) {
        $tbl->set_tabletail( $self->_get_default_tabletail_code() );
    }

    my $template_vars = {
        'CENTER' => $tbl->_get_default_align ? 1 : $tbl->get_center,
        'LEFT'   => $tbl->get_left(),
        'RIGHT'  => $tbl->get_right(),
        'ENVIRONMENT'  => $tbl->get_environment,
        'FONTFAMILY'   => $tbl->get_fontfamily(),
        'FONTSIZE'     => $tbl->get_fontsize(),
        'FOOTTABLE'    => $tbl->get_foottable(),
        'POSITION'     => $tbl->get_position(),
        'CAPTION_TOP'  => $tbl->get_caption_top(),
        'CAPTION'      => $self->_get_caption(),
        'CAPTION_CMD'  => $self->_get_caption_command(),
        'CONTINUED'    => $tbl->get_continued(),
        'CONTINUEDMSG' => $tbl->get_continuedmsg(),
        'SHORTCAPTION' => (
              $tbl->get_maincaption  ? $tbl->get_maincaption
            : $tbl->get_shortcaption ? $tbl->get_shortcaption
            : 0
        ),
        'SIDEWAYS' => $tbl->get_sideways(),
        'STAR'     => $tbl->get_star(),
        'WIDTH'    => $tbl->get_width(),
        'MAXWIDTH' => $tbl->get_maxwidth(),
        'COLDEF'   => $tbl->get_coldef ? $tbl->get_coldef
        : $tbl->_get_coldef_code( $tbl->get_data ),
        'LABEL'         => $tbl->get_label(),
        'TABLEHEADMSG'  => $tbl->get_tableheadmsg(),
        'TABLETAIL'     => $tbl->get_tabletail(),
        'TABLELASTTAIL' => $tbl->get_tablelasttail(),
        'XENTRYSTRETCH' => $tbl->get_xentrystretch(),
        'HEADER_CODE' => $tbl->_get_matrix_latex_code( $tbl->get_header, 1 ),
        'DATA_CODE' => $tbl->_get_matrix_latex_code( $tbl->get_data, 0 ),
        'TABULAR_ENVIRONMENT'   => $self->_get_tabular_environment(),
        'EXTRA_ROW_HEIGHT_CODE' => (
            defined $theme->{EXTRA_ROW_HEIGHT}
            ? '\setlength{\extrarowheight}{'
                . $theme->{EXTRA_ROW_HEIGHT} . "}\n"
            : q{}
        ),
        'RULES_COLOR_GLOBAL_CODE' => (
            defined $theme->{RULES_COLOR_GLOBAL}
            ? $theme->{RULES_COLOR_GLOBAL} . "\n"
            : q{}
        ),
        'RULES_WIDTH_GLOBAL_CODE' => (
            defined $theme->{RULES_WIDTH_GLOBAL}
            ? $theme->{RULES_WIDTH_GLOBAL} . "\n"
            : q{}
        ),
        'RESIZEBOX_BEGIN_CODE' => $self->_get_begin_resizebox_code(),
        'RESIZEBOX_END_CODE'   => (
            $self->_table_obj->get_resizebox ? "}\n"
            : q{}
        ),
        'DEFINE_COLORS_CODE' => (
            defined $tbl->get_theme_settings->{DEFINE_COLORS}
            ? $tbl->get_theme_settings->{DEFINE_COLORS} . "\n"
            : q{}
        ),
        'LT_NUM_COLUMNS' => scalar( @{ $tbl->_get_data_summary() } ),
        'LT_BOTTOM_RULE_CODE' =>
            $tbl->_get_hline_code( $tbl->_get_RULE_BOTTOM_ID ),
    };

    my $template_obj = Template->new();
    my $template
        = $tbl->get_custom_template
        ? $tbl->get_custom_template
        : $self->_template;

    my $template_output;

    $template_obj->process( \$template, $template_vars, \$template_output )
        or croak $template_obj->error();
    return $template_output;
}

sub _check_options {
    my ($self) = @_;
    my $tbl = $self->_table_obj;

    # default floating enviromnent is table
    if ( $tbl->get_environment eq '1' ) {
        $tbl->set_environment('table');
    }

    if ( !$self->_is_floating ) {
        if ( !$tbl->get_environment ) {
            $tbl->_invalid_option_usage( 'environment',
                $tbl->get_type
                    . ' is non-floating and requires an environment' );
        }
        if ( $tbl->get_position ) {
            $tbl->_invalid_option_usage( 'position',
                $tbl->get_type
                    . ' is non-floating and thus does not support position' );
        }
    }

    # check center, right, left options
    my $cnt_true_alignments = 0;
    for my $align ( $tbl->get_center, $tbl->get_right, $tbl->get_left ) {
        if ($align) {
            $cnt_true_alignments++;
        }
    }
    if ( $cnt_true_alignments > 1 ) {
        $tbl->_invalid_option_usage( 'center, left, right',
            'only one allowed.' );
    }
    if ( $tbl->has_center || $tbl->has_right || $tbl->has_left ) {
        $tbl->_set_default_align(0);
    }
    else {
        $tbl->_set_default_align(1);
    }

    if ( $tbl->get_maincaption && $tbl->get_shortcaption ) {
        $tbl->_invalid_option_usage( 'maincaption, shortcaption',
            'only one allowed.' );
    }

    # handle default values by ourselves
    if ( $tbl->get_width_environment eq 'tabular*' ) {
        $tbl->set_width_environment(0);
    }
    if ( !$tbl->get_width ) {
        if ( $tbl->get_width_environment eq 'tabularx' ) {
            $tbl->_invalid_option_usage( 'width_environment',
                'Is tabularx and width is unset' );
        }
        elsif ( $tbl->get_width_environment eq 'tabulary' ) {
            $tbl->_invalid_option_usage( 'width_environment',
                'Is tabulary and width is unset' );
        }
    }
    return;
}

sub _get_caption_command {
    my ($self)    = @_;
    my $tbl       = $self->_table_obj;
    my $c_caption = 'caption';
    if ( $tbl->get_caption_top && $tbl->get_caption_top ne '1' ) {
        $c_caption = $tbl->get_caption_top;
        $c_caption =~ s{ \A \\ }{}xms;
    }
    return $c_caption;
}

sub _get_begin_resizebox_code {
    my ($self) = @_;
    if ( $self->_table_obj->get_resizebox ) {
        my $rb_width  = $self->_table_obj->get_resizebox->[0];
        my $rb_height = q{!};
        if ( defined $self->_table_obj->get_resizebox->[1] ) {
            $rb_height = $self->_table_obj->get_resizebox->[1];
        }
        return "\\resizebox{$rb_width}{$rb_height}{\n";
    }
    return q{};
}

sub _get_caption {
    my ($self)  = @_;
    my $caption = q{};
    my $tbl     = $self->_table_obj;

    if ( !$tbl->get_caption ) {
        if ( !$tbl->get_maincaption ) {
            return 0;
        }
    }
    else {
        $caption = $tbl->get_caption;
    }

    my $tmp = q{};
    if ( $tbl->get_maincaption ) {
        $tmp = $tbl->get_maincaption . '. ';
        if ( defined $tbl->get_theme_settings->{CAPTION_FONT_STYLE} ) {
            $tmp = $tbl->_add_font_family( $tmp,
                $tbl->get_theme_settings->{CAPTION_FONT_STYLE} );
        }
    }

    return $tmp . $caption;
}

sub _get_tabular_environment {
    my ($self) = @_;
    my $tbl = $self->_table_obj;

    my $res
        = $tbl->get_custom_tabular_environment
        ? $tbl->get_custom_tabular_environment
        : $self->_tabular_environment;

    if ( $tbl->get_width ) {
        if ( !$tbl->get_width_environment ) {
            $res .= q{*};
        }
        else {
            $res = $tbl->get_width_environment;
        }
    }
    return $res;
}

sub _get_default_tabletail_code {
    my ($self) = @_;

    my $tbl = $self->_table_obj;
    my $v0  = q{|} x $tbl->get_theme_settings->{'VERTICAL_RULES'}->[0];

    return
          $tbl->_get_hline_code( $tbl->_get_RULE_MID_ID )
        . '\multicolumn{'
        . @{ $tbl->_get_data_summary() }
        . "}{${v0}r$v0}{{"
        . $tbl->get_tabletailmsg
        . "}} \\\\\n";
}

1;
__END__

=head1 NAME

LaTeX::Table::Types::TypeI - Interface for LaTeX table types.

=head1 DESCRIPTION

This is the type interface (or L<Moose> role), that all type objects must use.
L<LaTeX::Table> delegates the LaTeX code generation to type
objects. It stores all information we have in easy to use L<"TEMPLATE
VARIABLES">. L<LaTeX::Table> ships with very flexible templates, but it is
possible to use the template variables defined here to build custom templates.

=head1 INTERFACE

=over

=item C<generate_latex_code>

=back

=head1 TEMPLATE VARIABLES

Most options are accessible here:

=over

=item C<CENTER, LEFT, RIGHT>

Example:

  [% IF CENTER %]\centering
  [% END %]

=item C<ENVIRONMENT, STAR, POSITION, SIDEWAYS>

These options for floating environments are typically used like:

  [% IF ENVIRONMENT %]\begin{[% ENVIRONMENT %][% IF STAR %]*[% END %]}[% IF POSITION %][[% POSITION %]][% END %]
  ...
  [% END %]
  # the tabular environment here
  ...
  [% IF ENVIRONMENT %] ...
  \end{[% ENVIRONMENT %][% IF STAR %]*[% END %]}[% END %]

=item C<CAPTION_TOP, CAPTION_CMD, SHORTCAPTION, CAPTION, CONTINUED, CONTINUEDMSG>

The variables to build the caption command. Note that there is NO template for
the C<maincaption> option. C<CAPTION> already includes this maincaption if
specified.

=item C<LABEL>

The label:

 [% IF LABEL %]\label{[% LABEL %]}[% END %]

=item C<TABULAR_ENVIRONMENT, WIDTH, COLDEF>

These three options define the tabular environment:

  \begin{[% TABULAR_ENVIRONMENT %]}[% IF WIDTH %]{[% WIDTH %]}[% END %]{[% COLDEF %]}

=item C<FONTFAMILY, FONTSIZE>

Example: 

  [% IF FONTSIZE %]\[% FONTSIZE %]
  [% END %][% IF FONTFAMILY %]\[% FONTFAMILY %]family
  [% END %]

=item C<TABLEHEADMSG, TABLETAIL, TABLELASTTAIL, XENTRYSTRETCH>

For the multi-page tables.

=item C<MAXWIDTH, FOOTTABLE>

Currently only used by L<LaTeX::Table::Types::Ctable>.

=back

In addition, some variables already contain formatted LaTeX code:

=over 

=item C<HEADER_CODE>

The formatted header:

  \toprule
  \multicolumn{2}{c}{Item} &             \\
  \cmidrule(r){1-2}
  Animal                   & Description & Price \\
  \midrule

=item C<DATA_CODE> 

The formatted data:

  Gnat      & per gram & 13.65 \\
            & each     & 0.01  \\
  Gnu       & stuffed  & 92.59 \\
  Emu       & stuffed  & 33.33 \\
  Armadillo & frozen   & 8.99  \\
  \bottomrule

=item C<RESIZEBOX_BEGIN_CODE, RESIZEBOX_END_CODE>

Everything between these two template variables is resized according the
C<resizebox> option.

=item C<EXTRA_ROW_HEIGHT_CODE, DEFINE_COLORS_CODE, RULES_COLOR_GLOBAL_CODE, RULES_WIDTH_GLOBAL_CODE>

Specified by the theme. C<EXTRA_ROW_HEIGHT_CODE> will contain the
corresponding LaTeX extrarowheight command, e.g for '1pt':

    \setlength{\extrarowheight}{1pt}

Otherwise it will contain the empty string. The other template variables will
contain the command specified by the corresponding theme option.

=back

Finally, some variables allow access to internal C<LaTeX::Table> variables:

=over

=item C<LT_NUM_COLUMNS>

Contains the number of columns of the table.

=item C<LT_BOTTOM_RULE_CODE>

Code that draws the rules at the bottom of the table according the theme
options.

=back 

=head1 SEE ALSO

L<LaTeX::Table>

The predefined templates: L<LaTeX::Table::Types::Std>,
L<LaTeX::Table::Types::Ctable>, L<LaTeX::Table::Types::Longtable>,
L<LaTeX::Table::Types::Xtab>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2010 C<< <limaone@cpan.org> >>

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
