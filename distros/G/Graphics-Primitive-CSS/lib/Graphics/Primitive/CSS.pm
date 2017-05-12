package Graphics::Primitive::CSS;
use Moose;

our $VERSION = '0.02';

use Carp qw(carp);
use Check::ISA;
use CSS::DOM;
use Graphics::Color::RGB;

has 'styles' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has 'css_dom' => (
    is => 'ro',
    isa => 'CSS::DOM',
    lazy => 1,
    default => sub { my $self = shift; CSS::DOM::parse($self->styles) }
);

sub apply {
    my ($self, $doc) = @_;

    my @rules = $self->css_dom->cssRules;

    foreach my $rule (@rules) {
        my $selector = $rule->selectorText;

        for(0..($rule->style->length - 1)) {

            my $prop = $rule->style->item($_);
            my $val = $rule->style->getPropertyValue($prop);

            my $comps;
            if($selector =~ /^\.(.*)/) {
                # Handle classes
                my $class = $1;
                $comps = $doc->find(sub {
                    my ($comp, $const) = @_;
                    return 0 unless defined($comp->class);
                    return $comp->class eq $class;
                });
            } elsif($selector =~ /#(.*)/) {
                # Handle names
                my $name = $1;
                $comps = $doc->find(sub {
                    my ($comp, $const) = @_;
                    return 0 unless defined($comp->name);
                    return $comp->name eq $name;
                });
            } elsif($selector =~ 'textbox') {
                # Handle "elements"
                $comps = $doc->find(sub {
                    my ($comp, $const) = @_;

                    return obj($comp, 'Graphics::Primitive::TextBox');
                });
            }

            return 1 unless defined($comps) && $comps->component_count;

            if($prop eq 'background-color') {

                my $color = $self->_process_color($val);
                next unless defined($color);

                $comps->each(sub {
                     my ($comp, $const) = @_;
                     $comp->background_color($color);
                });

            } elsif($prop eq 'border-bottom-color') {

                my $color = $self->_process_color($val);
                next unless defined($color);

                $comps->each(sub {
                     my ($comp, $const) = @_;
                     $comp->border->bottom->color($color);
                });

            } elsif($prop eq 'border-bottom-width') {

                if($val =~ /(\d+)px/) {
                    $comps->each(sub {
                         my ($comp, $const) = @_; $comp->border->bottom->width($1);
                    });
                }
            } elsif($prop eq 'border-color') {

                my $color = $self->_process_color($val);
                next unless defined($color);

                $comps->each(sub {
                     my ($comp, $const) = @_;
                     $comp->border->color($color);
                });

            } elsif($prop eq 'border-left-color') {

                my $color = $self->_process_color($val);
                next unless defined($color);

                $comps->each(sub {
                     my ($comp, $const) = @_;
                     $comp->border->left->color($color);
                });

            } elsif($prop eq 'border-left-width') {

                if($val =~ /(\d+)px/) {
                    $comps->each(sub {
                         my ($comp, $const) = @_; $comp->border->left->width($1);
                    });
                }
            } elsif($prop eq 'border-right-color') {

                my $color = $self->_process_color($val);
                next unless defined($color);

                $comps->each(sub {
                     my ($comp, $const) = @_;
                     $comp->border->right->color($color);
                });

            } elsif($prop eq 'border-right-width') {

                if($val =~ /(\d+)px/) {
                    $comps->each(sub {
                         my ($comp, $const) = @_; $comp->border->right->width($1);
                    });
                }

            } elsif($prop eq 'border-top-color') {

                my $color = $self->_process_color($val);
                next unless defined($color);

                $comps->each(sub {
                     my ($comp, $const) = @_;
                     $comp->border->top->color($color);
                });

            } elsif($prop eq 'border-top-width') {

                if($val =~ /(\d+)px/) {
                    $comps->each(sub {
                         my ($comp, $const) = @_; $comp->border->top->width($1);
                    });
                }

            } elsif($prop eq 'border-width') {
                my ($top, $right, $bottom, $left);
                if($val =~ /^(\d+)px$/) {
                    $top = $1; $bottom = $1;
                    $right = $1; $left = $1;

                } elsif($val =~ /^(\d+)px (\d+)px$/) {
                    $top = $1; $bottom = $1;
                    $right = $2; $left = $2;

                } elsif($val =~ /^(\d+)px (\d+)px (\d+)px (\d+)px$/) {
                    $top = $1; $right = $2;
                    $bottom = $3; $left = $4;
                }

                $comps->each(sub {
                     my ($comp, $const) = @_;
                     $comp->border->top->width($top);
                     $comp->border->right->width($right);
                     $comp->border->bottom->width($bottom);
                     $comp->border->left->width($left);
                });

            } elsif($prop eq 'color') {

                my $color = $self->_process_color($val);
                next unless defined($color);

                $comps->each(sub {
                     my ($comp, $const) = @_;
                     $comp->color($color);
                });

            } elsif($prop eq 'font-family') {
                $comps->each(sub {
                     my ($comp, $const) = @_; $comp->font->family($val);
                });

            } elsif($prop eq 'font-size') {
                if($val =~ /(\d+)pt/) {
                    $comps->each(sub {
                         my ($comp, $const) = @_; $comp->font->size($1);
                    });
                } else {
                    carp("Unknown font-size value: '$val'");
                }

            } elsif($prop eq 'font-weight') {
                $comps->each(sub {
                     my ($comp, $const) = @_; $comp->font->weight($val);
                });


            } elsif($prop eq 'margin') {
                my ($top, $right, $bottom, $left);
                if($val =~ /^(\d+)px (\d+)px$/) {
                    $top = $1; $bottom = $1;
                    $right = $2; $left = $2;
                } elsif($val =~ /^(\d+)px (\d+)px (\d+)px (\d+)px$/) {
                    $top = $1; $right = $2;
                    $bottom = $3; $left = $4;
                }

                $comps->each(sub {
                     my ($comp, $const) = @_;
                     $comp->margins->top($top);
                     $comp->margins->right($right);
                     $comp->margins->bottom($bottom);
                     $comp->margins->left($left);
                });
            } elsif($prop eq 'margin-bottom') {
                if($val =~ /(\d+)px/) {
                    $comps->each(sub {
                         my ($comp, $const) = @_; $comp->margins->bottom($1);
                    });
                }
            } elsif($prop eq 'margin-left') {
                if($val =~ /(\d+)px/) {
                    $comps->each(sub {
                         my ($comp, $const) = @_; $comp->margins->left($1);
                    });
                }
            } elsif($prop eq 'margin-right') {
                if($val =~ /(\d+)px/) {
                    $comps->each(sub {
                         my ($comp, $const) = @_; $comp->margins->right($1);
                    });
                }
            } elsif($prop eq 'margin-top') {
                if($val =~ /(\d+)px/) {
                    $comps->each(sub {
                         my ($comp, $const) = @_; $comp->margins->top($1);
                    });
                }

            } elsif($prop eq 'padding') {
                my ($top, $right, $bottom, $left);
                if($val =~ /^(\d+)px (\d+)px$/) {
                    $top = $1; $bottom = $1;
                    $right = $2; $left = $2;
                } elsif($val =~ /^(\d+)px (\d+)px (\d+)px (\d+)px$/) {
                    $top = $1; $right = $2;
                    $bottom = $3; $left = $4;
                }

                $comps->each(sub {
                     my ($comp, $const) = @_;
                     $comp->padding->top($top);
                     $comp->padding->right($right);
                     $comp->padding->bottom($bottom);
                     $comp->padding->left($left);
                });
            } elsif($prop eq 'padding-bottom') {
                if($val =~ /(\d+)px/) {
                    $comps->each(sub {
                         my ($comp, $const) = @_; $comp->padding->bottom($1);
                    });
                }
            } elsif($prop eq 'padding-left') {
                if($val =~ /(\d+)px/) {
                    $comps->each(sub {
                         my ($comp, $const) = @_; $comp->padding->left($1);
                    });
                }
            } elsif($prop eq 'padding-right') {
                if($val =~ /(\d+)px/) {
                    $comps->each(sub {
                         my ($comp, $const) = @_; $comp->padding->right($1);
                    });
                }
            } elsif($prop eq 'padding-top') {
                if($val =~ /(\d+)px/) {
                    $comps->each(sub {
                         my ($comp, $const) = @_; $comp->padding->top($1);
                    });
                }

            } elsif($prop eq 'text-align') {
                $comps->each(sub {
                     my ($comp, $const) = @_; $comp->horizontal_alignment($val);
                });
            } elsif($prop eq 'vertical-align') {
                $comps->each(sub {
                     my ($comp, $const) = @_; $comp->vertical_alignment($val);
                });
            }
        }
    }

    return 1;
}

# Attempt to find a valid color
sub _process_color {
    my ($self, $val) = @_;

    my $color;
    if($val =~ /^#(.*)/) {
        $color = Graphics::Color::RGB->from_hex_string($val);

    # TODO:
    # rgb(255, 0, 0)
    # rgb(100%, 0%, 0%)
    # rgba(255, 0, 0)
    # hsl(0, 100%, 50%)
    # hsla(120, 100%, 50%, 1)
    } else {
        # Going to try and treat it like a color name...
        $color = Graphics::Color::RGB->from_color_library(
            "svg:$val"
        );
    }

    unless(defined($color)) {
        carp("Unable to parse color: '$val'");
    }

    return $color;
}

1;

=head1 NAME

Graphics::Primitive::CSS - Style Graphics::Primitive documents with CSS

=head1 SYNOPSIS

    use Graphics::Primitive::CSS;

    my $styler = Graphics::Primitive::CSS->new(
        style => '
            .foo {
                font-size: 12pt;
                vertical-align: center;
            }
        '
    );

    my $doc = Graphics::Primitive::Container->new;
    my $textbox = Graphics::Primitive::TextBox->new( class => 'foo' );
    $doc->add_component($textbox);

    $styler->apply($doc);

=head1 DESCRIPTION

Graphics::Primitive::CSS allows you to change the various attributes of a
Graphics::Primitive document using CSS.

=head1 SELECTORS

Graphics::Primitive::CSS currently supports a class (.classname), element
(only textbox currently), and 'id' (#name) selector.  It does not support
nested selectors (yet).

=head1 COLORS

Colors can be suppled as an RBG hex triplet (#f0f0f0 and #fff) and W3C
spec name (aliceblue).  Support is intended for rgb, rgba, hsl and hsla.

=head1 PROPERTIES

Graphics::Primitive::CSS supports the following properties in the following
ways.

=over 4

=item background-color, color

Background and foreground color

=item border-color

Color of all borders. B<Note: Only supports a single color value currently.>

=item border-color-top, border-color-right, border-color-bottom, border-color-left

Set the color for various borders

=item border-width-top, border-width-right, border-width-bottom, border-width-left

Set the width for a border (in pixels)

=item font-size, font-family

Size of font as points (e.g. 7pt).  Family name (does not support lists!)

=item margin

2 value (top, left) and 4 value (top, right, bottom, left).  Only pixels
are supported.

=item margin-top, margin-left, margin-bottom, margin-right

=item padding

2 value (top, left) and 4 value (top, right, bottom, left).  Only pixels
are supported.

=item padding-top, padding-left, padding-bottom, padding-right


Only pixels are supported.


=back

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
