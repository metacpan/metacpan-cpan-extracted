package HTML::Tooltip::Javascript;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HTML::Tooltip::Javascript ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.01';

# Preloaded methods go here.

sub new {
    my ($class, %arg) = @_;
    my $self = {};
    $self->{javascript_dir} = $arg{javascript_dir} || '/';
    $self->{javascript_dir} .= "/" unless ($self->{javascript_dir} =~ m:/$:);
    $self->{options} = $arg{options} || {};
    bless($self, $class);
    return $self;
}

sub tooltip {
    my ($self, $tip, $options) = @_;

    return '' if (!$tip && !$self->{options}->{default_tip});

    $tip = $self->{options}->{default_tip} if (!$tip);

    $tip =~ s/\\/\\\\/g;
    $tip =~ s/['"]/\\'/g;
    $tip =~ s/[\n\r]//g;

    my %opts = %{$self->{options}};
    foreach my $o (keys %$options) {
        $opts{$o} = $options->{$o};
    }

    my $text = ' onmouseover="';
    my %can_be_zero = (
        borderwidth => 1,
        delay => 1,
    );
    foreach my $o (keys %opts) {
        next if ($o eq 'default_tip');
        next if ($o eq 'function');
        if ($can_be_zero{$o}) {
            next if (!defined $opts{$o});
        } else {
            next if (!$opts{$o});
        }
        my $param = uc($o);
        my $val = $opts{$o};

        if ($o !~ m/fix/i) {
            $val = "'$val'" unless
              ($val =~ m/^\d+$/ || $val =~ m/^true$/i || $val =~ m/^false$/);
        }

        $text .= "this.T_$param=$val; ";
    }

    if ($opts{'function'}) {
      $text .= "return escape($tip);";
    } else {
      $text .= "return escape('$tip');";
    }
    $text .= '" ';
    return $text;
}

sub at_end($) {
    my ($self) = @_;
    my $js = $self->{javascript_dir} . 'wz_tooltip.js';
    return qq(<SCRIPT LANGUAGE="Javascript" TYPE="text/javascript" src="$js"></SCRIPT>);
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

HTML::Tooltip::Javascript - Provides a perl interface for easy use of Walter Zorn's javascript tooltip library (versions prior to 4.0).  See http://www.walterzorn.com/tooltip_old/tooltip_e.htm

=head1 SYNOPSIS

    use HTML::Tooltip::Javascript;

    my $tt = HTML::Tooltip::Javascript->new(
        javascript_dir => '/javascript/',
        options        => \%default_options,
    );

    # In HTML output ...

    my $tip1 = $tt->tooltip("Tip", \%options);
    print qq(<a href="/example/" $tip1>Example</a>);

    # Output the script tag that refers to the Javascript tooltip
    # library.  It's essential that this is printed after all other
    # tooltip related output.

    print $tt->at_end;

    # ... end HTML here

=head1 DESCRIPTION


This perl module provides an easy interface to Walter Zorn's GPLed Javascript tooltip library (versions prior to 4.0).  For further information on the Javascript library see http://www.walterzorn.com.

On a web page, a tooltip is a box of text and/or images that pops up when the mouse hovers over an image, link, some text or an area of the page (div tag).  Walter Zorn's library allows great control over these boxes including changing colors, borders, fonts, images, delay (how fast the box pops up), alignment, shadows and more.

This perl module makes the Javascript tooltip library simple to use from a CGI aspect, allowing you to set defaults so that all your tooltips appear the same, and keeping the amount of code you have to write to a minimum.

=head1 QUICK START

For those who don't like reading doco, here's a working example.  Make sure you've copied wz_tooltip.js into a web enabled directory.

    #!/usr/bin/perl
    use strict;
    use warnings;
    use CGI;
    use CGI::Carp qw(fatalsToBrowser); # Comment this out in production
    use HTML::Tooltip::Javascript;

    my $q = CGI->new();

    my $tt = HTML::Tooltip::Javascript->new(
        # Relative url path to where wz_tooltip.js is
        javascript_dir => '/javascript/',
        options        => {
            bgcolor     => '#EEEEEE',
            default_tip => 'Tip not defined',
            delay       => 0,
            title       => 'Tooltip',
        },
    );

    my $tip1 = $tt->tooltip("Walter Zorn's page", {fontsize => '30px'});
    my $tip2 = $tt->tooltip("CPAN");
    my $tip3 = $tt->tooltip();

    print $q->header;
    print $q->start_html;

    print <<"EOT";
    <a href="http://www.walterzorn.com" $tip1>Walter Zorn</a><BR>
    <a href="http://search.cpan.org"    $tip2>CPAN</a><BR>
    <a href="http://www.perlmeme.org"   $tip3>Perlmeme</a><BR>
    EOT

    print $tt->at_end;
    print $q->end_html;

=head1 METHODS

=head2 new

    my $tt = HTML::Tooltip::Javascript->new(
        javascript_dir => '/javascript/',
        options        => \%default_options,
    );

This method create a new HTML::Tooltip::Javascript object.  The parameters are optional.

=over 4

=item javascript_dir

This defines the relative url to the wz_tooltip.js file.  For example, if you have put the wz_tooltip.js file in a 'javascript' directory under your document root, then you would use:

    javascript_dir => '/javascript/'

The default is /.

=item options

The hash of options defines the options available in Walter Zorn's library, but with more user-friendly names.  It also allows the definition of default text for the tooltip box.  The options available are:

    option           javascript option
    -------          ------------------
    above            T_ABOVE
    bgcolor          T_BGCOLOR
    bgimg            T_BGIMG
    borderwidth      T_BORDERWIDTH
    bordercolor      T_BORDERCOLOR
    default_tip      (none)
    delay            T_DELAY
    fix              T_FIX
    fontcolor        T_FONTCOLOR
    fontface         T_FONTFACE
    fontsize         T_FONTSIZE
    fontweight       T_FONTWEIGHT
    function         (none)
    left             T_LEFT
    above            T_ABOVE
    offsetx          T_OFFSETX
    offsety          T_OFFSETY
    padding          T_PADDING
    shadowcolor      T_SHADOWCOLOR
    shadowwidth      T_SHADOWWIDTH
    static           T_STATIC
    sticky           T_STICKY
    title            T_TITLE
    titlecolor       T_TITLECOLOR
    width            T_WIDTH

When defined in new, the options will be applied to each tooltip, unless the call to tooltip() specifically redefines that option.

The default_tip is the text that will be used if no text is provided in the call to tooltip().

The function option is used if the text you pass in as the tip is actually a call to a javascript function.  The javascript function must return text to output in the tooltip.

=head2 tooltip

    my $tip1 = $tt->tooltip("Tip", \%options);

This method returns the HTML to be inserted into the HTML element for which the tooltip is to be displayed.

For example, to output a tooltip for a link:

    my $tip1 = $tt->tooltip("Example Tip", {fontcolor => 'blue'});
    print qq(<a href="/example/" $tip1>Example</a>);

This would output a link with text 'Example', and when the mouse pointer hovers over the link, a popup box with the words 'Example Tip' in blue would appear.

Any options passed into to the tooltip() method will overwrite the values provided in the new method.  However, options provided in the new method will be inherited unless specifically undefined in the tooltip method.

=head2 at_end

    print $tt->at_end;

This method outputs the html to include Walter Zorn's script.  It must be output after all tooltip related output.  We recommend printing the output of this method at the end of the html, just before the close BODY tag (hence the name at_end()).

=head1 BROWSER SUPPORT

Walter Zorn's site states that the library supports the following browsers:

Linux: Konqueror 3, Browsers with Gecko-Engine (Mozilla/Firefox, Netscape 6, Galeon), Netscape 4 and 6, Opera 5 and 6.

Windows: Netscape 4, Gecko Browsers, IE 4, 5.0, 5.5 and 6.0, Opera 5,6,7.

Other: The equivalent browsers on other Operating Systems should also work as expected.

=head1 EXPLANATION OF OPTIONS

These explanations are based on Walter Zorn's own documentation at http://www.walterzorn.com, except for 'default_tip' and 'function' which are perl only options.

=item above

Places the tooltip above the mousepointer. Value: true.  Additionally applying the B<offsety> command allows to set the vertical distance from the mousepointer.

=item bgcolor

Background color of the tooltip.

=item bgimg

Background image.

=item borderwidth

Width of tooltip border. May be 0 to hide the border.

=item bordercolor

Border color.

=item default_tip

Used in the new() method only.  Provides default text to be used in a tooltip when no other text is defined.

=item delay

Tooltip shows up after the specified timeout (milliseconds). A behavior similar to that of OS based tooltips.

=item fix

Fixes the tooltip to the co-ordinates specified within the square brackets. Useful, for example, if combined with the B<sticky> command.

=item fontcolor

Font color.

=item fontface

Font face / family.

=item fontsize

Font size + unit.  Unit inevitably required.

=item fontweight

Font weight.  Available values: 'normal' or 'bold'.

=item function

Used to indicate that the text is actually a call to a javascript function.

=item left

Tooltip positioned on the left side of the mousepointer. Value: true.  A suggested use is also setting B<above> to true when using this option.

=item offsetx

Horizontal offset from mouse-pointer.  To center the tooltip below (or above) the mousepointer, apply the value -tooltipwidth/2. In wz_tooltip.js itself, width is preset to 300.

=item offsety

Vertical offset from mouse-pointer.

=item padding

Inner spacing, i.e. the spacing between border and content, for instance text or image(s).

=item shadowcolor

Creates shadow with the specified color. Value in single quotes. Shadow width (strength) will be automatically processed to 3 (pixels) if no global shadow width setting can be found in in wz_tooltip.js, and the concerned html tag doesn't contain a B<shadowwidth> command.

=item shadowwidth

Creates shadow with the specified width (strength). Shadow color will be automatically processed to '#cccccc' (light grey) if neither a global setting in wz_tooltip.js nor a B<shadowcolor> command can be found.

=item static

Like OS-based tooltips, the tooltip doesn't follow the movements of the mouse-pointer. Value: true

=item sticky

The tooltip stays fixed on it's initial position until another tooltip is activated, or the user clicks on the document. Value: true

=item title

Title. Text in single quotes. Background color is automatically the same as the border color.

=item titlecolor

Color of title text. Preset in wz_tooltip.js is '#ffffff' (white).

=item width

Width of tooltip.

=head1 ACKNOWLEDGEMENTS

Nothing would be possible in the open source world without people like Walter Zorn providing elegent, stable, well documented and available code, like the Javascript tooltip library.  Thanks Walter!

=head1 SEE ALSO

See http://www.walterzorn.com/tooltip/tooltip_e.htm
and http://www.perlmeme.org/tutorials/html_tooltip_javascript_talk.html

=head1 LIMITATIONS

You cannot use Javascript to dynamically change the contents of the tooltip.  What you put in the HTML is what you get in the tooltip.  This is a feature of the underlying Javascript library and not the Perl module.

=head1 AUTHORS

Becky Alcorn, Simon Taylor.
Unisolve Pty Ltd
E<lt>simon@unisolve.com.auE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004,2006 by Unisolve Pty Ltd

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
