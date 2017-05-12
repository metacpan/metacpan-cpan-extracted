#!/usr/bin/env perl

BEGIN {
    die qq{$0 requires Mojolicious::Lite, which isn't installed.

    Currently requires Mojolicious::Lite which isn't available for perl 5.8.
    If this affects you you can run Devel::SizeMe with your normal perl and
    run sizeme_graph.pl with a different perl, perhaps on a different machine.
    \n}
        unless eval "require Mojolicious::Lite";
}

=head1 NAME

sizeme_graph.pl - web server providing an interactive treemap of Devel::SizeMe data

=head1 SYNOPSIS

    sizeme_graph.pl --db sizeme.db daemon

    sizeme_graph.pl daemon # same as above

Then open a web browser on http://127.0.0.1:3000

=head1 DESCRIPTION

Reads a database created by sizeme_store.pl and provides a web interface with
an interactive treemap of the data.

Currently requires Mojolicious::Lite which isn't available for perl 5.8.
If this affects you you can run Devel::SizeMe with your normal perl and
run sizeme_graph.pl with a different perl, perhaps on a different machine.

=head2 TODO

Current implementation is all very alpha and rather hackish.

Split out the db and tree code into a separate module.

Use a history management library so the back button works and we can have
links to specific nodes.

Better tool-tip and/or add a scrollable information area below the treemap
that could contain details and links.

Make the treemap resize to fit the browser window (as NYTProf does).

Protect against nodes with thousands of children
    perhaps replace all with single merged child that has no children itself
    but just a warning as a title.

Implement other visualizations, such as a space-tree
http://thejit.org/static/v20/Jit/Examples/Spacetree/example2.html

=cut

use strict;
use warnings;

use Mojolicious::Lite; # possibly needs v3
use JSON::XS;
use HTML::Entities qw(encode_entities);
use Getopt::Long;
use Devel::Dwarn;
use Devel::SizeMe::Graph;
use DBI;

my $dbh;
my %node_queue;
my %node_cache;
my $db_modtime;
my $j = JSON::XS->new;

GetOptions(
    'db=s' => \(my $opt_db = 'sizeme.db'),
    'showid!' => \my $opt_showid,
    'debug!' => \my $opt_debug,
) or exit 1;

die "Can't open $opt_db: $!\n" unless -r $opt_db;
warn "Reading $opt_db\n";

sub init {
    warn "Opening $opt_db\n";
    $db_modtime = -t $opt_db;
    $dbh = DBI->connect("dbi:SQLite:$opt_db", undef, undef, { RaiseError => 1 });
    %node_queue = ();
    %node_cache = ();
}

sub check_for_db_update {
    init() if !$db_modtime or $db_modtime = -t $opt_db;
}

check_for_db_update();


my $static_dir = $INC{'Devel/SizeMe/Graph.pm'} or die 'panic';
$static_dir =~ s:\.pm$:/static:;
die "panic $static_dir" unless -d $static_dir;
if ( $Mojolicious::VERSION >= 2.49 ) {
    push @{ app->static->paths }, $static_dir;
} else {
    app->static->root($static_dir);
}


sub name_path_for_node {
    my ($id, $parent_id_only) = @_;
    my $orig_id = $id;
    my @name_path;

    while ($id) { # work backwards towards root
        my $node = inflate_node(_get_node($id));
        push @name_path, $node;
        $id = ($parent_id_only) ? $node->{parent_id} : $node->{namedby_id} || $node->{parent_id};
        if (@name_path > 1_000) {
            my %id_count;
            ++$id_count{$_->{id}} for @name_path;
            my $desc = join ", ", map { "n$_ ($id_count{$_})" } keys %id_count;
            warn "name_path too deep (possible parent_id/namedby_id loop involving $desc)\n";
            # switch to using only parent_id if not already doing so
            return name_path_for_node($orig_id, 1) if not $parent_id_only;
            last; # else return what we've got so far
        }
    }

    return [ reverse @name_path ];
}


# Documentation browser under "/perldoc"
plugin 'PODRenderer';

get '/:id' => { id => 1 } => sub {
    my $self = shift;
    # JS handles the :id
    $self->render('index');
};


# /jit_tree are AJAX requests from the treemap visualization
get '/jit_tree/:id/:depth' => sub {
    my $self = shift;

    check_for_db_update();

    my $id = $self->stash('id');
    my $depth = $self->stash('depth');

    warn "/jit_tree/$id/$depth ... \n";

    # hack, would be best done on the client side
    my $logarea = (defined $self->param('logarea'))
        ? $self->param('logarea')
        : Mojo::URL->new($self->req->headers->referrer)->query->param('logarea');

    my $node_tree = _fetch_node_tree($id, $depth);
    my $jit_tree = _transform_node_tree($node_tree, sub {
        my ($node) = @_;
        my $children = delete $node->{children}; # XXX edits the src tree
        my $area = $node->{self_size}+$node->{kids_size};
        $node->{'$area'} = ($logarea && $area) ? log($area) : $area; # XXX move to jit js
        my $jit_node = {
            id   => $node->{id},
            name => ($node->{title} || $node->{name}).($opt_showid ? " #$node->{id}" : ""),
            data => $node,
        };
        $jit_node->{children} = $children if $children;
        return $jit_node;
    });

    if (1){ # debug
        #use Data::Dump qw(pp);
        local $jit_tree->{children};
        require Storable;
        Dwarn(Storable::dclone($jit_tree)); # dclone to avoid stringification
    }

    my %response = (
        name_path  => name_path_for_node($id),
        nodes => $jit_tree
    );

    # XXX temp hack
    #     //   <li><a href="#">Home</a> <span class="divider">/</span></li>
    #     //   <li><a href="#">Library</a> <span class="divider">/</span></li>
    #     //   <li class="active">Data</li>
    $response{name_path_html} = join "", map {
        my $html = ($_->{type} == 2) # link
            ? sprintf q{%s}, $_->{name}
            : sprintf q{<a href="/%d" title="%s">%s</a>},
                $_->{id}, encode_entities($_->{name}), encode_entities($_->{attr}{label} || $_->{name});
        my $divider = ($_->{type} == 2) ? "&rarr;" : "&rarr;";
        qq{<li>$html<span class="divider">$divider</span></li>}
    } @{$response{name_path}};

    $self->render(json => \%response);
};

sub _set_node_queue {
    my $nodes = shift;
    ++$node_queue{$_} for @$nodes;
}
sub _get_node {
    my $id = shift;

    my $node = $node_cache{$id};
    return $node if ref $node;

    my @ids;
    # ensure the one the caller wanted is actually in the batch
    push @ids, $id;
    delete $node_queue{$id};
    # also fetch a chunk of nodes from the read-ahead list
    while ( $_ = scalar each %node_queue ) {
        delete $node_queue{$_};
        push @ids, $_;
        last if @ids > 1_000; # batch size
    }

    my $sql = "select * from node where id in (".join(",",@ids).")";
    my $rows = $dbh->selectall_arrayref($sql);
    for (@{ $dbh->selectall_arrayref($sql, { Slice => {} })}) {
        $node_cache{ $_->{id} } = $_;
    }

    return $node_cache{$id};
}

sub inflate_node {
    my $node = shift or return undef;
    $node = { %$node }; # XXX copy for inflation
    $node->{$_} += 0 for (qw(child_count kids_node_count kids_size self_size)); # numify
    $node->{leaves} = $j->decode(delete $node->{leaves_json});
    $node->{attr}   = $j->decode(delete $node->{attr_json});
    return $node;
}

sub _fetch_node_tree {
    my ($id, $depth) = @_;

    warn "#$id fetching\n"
        if $opt_debug;

    my $node = _merge_up_only_children(inflate_node(_get_node($id)))
        or die "No node $id";

    #$node->{name} .= "->" if $node->{type} == 2 && $node->{name};

    if ($node->{child_ids} && $depth) {
        my @child_ids = split /,/, $node->{child_ids};

        if (@child_ids > 1_000) {
            warn "Node $id ($node->{name}) has ".scalar(@child_ids)." children\n";
            # XXX merge/prune/something?
        }

        # XXX hack to handle nodes that possibly have large numbers of children
        $depth = 1 if $depth > 1 and $node->{name} =~ /^arena|^unaccounted|^unseen|^ref_loop/;

        _set_node_queue(\@child_ids);
        $node->{children} = [ map { _fetch_node_tree($_, $depth-1) } @child_ids ];
        $node->{child_count} = @{ $node->{children} };
    }

    return $node;
}


sub get_only_child {
    my $node = shift;
    my @child_ids = split /,/, $node->{child_ids}||'';
    return undef if @child_ids != 1;
    return inflate_node(_get_node($child_ids[0]))
}


# if this node has only one child then we merge that child into this node
# this makes the treemap much more usable.
# this probably ought to be a transform of the db data (also update depth)
sub _merge_up_only_children {
    my $node = shift or return undef;

    my @merge = ($node);
    while (my $onlychild = get_only_child($merge[-1])) {
        push @merge, $onlychild;
    }
    $node = shift @merge;
    return $node unless @merge;

    warn "merging up into $node->{id} children: @{[ map { $_->{id} } @merge ]}\n";

    # sum these numeric attributes
    for (qw(self_size kids_size)) {
        for (@merge) {
            $node->{$_} += $_->{$_} if defined $_->{$_};
        }
    }
    # accumulate leafs
    for (@merge) {
        my $leaves = $_->{leaves} or next;
        $node->{leaves}{$_} += $leaves->{$_} for keys %$leaves;
    }
    # take these from the deepest child
    for (qw(child_ids kids_node_count type)) {
        $node->{$_} = $merge[-1]->{$_};
    }
    if ($merge[-1]->{type} != $node->{type}) {
        warn "merging only children changes type of $node->{id} from $node->{type} to $merge[-1]->{type} (from $merge[-1]->{id})\n";
        $node->{type} = $merge[-1]->{type}; # XXX?
    }
    # pick deepest true instance
    $node->{namedby_id} = (grep { $_ } map { $_->{namedby_id} } reverse @merge) || $node->{namedby_id};

    # join unique values
    for my $k (qw(name title)) {
        $node->{$k} = join "; ", uniq( map { $_->{$k} } ($node, @merge) );
    }

    # TODO attr merging is skipped till there's a clear need
    for my $n (@merge) {

        # handle {n} attribute
        my $an = $n->{attr}{n};
        next unless $an and %$an;
        $node->{attr}{n}{$_} += $an->{$_} for keys %$an;
    }

    # these fields we don't change:
    # depth, parent_id

    $node->{_ids_merged} = join ",", map { $_->{id} } @merge;

    return $node;
}


sub _transform_node_tree {  # recurse depth first
    my ($node, $transform) = @_;
    if (my $children = $node->{children}) {
        $_ = _transform_node_tree($_, $transform) for @$children;
    }
    return $transform->($node);
}

sub uniq (@) {
    my %seen = ();
    grep { defined $_ and not $seen{$_}++ } @_;
}


app->start;

{   # just to reserve the namespace for future use
    package Devel::SizeMe::Graph;
    1;
}

__DATA__
@@ index.html.ep
% layout 'default';
% title 'Welcome';
Welcome to the Mojolicious real-time web framework!

@@ layouts/default.html.ep
<!DOCTYPE html>
<html lang="en">

<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Perl Memory Treemap</title>

<!-- CSS Files -->
<link type="text/css" href="css/base.css" rel="stylesheet" />
<link type="text/css" href="css/Treemap.css" rel="stylesheet" />
<link type="text/css" href="yesmeck-jquery-jsonview/jquery.jsonview.css" rel="stylesheet" />
<link type="text/css" href="bootstrap/css/bootstrap.min.css" rel="stylesheet" media="screen" />
<link type="text/css" href="bootstrap/css/bootstrap-responsive.min.css" rel="stylesheet" />

<!--[if IE]><script language="javascript" type="text/javascript" src="excanvas.js"></script><![endif]-->

</head>

<body>

<div class="container-fluid">

<div class="row-fluid">

    <div class="span3" id="sizeme_left_column_div">

        <div class="row-fluid">
            <div class="span12" id="sizeme_title_div">
                <h4>Perl Memory TreeMap</h4> 
            </div>
        </div>
        <div class="row-fluid">
            <div class="span12 text-left" id="sizeme_info_div">
                <p class="text-left">
                <a id="goto_parent" href="#" class="theme button white">Go to Parent</a>
                <form name=params id="sizeme_params_form">
                <label for="logarea">Log scale
                <input type=checkbox id="sizeme_logarea_checkbox" name="logarea">
                </form>
                </p>
            </div>
        </div>
        <div class="row-fluid">
            <small>
            <div class="span12 text-left" id="sizeme_data_div">
            </div>
            </small>
        </div>

    </div>

    <div class="span9" id="sizeme_right_column_div">
        <div class="row-fluid">
            <div class="span12" id="sizeme_path_div">
                <ul class="breadcrumb pull-left text-left" id="sizeme_path_ul">Path</ul>
            </div>
            <div class="span12" style="margin-left:0; text-align:center">
                <div id="infovis"></div>
            </div>
        </div>
    </div>
</div>

<div class="row-fluid">
    <div class="span12" id="sizeme_log_div">
        <p class="text-left" id="sizeme_log_p">Log</p>
    </div>
</div>

</div>

<script language="javascript" type="text/javascript" src="jit-yc.js"></script>
<script language="javascript" type="text/javascript" src="jquery-1.8.1-min.js"></script>
<script language="javascript" type="text/javascript" src="sprintf.js"></script>
<script language="javascript" type="text/javascript" src="treemap.js"></script>
<script language="javascript" type="text/javascript" src="bootstrap/js/bootstrap.min.js"></script>
<script language="javascript" type="text/javascript" src="yesmeck-jquery-jsonview/jquery.jsonview.js"></script>
<script type="text/javascript"> $('document').ready(init) </script>

</body>
</html>
