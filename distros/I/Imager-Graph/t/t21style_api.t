#!perl -w
use strict;
use Imager::Graph::Pie;
use lib 't/lib';
use Imager::Font::Test;
use Test::More;

++$|;

use Imager qw(:handy);

plan tests => 3;

my $font = Imager::Font::Test->new();

my @data;

for (0 .. 10) {
    push @data, $_;
}

my $api_graph = Imager::Graph::Pie->new();
$api_graph->add_data_series(\@data, 'Positive Slope');
$api_graph->set_style('ocean');
$api_graph->set_labels([0 .. 10]);

$api_graph->set_image_width(800);
$api_graph->set_image_height(600);
$api_graph->set_graph_size(500);
$api_graph->set_font($font);
$api_graph->set_image_background('FF00FF');
$api_graph->set_channels(3);
$api_graph->set_line_color('00FF00');
$api_graph->set_title('Tester Title');
$api_graph->set_title_font_size(14);
$api_graph->set_title_font_color('444444');
$api_graph->set_title_horizontal_align('left');
$api_graph->set_title_vertical_align('bottom');
$api_graph->set_text_font_size(18);
$api_graph->set_text_font_color('FFFFFF');
$api_graph->set_graph_background_color('00FF00');
$api_graph->set_graph_foreground_color('FF00FF');
$api_graph->set_legend_font_color('0000FF');
$api_graph->set_legend_font($font);
$api_graph->set_legend_font_size(17);
$api_graph->set_legend_patch_size(30);
$api_graph->set_legend_patch_gap(20);
$api_graph->set_legend_horizontal_align('left');
$api_graph->set_legend_vertical_align('top');
$api_graph->set_legend_padding(5);
$api_graph->set_legend_outside_padding(12);
$api_graph->set_legend_fill('000000');
$api_graph->set_legend_border('222222');
$api_graph->set_legend_orientation('horizontal');
$api_graph->set_callout_font_color('FF0000');
$api_graph->set_callout_font($font);
$api_graph->set_callout_font_size(45);
$api_graph->set_callout_line_color('FF2211');
$api_graph->set_callout_leader_inside_length(10);
$api_graph->set_callout_leader_outside_length(20);
$api_graph->set_callout_leader_length(30);
$api_graph->set_callout_gap(5);
$api_graph->set_label_font_color('55FFFF');
$api_graph->set_label_font($font);
$api_graph->set_label_font_size(16);
$api_graph->set_drop_shadow_fill_color('113333');
$api_graph->set_drop_shadow_offset(25);
$api_graph->set_drop_shadowXOffset(30);
$api_graph->set_drop_shadowYOffset(5);
$api_graph->set_drop_shadow_filter({ type=>'mosaic', size => 20 });
$api_graph->set_outline_color('FF00FF');
$api_graph->set_data_area_fills([qw(FF0000 00FF00 0000FF)]);
$api_graph->set_data_line_colors([qw(FF0000 00FF00 0000FF)]);

my $api_img = $api_graph->draw(
    features => [qw(legend outline labels)],
) || die $api_graph->error;

ok($api_img);

my $style_graph = Imager::Graph::Pie->new();

$style_graph->add_data_series(\@data, 'Positive Slope');
$style_graph->set_style('ocean');
$style_graph->set_labels([0 .. 10]);

my $style_img = $style_graph->draw(
    features => [qw(legend outline labels)],
    font    => $font, # base font                              * set_font()
    back    => 'FF00FF', # Background color/fill                  - set_image_background()
    size    => 500, # Size of the graph                      * set_size()
    width   => 800, # width of the image                     * set_width()
    height  => 600, # height of the image                    * set_height()
    channels => 3, # # of channels in the image            - set_channels()
    line    => '00FF00', # color of lines                         - set_line_color()
    title   => {
        text    => 'Tester Title', # title for the chart                * set_title()
        size    => '14', # size of the title font             - set_title_font_size()
        color   => '444444', # color of the title                 - set_title_font_color()
        halign  => 'left', # horizontal alignment of the title  - set_title_horizontal_align()
        valign  => 'bottom', # vertical alignment of the title    - set_title_vertical_align()
    },
    text    => {
        color   => 'FFFFFF', # default color of text              - set_text_font_color()
        size    => '18', # default size of text               - set_text_font_size()
    },
    bg      => '00FF00', # background color of the graph          - set_graph_background_color()
    fg      => 'FF00FF', # foreground color of the graph          - set_graph_foreground_color()
    legend  => {
        color   => '0000FF', # text color for the legend          - set_legend_font_color()
        font    => $font, # font to be used for the legend     - set_legend_font()
        size    => 17, # font size to be used for labels
                        # in the legend                     - set_legend_font_size()
        patchsize   => 30, # the size in pixels? percent?   - set_legend_patch_size()
                           # of the color patches in
                           # the legend.
        patchgap    => 20, # gap between the color patches. - set_legend_patch_gap()
                           # in pixels?  percent?
        halign      => 'left', # horizontal alignment of the    - set_legend_horizontal_align()
                           # legend within the graph
        valign      => 'top', # vertical alignment of the      - set_legend_vertical_align()
                           # legend within the graph
        padding     => '5', # the space between the patches  - set_legend_padding()
                           # of color and the outside of
                           # the legend box
        outsidepadding  => '12', # the space between the      - set_legend_outside_padding()
                               # border of the legend,
                               # and the outside edge of the
                               # legend
        fill            => '000000', # A fill for the background  - set_legend_fill()
                               # of the legend.
        border          => '222222', # The color of the border of - set_legend_border()
                               # the legend.
        orientation     => 'horizontal', # the orientation of the     - set_legend_orientation()
                               # legend
    },
    callout => {
        color   => 'FF0000', # the color of the callout text      - set_callout_font_color()
        font    => $font, # the font to use for callouts       - set_callout_font()
        size    => 45, # the font size for callout text     - set_callout_font_size()
        line    => 'FF2211', # the color of the line from the     - set_callout_line_color()
                       # callout to the graph
        inside  => '10', # the length in pixels? of the       - set_callout_leader_inside_length()
                       # leader...
        outside => '20', # the other side of the leader?      - set_callout_leader_outside_length()
        leadlen => '30', # the length of the horizontal       - set_callout_leader_length()
                       # part of the leader
        gap     => '5', # the space between the callout      - set_callout_gap()
                       # leader and the callout text
    },
    label   => {
        color   => '55FFFF', # the color of the label text        - set_label_font_color()
        font    => $font, # font used for labels               - set_label_font()
        size    => 16, # the font size used for labels      - set_label_font_size()
    },
    dropshadow  => {
        fill    => '113333', # the color used for drop shadows    - set_drop_shadow_fill_color()
        off     => 25, # the offset of the dropshadow...    - set_drop_shadow_offset()
                       # in percent?  pixels?
        offx    => 30, # horizontal offset of the           - set_drop_shadowXOffset()
                       # dropshadow
        offy    => 5, # vertical offset of the dropshadow  - set_drop_shadowYOffset()
        filter  => { type=>'mosaic', size => 20 },

                       # the filter description passed to   - set_drop_shadow_filter()
                       # Imager's filter method to blur
                       # the drop shadow. Default: an 11
                       # element convolution filter.
    },
    outline => {
        line    => 'FF00FF', # the color of the outline           - set_outline_color()
                       # around data areas
    },
    fills   => [
        qw(FF0000 00FF00 0000FF)
        # An array ref describing how to fill data areas    - set_data_area_fills()
        # in the graph.  used by pie, column, stacked
        # column graphs
    ],
    colors  => [
        qw(FF0000 00FF00 0000FF)
        # An array ref of colors, used by line graphs.      - set_data_line_colors()
    ],

) || die $style_graph->error;

ok($api_img);

my ($api_content, $style_content);

$style_img->write(data => \$style_content, type=>'raw') or die "Err: ".$style_img->errstr;
$api_img->write(data  => \$api_content,  type=>'raw') or die "Err: ".$api_img->errstr;

ok($style_content eq $api_content);



