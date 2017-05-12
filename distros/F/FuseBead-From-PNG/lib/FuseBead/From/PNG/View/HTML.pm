package FuseBead::From::PNG::View::HTML;

use strict;
use warnings;

BEGIN {
    $FuseBead::From::PNG::VERSION = '0.02';
}

use parent qw(FuseBead::From::PNG::View);

use FuseBead::From::PNG::Const qw(:all);

use Data::Debug;

sub print {
    my $self = shift;
    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my @styles;
    my @bead_list;

    my $bead_diameter = FuseBead::From::PNG::Bead->new({ color => [ FuseBead::From::PNG::Const->BEAD_COLORS ]->[0] })->diameter;
    my $border_width  = 1;
    my $pixel_size    = $bead_diameter * FuseBead::From::PNG::Const->MILLIMETER_TO_PIXEL - $border_width * 2;

    push @styles, ".picture { border-collapse: collapse; page-break-before: always; }";
    push @styles, ".picture td { height: ${pixel_size}px; width: ${pixel_size}px; border: solid black ${border_width}px; padding: 0; }";
    push @styles, ".bead_display { margin-top: 1em; }";

    my $bead_total = 0;
    for my $color (sort { $a->{'color'} cmp $b->{'color'} } values %{$args{'beads'}}) {
        my $cid = $color->{'color'};
        my $bead_color = $self->png->bead_colors->{$cid};

        push @styles, '.'.lc($cid).' { background: #'.$bead_color->{'hex_color'}.'; }';
        push @bead_list, '<tr><td>'.$bead_color->{'name'}.'</td><td>'.$color->{'quantity'}.'</td></tr>';
        $bead_total += $color->{'quantity'};
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
            my $suffix     = FuseBead::From::PNG::Const->$suffix_key;

            my ($length, $height) = @{$args{'info'}{$type}}{qw/length height/};
            $html .= qq{<table><tbody>\n};
            $html .= qq{<tr><td>Length:</td><td>$length $suffix</td></tr>\n};
            $html .= qq{<tr><td>Height:</td><td>$height $suffix</td></tr>\n};
            $html .= qq{</tbody></table>\n};
        }
    }
    $html .= qq{</section>\n\n};

    # Bead List
    $html .= qq{<section class="bead_list">\n};
    $html .= qq{<h2>Bead List</h2>\n};
    $html .= qq{<p>Total Beads - $bead_total</p>\n};
    $html .= qq{<table><thead><tr><th>Bead</th><th>Quantity</th></thead><tbody>\n};
    $html .= $_."\n" for @bead_list;
    $html .= qq{</tbody></table>\n};
    $html .= qq{</section>\n\n};

    # Picture
    $html .= qq{<section class="bead_display">\n};
    $html .= qq{<table class="picture"><tbody>\n};
    $html .= qq{<tr>}; # first <tr>
    my $y = 0;
    for my $color (@{$args{'plan'}}) {
        my ($class, $name) = (lc($color->{'color'}), $self->png->bead_colors->{$color->{'color'}}{'name'});
        if($y != $color->{'meta'}{'y'}) {
            $html .= qq{</tr>\n};
            $y = $color->{'meta'}{'y'};
        }
        $html .= qq[<td title="$name" class="$class"></td>];
    }
    $html .= qq{</tr>\n}; # last </tr>
    $html .= qq{</tbody></table>\n};
    $html .= qq{</section>\n};

    return $html;
}

=pod

=head1 NAME

FuseBead::From::PNG::View::HTML - Format data returned from FuseBead::From::PNG

=head1 SYNOPSIS

  use FuseBead::From::PNG;

  my $object = FuseBead::From::PNG->new({ filename => 'my_png.png' });

  $object->process(view => 'HTML'); # Data is returned as HTML

=head1 DESCRIPTION

Class to returned processed data in HTML format

=head1 USAGE

=head2 new

 Usage     : ->new()
 Purpose   : Returns FuseBead::From::PNG::View::HTML object

 Returns   : FuseBead::From::PNG::View::HTML object
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
    https://github.com/gaudeon/FuseBead-From-Png

=head1 COPYRIGHT

This program is free software licensed under the...

    The MIT License

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

1;
