use strict;
use warnings;
package Inky;
$Inky::VERSION = '0.161810';
use Moo;
use strictures 2;
use namespace::clean;
use Mojo::DOM;
use Const::Fast;

# ABSTRACT: Inky templates, in Perl

const my $DEFAULT_SPACER_SIZE_PX => 16;
const my $DEFAULT_COLS           => 12;

has 'column_count'   => ( is => 'ro', default => sub { $DEFAULT_COLS } );
has '_component_tags' => ( is => 'ro', default => sub { return [qw<
    button row columns container callout inky block-grid menu item center
    spacer wrapper
>]});

sub _classes {
    my ($element, @classes) = @_;
    if ($element->attr('class')) {
        push @classes, split /\s+/xms, $element->attr('class');
    }
    return join q{ }, @classes;
}

sub _add_standard_attributes {
    my ($element) = @_;

    # Keep all attributes but these
    my %skipped = map { $_ => 1 } qw<class id href size large no-expander small target>;
    my $result  = '';
    my $attrs   = $element->attr;

    for my $attr (sort keys %{$attrs}) {
        next if exists $skipped{$attr};
        my $value = $attrs->{$attr} // '';
        $result .= qq! $attr="$value"!;
    }
    return $result;
}

my %COMPONENTS = (
    columns => sub {
        my ($self, $element) = @_;
        return $self->_make_column($element, 'columns');
    },
    row => sub {
        my ($self, $element, $inner) = @_;
        return sprintf '<table %s class="%s"><tbody><tr>%s</tr></tbody></table>',
            _add_standard_attributes($element),
            _classes($element, 'row'), $inner;
    },
    button => \&_make_button,
    container => sub {
        my ($self, $element, $inner) = @_;
        return sprintf '<table %s align="center" class="%s"><tbody><tr><td>%s</td></tr></tbody></table>',
            _add_standard_attributes($element),
            _classes($element, 'container'), $inner;
    },
    inky => sub {
        return '<tr><td><img src="https://raw.githubusercontent.com/arvida/emoji-cheat-sheet.com/master/public/graphics/emojis/octopus.png" /></tr></td>';
    },
    'block-grid' => sub {
        my ($self, $element, $inner) = @_;
        return sprintf '<table class="%s"><tr>%s</tr></table>',
            _classes($element, 'block-grid', join q{}, 'up-', $element->attr('up')),
            $inner;
    },
    menu => sub {
        my ($self, $element, $inner) = @_;
        my $center_attr = $element->attr('align') ? 'align="center"' : q{};
        return sprintf '<table %s class="%s"%s><tr><td><table><tr>%s</tr></table></td></tr></table>',
            _add_standard_attributes($element),
            _classes($element, 'menu'), $center_attr, $inner;
    },
    item => sub {
        my ($self, $element, $inner) = @_;
        my $target = '';
        $target = sprintf ' target="%s"', $element->attr('target')
            if $element->attr('target');
        return sprintf '<th %s class="%s"><a href="%s"%s>%s</a></th>',
            _add_standard_attributes($element),
            _classes($element, 'menu-item'), $element->attr('href'), $target, $inner;
    },
    center => \&_make_center,
    callout => sub {
        my ($self, $element, $inner) = @_;
        return sprintf '<table %s class="callout"><tr><td class="%s">%s</td><td class="expander"></td></tr></table>',
            _add_standard_attributes($element),
            _classes($element, 'callout-inner'), $inner;
    },
    spacer => sub {
        my ($self, $element, $inner) = @_;
        my $size;
        my $html = '';
        if ($element->attr('size-sm') || $element->attr('size-lg')) {
            if ($element->attr('size-sm')) {
                $size = $element->attr('size-sm');
                $html .= qq!<table class="%s hide-for-large"><tbody><tr><td height="${size}px" style="font-size:${size}px;line-height:${size}px;">&nbsp;</td></tr></tbody></table>!;
            }
            if ($element->attr('size-lg')) {
                $size = $element->attr('size-lg');
                $html .= qq!<table class="%s show-for-large"><tbody><tr><td height="${size}px" style="font-size:${size}px;line-height:${size}px;">&nbsp;</td></tr></tbody></table>!;
            }
        } else {
            $size = $element->attr('size') // $DEFAULT_SPACER_SIZE_PX;
            $html = qq!<table class="%s"><tbody><tr><td height="${size}px" style="font-size:${size}px;line-height:${size}px;">&nbsp;</td></tr></tbody></table>!;
        }
        if ($element->attr('size-sm') && $element->attr('size-lg')) {
            return sprintf $html,
                _classes($element,'spacer'),
                _classes($element,'spacer'),
        }
        return sprintf $html,
            _classes($element,'spacer');
    },
    wrapper => sub {
        my ($self, $element, $inner) = @_;
        return sprintf '<table %s class="%s" align="center"><tr><td class="wrapper-inner">%s</td></tr></table>',
            _add_standard_attributes($element),
            _classes($element, 'wrapper'), $inner;
    },
);

sub _make_button {
    my ($self, $element, $inner) = @_;

    my $expander = q{};

    # Prepare optional target attribute for the <a> element
    my $target = '';
    $target = ' target=' . $element->attr('target')
        if $element->attr('target');

    # If we have the href attribute we can create an anchor for the inner
    # of the button
    $inner = sprintf '<a href="%s"%s>%s</a>',
        $element->attr('href'), $target, $inner
        if $element->attr('href');

    # If the button is expanded, it needs a <center> tag around the content
    my @el_classes = split /\s+/xms, $element->attr('class') // '';
    if (scalar grep { $_ eq 'expand' || $_ eq 'expanded' } @el_classes) {
        $inner = sprintf '<center>%s</center>', $inner;
        $expander = qq!\n<td class="expander"></td>!;
    }

    # The . button class is always there, along with any others on the <button>
    # element
    return sprintf '<table class="%s"><tr><td><table><tr><td>%s</td></tr></table></td>%s</tr></table>',
        _classes($element, 'button'), $inner, $expander;
}

sub _make_center {
    my ($self, $element, $inner) = @_;

    if ($element->children->size > 0) {
        $element->children->each(sub {
            my ($e) = @_;
            $e->attr('align', 'center');
            my @classes = split /\s+/xms, $e->attr('class') // q{};
            $e->attr('class', join q{ }, @classes, 'float-center');
        });
        $element->find('item, .menu-item')->each(sub {
            my ($e) = @_;
            my @classes = split /\s+/xms, $e->attr('class') // q{};
            $e->attr('class', join q{ }, @classes, 'float-center');
        });
    }
    $element->attr('data-parsed', q{});
    return sprintf '%s', $element->to_string;
}

sub _component_factory {
    my ($self, $element) = @_;

    my $inner = $element->content;

    my $tag = $element->tag;
    return $COMPONENTS{$tag}->($self, $element, $inner)
        if exists $COMPONENTS{$tag};

    # If it's not a custom component, return it as-is
    return sprintf '<tr><td>%s</td></tr>', $inner;
}

sub _make_column {
    my ($self, $col) = @_;

    my $output   = q{};
    my $inner    = $col->content;
    my @classes  = ();
    my $expander = q{};

    my $attributes       = $col->attr;
    my $attr_no_expander = exists $attributes->{'no-expander'}
                         ? $attributes->{'no-expander'}
                         : 0;
    $attr_no_expander = 1
        if exists $attributes->{'no-expander'}
        && !defined $attributes->{'no-expander'};
    $attr_no_expander = 0
        if $attr_no_expander eq 'false';

    # Add 1 to include current column
    my $col_count = $col->following->size
                  + $col->preceding->size
                  + 1;

    # Inherit classes from the <column> tag
    if ($col->attr('class')) {
        push @classes, split /\s+/xms, $col->attr('class');
    }

    # Check for sizes. If no attribute is provided, default to small-12.
    # Divide evenly for large columns
    my $small_size = $col->attr('small') || $self->column_count;
    my $large_size =  $col->attr('large')
                   || $col->attr('small')
                   || int($self->column_count / $col_count);

    push @classes, sprintf 'small-%s', $small_size;
    push @classes, sprintf 'large-%s', $large_size;

    # Add the basic "columns" class also
    push @classes, 'columns';

    # Determine if it's the first or last column, or both
    push @classes, 'first'
        if !$col->preceding('columns, .columns')->size;
    push @classes, 'last'
        if !$col->following('columns, .columns')->size;

    # If the column contains a nested row, the .expander class should not be
    # used. The == on the first check is because we're comparing a string
    # pulled from $.attr() to a number
    if ($large_size == $self->column_count && $col->find('.row, row')->size == 0 && !$attr_no_expander) {
        $expander = qq!\n<th class="expander"></th>!;
    }

    # Final HTML output
    $output = <<'END';
    <th class="%s" %s>
      <table>
        <tr>
          <th>%s</th>%s
        </tr>
      </table>
    </th>
END

    my $class = join q{ }, @classes;
    return sprintf $output,
        $class, _add_standard_attributes($col), $inner, $expander
}

sub _extract_raws {
    my ($string) = @_;

    my @raws;
    my $i = 0;
    my $str = $string;
    my $rx  = qr{<\s*raw\s*>(.*?)</\s*raw\s*>}xism;

    while (my ($raw) = $str =~ $rx) {
        push @raws, $raw;
        $str =~ s/$rx/###RAW$i###/xsm;
        $i++;
    }
    return (\@raws, $str);
}

sub _reinject_raws {
    my ($string, $raws) = @_;

    my $str = $string;
    for my $i (0..$#{$raws}) {
        $str =~ s{\#{3}RAW$i\#{3}}{$raws->[$i]}xms;
    }
    return $str;
}

sub release_the_kraken {
    my ($self, $html) = @_;

    my ($raws, $string) = _extract_raws($html);

    my $dom = Mojo::DOM->new( $string );
    my $tags = join ', ',
        map { $_ eq 'center' ? "$_:not([data-parsed])" : $_ }
        @{ $self->_component_tags };

    while ($dom->find($tags)->size) {
        my $elem     = $dom->find($tags)->first;
        my $new_html = $self->_component_factory($elem);
        $elem->replace($new_html);
    }
    $string = $dom->to_string;
    return _reinject_raws($string, $raws);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Inky - Inky templates, in Perl

=head1 VERSION

version 0.161810

=head1 SYNOPSIS

    use Inky;
    my $html = '..';
    say Inky->new->release_the_kraken($html);

=head1 DESCRIPTION

A Perl version of the Inky template language, see
L<https://github.com/zurb/inky|https://github.com/zurb/inky>.

=head1 METHODS

=head2 new

Creates a new L<Inky|Inky> object.

=head2 column_count

How many columns is the email supposed to have, defaults to 12 col layout

=head2 release_the_kraken

Given some HTML possibly containing Inky template elements, returns it
expanded.

=head1 HOW TO USE INKY AND CREATE A FANTASTIC HTML EMAIL WITH IT

See L<https://github.com/zurb/inky|https://github.com/zurb/inky> for an overview
of the tags that L<Inky|Inky> introduces.

You'll likely want to use the CSS from
L<https://github.com/zurb/foundation-emails|https://github.com/zurb/foundation-emails>
in order to style your HTML e-mails "properly" for use with L<Inky|Inky>.

You'll want to use the HTML "wrapper template" from
L<https://github.com/zurb/foundation-emails-template/blob/master/src/layouts/default.html|https://github.com/zurb/foundation-emails-template/blob/master/src/layouts/default.html>.

You might want to convert that HTML into the templating system you are going to
be using, such as L<Template|Template> or L<Text::Xslate|Text::Xslate>.

For example, in L<Template|Template> you'll want to create a C<wrapper.tt>
containing the above file's contents, and ensuring you have:

    ...
    <center>
    [% content %]
    </center>
    ...

You'll then be able to use the never-changing wrapper template to create
beautiful HTML emails, creating a C<your_mailing_list.tt> which contains
something like:

    [%-
    SET override_css = '
        // any override to be placed _after_ the Foundation for Emails CSS
    ';
    WRAPPER "path/to/wrapper.tt"
    -%]
    Your email contents go here
    [% END %]

To style them "properly", you'll want to clone the repository at:
L<https://github.com/zurb/foundation-emails|https://github.com/zurb/foundation-emails>,
and make changes to the various source C<scss> files to fit your "brand",
assuming the defaults aren't to your liking.

Once done, you'll have to generate the CSS, using something like:

    sass -t compact --sourcemap=none --no-cache foundation.scss > foundation.css

If you want to include the foundation CSS and a newsletter-specific overriding
CSS, you will want to modify the C<wrapper.tt> to contain, near the C<body>
tag:

  <body>
    [%~# CSS::Inliner REQUIRES type = "text/css" ~%]
    <style type="text/css">
    [% foundation_css %]
    [% override_css   %]
    </style>
    ....

The C<style> I<must> go in the C<body> as otherwise some mailers will wail to
"use" it.

If you need to support Gmail and other mail readers which do I<not> allow
inline styles, you'll likely have no option but to use
L<CSS::Inliner|CSS::Inliner>, which - with the above C<style> addition to the
C<wrapper.tt> template, will allow you to seamlessly inline your styles in the
HTML email.

It's entirely up to you to also use L<HTML::Packer|HTML::Packer> to ensure any
useless whitespace and comments are trimmed from the resulting email.

To sum up, and assuming you'll be using Template, HTML::Packer and
CSS::Inliner, here's a rough program to send a beautiful HTML email with Inky
and Foundation for Emails:

    use 5.010_001;
    use strict;
    use warnings;
    use Inky;
    use Template;
    use HTML::Packer;
    use CSS::Packer;
    use CSS::Inliner;
    use Path::Tiny;
    use Carp qw<croak>;
    # Create TT object, ensure the foundation for emails CSS is in the stash
    my $TT = Template->new(
        # any TT options go here
    );
    my $stash = {
        foundation_css => path('./foundation.css')->slurp_utf8,
        # your other data goes here
    };
    my $html = '';
    $TT->process('your_mailing_list.tt', $stash, \$html)
        or croak $TT->error;
    # At this point $html contains the full "inky" templated email.
    my $INKY    = Inky->new;
    my $PACKER  = HTML::Packer->init;
    my $parsed  = $INKY->release_the_kraken($html);
    my $inliner = CSS::Inliner->new({ leave_style => 1, relaxed => 1 });
    $inliner->read({ html => $parsed });
    my $inlined  = $inliner->inlinify;
    my $minified = $PACKER->minify( \$inlined, {
        remove_comments => 1,
        remove_newlines => 1,
        do_stylesheet   => 'minify', # needs CSS::Packer
    });
    say $minified;
    # $minified is your beautiful HTML email, with styles inlined,
    # and ready to be sent to an unsuspecting user!

That's all, folks!

=head1 CHANGES FROM NPM VERSION

The current version of this module is up-to-date with
L<https://github.com/zurb/inky|https://github.com/zurb/inky> branch C<master>
as of 2016-06-23.

Additional component tags aren't supported.

Differing amounts of columns are untested.

=for HTML  <p><a href="https://travis-ci.org/theregister/p5-Inky/"><img src="https://api.travis-ci.org/theregister/p5-Inky.svg" alt="Travis status" /></a></p>

=head1 AUTHOR

Marco Fontani

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Situation Publishing LTD.

This is free software, licensed under:

  The MIT (X11) License

=cut
