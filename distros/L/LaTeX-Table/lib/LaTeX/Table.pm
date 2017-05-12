package LaTeX::Table;

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::FollowPBP;

use version; our $VERSION = qv('1.0.6');

use LaTeX::Table::Types::Std;
use LaTeX::Table::Types::Xtab;
use LaTeX::Table::Types::Ctable;
use LaTeX::Table::Types::Longtable;

use Carp;
use Scalar::Util qw(reftype);
use English qw( -no_match_vars );

use Module::Pluggable
    search_path => 'LaTeX::Table::Themes',
    sub_name    => 'themes',
    except      => 'LaTeX::Table::Themes::ThemeI',
    instantiate => 'new';

# Scalar options:

# Str
for my $attr (
    qw(label maincaption shortcaption caption caption_top coldef
    custom_template width maxwidth width_environment
    custom_tabular_environment position tabletail star)
    )
{
    has $attr => ( is => 'rw', isa => 'Str', default => 0 );
}

has 'filename'  => ( is => 'rw', isa => 'Str', default => 'latextable.tex' );
has 'foottable' => ( is => 'rw', isa => 'Str', default => q{} );
has 'eor'       => ( is => 'rw', isa => 'Str', default => q{\\\\} );
has 'environment'  => ( is => 'rw', isa => 'Str', default => 1 );
has 'theme'        => ( is => 'rw', isa => 'Str', default => 'Meyrin' );
has 'continuedmsg' => ( is => 'rw', isa => 'Str', default => '(continued)' );
has 'tabletailmsg' =>
    ( is => 'rw', isa => 'Str', default => 'Continued on next page' );
has 'tableheadmsg' =>
    ( is => 'rw', isa => 'Str', default => 'Continued from previous page' );
has 'tablelasttail' => ( is => 'rw', isa => 'Str', default => q{} );

# Num
has 'xentrystretch' => ( is => 'rw', isa => 'Num', default => 0 );

# Bool
for my $attr (qw(center left right _default_align continued sideways)) {
    has $attr => (
        is        => 'rw',
        isa       => 'Bool',
        predicate => "has_$attr",
        clearer   => "clear_$attr",
    );
}

# enum
has 'type' => (
    is      => 'rw',
    isa     => enum( [qw( std ctable xtab longtable )] ),
    default => 'std',
);
has 'fontfamily' => (
    is      => 'rw',
    isa     => enum( [qw( 0 rm sf tt )] ),
    default => 0,
);
has 'fontsize' => (
    is  => 'rw',
    isa => enum(
        [   qw(0 tiny scriptsize footnotesize
                small normal large Large LARGE huge Huge)
        ]
    ),
    default => 0,
);

# Reference/Object options
has 'coldef_strategy'     => ( is => 'rw', isa => 'HashRef' );
has 'callback'            => ( is => 'rw', isa => 'CodeRef' );
has 'resizebox'           => ( is => 'rw', isa => 'ArrayRef[Str]' );
has 'columns_like_header' => ( is => 'rw', isa => 'ArrayRef[Int]' );
has 'header' =>
    ( is => 'rw', isa => 'ArrayRef[ArrayRef[Value]]', default => sub { [] } );
has 'data' =>
    ( is => 'rw', isa => 'ArrayRef[ArrayRef[Value]]', default => sub { [] } );
has 'predef_themes' =>
    ( is => 'rw', isa => 'HashRef[HashRef]', default => sub { {} } );
has 'custom_themes' =>
    ( is => 'rw', isa => 'HashRef[HashRef]', default => sub { {} } );

# private
has '_data_summary' => ( is => 'rw', isa => 'ArrayRef[Str]' );
has '_type_obj'     => ( is => 'rw', isa => 'LaTeX::Table::Types::TypeI' );
has '_RULE_TOP_ID'    => ( is => 'ro', default => 0 );
has '_RULE_MID_ID'    => ( is => 'ro', default => 1 );
has '_RULE_INNER_ID'  => ( is => 'ro', default => 2 );
has '_RULE_BOTTOM_ID' => ( is => 'ro', default => 3 );

__PACKAGE__->meta->make_immutable;

sub generate_string {
    my ( $self, @args ) = @_;

    # analyze the data
    $self->_calc_data_summary( $self->get_data );

    my $type_obj_name
        = 'LaTeX::Table::Types::'
        . uc( substr $self->get_type, 0, 1 )
        . substr $self->get_type, 1;
    $self->_set_type_obj( $type_obj_name->new( _table_obj => $self ) );

    return $self->_get_type_obj->generate_latex_code();
}

sub generate {
    my ( $self, $header, $data ) = @_;
    open my $LATEX, '>', $self->get_filename
        or $self->_ioerror( 'open', $OS_ERROR );
    print {$LATEX} $self->generate_string( $header, $data )
        or $self->_ioerror( 'write', $OS_ERROR );
    close $LATEX
        or $self->_ioerror( 'close', $OS_ERROR );
    return 1;
}

sub get_available_themes {
    my ($self) = @_;
    my %defs;

    for my $theme_obj ( $self->themes ) {
        %defs = ( %defs, %{ $theme_obj->_definition } );
    }
    $self->set_predef_themes( \%defs );
    return {
        ( %{ $self->get_predef_themes }, %{ $self->get_custom_themes } ) };
}

sub _invalid_option_usage {
    my ( $self, $option, $msg ) = @_;
    croak "Invalid usage of option $option: $msg.";
}

sub _ioerror {
    my ( $self, $function, $error ) = @_;
    croak "IO error: Can't $function '" . $self->get_filename . "': $error";
}

sub _default_coldef_strategy {
    my ($self) = @_;
    my $STRATEGY = {
        MISSING_VALUE => qr{\A \s* \z}xms,
        NUMBER =>
            qr{\A\s*([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?\s*\z}xms,
        NUMBER_MUST_MATCH_ALL => 1,
        LONG                  => qr{\A \s* (?=\w+\s+\w+).{29,}? \S}xms,
        LONG_MUST_MATCH_ALL   => 0,
        NUMBER_COL            => 'r',
        NUMBER_COL_X          => 'r',
        LONG_COL              => 'p{5cm}',
        LONG_COL_X            => 'X',
        LONG_COL_Y            => 'L',
        DEFAULT_COL           => 'l',
        DEFAULT_COL_X         => 'l',
    };
    $self->set_coldef_strategy($STRATEGY);
    return $STRATEGY;
}

sub _get_coldef_types {
    my ($self) = @_;

    # everything that does not contain an underscore is a coltype
    my @coltypes = sort grep {m{ \A [^_]+ \z }xms}
        keys %{ $self->get_coldef_strategy };

    return @coltypes;
}

sub _check_coldef_strategy {
    my ( $self, $strategy ) = @_;
    my $default = $self->_default_coldef_strategy;
    for my $key ( keys %{$default} ) {
        if ( !defined $strategy->{$key} ) {
            $strategy->{$key} = $default->{$key};
        }
    }

    $self->set_coldef_strategy($strategy);

    my @coltypes = $self->_get_coldef_types();
    for my $type (@coltypes) {
        if ( !defined $strategy->{"${type}_COL"} ) {
            $self->_invalid_option_usage( 'coldef_strategy',
                "Missing column attribute ${type}_COL for $type" );
        }
        if ( !defined $strategy->{"${type}_MUST_MATCH_ALL"} ) {
            $strategy->{"${type}_MUST_MATCH_ALL"} = 1;
        }
    }
    return;
}

sub _extract_number_columns {
    my ( $self, $col ) = @_;
    my $def = $self->_get_mc_def($col);
    return defined $def->{cols} ? $def->{cols} : 1;
}

sub _row_is_latex_command {
    my ( $self, $row ) = @_;
    if ( scalar( @{$row} ) == 1 && $row->[0] =~ m{\A \s* \\ }xms ) {
        return 1;
    }
    return 0;
}

sub _calc_data_summary {
    my ( $self, $data ) = @_;
    my $max_col_number = 0;
    my $strategy       = $self->get_coldef_strategy;
    if ( !$strategy ) {
        $strategy = $self->_default_coldef_strategy;
    }
    else {
        $self->_check_coldef_strategy($strategy);
    }
    my %matches;
    my %cells;

    my @coltypes = $self->_get_coldef_types();

ROW:
    for my $row ( @{$data} ) {
        if ( scalar @{$row} == 0 || $self->_row_is_latex_command($row) ) {
            next ROW;
        }
        if ( scalar @{$row} > $max_col_number ) {
            $max_col_number = scalar @{$row};
        }
        my $i = 0;
    COL:
        for my $col ( @{$row} ) {
            next COL if $col =~ $strategy->{MISSING_VALUE};

            for my $coltype (@coltypes) {
                if ( $col =~ $strategy->{$coltype} ) {
                    $matches{$i}{$coltype}++;
                }
            }
            $cells{$i}++;
            $i += $self->_extract_number_columns($col);
        }
    }
    my @summary;
    for my $i ( 0 .. $max_col_number - 1 ) {
        my $type_of_this_col = 'DEFAULT';
        for my $coltype (@coltypes) {
            if (defined $matches{$i}{$coltype}
                && (  !$strategy->{"${coltype}_MUST_MATCH_ALL"}
                    || $cells{$i} == $matches{$i}{$coltype} )
                )
            {
                $type_of_this_col = $coltype;
            }
        }
        push @summary, $type_of_this_col;
    }
    $self->_set_data_summary( \@summary );
    return;
}

sub _apply_callback_cell {
    my ( $self, $i, $j, $value, $is_header ) = @_;
    my $col_cb = $self->_get_mc_def($value);
    $col_cb->{value}
        = &{ $self->get_callback }( $i, $j, $col_cb->{value}, $is_header );
    return $self->_get_mc_value($col_cb);
}

# formats the data/header as latex code
sub _get_matrix_latex_code {
    my ( $self, $data_ref, $is_header ) = @_;

    my $theme  = $self->get_theme_settings;
    my $i      = 0;
    my $row_id = 0;

    my @code
        = $is_header
        ? ( $self->_get_hline_code( $self->_get_RULE_TOP_ID ) )
        : ();
ROW:
    for my $row ( @{$data_ref} ) {
        $i++;
        my @cols = @{$row};

        # empty rows produce a horizontal line
        if ( !@cols ) {
            push @code,
                $self->_get_hline_code( $self->_get_RULE_INNER_ID, 1 );
            next ROW;
        }

        # single column rows that start with a backslash are just
        # printed out
        if ( $self->_row_is_latex_command($row) ) {
            push @code, $cols[0] . "\n";
            next ROW;
        }
        if ( $self->get_callback ) {
            my $k = 0;
            for my $col (@cols) {
                $col = $self->_apply_callback_cell( $row_id, $k, $col,
                    $is_header );
                $k += $self->_extract_number_columns($col);
            }
        }
        if ($is_header) {
            my $j = 0;
            for my $col (@cols) {
                $col = $self->_apply_header_formatting( $col,
                    ( !defined $theme->{STUB_ALIGN} || $j > 0 ) );
                $j += $self->_extract_number_columns($col);
            }
        }
        $row_id++;

        # now print the row LaTeX code
        my $bgcolor
            = $is_header      ? $theme->{'HEADER_BG_COLOR'}
            : ( $row_id % 2 ) ? $theme->{'DATA_BG_COLOR_ODD'}
            :                   $theme->{'DATA_BG_COLOR_EVEN'};
        push @code, $self->_get_row_array( \@cols, $bgcolor, $is_header );

        next ROW if $is_header;

        # do we have to draw a horizontal line?
        if ( $i == scalar @{$data_ref} ) {
            push @code, $self->_get_hline_code( $self->_get_RULE_BOTTOM_ID );
        }
        else {
            push @code, $self->_get_hline_code( $self->_get_RULE_INNER_ID );
        }
    }

    # without header, just draw the topline, not this midline
    if ( $is_header && $i ) {
        push @code, $self->_get_hline_code( $self->_get_RULE_MID_ID );
    }

    return $self->_align_code( \@code );
}

sub _align_code {
    my ( $self, $code_ref ) = @_;
    my %max;
    for my $row ( @{$code_ref} ) {
        next if ( !defined reftype $row);
        for my $i ( 0 .. scalar( @{$row} ) - 1 ) {
            $row->[$i] =~ s{^\s+|\s+$}{}gxms;
            my $l = length $row->[$i];
            if ( !defined $max{$i} || $max{$i} < $l ) {
                $max{$i} = $l;
            }
        }
    }

    my $code = q{};
ROW:
    for my $row ( @{$code_ref} ) {
        if ( !defined reftype $row) {
            $code .= $row;
            next ROW;
        }
        for my $i ( 0 .. scalar( @{$row} ) - 1 ) {
            $row->[$i] = sprintf '%-*s', $max{$i}, $row->[$i];
        }
        $code .= join( ' & ', @{$row} ) . q{ } .  $self->get_eor . "\n";
    }
    return $code;
}

sub _get_hline_code {
    my ( $self, $id, $single ) = @_;
    my $theme  = $self->get_theme_settings;
    my $hlines = $theme->{'HORIZONTAL_RULES'};
    my $line   = '\hline';
    if ( defined $theme->{RULES_CMD}
        && reftype $theme->{RULES_CMD} eq 'ARRAY' )
    {
        $line = $theme->{RULES_CMD}->[$id];
    }
    if ( $id == $self->_get_RULE_BOTTOM_ID ) {
        $id = 0;
    }

    # just one line?
    if ( defined $single && $single ) {
        return "$line\n";
    }
    return "$line\n" x $hlines->[$id];
}

sub _apply_header_formatting {
    my ( $self, $col, $aligning ) = @_;
    my $theme = $self->get_theme_settings;
    if (   $aligning
        && defined $theme->{'HEADER_CENTERED'}
        && $theme->{'HEADER_CENTERED'} )
    {
        $col = $self->_add_mc_def(
            { value => $col, align => 'c', cols => '1' } );
    }
    if ( length $col ) {
        if ( defined $theme->{'HEADER_FONT_STYLE'} ) {
            $col = $self->_add_font_family( $col,
                $theme->{'HEADER_FONT_STYLE'} );
        }
        if ( defined $theme->{'HEADER_FONT_COLOR'} ) {
            $col = $self->_add_font_color( $col,
                $theme->{'HEADER_FONT_COLOR'} );
        }
    }
    return $col;
}

sub _get_cell_bg_color {
    my ( $self, $row_bg_color, $col_id ) = @_;
    my $cell_bg_color = $row_bg_color;
    if ( $self->get_columns_like_header ) {
    HEADER_COLUMN:
        for my $i ( @{ $self->get_columns_like_header } ) {
            if ( $i == $col_id ) {
                $cell_bg_color
                    = $self->get_theme_settings->{'HEADER_BG_COLOR'};
                last HEADER_COLUMN;
            }
        }
    }
    return $cell_bg_color;
}

sub _get_row_array {
    my ( $self, $cols_ref, $bgcolor, $is_header ) = @_;
    my @cols;
    my @cols_defs = map { $self->_get_mc_def($_) } @{$cols_ref};
    my $vlines    = $self->get_theme_settings->{'VERTICAL_RULES'};
    my $v0        = q{|} x $vlines->[0];
    my $v1        = q{|} x $vlines->[1];
    my $v2        = q{|} x $vlines->[2];
    my $j         = 0;
    my $col_id    = 0;
    for my $col_def (@cols_defs) {

        if ( !$is_header && $self->get_columns_like_header ) {
        HEADER_COLUMN:
            for my $i ( @{ $self->get_columns_like_header } ) {
                next HEADER_COLUMN if $i != $col_id;
                $col_def = $self->_get_mc_def(
                    $self->_apply_header_formatting(
                        $self->_get_mc_value($col_def), 0
                    )
                );
                if ( !defined $col_def->{cols} ) {
                    my @summary = @{ $self->_get_data_summary() };
                    $col_def->{cols} = 1;
                    $col_def->{align}
                        = $self->get_coldef_strategy->{ $summary[$col_id]
                            . $self->_get_coldef_type_col_suffix };
                }
            }
        }
        if ( defined $col_def->{cols} ) {
            my $vl_pre  = $j == 0           ? $v0 : q{};
            my $vl_post = $j == $#cols_defs ? $v0 : $j == 0
                && $col_def->{cols} == 1 ? $v1 : $v2;

            my $color_code = q{};

            my $cell_bg_color
                = $self->_get_cell_bg_color( $bgcolor, $col_id );
            if ( defined $cell_bg_color ) {
                $color_code = '>{\columncolor{' . $cell_bg_color . '}}';
            }

            push @cols,
                  '\\multicolumn{'
                . $col_def->{cols} . '}{'
                . $vl_pre
                . $color_code
                . $col_def->{align}
                . $vl_post . '}{'
                . $col_def->{value} . '}';

            $col_id += $col_def->{cols};
        }
        else {
            push @cols, $col_def->{value};
            $col_id++;
        }
        $j++;
    }
    if ( defined $bgcolor ) {

        # @cols has always at least one element, otherwise we draw a line
        $cols[0] = "\\rowcolor{$bgcolor}" . $cols[0];
    }
    return \@cols;
}

sub _add_mc_def {
    my ( $self, $arg_ref ) = @_;
    my $def = $self->_get_mc_def( $arg_ref->{value} );
    return defined $def->{cols}
        ? $arg_ref->{value}
        : $self->_get_mc_value($arg_ref);
}

sub _get_mc_value {
    my ( $self, $def ) = @_;
    return
        defined $def->{cols}
        ? $def->{value} . q{:} . $def->{cols} . $def->{align}
        : $def->{value};
}

sub _get_mc_def {
    my ( $self, $value ) = @_;
    return $value =~ m{ \A (.*)\:(\d+)([clr]) \s* \z }xms
        ? {
        value => $1,
        cols  => $2,
        align => $3
        }
        : { value => $value };
}

sub _add_font_family {
    my ( $self, $col, $family ) = @_;
    my %know_families = ( tt => 1, bf => 1, it => 1, sc => 1 );
    if ( !defined $know_families{$family} ) {
        $self->_invalid_option_usage(
            'custom_themes',
            "Family not known: $family. Valid families are: " . join ', ',
            sort keys %know_families
        );
    }
    my $col_def = $self->_get_mc_def($col);
    $col_def->{value} = "\\text$family" . '{' . $col_def->{value} . '}';
    return $self->_get_mc_value($col_def);
}

sub _add_font_color {
    my ( $self, $col, $color ) = @_;
    my $col_def = $self->_get_mc_def($col);
    $col_def->{value} = "\\color{$color}" . $col_def->{value};
    return $self->_get_mc_value($col_def);
}

sub _get_coldef_type_col_suffix {
    my ($self) = @_;
    if ( $self->get_width_environment eq 'tabularx' ) {
        return '_COL_X';
    }
    elsif ( $self->get_width_environment eq 'tabulary' ) {
        return '_COL_Y';
    }
    return '_COL';
}

sub _get_coldef_code {
    my ( $self, $data ) = @_;
    my @cols   = @{ $self->_get_data_summary() };
    my $vlines = $self->get_theme_settings->{'VERTICAL_RULES'};

    my $v0 = q{|} x $vlines->[0];
    my $v1 = q{|} x $vlines->[1];
    my $v2 = q{|} x $vlines->[2];

    my $table_def  = q{};
    my $i          = 0;
    my $strategy   = $self->get_coldef_strategy();
    my $typesuffix = $self->_get_coldef_type_col_suffix();

    my @attributes = grep {m{ _COL }xms} keys %{$strategy};

    for my $col (@cols) {

        # align text right, numbers left, first col always left
        my $align;

        for my $attribute ( sort @attributes ) {
            if ( $attribute =~ m{ \A $col $typesuffix \z }xms ) {
                $align = $strategy->{$attribute};

                # for _X and _Y, use default if no special defs are found
            }
            elsif ( ( $typesuffix eq '_COL_X' || $typesuffix eq '_COL_Y' )
                && $attribute =~ m{ \A $col _COL \z }xms )
            {
                $align = $strategy->{$attribute};
            }
        }

        if ( $i == 0 ) {
            if ( defined $self->get_theme_settings->{'STUB_ALIGN'} ) {
                $align = $self->get_theme_settings->{'STUB_ALIGN'};
            }
            $table_def .= $v0 . $align . $v1;
        }
        elsif ( $i == ( scalar(@cols) - 1 ) ) {
            $table_def .= $align . $v0;
        }
        else {
            $table_def .= $align . $v2;
        }
        $i++;
        if (   $i == 1
            && $self->get_width
            && !$self->get_width_environment )
        {
            $table_def .= '@{\extracolsep{\fill}}';
        }
    }
    return $table_def;
}

sub get_theme_settings {
    my ($self) = @_;

    my $themes = $self->get_available_themes();
    if ( defined $themes->{ $self->get_theme } ) {
        return $themes->{ $self->get_theme };
    }
    $self->_invalid_option_usage( 'theme', 'Not known: ' . $self->get_theme );
    return;
}

no Moose::Util::TypeConstraints;
no Moose;
1;    # Magic true value required at end of module
__END__

=head1 NAME

LaTeX::Table - Perl extension for the automatic generation of LaTeX tables.

=head1 VERSION

This document describes LaTeX::Table version 1.0.6

=head1 SYNOPSIS

  use LaTeX::Table;
  use Number::Format qw(:subs);  # use mighty CPAN to format values

  my $header = [
      [ 'Item:2c', '' ],
      [ '\cmidrule(r){1-2}' ],
      [ 'Animal', 'Description', 'Price' ],
  ];
  
  my $data = [
      [ 'Gnat',      'per gram', '13.65'   ],
      [ '',          'each',      '0.0173' ],
      [ 'Gnu',       'stuffed',  '92.59'   ],
      [ 'Emu',       'stuffed',  '33.33'   ],
      [ 'Armadillo', 'frozen',    '8.99'   ],
  ];

  my $table = LaTeX::Table->new(
  	{   
        filename    => 'prices.tex',
        maincaption => 'Price List',
        caption     => 'Try our special offer today!',
        label       => 'table:prices',
        position    => 'tbp',
        header      => $header,
        data        => $data,
  	}
  );
  
  # write LaTeX code in prices.tex
  $table->generate();

  # callback functions help you to format values easily (as
  # a great alternative to LaTeX packages like rccol)
  #
  # Here, the first colum and the header is printed in upper
  # case and the third colum is formatted with format_price()
  $table->set_callback(sub { 
       my ($row, $col, $value, $is_header ) = @_;
       if ($col == 0 || $is_header) {
           $value = uc $value;
       }
       elsif ($col == 2 && !$is_header) {
           $value = format_price($value, 2, '');
       }
       return $value;
  });     
  
  print $table->generate_string();

Now in your LaTeX document:

  \documentclass{article}

  % for multi-page tables (xtab or longtable)
  \usepackage{xtab}
  %\usepackage{longtable}

  % for publication quality tables (Meyrin theme, the default)
  \usepackage{booktabs}
  % for the NYC theme 
  \usepackage{array}
  \usepackage{colortbl}
  \usepackage{xcolor}
  
  \begin{document}
  \input{prices}
  \end{document}
  
=head1 DESCRIPTION

LaTeX makes professional typesetting easy. Unfortunately, this is not entirely
true for tables and the standard LaTeX table macros have a rather limited
functionality. This module supports many CTAN packages and hides the
complexity of using them behind an easy and intuitive API.

=head1 FEATURES 

This module supports multi-page tables via the C<xtab> or the C<longtable>
package.  For publication quality tables, it uses the C<booktabs> package. It
also supports the C<tabularx> and C<tabulary> packages for nicer fixed-width
tables.  Furthermore, it supports the C<colortbl> package for colored tables
optimized for presentations. The powerful new C<ctable> package is supported
and especially recommended when footnotes are needed. C<LaTeX::Table> ships
with some predefined, good looking L<"THEMES">. The program I<ltpretty> makes
it possible to use this module from within a text editor. 

=head1 INTERFACE 

=over

=item C<my $table = LaTeX::Table-E<gt>new($arg_ref)>

Constructs a C<LaTeX::Table> object. The parameter is an hash reference with
options (see below).

=item C<$table-E<gt>generate()>

Generates the LaTeX table code. The generated LaTeX table can be included in
a LaTeX document with the C<\input> command:
  
  % include prices.tex, generated by LaTeX::Table 
  \input{prices}

=item C<$table-E<gt>generate_string()>

Same as generate() but instead of creating a LaTeX file, this returns the LaTeX code
as string.

  my $latexcode = $table->generate_string();

=item C<$table-E<gt>get_available_themes()>

Returns an hash reference to all available themes.  See L<"THEMES"> for
details.

  for my $theme ( keys %{ $table->get_available_themes } ) {
    ...
  }

=item C<$table-E<gt>search_path( add =E<gt> "MyThemes" );> 

C<LaTeX::Table> will search under the C<LaTeX::Table::Themes::> namespace for
themes. You can add here an additional search path. Inherited from
L<Module::Pluggable>.

=back

=head1 OPTIONS

Options can be defined in the constructor hash reference or with the setter
C<set_optionname>. Additionally, getters of the form C<get_optionname> are
created.

=head2 BASIC OPTIONS

=over

=item C<filename>

The name of the LaTeX output file. Default is 'latextable.tex'.

=item C<type>

Can be 'std' (default) for standard LaTeX tables, 'ctable' for tables using
the C<ctable> package or 'xtab' and 'longtable' for multi-page tables (requires
the C<xtab> and C<longtable> LaTeX packages, respectively). 

=item C<header>

The header. It is a reference to an array (the rows) of array references (the
columns).

  $table->set_header([ [ 'Animal', 'Price' ] ]);

will produce following header:

  +--------+-------+
  | Animal | Price |
  +--------+-------+

Here an example for a multirow header:

  $table->set_header([ [ 'Animal', 'Price' ], ['', '(roughly)' ] ]);

This code will produce this header:

  +--------+-----------+
  | Animal |   Price   |
  |        | (roughly) |
  +--------+-----------+

Single column rows that start with a backslash are treated as LaTeX commands
and are not further formatted. So,

  my $header = [
      [ 'Item:2c', '' ],
      ['\cmidrule{1-2}'],
      [ 'Animal', 'Description', 'Price' ]
  ];

will produce following LaTeX code in the Zurich theme:

  \multicolumn{2}{c}{\textbf{Item}} &                                          \\ 
  \cmidrule{1-2}
  \textbf{Animal}                   & \multicolumn{1}{c}{\textbf{Description}} & \multicolumn{1}{c}{\textbf{Price}}\\ 

Note that there is no C<\multicolumn>, C<\textbf> or C<\\> added to the second row.

=item C<data>

The data. Once again a reference to an array (rows) of array references
(columns). 

  $table->set_data([ [ 'Gnu', '92.59' ], [ 'Emu', '33.33' ] ]);

And you will get a table like this:

  +-------+---------+
  | Gnu   |   92.59 |
  | Emu   |   33.33 |
  +-------+---------+

An empty column array will produce a horizontal rule (line):

  $table->set_data([ [ 'Gnu', '92.59' ], [], [ 'Emu', '33.33' ] ]);

Now you will get such a table:

  +-------+---------+
  | Gnu   |   92.59 |
  +-------+---------+
  | Emu   |   33.33 |
  +-------+---------+

This works also in C<header>. 

Single column rows starting with a backslash are again printed without any
formatting. So,

  $table->set_data([ [ 'Gnu', '92.59' ], ['\hline'], [ 'Emu', '33.33' ] ]);

is equivalent to the example above (except that there always the correct rule
command is used, i.e. C<\midrule> vs. C<\hline>).

=item C<custom_template> 

The table types listed above use the L<Template> toolkit internally. These
type templates are very flexible and powerful, but you can also provide a
custom template:

  # Returns the header and data formatted in LaTeX code. Nothing else.
  $table->set_custom_template('[% HEADER_CODE %][% DATA_CODE %]');

See L<LaTeX::Table::Types::TypeI>.

=back

=head2 FLOATING TABLES

=over

=item C<environment>

If get_environment() returns a true value, then a floating environment will be 
generated. For I<std> tables, the default environment is 'table'. A true value different
from '1' will be used as environment name. Default is 1 (use a 'table'
environment).

The non-floating I<xtab> and I<longtable> environments are mandatory
(get_environment() must return a true value here) and support all options in
this section except for C<position>.

The I<ctable> type automatically adds an environment when any of the
following options are set.

=item C<caption>

The caption of the table. Only generated if get_caption() returns a true value. 
Default is 0. Requires C<environment>.

=item C<caption_top>

If get_caption_top() returns a true value, then the caption is placed above the
table. To use the standard caption command (C<\caption> in I<std> and
I<longtable>, C<\topcaption> in I<xtab>) , use 

  ...
  caption_top => 1, 
  ...

You can specify an alternative command here:

  ...
  caption_top => 'topcaption', # would require the topcapt package

Or even multiple commands: 

  caption_top =>
     '\setlength{\abovecaptionskip}{0pt}\setlength{\belowcaptionskip}{10pt}\caption',
  ...

Default 0 (caption below the table) because the spacing in the standard LaTeX 
macros is optimized for bottom captions. At least for multi-page tables, 
however, top captions are highly recommended. You can use the C<caption> 
LaTeX package to fix the spacing:

  \usepackage[tableposition=top]{caption} 

=item C<maincaption>

If get_maincaption() returns a true value, then this value will be displayed 
in the table listing (C<\listoftables>) and before the C<caption>. For example,

  maincaption => 'Price List',
  caption     => 'Try our special offer today!',

will generate

  \caption[Price List]{Price List. Try our special offer today!}

Themes can set the font family of the maincaption. 

Default 0. Requires C<environment>. 

=item C<shortcaption>

Same as C<maincaption>, but does not appear in the caption, only in the table
listing. Default 0. Requires C<environment>.

=item C<continued>

If true, then the table counter will be decremented by one and the
C<continuedmsg> is appended to the caption. Useful for splitting tables. Default 0.

  $table->set_continued(1);

=item C<continuedmsg>

If get_continued() returns a true value, then this text is appended to the
caption. Default '(continued)'.

=item C<center>, C<right>, C<left>

Defines how the table is aligned in the available textwidth. Default is centered. Requires 
C<environment>. Only one of these options may return a true value.
    
  # don't generate any aligning code
  $table->set_center(0);
  ...
  # restore default
  $table->clear_center();

=item C<label>

The label of the table. Only generated if get_label() returns a true value.
Default is 0. Requires C<environment>. 

 $table->set_label('tbl:prices');

=item C<position>

The position of the environment, e.g. 'tbp'. Only generated if get_position()
returns a true value. Default 0. Requires C<environment> and tables of C<type>
I<std> or I<ctable>.

=item C<sideways>

Rotates the environment by 90 degrees. Default 0. For tables of C<type> I<std>
and I<ctable>, this requires the C<rotating> LaTeX package, for I<xtab> or
I<longtable> tables the C<lscape> package.

 $table->set_sideways(1);

=item C<star>

Use the starred versions of the environments, which place the float over two
columns when the C<twocolumn> option or the C<\twocolumn> command is active.
Default 0.

 $table->set_star(1);

=item C<fontfamily>

Valid values are 'rm' (Roman, serif), 'sf' (Sans-serif), 'tt' (Monospace or
typewriter) and 0. Default is 0 (does not define a font family).  Requires
C<environment>.

=item C<fontsize>

Valid values are 'tiny', 'scriptsize', 'footnotesize', 'small', 'normal',
'large', 'Large', 'LARGE', 'huge', 'Huge' and 0. Default is 0 (does not define
a font size). Requires C<environment>.

=back

=head2 TABULAR ENVIRONMENT

=over 

=item C<custom_tabular_environment>

If get_custom_tabular_environment() returns a true value, then this specified
environment is used instead of the standard environments 'tabular' (I<std>)
'longtable' (I<longtable>) or 'xtabular' (I<xtab>). For I<xtab> tables, you
can also use the 'mpxtabular' environment here if you need footnotes. See the
documentation of the C<xtab> package.

See also the documentation of C<width> below for cases when a width is
specified.

=item C<coldef>

The table column definition, e.g. 'lrcr' which would result in:

  \begin{tabular}{lrcr}
  ..

If unset, C<LaTeX::Table> tries to guess a good definition. Columns containing
only numbers are right-justified, others left-justified. Columns with cells
longer than 30 characters are I<p> (paragraph) columns of size '5cm' (I<X>
columns when the C<tabularx>, I<L> when the C<tabulary> package is selected).
These rules can be changed with set_coldef_strategy(). Default is 0 (guess
good definition). The left-hand column, the stub, is normally excluded here
and is always left aligned. See L<LaTeX::Table::Themes::ThemeI>.

=item C<coldef_strategy>

Controls the behavior of the C<coldef> calculation when get_coldef()
does not return a true value. It is a reference to a hash that contains
regular expressions that define the I<types> of the columns. For example, 
the standard types I<NUMBER> and I<LONG> are defined as:

  {
    NUMBER                =>
       qr{\A\s*([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?\s*\z}xms,
    NUMBER_MUST_MATCH_ALL => 1,
    NUMBER_COL            => 'r',
    LONG                  => qr{\A\s*(?=\w+\s+\w+).{29,}?\S}xms,
    LONG_MUST_MATCH_ALL   => 0,
    LONG_COL              => 'p{5cm}',
    LONG_COL_X            => 'X',
    LONG_COL_Y            => 'L',
  };

=over

=item C<TYPE =E<gt> $regex>

New types are defined with the regular expression C<$regex>. All B<cells> that
match this regular expression have type I<TYPE>. A cell can have multiple
types. The name of a type is not allowed to contain underscores (C<_>).

=item C<TYPE_MUST_MATCH_ALL>

This defines if whether a B<column> has type I<TYPE> when all B<cells> 
are of type I<TYPE> or at least one. Default is C<1> (C<$regex> must match
all).

Note that columns can have only one type. Types are applied alphabetically, 
so for example a I<LONG> I<NUMBER> column has as final type I<NUMBER>.

=item C<TYPE_COL>

The C<coldef> attribute for I<TYPE> columns. Required (no default value).

=item C<TYPE_COL_X>, C<TYPE_COL_Y>

Same as C<TYPE_COL> but for C<tabularx> or C<tabulary> tables. If undefined,
the attribute defined in C<TYPE_COL> is used. 

=item C<DEFAULT_COL>, C<DEFAULT_COL_X>, C<DEFAULT_COL_Y>

The C<coldef> attribute for columns that do not match any specified type.
Default 'l' (left-justified).

=item C<MISSING_VALUE =E<gt> $regex>

Column values that match the specified regular expression are omitted in the
C<coldef> calculation. Default is C<qr{\A \s* \z}xms>.

=back

Examples:

  # change standard types
  $table->set_coldef_strategy({
    NUMBER   => qr{\A \s* \d+ \s* \z}xms, # integers only
    LONG_COL => '>{\raggedright\arraybackslash}p{7cm}', # non-justified
  });

  # add new types (here: columns that contain only URLs)
  $table->set_coldef_strategy({
    URL     => qr{\A \s* http }xms, 
    URL_COL => '>{\ttfamily}l',
  });

  

=item C<width>

If get_width() returns a true value, then C<LaTeX::Table> will use the starred
version of the environment (e.g. C<tabular*> or C<xtabular*>) and will add the
specified width as second parameter. It will also add
C<@{\extracolsep{\fill}}> to the table column definition:

  # use 75% of textwidth 
  $table->set_width('0.75\textwidth');

This will produce following LaTeX code:

  \begin{tabular*}{0.75\textwidth}{l@{\extracolsep{\fill} ... }

For tables of C<type> I<std>, it is also possible to use the C<tabularx> and
C<tabulary> LaTeX packages (see C<width_environment> below). The tables of
type I<ctable> automatically use the C<tabularx> package. See also
C<width_environment> for how to use this feature with I<longtable>. 

=item C<width_environment>

If get_width() (see above) returns a true value and table is of C<type> I<std>,
then this option provides the possibility to add a custom tabular environment
that supports a table width:

  \begin{environment}{width}{def}

To use for example the one provided by the C<tabularx> LaTeX package, write:

  # use the tabularx package (for a std table)
  $table->set_width('300pt');
  $table->set_width_environment('tabularx');

Note this will not add C<@{\extracolsep{\fill}}> and that this overwrites
a C<custom_tabular_environment>. 

It is possible to use C<tabularx> together with tables of type I<longtable>.
In this case, you have to generate a I<file> and then load the table with the
C<LTXtable> command (C<ltxtable> package):

  $table = LaTeX::Table->new(
      {   filename    => 'mylongtable.tex'
          type        => 'longtable',
          ...
          width_environment => 'tabularx', 
      }
  );
 
Then in LaTeX:
  
  \LTXtable{0.8\textwidth}{mylongtable}
  
Note that we have to do the specification of the width in LaTeX. 

Default is 0 (see C<width>).

=item C<maxwidth>

Only supported by tables of type I<ctable>. 

=item C<eor>

String specifying the end of a row. Default is '\\'.
  
  $table->set_eor("\\\\[1em]");

Callback functions (see below) can be used to manually set the eor after the last
column. This is useful when some rows require different eor strings. 

=item C<callback>

If get_callback() returns a true value and the return value is a code reference,
then this callback function will be called for every column in C<header>
and C<data>. The return value of this function is then printed instead of the 
column value. 

The passed arguments are C<$row>, C<$col> (both starting with 0), C<$value> and 
C<$is_header>.

  use LaTeX::Encode;
  use Number::Format qw(:subs);  
  ...
  
  # rotate header (not the first column),
  # use LaTeX::Encode to encode LaTeX special characters,
  # format the third column with Format::Number (only the data)
  my $table = LaTeX::Table->new(
      {   header   => $header,
          data     => $data,
          callback => sub {
              my ( $row, $col, $value, $is_header ) = @_;
              if ( $col != 0 && $is_header ) {
                    $value = '\begin{sideways}' . $value . '\end{sideways}';
              }
              elsif ( $col == 2 && !$is_header ) {
                  $value = format_price($value, 2, '');
              }
              else {
                  $value = latex_encode($value);
              }
              return $value;
          },
      }
  );

=item C<foottable>

Only supported by tables of type C<ctable>. The footnote C<\tnote> commands.
See the documentation of the C<ctable> LaTeX package.

  $table->set_foottable('\tnote{footnotes are placed under the table}');

=item C<resizebox>

If get_resizebox() returns a true value, then the resizebox command is used to
resize the table. Takes as argument a reference to an array. The first element
is the desired width. If a second element is not given, then the height is set to
a value so that the aspect ratio is still the same. Requires the C<graphicx>
LaTeX package. Default 0.

  $table->set_resizebox([ '0.6\textwidth' ]);

  $table->set_resizebox([ '300pt', '200pt' ]);


=back

=head2 MULTI-PAGE TABLES

=over

=item C<tableheadmsg>

When get_caption_top() and get_tableheadmsg() both return true values, then
additional captions are printed on the continued pages. Default caption text 
is 'Continued from previous page'.

=item C<tabletailmsg>

Message at the end of a multi-page table. Default is 'Continued on next page'. 
When using C<caption_top>, this is in most cases unnecessary and it is
recommended to omit the tabletail (see below).

=item C<tabletail>

Custom table tail. Default is multicolumn with the tabletailmsg (see above) 
right-justified. 
  
  # don't add any tabletail code:
  $table->set_tabletail(q{});

=item C<tablelasttail>

Same as C<tabletail>, but defines only the bottom of the last page ('lastfoot'
in the C<longtable> package). Default C<''>.

=item C<xentrystretch>

Option for xtab. Play with this option if the number of rows per page is not 
optimal. Requires a number as parameter. Default is 0 (does not use this option).

  $table->set_xentrystretch(-0.1);

=back

=head2 THEMES

=over

=item C<theme>

The name of the theme. Default is I<Meyrin> (requires C<booktabs> LaTeX
package).

See L<LaTeX::Table::Themes::ThemeI> how to define custom themes.

The themes are defined in L<LaTeX::Table::Themes::Beamer>,
L<LaTeX::Table::Themes::Booktabs>, L<LaTeX::Table::Themes::Classic>,
L<LaTeX::Table::Themes::Modern>.

  $table->set_theme('Zurich');

=item C<predef_themes>

All predefined themes. Getter only.

=item C<custom_themes>

All custom themes. See L<LaTeX::Table::Themes::ThemeI>.

=item C<columns_like_header>

Takes as argument a reference to an array with column ids (again, starting
with 0). These columns are formatted like header columns.

  # a "transposed" table ...
  my $table = LaTeX::Table->new(
      {   data     => $data,
          columns_like_header => [ 0 ], }
  );

=back

=head1 MULTICOLUMNS 

Multicolumns are defined in LaTeX with
C<\multicolumn{$cols}{$alignment}{$text}>. This module supports a simple
shortcut of the format C<$text:$cols$alignment>. For example, C<Item:2c> is
equivalent to C<\multicolumn{2}{c}{Item}>. Note that vertical rules (C<|>) are
automatically added here according the rules settings in the theme.  See
L<LaTeX::Table::Themes::ThemeI>. C<LaTeX::Table> also uses this shortcut to
determine the column ids. So in this example,

  my $data = [ [' \multicolumn{2}{c}{A}', 'B' ], [ 'C:2c', 'D' ] ];

'B' would have an column id of 1 and 'D' 2 ('A' and 'C' both 0). This is important 
for callback functions and for the coldef calculation. 
See L<"TABULAR ENVIRONMENT">.

=head1 EXAMPLES

See I<examples/examples.pdf> in this distribution for a short tutorial that
covers the main features of this module. See also the example application
I<csv2pdf> for an example of the common task of converting a CSV (or Excel)
file to LaTeX or even PDF.

=head1 DIAGNOSTICS

If you get a LaTeX error message, please check whether you have included all
required packages. The packages we use are C<array>, C<booktabs>, C<colortbl>,
C<ctable>, C<graphicx>, C<longtable>, C<lscape>, C<rotating>, C<tabularx>,
C<tabulary>, C<xcolor> and C<xtab>. 

C<LaTeX::Table> may throw one of these errors:

=over

=item C<IO error: Can't ...>

In method generate(), it was not possible to write the LaTeX code to
C<filename>. 

=item C<Invalid usage of option ...> 

In method generate() or generate_string(). See the examples in this document
and in I<examples/examples.pdf> for the correct usage of this option.

=item C<Attribute (option) ... >

In method new() or set_option(). You passed a wrong type to the option. See
this document or I<examples/examples.pdf> for the correct usage of this option.

=back

=head1 CONFIGURATION AND ENVIRONMENT

C<LaTeX::Table> requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Carp>, L<Module::Pluggable>, L<Moose>, L<English>, L<Scalar::Util>,
L<Template>

=head1 BUGS AND LIMITATIONS

The C<width> option causes problems with themes using the C<colortbl> package.
You may have to specify here the overhang arguments of the C<\columcolor>
commands manually. Patches are of course welcome.

Problems with the C<width> option are also known for tables of type
I<longtable>. You should use the C<tabularx> package as described in the
C<width_environment> documentation. 

Please report any bugs or feature requests to
C<bug-latex-table@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>. 

=head1 SEE ALSO

L<Data::Table>, L<LaTeX::Encode>

=head1 CREDITS

=over

=item ANDREWF, ANSGAR and REHSACK for some great patches and suggestions.

=item David Carlisle for the C<colortbl>, C<longtable>, C<ltxtable>,
C<tabularx> and C<tabulary> LaTeX packages.

=item Wybo Dekker for the C<ctable> LaTeX package.

=item Simon Fear for the C<booktabs> LaTeX package. The L<"SYNOPSIS"> table is
the example in his documentation.

=item Lapo Filippo Mori for the excellent tutorial I<Tables in LaTeX2e:
Packages and Methods>.

=item Peter Wilson for the C<xtab> LaTeX package.

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2010 C<< <limaone@cpan.org> >> 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
