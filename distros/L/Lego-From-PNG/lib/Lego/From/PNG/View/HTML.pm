package Lego::From::PNG::View::HTML;

use strict;
use warnings;

BEGIN {
    $Lego::From::PNG::VERSION = '0.04';
}

use parent qw(Lego::From::PNG::View);

use Lego::From::PNG::Const qw(:all);

use Data::Debug;

sub print {
    my $self = shift;
    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my @styles;
    my @brick_list;

    push @styles, '.picture td { height: 1em; }';

    push @styles, ".length_$_ { width: ${_}em; }" for LEGO_BRICK_LENGTHS;

    my $brick_total = 0;
    for my $color (sort { $a->{'color'}.$a->{'length'} cmp $b->{'color'}.$b->{'length'} } values %{$args{'bricks'}}) {
        my $cid = $color->{'color'};
        my $lego_color = $self->png->lego_colors->{$cid};

        push @styles, '.'.lc($cid).' { background: #'.$lego_color->{'hex_color'}.'; }';
        push @brick_list, '<tr><td>'.$lego_color->{'official_name'}.' '.join('x',@{$color}{qw(depth length height)}).'</td><td>'.$color->{'quantity'}.'</td></tr>';
        $brick_total += $color->{'quantity'};
    }

    my $html;

    # Styles
    $html .= qq{<style>\n};
    $html .= $_."\n" for @styles;
    $html .= qq{</style>\n\n};

    # Info
    $html .= qq{<section class="info">\n};
    $html .= qq{<h2>Info</h2>\n};
    for my $type(qw/metric imperial/) {
        if (exists $args{'info'}{$type}) {
            my $suffix_key = uc($type) . '_SUFFIX';
            my $suffix     = Lego::From::PNG::Const->$suffix_key;

            my ($depth, $length, $height) = @{$args{'info'}{$type}}{qw/depth length height/};
            $html .= qq{<table><tbody>\n};
            $html .= qq{<tr><td>Depth:</td><td>$depth $suffix</td></tr>\n};
            $html .= qq{<tr><td>Length:</td><td>$length $suffix</td></tr>\n};
            $html .= qq{<tr><td>Height:</td><td>$height $suffix</td></tr>\n};
            $html .= qq{</tbody></table>\n};
        }
    }
    $html .= qq{</section>\n\n};

    # Brick List
    $html .= qq{<section class="brick_list">\n};
    $html .= qq{<h2>Brick List</h2>\n};
    $html .= qq{<p>Total Bricks - $brick_total</p>\n};
    $html .= qq{<table><thead><tr><th>Brick</th><th>Quantity</th></thead><tbody>\n};
    $html .= $_."\n" for @brick_list;
    $html .= qq{</tbody></table>\n};
    $html .= qq{</section>\n\n};

    # Picture
    $html .= qq{<section class="brick_display">\n};
    $html .= qq{<h2>Picture</h2>\n};
    $html .= qq{<table class="picture" border="1"><tbody>\n};
    $html .= qq{<tr>}; # first <tr>
    my $y = 0;
    for my $color (@{$args{'plan'}}) {
        my ($class, $colspan, $name) = (lc($color->{'color'}), $color->{'length'}, $self->png->lego_colors->{$color->{'color'}}{'official_name'});
        if($y != $color->{'meta'}{'y'}) {
            $html .= qq{</tr>\n};
            $y = $color->{'meta'}{'y'};
        }
        $html .= qq[<td colspan="$colspan" title="$name $color->{'depth'}x$color->{'length'}x$color->{'height'}" class="$class length_${colspan}"></td>];
    }
    $html .= qq{</tr>\n}; # last </tr>
    $html .= qq{</tbody></table>\n};
    $html .= qq{</section>\n};

    return $html;
}

=pod

=head1 NAME

Lego::From::PNG::View::HTML - Format data returned from Lego::From::PNG

=head1 SYNOPSIS

  use Lego::From::PNG;

  my $object = Lego::From::PNG->new({ filename => 'my_png.png' });

  $object->process(view => 'HTML'); # Data is returned as HTML

=head1 DESCRIPTION

Class to returned processed data in HTML format

=head1 USAGE

=head2 new

 Usage     : ->new()
 Purpose   : Returns Lego::From::PNG::View::HTML object

 Returns   : Lego::From::PNG::View::HTML object
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head2 print

 Usage     : ->print({}) or ->print(key1 => val1, key2 => val2)
 Purpose   : Returns HTML formated data (in utf8 and pretty format)

 Returns   : Returns HTML formated data (in utf8 and pretty format)
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head1 BUGS

=head1 SUPPORT

=head1 AUTHOR

    Travis Chase
    CPAN ID: GAUDEON
    gaudeon@cpan.org
    https://github.com/gaudeon/Lego-From-Png

=head1 COPYRIGHT

This program is free software licensed under the...

    The MIT License

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

1;
