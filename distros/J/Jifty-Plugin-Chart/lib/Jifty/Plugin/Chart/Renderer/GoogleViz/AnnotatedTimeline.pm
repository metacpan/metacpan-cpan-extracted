package Jifty::Plugin::Chart::Renderer::GoogleViz::AnnotatedTimeline;
use strict;
use warnings;
use base 'Jifty::Plugin::Chart::Renderer::GoogleViz';

use constant packages_to_load => 'annotatedtimeline';
use constant chart_class => 'google.visualization.AnnotatedTimeLine';

sub draw_params {
    my $self = shift;
    my $opts = shift || {};
    return { displayAnnotations => 'true', %$opts };
}

1;

