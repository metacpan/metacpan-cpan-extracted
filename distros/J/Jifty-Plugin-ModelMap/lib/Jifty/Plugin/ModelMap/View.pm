package Jifty::Plugin::ModelMap::View;

use strict;
use warnings;
use utf8;

=head1 NAME

Jifty::Plugin::ModelMap::View

=cut

#use Data::Dumper;
use Jifty::View::Declare -base;
use Jifty::View::Declare::Page;
use GraphViz;
use HTML::Entities;
use Memoize;

memoize('_g');
memoize('_as_png');
memoize('_as_cmapx');

sub _g {
    my @models = Jifty->class_loader->models;

    my $g = GraphViz->new();

    for my $model (@models) {
        $model =~ m/::(\w+)$/o;
        $g->add_node($model, label => encode_entities(_str_model($model)), shape => 'record',
            URL => '__jifty/admin/model/'.$1
        );
        for my $column ($model->columns) {
            next unless $column->refers_to;
            if ($column->refers_to =~ m/^(.*)Collection$/o) {
                $g->add_edge($model => $1, labeldistance => 2, headlabel => 'n', taillabel => $column->name);
            }
            else {
                $g->add_edge($model => $column->refers_to, labeldistance => 2, headlabel => '1', taillabel => $column->name);
            }
        }
    }
    $g;
}

sub _as_png {
    _g->as_png;
}

sub _as_cmapx {
    _g->as_cmapx;
}

sub _str_column {
    my $column = shift;

    my $tail = do {
        if ($column->label) {
            "--" . $column->label;
        }
        else {
            "";
        }
    };
    join(" ", $column->name, uc($column->type), $tail);
}

sub _str_model {
    my $model = shift;

    $model =~ m/::(\w*)$/o;

    # The label can contain embedded newlines with '\n', as well as
    # '\c', '\l', '\r' for center, left, and right justified lines.
    # http://search.cpan.org/~lbrocard/GraphViz-2.03/lib/GraphViz.pm
    ($1.'\n')
    .join('\l', map { _str_column($_) } $model->columns)
    .'\l';
}

=head1 TEMPLATE

=head2 /model_map

=cut

template 'model_map' => page {
    { title is 'All tables in Jifty Database' };

    my @models = Jifty->class_loader->models;
    if (@models) {
        outs_raw(_as_cmapx());
        img { attr { src => "model_map/graph", alt => "Model Map Image", usemap => '#test' } };
    }
    else {
        p { "model is empty." };
    }
};

=head2 /model_map/graph

=cut

template 'model_map/graph' => sub {
    Jifty->handler->apache->content_type('image/png');
    outs_raw(_as_png);
};

=head1 AUTHOR

bokutin, C<< <bokutin at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 bokutin, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
