package Devel::IPerl::Plugin::Chart::Plotly;

use strict;
use warnings;
use utf8;

use Module::Find;
use namespace::autoclean;

our $VERSION = '0.005';    # VERSION

# ABSTRACT: Inline display of plotly charts in Jupyter notebooks using L<Devel::IPerl> kernel

my $require_plotly = <<'EOJS';
<script>
//# sourceURL=iperl-devel-plugin-chart-plotly.js
            $('#Plotly').each(function(i, e) { $(e).attr('id', 'plotly') });

            if (!window.Plotly) {
                requirejs.config({
                  paths: {
                    plotly: ['https://cdn.plot.ly/plotly-latest.min']},
                });
                window.Plotly = {
                  plot : function(div, data, layout) {
                    require(['plotly'], function(plotly) {
                      window.Plotly=plotly;
                      Plotly.plot(div, data, layout);
                    });
                  }
                }
            }
</script>
EOJS

sub register {

    # only works registering the plugin for each notebook
    require Chart::Plotly::Plot;
    require Role::Tiny;

    Role::Tiny->apply_roles_to_package( 'Chart::Plotly::Plot',
                                        q(Devel::IPerl::Plugin::Chart::Plotly::Plot::IPerlRole) );
    for my $module ( findsubmod('Chart::Plotly::Trace') ) {
        Role::Tiny->apply_roles_to_package( $module, q(Devel::IPerl::Plugin::Chart::Plotly::Plot::Trace::IPerlRole) );
    }
}

{
    package Devel::IPerl::Plugin::Chart::Plotly::Plot::IPerlRole;

    use Moo::Role;

    use Devel::IPerl::Display::HTML;

    sub iperl_data_representations {
        my ($plot) = @_;
        Devel::IPerl::Display::HTML->new( $require_plotly . $plot->html( load_plotly_using_script_tag => 0 ) )
          ->iperl_data_representations;
    }

}

{
    package Devel::IPerl::Plugin::Chart::Plotly::Plot::Trace::IPerlRole;

    use Moo::Role;

    use Devel::IPerl::Display::HTML;

    sub iperl_data_representations {
        require Chart::Plotly::Plot;
        my ($trace) = @_;
        my $plot = Chart::Plotly::Plot->new( traces => [$trace] );
        Devel::IPerl::Display::HTML->new( $require_plotly . $plot->html( load_plotly_using_script_tag => 0 ) )
          ->iperl_data_representations;
    }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Plugin::Chart::Plotly - Inline display of plotly charts in Jupyter notebooks using L<Devel::IPerl> kernel

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    # In notebook
    IPerl->load_plugin('Chart::Plotly');

    # Trace objects get displayed automatically
    use Chart::Plotly::Trace::Scatter;
    my $scatter_trace = Chart::Plotly::Trace::Scatter->new( x => [ 1 .. 5 ], y => [ 1 .. 5 ] );

    # Also Plot objects
    use Chart::Plotly::Trace::Box;
    use Chart::Plotly::Plot;

    my $x = [ 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3 ];
    my $box1 = Chart::Plotly::Trace::Box->new( x => $x, y => [ map { rand() } ( 1 .. ( scalar(@$x) ) ) ], name => "box1" );
    my $box2 = Chart::Plotly::Trace::Box->new( x => $x, y => [ map { rand() } ( 1 .. ( scalar(@$x) ) ) ], name => "box2" );
    my $plot = Chart::Plotly::Plot->new( traces => [ $box1, $box2 ], layout => { boxmode => 'group' } );

=head1 DESCRIPTION

Plugin to display automatically L<Chart::Plotly> plot objects in Jupyter notebooks using kernel L<Devel::IPerl>

The example above can be viewed in L<nbviewer|http://nbviewer.jupyter.org/github/pablrod/p5-Devel-IPerl-Plugin-Chart-Plotly/blob/master/examples/PlotlyPlugin.ipynb>

=head1 INSTANCE METHODS

=head2 register

This method is called automatically by L<Devel::IPerl>. You only need to load the plugin:

    IPerl->load_plugin('Chart::Plotly');

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=head1 CONTRIBUTOR

=for stopwords Roy Storey

Roy Storey <kiwiroy@users.noreply.github.com>

=cut
