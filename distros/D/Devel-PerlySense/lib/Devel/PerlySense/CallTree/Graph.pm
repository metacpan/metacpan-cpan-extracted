=head1 NAME

Devel::PerlySense::CallTree::Graph - A GraphViz graph of the CallTree

=head1 DESCRIPTION


=cut

package Devel::PerlySense::CallTree::Graph;
$Devel::PerlySense::CallTree::Graph::VERSION = '0.0223';
use strict;
use warnings;
use utf8;



use Moo;
use Path::Tiny;
use Digest::SHA qw/ sha256_hex /;

use Devel::PerlySense::CallTree;
use Devel::PerlySense::CallTree::Caller;



has call_tree => ( is => "ro", required => 1 );

has output_format => ( is => "lazy" );
sub _build_output_format { "png" }

has output_dir => ( is => "lazy" );
sub _build_output_dir { "." }
around output_dir => sub {
    my $orig = shift;
    my $self = shift;
    my $dir = $self->$orig(@_);

    (-e $dir) or $dir->mkpath();
    (-d $dir) or die("Can not create directory ($dir)\n");

    return $dir;
};

has base_file => ( is => "lazy" );
sub _build_base_file {
    my $self = shift;
    return sha256_hex( $self->edge_declarations_text );
}

has dot_file => ( is => "lazy" );
sub _build_dot_file {
    my $self = shift;
    my $file = path($self->output_dir, $self->base_file . ".dot")->absolute;
    return $file;
}

has output_file => ( is => "lazy" );
sub _build_output_file {
    my $self = shift;
    path($self->output_dir, $self->base_file . "." . $self->output_format)->absolute;
}

has edge_declarations_text => ( is => "lazy" );
sub _build_edge_declarations_text {
    my $self = shift;
    my $called_by_caller = $self->call_tree->method_called_by_caller;
    my $edge_declarations = join(
        "\n",
        map {
            my $callers = $called_by_caller->{ $_ };
            my @callers = sort keys %$callers;
            my $target = Devel::PerlySense::CallTree::Caller->new({
                caller => $_,
            });
            join(
                "\n",
                map {
                    my $method_caller  = $_;
                    my $caller = Devel::PerlySense::CallTree::Caller->new({
                        caller => $method_caller,
                    });
                    "    " . $caller->id . " -> " . $target->id;
                }
                @callers
            );
        }
        sort keys %$called_by_caller
    );
    return $edge_declarations;
}

has cluster_declarations_text => ( is => "lazy" );
sub _build_cluster_declarations_text {
    my $self = shift;
    my $package_callers = $self->call_tree->package_callers;
    my $cluster_declarations = join(
        "\n",
        map {
            my $package = $_;
            my $callers = $package_callers->{ $package };
            my $node_declarations = join(
                "\n",
                map { "    " . $self->node_declaration($_) }
                @$callers
            );

            my $package_id = $self->to_id(package => $package);
            qq|
    subgraph cluster_${package_id} {
        label = "$package";
$node_declarations
    }
|;
        }
        sort keys %$package_callers
    );
    return $cluster_declarations;
}

has dot_source_template => ( is => "lazy" );
sub _build_dot_source_template {
    my $self = shift;
    my $source = qq|
digraph d {
    overlap  = false
    ranksep  = 0.3; nodesep = 0.1;
    rankdir  = TB;
    fontname = "Verdana";
    labelloc = "t";

    // splines=ortho

    graph [
        fontname = "Verdana",
        fontsize = 10,
        fontcolor = "#2980b9",
        style = "rounded",
        color="#cccccc",
    ];

    node [
        width    = 0.1,
        height   = 0.2,
        fontname = "Verdana",
        fontsize = 8,
        shape    = "none",
    ];
    edge [
        arrowsize = 0.4,
        fontname  = "Helvetica",
        fontsize  = 9,
    ];


%s


%s

}

|;
}

sub create_graph {
    my $self = shift;
    my $dot_file = $self->dot_file;
    $self->write_dot_file( $dot_file );
    $self->run_dot( $dot_file, $self->output_file );
}

sub node_declaration {
    my $self = shift;
    my ($caller) = @_;
    return sprintf(
        qq{    %s [ label="%s" ];},
        $caller->id,
        $caller->method,
    );
}

sub to_id {
    my $self = shift;
    my ($prefix, $name) = @_;
    $name =~ s/\W+/_/gsm;
    return join("_", $prefix, lc($name));
}

sub to_caller {
    my $self = shift;
    my ($caller) = @_;
    return Devel::PerlySense::CallTree::Caller->new({ caller => $caller });
}

sub write_dot_file {
    my $self = shift;
    my ($filename) = @_;
    my $source = sprintf(
        $self->dot_source_template,
        $self->cluster_declarations_text(),
        $self->edge_declarations_text(),
    );
    path($filename)->spew($source);
}

sub run_dot {
    my $self = shift;
    my ($dot_file, $output_file) = @_;
    my $format = $self->output_format;
    my $command = qq|dot -T$format -o"$output_file" "$dot_file" 2>&1|;
    my $error = qx($command);
    $error and die("Could not run 'dot':\n$!\n$error \n");
}

1;




__END__

=encoding utf8

=head1 AUTHOR

Johan Lindstrom, C<< <johanl@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-devel-perlysense@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-PerlySense>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
