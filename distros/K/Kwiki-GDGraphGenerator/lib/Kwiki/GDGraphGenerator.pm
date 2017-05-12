package Kwiki::GDGraphGenerator;
use strict;
use warnings;

use Kwiki::Plugin '-Base';
use Kwiki::Installer '-base';

our $VERSION = "0.04";

const class_title => 'Kwiki graphs';
const class_id    => 'graphgenerator';

sub register {
    my $registry = shift;
    $registry->add( wafl => graph => 'Kwiki::GDGraphGenerator::Wafl' );
}

package Kwiki::GDGraphGenerator::Wafl;
use Spiffy '-Base';
use base 'Spoon::Formatter::WaflBlock';

field 'config';

sub to_html {

    # parse the config, make sure options are there
    require YAML;
    $self->config( eval { YAML::Load( $self->block_text ) } );
    return $self->error("make sure your YAML is correct") if $@;
    return $self->error("graph config isn't a hash")
        unless $self->config && ref $self->config eq 'HASH';
    foreach (qw( id data type )) {
        return $self->error("graph config must specify '$_'")
            unless exists $self->config->{$_};
    }

    # check to see if the graph exists -- if not, create it
    my $error = $self->generate_image
        unless -e $self->checksum_path
        && io( $self->checksum_path )->assert->scalar eq $self->checksum;
    return $self->error($error) if $error;

    # return a simple link
    $self->hub->template->process( 'graphgenerator_inline.html',
        src => $self->image_path );
}

sub error {
    $self->hub->template->process( 'graphgenerator_error.html',
        msg => "Couldn't create graph: " . shift );
}

sub checksum {
    require Data::Dumper;
    require Digest::MD5;
    my $d = new Data::Dumper( [ $self->config ] );
    Digest::MD5::md5_hex( $d->Sortkeys(1)->Indent(0)->Dump );
}

sub image_path {
    $self->hub->cgi->button;
    $self->hub->graphgenerator->plugin_directory . '/'
        . $self->hub->pages->current->id . '.'
        . $self->config->{id} . '.png';
}

sub checksum_path {
    $self->image_path . '.config.md5';
}

sub generate_image {

    # load config, put things in variables and strip out
    # options we're not going to give to set()
    # (NOTE: width and height are read-only)
    my %config = %{ $self->config };
    my ( $type, $width, $height, $data )
        = @config{qw( type width height data )};
    delete @config{qw( type width height data id )};
    $width  ||= 300;
    $height ||= 300;

    # check for keys we don't allow
    foreach my $key (qw( logo )) {
        return "specifying $key is not permitted" if $config{$key};
    }

    # create a new graph object
    require GD::Graph;
    my $class = "GD::Graph::$type";
    eval "require $class;";
    return "couldn't create new $class" if $@;
    my $graph = $class->new( $width, $height );

    # set the options and plot the data
    $graph->set(%config)
        or return "couldn't use config: " . $graph->error;
    my $gd = $graph->plot($data)
        or return "couldn't plot graph: " . $graph->error;

    # save to the files
    io( $self->image_path ) < $gd->png;
    io( $self->checksum_path ) < $self->checksum;

    # undef means no error
    return;
}

package Kwiki::GDGraphGenerator;
1;

__DATA__

=head1 NAME 

Kwiki::GDGraphGenerator - put pretty graphs into your Kwiki pages

=head1 SYNOPSIS

 $ cd /path/to/kwiki
 $ kwiki -add Kwiki::GDGraphGenerator

In your KwikiText:

 .graph
 id: test
 type: pie
 data:
   - [ bacon, eggs, ham, home fries, hash ]
   - [ 1,     4,    2,   3,          2    ]
 .graph

=head1 DESCRIPTION

This module turns C<graph> WAFL blocks into pretty graphs using L<GD::Graph>. Between the C<.graph> directives must be valid L<YAML>. Some keys are required.

=head2 Keys

=over 4

=item * B<id> - I<REQUIRED>, must be unique for every page, must be valid characters in a filename. Examples: C<sales> or C<marmots>.

=item * B<type> - I<REQUIRED>, the type of graph, will be prepended with "GD::Graph::" to determine which L<GD::Graph> module to use

=item * B<data> - I<REQUIRED>, the data set. See L<"Examples"> below.

=item * B<width> and B<height>, defaults are both 300 (pixels).

=item * B<title>, text title of the graph

=item * B<x_label> and B<y_label>, axis labels

=item * ...and any other options you can find in L<GD::Graph/"OPTIONS">.

=back

=head2 Examples

    .graph
    id: orangejuice
    type: bars
    title: Gallons of OJ I Drank This Week
    x_label: Day of Week
    y_label: No. of Gallons
    shadow_depth: 2
    data:
      - [ Sun, Mon, Tue, Wed, Thu, Fri, Sat ]
      - [ 23,  12,  43,  3,   16,  18,  30   ]
    .graph

    .graph
    id: lines
    type: lines
    line_width: 3
    show_values: 1
    data:
      - [ 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 ]
      - [ 1, 4, 2, 3, 6, 4, 2, 5, 6, 7 ]
      - [ 3, 5, 1, 1, 6, 8, 4, 6, 2, 4 ]
      - [ 3, 5, 9, 2, 5, 6, 3, 1, 7, 7 ]
    .graph

    .graph
    id: test
    type: pie
    width: 500
    height: 200
    dclrs: [ red, green, blue, yellow, purple, cyan, orange ]
    data:
      - [ bacon, eggs, ham, home fries, hash ]
      - [ 1,     4,    2,  3,  2 ]
    .graph

=head1 CAVEATS

You might need to clean up the cache for this module every now and then. The cache is located in the F<plugin/graphgenerator> directory in your Kwiki installation directory.

The "logo" key is not allowed because it would allow anyone to view any image on the filesystem that the Kwiki user could read.

=head1 AUTHORS

Ian Langworth <langworth.com>

=head1 SEE ALSO

L<Kwiki>, L<GD::Graph>, L<GD::Graph::colour>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ian Langworth

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__plugin/graphgenerator/.htaccess__
Allow from all

__template/tt2/graphgenerator_error.html__
<!-- BEGIN graphgenerator_error.html -->
<p><span class="error">[% msg %]</span></p>
<!-- END graphgenerator_error.html -->

__template/tt2/graphgenerator_inline.html__
<!-- BEGIN graphgenerator_inline.html -->
<img src="[% src %]" alt="(graph)" />
<!-- END graphgenerator_inline.html -->
