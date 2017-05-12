package HTML::FromANSI;
$HTML::FromANSI::VERSION = '2.03';

use strict;
use base qw/Exporter/;
use vars qw/@EXPORT @EXPORT_OK @Color %Options/;
use Term::VT102::Boundless;
use HTML::Entities;
use Scalar::Util qw(blessed reftype);
use Carp qw(croak);

=head1 NAME

HTML::FromANSI - Mark up ANSI sequences as HTML

=head1 SYNOPSIS

    use HTML::FromANSI (); # avoid exports if using OO
    use Term::ANSIColor;

    my $h = HTML::FromANSI->new(
        fill_cols => 1,
    );


    $h->add_text(color('bold blue'), "This text is bold blue.");

    print $h->html;


    # you can append text in the new api:

    $h->add_text(color('bold blue'), " still blue.");

    print $h->html



    # The old API still works:

    $HTML::FromANSI::Options{fill_cols} = 1; # fill all 80 cols
    print ansi2html(color('bold blue'), "This text is bold blue.");

=head1 DESCRIPTION

This small module converts ANSI text sequences to corresponding HTML
codes, using stylesheets to control color and blinking properties.

It exports C<ansi2html()> by default, which takes an array, joins it
it into a single scalar, and returns its HTML rendering.

From version 2.00 an object oriented api which is safer for multiple uses (no
more manipulation of shared C<%Options>) is available. It is reccomended that
you no longer import any functions by doing:

    use HTML::FromANSI ();

and use the new documented API instead of the functional one.

The underlying ANSI code processing is done by L<Term::VT102>, a DEC VT102
terminal emulator. To generate ANSI codes for color changes, cursor movements
etc, take a look at L<Term::ANSIScreen> and L<Term::ANSIColor>.

=head1 METHODS

=over 4

=item new

The constructor. See L</OPTIONS> for the options it takes.

=item add_text @text

Adds text input to the terminal emulator.

=item html

Renders the screen as computed by C<terminal_object> into HTML.

=item ansi_to_html @text

A convenience method.

Calls C<add_text> and then C<html>.

=item terminal_object

The underlying terminal emulator object.

=back

=head1 OPTIONS

These are parameters you can pass to C<new>.

=over 4

=item linewrap

A boolean value to specify whether to wrap lines that exceeds
width specified by C<col>, or simply truncate them. Defaults to C<1>.

Only takes effect if you override C<terminal_class> or C<terminal_object> with
a L<Term::VT102> (instead of L<Term::VT102::Boundless>).

=item lf_to_crlf

A boolean value to specify whether to translate all incoming
\n into C<\r\n> or not; you generally wants to use this if your
data is from a file using unix line endings. The default is C<0>
on MSWin32 and MacOS, and C<1> on other platforms.

=item fill_cols

A boolean value to specify whether to fill empty columns with
space; use this if you want to maintain a I<screen-like> appearance
in the resulting HTML, so that each row will be aligned properly.
Defaults to C<0>.

=item html_entity

A boolean value to specify whether to escape all high-bit characters
to HTML entities or not; defaults to C<0>, which means only C<E<lt>>,
C<E<gt>>, C<"> and C<&> will be escaped. (Handy when processing most
ANSI art entries.)

=item cols

A number specifying the width of the virtual terminal; defaults to 80.

When C<Term::VT102::Boundless> is in use (the default) this specifies the
minimum number of rows to draw.

When using C<Term::VT102> (by overriding C<terminal_class> or
C<terminal_object>) then the number of columns is fixed.

=item rows

When C<Term::VT102::Boundless> is in use (the default) this specifies the
minimum number of rows to draw.

When L<Term::VT102> is in use (by overriding C<terminal_class> or
L<terminal_object>) then it sets the height of the virtual terminal; rows that
exceeds this number will be truncated.

=item font_face

A string used as the C<face> attribute to the C<font> tag enclosing the
HTML text; defaults to C<fixedsys, lucida console, terminal, vga, monospace>.

If this option and the C<style> option are both set to empty strings, the
C<font> tag will be omitted.

=item style

A string used as the C<style> attribute to the C<font> tag enclosing the
HTML text; defaults to <line-height: 1; letter-spacing: 0; font-size: 12pt>.

If this option and the C<font_face> option are both set to empty strings, the
C<font> tag will be omitted.

=item tt

A boolean value specifying whether the HTML text should be enclosed in a
C<tt> tag or not. Defaults to C<1>.

=item show_cursor

A boolean value to control whether to highlight the character under
the cursor position, by reversing its background and foregroud color.
Defaults to C<0>.

If the cursor is on it's own line and C<show_cursor> is set, then that row will
be omitted.

=item terminal_class

The class to instantiate C<terminal_object> with. Defaults to
L<Term::VT102::Boundless>.

=item terminal_object

Any L<Term::VT102> compatible object should work here.

If you override it most values like C<cols>, C<rows>, C<terminal_class> etc
will be ignored.

=cut

@EXPORT = '&ansi2html';
@EXPORT_OK = qw|@Color %Options|;

@Color = (qw(
    black   darkred darkgreen),'#8b8b00',qw(darkblue darkmagenta darkcyan gray
    dimgray     red     green    yellow         blue     magenta     cyan white
));

%Options = (
    linewrap	=> 1,		# wrap long lines
    lf_to_crlf	=> (		# translate \n to \r\n on Unix
        $^O !~ /^(?:MSWin32|MacOS)$/
    ),
    fill_cols	=> 0,		# fill all (80) columns with space
    html_entity => 0,		# escape all HTML entities
    cols	=> 80,		# column width
    rows	=> undef,	# let ansi2html figure it out
    font_face	=> 'fixedsys, lucida console, terminal, vga, monospace',
    style	=> 'line-height: 1; letter-spacing: 0; font-size: 12pt',
    tt		=> 1,
    show_cursor	=> 0,

    terminal_class => 'Term::VT102::Boundless',
);

sub import {
    my $class = shift;
    while (my ($k, $v) = splice(@_, 0, 2)) {
        $Options{$k} = $v;
    }
    $class->export_to_level(1);
}

sub new {
    my ( $class, @args ) = @_;

    if ( @args == 1 && reftype($args[0]) eq 'HASH' ) {
        return bless { %Options, %{ $args[0] } }, $class;
    } elsif ( @args % 2 == 0 ) {
        return bless { %Options, @args }, $class;
    } else {
        croak "Constructor arguments must be an even sized list or a hash ref";
    }
}

sub _obj_args {
    if ( blessed($_[0]) and $_[0]->isa(__PACKAGE__) ) {
        return @_;
    } else {
        return ( __PACKAGE__->new(), @_ );
    }
}

sub ansi2html {
    my ( $self, @args ) = _obj_args(@_);
    $self->ansi_to_html(@args);
}

sub terminal_object {
    my ( $self, @args ) = @_;
    $self->{terminal_object} ||= $self->create_terminal_object(@args);
}

sub create_terminal_object {
    my ( $self, %args ) = @_;

    my $class = $self->{terminal_class};

    if ( $class ne 'Term::VT102::Boundless' ) {
        ( my $file = "${class}.pm" ) =~ s{::}{/}g;
        require $file;
    }

    my $vt = $class->new(
        cols => $self->{cols},
        ( defined($self->{rows}) ? ( rows => $self->{rows} ) : () ),
    );

    $vt->option_set(LINEWRAP => $self->{linewrap});
    $vt->option_set(LFTOCRLF => $self->{lf_to_crlf});

    $vt->_code_DECTCEM( $self->{show_cursor} );

    return $vt;
}

sub add_text {
    my ( $self, @lines ) = @_;
    $self->terminal_object->process($_) for @lines;
}

sub ansi_to_html {
    my ( $self, @lines ) = @_;

    $self->add_text(@lines);

    return $self->html;
}

sub html {
    my ( $self, @args ) = @_;

    my $result = $self->parse_vt($self->terminal_object);

    if (length $self->{font_face} or length $self->{style}) {
        $result = "<font face='$self->{font_face}' style='$self->{style}'>".
        $result."</font>";
    }

    $result = "<tt>$result</tt>" if $self->{tt};

    return $result;
}

sub parse_vt {
    my ( $self, $vt ) = _obj_args(@_);

    my (%prev, %this); # attributes
    my $out;

    my ($x, $y) = ($vt->x, $vt->y);

    my $total_rows = $vt->rows;

    foreach my $row_num (1 .. $total_rows) {
        local $SIG{__WARN__} = sub {}; # abandon all hope, ye who enter here

        my $row = $vt->row_text($row_num);
        my $att = $vt->row_attr($row_num);

        if ( $row_num == $total_rows and $total_rows != ($self->{rows}||0) # this is the last row
            and $row =~ /^[\s\x00]*$/s # and it's completely empty
            and !$self->{show_cursor} # and we're not showing a cursor
        ) { last } # skip it

        foreach my $col_num (0 .. length($row)) {
            my $text = substr($row, $col_num,, 1);

            @this{qw|fg bg bo fo st ul bl rv|} = $vt->attr_unpack(
                substr($att, $col_num * 2, 2)
            );

            if ($y == $row_num and $x == $col_num + 1 and $self->{show_cursor}) {
                # this block is the cursor
                @this{qw|fg bg bo bl|} = (@this{qw|bg fg bl bo|});
                $text = ' ' if $text eq '\000';
            }
            elsif ($text eq "\000") {
                next unless $self->{fill_cols};
            }

            $out .= $self->diff_attr(\%prev, \%this) . (
                ($text eq ' ' or $text eq "\000") ? '&nbsp;':
                $self->{html_entity} ? encode_entities($text)
                : encode_entities($text, '<>"&')
            );

            %prev = %this;
        }

        $out .= "<br>";
    }

    return "$out</span>";
}

sub diff_attr {
    my ($self, $prev, $this) = _obj_args(@_);
    my $out = '';

    # skip if the attributes remain unchanged
    return if %{$prev} and not scalar (grep {
            ($_->[0] ne $_->[1])
        } map {
            [ $prev->{$_}, $this->{$_} ]
        } keys %{$this}
    );

    # bold, faint, standout, underline, blink and reverse
    my ($fg, $bg, $bo, $fo, $st, $ul, $bl, $rv)
        = @{$this}{qw|fg bg bo fo st ul bl rv|};

    ($fg, $bg) = ($bg, $fg) if $rv;

    $out .= "</span>" if %{$prev};
    $out .= "<span style='";
    $out .= "color: $Color[$fg + $bo * 8]; ";
    $out .= "background: $Color[$bg + $bl * 8]; ";
    $out .= "text-decoration: underline; " if $ul;
    $out .= "'>";

    return $out;
}

1;

__END__

=head1 SEE ALSO

L<Term::VT102::Boundless>, L<HTML::Entities>, L<Term::ANSIScreen>

=head1 AUTHORS

Audrey Tang E<lt>audreyt@audreyt.orgE<gt>
Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

Copyright 2001, 2002, 2003 by Audrey Tang E<lt>audreyt@audreyt.orgE<gt>.

Copyright 2007 Yuval Kogman E<lt>nothingmuch@Woobling.orgE<gt>

This program is free software; you can redistribute it and/or
modify it under the terms of the MIT license or the same terms as Perl itself.

=cut
