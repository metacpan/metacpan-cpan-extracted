#!/usr/bin/env perl

=head1 NAME

sizeme_store.pl - process and store the raw data stream from Devel::SizeMe

=head1 SYNOPSIS

    sizeme_store.pl [--text] [--dot=sizeme.dot] [--db=sizeme.db]

Typically used with Devel::SizeMe via the C<SIZEME> env var:

    export SIZEME='|sizeme_store.pl --text'
    export SIZEME='|sizeme_store.pl --dot=sizeme.dot'
    export SIZEME='|sizeme_store.pl --db=sizeme.db'

=head1 DESCRIPTION

Reads the raw memory data from Devel::SizeMe and processes the tree
via a stack, propagating data such as totals, up the tree nodes
as the data streams through.  Output completed nodes in the request formats.

The --text output is similar to the textual representation output by the module
when the SIZEME env var is set to an empty string.

The --dot output is suitable for feeding to Graphviz. (On OSX the Graphviz
application will be started automatically.)

The --db output is a SQLite database. The db schema is very subject to change.
This output is destined to be the primary one. The other output types will
probably become separate programs that read the db.

=head1 TODO

Current implementation is all very alpha and rather hackish.

Refactor to separate the core code into a module.

Move the output formats into separate modules, which should probably read from
the db so the db becomes the canonical source of data.

Import constants from XS.

=cut

# Needs to be generalized to support pluggable output formats.
# Actually it needs to be split so sizeme_store.pl only does the store
# and another program drives the output with plugins.
# Making nodes into (lightweight fast) objects would be smart.
# Tests would be even smarter!
#
# When working on this code it's important to have a sense of the flow.
# Specifically the way that depth drives the completion of nodes.
# It's a depth-first stream processing machine, which only ever holds
# a single stack of the currently incomplete nodes, which is always the same as
# the current depth. I.e., when a node of depth N arrives, all nodes >N are
# popped off the stack and 'completed', each rippling data up to its parent.

use strict;
use warnings;
use autodie;

use DBI qw(looks_like_number);
use DBD::SQLite;
use JSON::XS;
use Devel::Dwarn;
use Data::Dumper;
use Getopt::Long;
use Carp qw(carp croak confess);

use Devel::SizeMe::Core qw(:type :attr NPattr_NOTE);

my @attr_type_name = (qw(size NAME PADFAKE my PADTMP NOTE ADDR REFCNT)); # XXX get from XS in some way


GetOptions(
    'text!' => \my $opt_text,
    'dot=s' => \my $opt_dot,
    'tree!' => \my $opt_tree,
    'gexf=s' => \my $opt_gexf,
    'db=s'  => \my $opt_db,
    'verbose|v+' => \my $opt_verbose,
    'debug|d!' => \my $opt_debug,
    'showid!' => \my $opt_showid,
    'open!' => \my $opt_open,
) or exit 1;

$| = 1; #if $opt_debug;
my $run_size = 0;
my $total_size = 0;

my $j = JSON::XS->new->ascii->pretty(0);

my ($dbh, $node_ins_sth);
if ($opt_db) {
    $dbh = DBI->connect("dbi:SQLite:dbname=$opt_db","","", {
        RaiseError => 1, PrintError => 0, AutoCommit => 0
    });
    $dbh->do("PRAGMA synchronous = OFF");
}

my @outputs;
my @stack;
my %seqn2node;


my %links_to_addr;
my %node_id_of_addr;
sub note_item_addr {
    my ($addr, $id) = @_;
    # for items with addr we record the id of the item
    if (my $old = $node_id_of_addr{$addr}) {
        return if $id == $old;
        warn "id for address $addr changed from $old to $id"
            ." (type $seqn2node{$old}->{type} to $seqn2node{$id}->{type})!\n";
    }
    $node_id_of_addr{$addr} = $id;
    Dwarn { node_id_of_addr => $id } if $opt_debug;
}

sub note_link_to_addr {
    my ($addr, $id) = @_;
    # for links with addr we build a list of all the link ids
    # associated with an addr
    ++$links_to_addr{$addr}{$id};
    Dwarn { links_to_addr => $links_to_addr{$addr} } if $opt_debug;
}




sub enter_node {
    my $x = shift;
    warn ">> enter_node $x->{id}\n" if $opt_verbose;
    return $x;
}


sub leave_node {
    my $x = shift;
    confess unless defined $x->{id};
    warn "<< leave_node $x->{id}\n" if $opt_verbose;
    #delete $seqn2node{$x->{id}};

    my $self_size = 0;
    $self_size += $_ for values %{$x->{leaves}};
    $x->{self_size} = $self_size;
    my $attr = $x->{attr};

    # improve the name of elem nodes
    if ($x->{name} eq 'elem'
        and defined(my $index = $x->{attr}{+NPattr_NOTE}{i})
    ) {
        my $padlist;
        if (@stack >= 3 && ($padlist=$stack[-3])->{name} eq 'PADLIST') {
            # elem link <- SV(PVAV) <- elem link <- PADLIST
            my $padnames = $padlist->{attr}{+NPattr_PADNAME} || [];
            if (my $padname = $padnames->[$index]) {
                $x->{attr}{label} = "my($padname)";
            }
            else {
                $x->{attr}{label} = ($index) ? "PAD[$index]" : '@_';
            }
        }
        elsif (@stack >= 1 && ($padlist=$stack[-1])->{name} eq 'PADLIST') {
            my $padnames = $padlist->{attr}{+NPattr_PADNAME} || [];
            $x->{attr}{label} = "Pad$index";
        }
        else {
            $x->{attr}{label} = "[$index]";
        }
    }

    my $parent = $stack[-1];

    # if node has addr and there are multiple links_to_addr{$addr}
    # then we can choose which one will be our parent
    my $addr = $attr->{addr};
    # XXX disabled for now - really needs to be done as a separate phase
    if ( 0 && $addr) { # TODO add option to control adoption
        if ($x->{type} == NPtype_LINK) {

        }
        else {
            if ( keys %{$links_to_addr{$addr}||{}} > 1) {
                my @candidates = sort { $a <=> $b } keys %{$links_to_addr{$addr}};
                # XXX for now we simply pick one that isn't our current parent
                # because our current parent will be the arena for SVs where
                # we've not been able to find all the refs
                my @other = grep { $_ != $parent->{id} } @candidates;
                my $new_parent_id = shift @other;
                warn "$x->{id} addr $addr parent_id changed from $parent->{id} to $new_parent_id (candidates: @candidates)\n";
                # we can't simply change $parent here because we've already
                # 'left' that new parent so that node and the ones above it have
                # their totals set. We'd have to change them all. We could do that
                # as an edit to the db once we're using the db as the primary store.
                # Meanwhile we'll use a separate field to record the parent that
                # should be used for naming his node
                $x->{namedby_id} = $new_parent_id;
            }
        }
    }

    if ($parent) {
        # link to parent
        $x->{parent_id} = $parent->{id};
        # accumulate into parent
        # XXX should be done in the db after db transforms
        $parent->{kids_node_count} += 1 + ($x->{kids_node_count}||0);
        $parent->{kids_size} += $self_size + $x->{kids_size};
        push @{$parent->{child_id}}, $x->{id}; # XXX 
    }

    $_->leave_node($x) for (@outputs);

    # output
    # ...
    if ($dbh) {
        my $attr_json = $j->encode($x->{attr});
        my $leaves_json = $j->encode($x->{leaves});
        $node_ins_sth->execute(
            $x->{id}, $x->{name}, $x->{attr}{label}, $x->{type}, $x->{depth},
            $x->{parent_id}, $x->{namedby_id},
            $x->{self_size}, $x->{kids_size}, $x->{kids_node_count},
            $x->{child_id} ? join(",", @{$x->{child_id}}) : undef,
            $attr_json, $leaves_json,
        );
        # XXX attribs
    }

    return $x;
}

my $indent = ":   ";

while (<>) {
    warn "\t\t\t\t== $_" if $opt_debug;
    chomp;

    my ($type, $id, $val, $name, $extra) = split / /, $_, 5;

    if ($type =~ s/^-//) {     # Node type ($val is depth)

        # this is the core driving logic

        while ($val < @stack) {
            my $x = leave_node(pop @stack);
            warn "N $id d$val ends $x->{id} d$x->{depth}: size $x->{self_size}+$x->{kids_size}\n"
                if $opt_debug;
        }

        printf "%s%s%s %s [#%d @%d]\n", $indent x $val, $name,
                ($type == NPtype_LINK) ? "->" : "",
                $extra||'', $id, $val
            if $opt_text;

        die "panic: stack already has item at depth $val" if $stack[$val];
        die "Depth out of sync\n" if $val != @stack;

        my $node = { # enter_node({...})
            id => $id, type => $type, name => $name, extra => $extra,
            attr => { }, leaves => {}, depth => $val, self_size=>0,
            kids_size=>0, kids_node_count=>0
        };

        $stack[$val] = $seqn2node{$id} = $node;

        # if parent is a link that has an addr then note the addr is associated with this node
        if ($type != NPtype_LINK
            and $val
            and (my $addr_on_parent_link = $stack[-2]{attr}{addr})
        ) {
            note_item_addr($addr_on_parent_link, $id);
        }

    }

    # --- Leaf name and memory size
    elsif ($type eq "L") {
        my $node = $seqn2node{$id} or die "panic: Leaf refers to unknown node $id: $_";
        $node->{leaves}{$name} += $val;
        $node->{attr}{n}{$name}++;
        $run_size += $val;
        printf "%s+%d=%d %s\n", $indent x ($node->{depth}+1), $val, $run_size, $name
            if $opt_text;
    }

    # --- Attribute type, name and value (all rather hackish)
    elsif (looks_like_number($type)) {
        my $node = $seqn2node{$id} || die;
        my $attr = $node->{attr} || die;

        # attributes where the string is a key (or always empty and the type is the key)
        if ($type == NPattr_LABEL or $type == NPattr_NOTE) {
            printf "%s~%s(%s) %d [t%d]\n", $indent x ($node->{depth}+1), $attr_type_name[$type], $name, $val, $type
                if $opt_text;
            warn "Node $id already has attribute $type:$name (value $attr->{$type}{$name})\n"
                if exists $attr->{$type}{$name};
            $attr->{$type}{$name} = $val;
            #Dwarn $attr;
            if ($type == NPattr_NOTE) {
            }
            elsif ($type == NPattr_LABEL) {
                $attr->{label} = $name if !$val; # XXX hack
            }
        }
        elsif ($type == NPattr_ADDR) {
            printf "%s~%s %d 0x%x [#%d t%d]\n", $indent x ($node->{depth}+1), $attr_type_name[$type], $val, $val, $node->{id}, $type
                if $opt_text;
            $attr->{addr} = $val;
            # for SVs we see all the link addrs before the item addr
            # for hek's etc we see the item addr before the link addrs
            if ($node->{type} == NPtype_LINK) {
                note_link_to_addr($val, $id);
            }
            else {
                note_item_addr($val, $id);
            }
        }
        elsif (NPattr_PADFAKE==$type or NPattr_PADTMP==$type or NPattr_PADNAME==$type) {
            printf "%s~%s('%s') %d [t%d]\n", $indent x ($node->{depth}+1), $attr_type_name[$type], $name, $val, $type
                if $opt_text;
            warn "Node $id already has attribute $type:$name (value $attr->{$type}[$val])\n"
                if defined $attr->{$type}[$val];
            $attr->{+NPattr_PADNAME}[$val] = $name; # store all as NPattr_PADNAME
        }
        elsif (NPattr_REFCNT==$type) {
            printf "%s~%s %d\n", $indent x ($node->{depth}+1), $attr_type_name[$type], $val
                if $opt_text;
            $attr->{refcnt} = $val;
        }
        else {
            printf "%s~%s %d [t%d]\n", $indent x ($node->{depth}+1), $name, $val, $type
                if $opt_text;
            warn "Unknown attribute type '$type' on line $. ($_)";
        }
    }
    elsif ($type eq 'S') { # start of a run
        die "Unexpected start token" if @stack;

        if ($opt_tree) {
            my $out = Devel::SizeMe::Output::Text->new();
            $out->start_event_stream;
            push @outputs, $out;
        }

        if ($opt_dot) {
            my $out = Devel::SizeMe::Output::Graphviz->new(file => $opt_dot);
            $out->start_event_stream;
            push @outputs, $out;
        }

        if ($opt_gexf) {
            my $out = Devel::SizeMe::Output::GEXF->new(file => $opt_gexf);
            $out->start_event_stream;
            push @outputs, $out;
        }

        if ($dbh) {
            # XXX add a size_run table records each run
            # XXX pick a table name to store the run nodes in
            # XXX use separate tables for nodes and links
            #$run_ins_sth->execute(
            my $table = "node";
            $dbh->do("DROP TABLE IF EXISTS $table");
            $dbh->do(qq{
                CREATE TABLE $table (
                    id integer primary key,
                    name text,
                    title text,
                    type integer,
                    depth integer,
                    parent_id integer,
                    namedby_id integer,

                    self_size integer,
                    kids_size integer,
                    kids_node_count integer,
                    child_ids text,
                    attr_json text,
                    leaves_json text
                )
            });
            $node_ins_sth = $dbh->prepare(qq{
                INSERT INTO $table VALUES (?,?,?,?,?,?,?,  ?,?,?,?,?,?)
            });
        }
    }
    elsif ($type eq 'E') { # end of a run

        my $top = $stack[0]; # grab top node before we pop all the nodes
        leave_node(pop @stack) while @stack;

        # if nothing output (ie size(undef))
        $top ||= { self_size=>0, kids_size=>0, kids_node_count=>0 };

        my $top_size = $top->{self_size}+$top->{kids_size};

        printf "Total size %s spread over %d nodes [lines=%d bytes=%d write=%.2fs]\n",
            fmt_size($top_size), 1+$top->{kids_node_count}, $., $top_size, $val;
        # the duration here ($val) is from Devel::SizeMe perspective
        # ie doesn't include time to read file/pipe and commit to database.

        if ($opt_verbose or $run_size != $top_size) {
            warn "EOF ends $top->{id} d$top->{depth}: size in $run_size, out $top_size ($top->{self_size}+$top->{kids_size})\n";
            warn Dumper($top) if $opt_debug;
        }
        #die "panic: seqn2node should be empty ". Dumper(\%seqn2node) if %seqn2node;

        $_->end_event_stream for @outputs;

        $dbh->commit if $dbh;
    }
    else {
        warn "Invalid type '$type' on line $. ($_)";
        next;
    }

    $dbh->commit if $dbh and $id % 10_000 == 0;
}
die "EOF without end token" if @stack;

@outputs = (); # DESTROY


sub fmt_size {
    my $size = shift;
    my $kb = $size / 1024;
    return sprintf "%d", $size if $kb < 5;
    return sprintf "%.1fKB", $kb if $kb < 1000;
    return sprintf "%.1fMB", $kb/1024;
}


BEGIN {
package Devel::SizeMe::Output;
use Moo;
use autodie;
use Carp qw(croak);
use HTML::Entities qw(encode_entities);

my @attr_names = qw(label_attr size_attr kids_size_attr total_size_attr weight_attr);
has \@attr_names => (is => 'rw');

has file => (is => 'ro');

my %pending_links;

sub start_event_stream {
    my ($self) = @_;
    $self->create_output;
    $self->write_prologue;
}

sub end_event_stream {
    my ($self) = @_;

    $self->write_pending_links;
    $self->write_dangling_links;
    $self->write_epilogue;

    $self->close_output;
    $self->view_output if $opt_open;
}

sub write_prologue {
}
sub write_epilogue {
}

sub assign_link_to_item {
    my ($self, $link_node, $child, $attr) = @_;
    $attr ||= {};

    my $child_id = (ref $child) ? $child->{id} : $child;

    warn "assign_link_to_item $link_node->{id} -> $child_id @{[ %$attr ]}\n"
        if $opt_verbose;
    warn "$link_node->{id} is not a link"
        if $link_node->{type} != ::NPtype_LINK;
    # XXX add check that $link_node is 'dangling'
    # XXX add check that $child is not a link

    my $cur = $pending_links{ $link_node->{id} }{ $child_id } ||= {};
    $cur->{hard} ||= $attr->{hard}; # hard takes precedence
}

sub assign_addr_to_link {
    my ($self, $addr, $link) = @_;

    if (my $id = $node_id_of_addr{$addr}) {
        # link to an addr for which we already have the node
        warn "LINK addr $link->{id} -> $id\n" if $opt_debug;
        $self->assign_link_to_item($link, $id, { hard => 0 });
    }
    else {
        # link to an addr for which we don't have node yet
        warn "link $link->{id} has addr $addr which has no associated node yet\n"
            if $opt_debug;
        # queue XXX
    }
}

sub resolve_addr_to_item {
    my ($self, $addr, $item) = @_;

    my $links_hashref = $links_to_addr{$addr}
        or return; # we've no links waiting for this addr

    my @links = map { $seqn2node{$_} } sort { $a <=> $b } keys %$links_hashref;
    for my $link_node (@links) {
        # skip link if it's the one that's the actual parent
        # (because that'll get its own link drawn later)
        # current that's identified by not having a parent_id (yet)
        next if not $link_node->{parent_id};
        warn "ITEM addr link $link_node->{id} ($seqn2node{$link_node->{parent_id}}{id}) -> $item->{id}\n"
            if $opt_verbose;
        $self->assign_link_to_item($link_node, $item->{id}, { hard => 0 });
    }
}


sub write_pending_links {
    my $self = shift;
    warn "write_pending_links\n"
        if $opt_debug;
    for my $link_id (sort { $a <=> $b } keys %pending_links) {
        my $dests = $pending_links{$link_id};
        my $link_node = $seqn2node{$link_id} or die "No node for id $link_id";
        for my $dest_id (sort { $a <=> $b } keys %$dests) {
            my $attr = $dests->{$dest_id};
            $self->emit_link($link_id, $dest_id, $attr);
        }
    }
}

sub write_dangling_links {
    my $self = shift;

    warn "write_dangling_links\n"
        if $opt_debug;
    for my $addr (sort { $a <=> $b } keys %links_to_addr) {
        my $link_ids = $links_to_addr{$addr};
        next if $node_id_of_addr{$addr}; # not dangling
        my @link_ids = sort { $a <=> $b } keys %$link_ids;

        # one of the links that points to this addr has
        # attributes that describe the addr being pointed to
        my @link_attr = grep { $_->{refcnt} } map { $seqn2node{$_}->{attr} } @link_ids;
        warn "multiple links to addr $addr have refcnt attr"
            if @link_attr > 1;
        my $attr = $link_attr[0];

        my @labels = sprintf("0x%x", $addr);
        unshift @labels, $attr->{label} if $attr->{label};
        push    @labels, "refcnt=$attr->{refcnt}" if $attr->{refcnt};

        $self->emit_addr_node($addr, \@labels, $attr);

        for my $link_id (@link_ids) {
            $self->emit_link($link_id, $addr, { kind => 'addr' });
        }
    }
}

sub view_output {
    my $self = shift;

    my $file = $self->file;
    if ($file && $file ne '/dev/tty') {
        system("cat $file") if $opt_debug;
    }
}


sub leave_item_node {
    my ($self, $item_node) = @_;
    my $label = $item_node->{attr}{label};
    $label = $item_node->{name} if not defined $label;
    $self->emit_item_node($item_node, { label => $label });
    if (my $addr = $item_node->{attr}{addr}) {
        $self->resolve_addr_to_item($addr, $item_node);
    }
}

sub leave_link_node {
    my ($self, $link_node) = @_;
    my @kids = @{$link_node->{child_id}||[]};
    warn "warning: NPtype_LINK $link_node->{id} ($link_node->{name}) has more than one child: @kids"
        if @kids > 1;
    for my $child_id (@kids) {
        $self->assign_link_to_item($link_node, $child_id, { hard => 1 });
    }
    # if this link has an address
    if (my $addr = $link_node->{attr}{addr}) {
        $self->assign_addr_to_link($addr, $link_node);
    }
}

sub leave_node {
    my ($self, $node) = @_;
    return $self->leave_item_node($node) if $node->{type} != ::NPtype_LINK;
    return $self->leave_link_node($node);
}


} # Devel::SizeMe::Output



BEGIN {

package Devel::SizeMe::Output::Text;

use Moo;
use autodie;
use Carp qw(croak);
use Devel::Dwarn;
use HTML::Entities qw(encode_entities);;

extends 'Devel::SizeMe::Output';

has fh => (is => 'rw');

my %buffered_edges;

*fmt_size = \&main::fmt_size;

sub BUILD {
    my $self = shift;
    %buffered_edges = ();
}

sub create_output {
    my $self = shift;
    $self->fh(\*STDOUT);
    $self->fh->autoflush if $opt_debug;
}

sub close_output {
    my $self = shift;
    $self->fh(undef);
}

sub leave_node {
    my ($self, $node) = @_;
    my $fh = $self->fh or return;

    my $size_str = sprintf "%s+%s=%s",
        fmt_size($node->{self_size}),
        fmt_size($node->{kids_size}),
        fmt_size($node->{self_size}+$node->{kids_size});
    my $pad = $indent x $node->{depth};

    printf "%s%s", $pad, $node->{name};

    printf q{ "%s"}, _escape($node->{attr}{label})
        if exists $node->{attr}{label};

    printf " --^" if ($node->{type} == ::NPtype_LINK);

    printf " [#%d @%d] %s\n", $node->{id}, $node->{depth}, $size_str;

    our $j ||= JSON::XS->new->ascii->pretty(0);
    printf "%s `attr %s\n", $pad, $j->encode($node->{attr})
        if keys %{$node->{attr}};
    print "$pad\n";
}


sub write_pending_links {
    print "write_pending_links skipped\n";
}

sub write_dangling_links {
    print "write_dangling_links skipped\n";
}

sub _escape {
    local $_ = shift;
    return "" if not defined $_;
    # escape unprintables XXX correct sins against unicode
    s/([\000-\037\200-\237])/sprintf("\\x%02x",ord($1))/eg;
    return $_;
}

} # END Text



BEGIN {

package Devel::SizeMe::Output::GEXF;
# http://gexf.net/format/index.html

use Moo;
use autodie;
use Carp qw(croak);
use HTML::Entities qw(encode_entities);;
use Carp qw(carp cluck croak confess);

extends 'Devel::SizeMe::Output';

has fh => (is => 'rw');

my %buffered_edges;

*fmt_size = \&main::fmt_size;

sub BUILD {
    my $self = shift;
    %buffered_edges = ();
}

sub create_output {
    my $self = shift;
    open my $fh, ">", $self->file;
    $self->fh($fh);
    $self->fh->autoflush if $opt_debug;
}

sub close_output {
    my $self = shift;
    close($self->fh);
    $self->fh(undef);
}

sub view_output {
    my $self = shift;
    $self->SUPER::view_output(@_);

    my $file = $self->file;
    system("open -a Gephi $file") if $^O eq 'darwin'; # OSX
}

sub write_prologue {
    my $self = shift;
    my $fh = $self->fh or return;

    print $fh qq{<?xml version="1.0" encoding="UTF-8"?>
<gexf xmlns="http://www.gexf.net/1.2draft"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:viz="http://www.gexf.net/1.2draft/viz"
        xsi:schemaLocation="http://www.gexf.net/1.2draft
        http://www.gexf.net/1.2draft/gexf.xsd" version="1.2">
    <meta lastmodifieddate="2013-01-01">
        <creator>Devel::SizeMe</creator>
        <description>Perl Internals Memory</description>
    </meta>
};
    print $fh qq{<graph defaultedgetype="directed">
        <attributes class="node" type="static">
        <attribute id="label" title="label" type="string"/>
        <attribute id="name" title="name" type="string"/>
        <attribute id="nsb" title="self_bytes" type="int"/>
        <attribute id="nkb" title="kids_bytes" type="int"/>
        <attribute id="ntb" title="total_bytes" type="int"/>
        <attribute id="nrc" title="refcnt" type="int"/>
        </attributes>
};

}


sub _fmt_viz {
    my ($viz) = @_;
    return '';
}

sub write_epilogue {
    my $self = shift;
    my $fh = $self->fh or return;

    print $fh qq{<edges>\n};
    for my $id (sort { $a <=> $b } %buffered_edges) {
        my $edge = $buffered_edges{$id};
        my ($src, $dest, $label, $weight, $viz) = @$edge;
        my $viz_str = _fmt_viz($viz);
        my $suffix = ($viz_str) ? ">$viz_str</edge>" : " />";
        print $fh sprintf qq{\t<edge id="%s" source="%s" target="%s" label="%s" weight="%s"%s\n},
                $id, $src, $dest, ::xml_escape($label), $weight, $suffix;
    }
    print $fh qq{</edges>\n};

    print $fh qq{</graph>\n</gexf>\n};
}

sub emit_link {
    my ($self, $link_id, $dest_id, $attr) = @_;
    my $fh = $self->fh or return;
    my $link_node = $seqn2node{$link_id} or die "No node for id $link_id";

    my @link_attr = ("id=$link_id");
    if ($attr->{kind} and $attr->{kind} eq 'addr') {
        push @link_attr, 'arrowhead="empty"', 'style="dotted"';
    }
    else {
        push @link_attr, ($attr->{hard}) ? () : ('style="dashed"');
    }
    my $link_name = $link_node->{attr}{label} || $link_node->{name};

    my $label = _dotlabel($link_name, $link_node),
    my $weight = 1;
    my %viz;

    my $new = [ $link_node->{parent_id}, $dest_id, $label, $weight, \%viz ];
    #push @$new, Carp::longmess('');
    if (my $old = $buffered_edges{$link_id}) {
        return;
        cluck "\nduplicate edge $link_id:\nold: @$old\nnew: @$new"
    }
    $buffered_edges{$link_id} = $new;
}

=pod
<node id="646" label="java.beans.PropertyEditorManager">
<viz:size value="4.18782"/>
<viz:color b="2" g="110" r="254"/>
<viz:position x="102.81538" y="-427.74304" z="0.0"/>
</node>
=cut

sub _emit_node {
    my ($self, $id, $label, $attr, $viz) = @_;
    my $fh = $self->fh or return;

    warn "no label for node $id\n" unless $label;
    printf $fh qq{\t<node id="%s" label="%s">\n}, $id, ::xml_escape($label||'');
    if (keys %$attr) {
        print $fh qq{\t<attvalues>\n};
        for my $k (sort keys %$attr) {
            my $v = $attr->{$k};
            next if not defined $v;
            printf $fh qq{\t\t<attvalue for="%s" value="%s"/>\n},
                $k, ::xml_escape($v);
        }
        print $fh qq{\t</attvalues>\n};
    }
    print $fh qq{\t</node>\n};
}

sub emit_item_node {
    my ($self, $item_node, $attr) = @_;
    my %attr = (
        nsb => $item_node->{self_size},
        nkb => $item_node->{kids_size},
        ntb => $item_node->{self_size}+$item_node->{kids_size},
        nrc => $item_node->{refcnt},
        name => $item_node->{name},
    );
    my %viz;
    my $label = _dotlabel($attr->{label}||$item_node->{name}, $item_node);
    $self->_emit_node($item_node->{id}, $label, \%attr, \%viz);
}

sub emit_addr_node {
    my ($self, $addr, $labels, $attr) = @_;

    # output a dummy node for this addr for the links to connect to
    my @node_attr = ('color="grey60"', 'style="rounded,dotted"');
    push @node_attr, (sprintf "label=%s", _dotlabel($labels));

    my %attr;
    #push @attr, $self->label_attr->fmt_data(_dotlabel(\@label));
    $self->_emit_node($addr, join("\n",@$labels), \%attr);
}

sub fmt_item_label {
    my ($self, $item_node) = @_;
    my @name;
    push @name, "\"$item_node->{attr}{label}\""
        if $item_node->{attr}{label};
    push @name, $item_node->{name};
    return \@name;
}


sub _dotlabel {
    my ($name, $node) = @_;
    my @names = (ref $name) ? @$name : ($name);
    $name = join " ", map {
        # escape unprintables XXX correct sins against unicode
        s/([\000-\037\200-\237])/sprintf("\\x%02x",ord($1))/eg;
        $_;
    } @names;
    return qq{$name};
}

} # END



# http://www.graphviz.org/content/attrs
BEGIN {
package Devel::SizeMe::Output::Graphviz;
use Moo;
use autodie;
use Carp qw(croak);
use HTML::Entities qw(encode_entities);;

extends 'Devel::SizeMe::Output';

has fh => (is => 'rw');

*fmt_size = \&main::fmt_size;

sub create_output {
    my $self = shift;
    open my $fh, ">", $self->file;
    $self->fh($fh);
    $self->fh->autoflush if $opt_debug;
}

sub close_output {
    my $self = shift;
    close($self->fh);
    $self->fh(undef);
}

sub view_output {
    my $self = shift;
    $self->SUPER::view_output(@_);

    my $file = $self->file;
    if ($file ne '/dev/tty') {
        #system("dot -Tsvg $file > sizeme.svg && open sizeme.svg");
        #system("open sizeme.html") if $^O eq 'darwin'; # OSX
        system("open -a Graphviz $file") if $^O eq 'darwin'; # OSX
    }
}

sub write_prologue {
    my $self = shift;
    my $fh = $self->fh or return;
    $self->SUPER::write_prologue(@_);
    print $fh "digraph {\n"; # }
    print $fh "graph [overlap=false, rankdir=LR]\n"; # target="???", URL="???"
}

sub write_epilogue {
    my $self = shift;
    my $fh = $self->fh or return;
    $self->SUPER::write_epilogue(@_);
    # { - balancing brace for the next line:
    print $fh "}\n";
}

sub emit_link {
    my ($self, $link_id, $dest_id, $attr) = @_;
    my $fh = $self->fh or return;
    my $link_node = $seqn2node{$link_id} or die "No node for id $link_id";

    my @link_attr = ("id=$link_id");
    if ($attr->{kind} and $attr->{kind} eq 'addr') {
        push @link_attr, 'arrowhead="empty"', 'style="dotted"';
    }
    else {
        push @link_attr, ($attr->{hard}) ? () : ('style="dashed"');
    }

    (my $link_name = $link_node->{attr}{label} || $link_node->{name}) =~ s/->$//; # XXX hack
    push @link_attr, (sprintf "label=%s", _dotlabel($link_name, $link_node));
    printf $fh qq{n%d -> n%d [%s];\n},
        $link_node->{parent_id}, $dest_id, join(",", @link_attr);
}

sub emit_addr_node {
    my ($self, $addr, $labels, $attr) = @_;
    my $fh = $self->fh or return;

    # output a dummy node for this addr for the links to connect to
    my @node_attr = ('color="grey60"', 'style="rounded,dotted"');
    push @node_attr, (sprintf "label=%s", _dotlabel($labels));
    printf $fh qq{n%d [%s];\n},
        $addr, join(",", @node_attr);
}

sub emit_item_node {
    my ($self, $item_node, $attr) = @_;
    my $fh = $self->fh or return;
    my $name = $self->fmt_item_label($item_node); # $attr->{label};
    my @node_attr = ( "id=$item_node->{id}" );
    push @node_attr, sprintf("label=%s", _dotlabel($name, $item_node))
        if $name;
    printf $fh qq{n%d [ %s ];\n}, $item_node->{id}, join(",", @node_attr);
}

sub fmt_item_label {
    my ($self, $item_node) = @_;
    my @name;
    push @name, "\"$item_node->{attr}{label}\""
        if $item_node->{attr}{label};
    push @name, $item_node->{name};
    if ($item_node->{kids_size}) {
        push @name, sprintf " %s+%s=%s",
            fmt_size($item_node->{self_size}),
            fmt_size($item_node->{kids_size}),
            fmt_size($item_node->{self_size}+$item_node->{kids_size});
    }
    else {
        push @name, sprintf " +%s",
            fmt_size($item_node->{self_size});
    }
    return \@name;
}


sub _dotlabel {
    my ($name, $node) = @_;
    my @names = (ref $name) ? @$name : ($name);
    $name = join "\\n", map {
        # escape unprintables XXX correct sins against unicode
        s/([\000-\037\200-\237])/sprintf("\\x%02x",ord($1))/eg;
        encode_entities($_)
    } @names;
    $name .= "\\n#$node->{id}" if $opt_showid && $node;
    return qq{"$name"};
}

} # END

BEGIN {
package Devel::SizeMe::Output::Easy;
use Moo;
use autodie;
use Carp qw(croak);
use HTML::Entities qw(encode_entities);;

extends 'Devel::SizeMe::Output';

has as => (is => 'rw', required => 1);
has graph => (is => 'rw');

*fmt_size = \&main::fmt_size;

sub create_output {
    my $self = shift;
    require Graph::Easy;
    my $graph = Graph::Easy->new();
    $graph->id('sizeme');
    $self->graph($graph);
}

sub close_output {
    my $self = shift;
    my $graph = $self->graph;
    $graph->set_attribute('root', 1);
    my %as_to_file = ($self->as, $self->file);
    $as_to_file{as_graphviz} = 'sizeme_eg.dot';
    # These trigger layout which is slooooow for more than a few node
    #$as_to_file{as_ascii} = 'sizeme_eg.txt';
    #$as_to_file{as_html} = 'sizeme_eg.html';
    #$as_to_file{as_svg} = 'sizeme_eg.svg';
    while ( my ($as, $file) = each %as_to_file) {
        warn "Writing graph $as to $file...\n" if $opt_debug or 1;
        open my $fh, ">", $file;
        print $fh $graph->$as();
        close $fh;
    }
}

sub view_output {
    my $self = shift;
    $self->SUPER::view_output(@_);

    my $file = $self->file;
    if ($file ne '/dev/tty') {
        #system("dot -Tsvg $file > sizeme.svg && open sizeme.svg");
        #system("open sizeme.html") if $^O eq 'darwin'; # OSX
        #system("open -a Graphviz $file") if $^O eq 'darwin'; # OSX
    }
}

sub emit_link {
    my ($self, $link_id, $dest_id, $attr) = @_;

    my $link_node = $seqn2node{$link_id} or die "No node for id $link_id";
    my $edge = $self->graph->add_edge($link_node->{parent_id}, $dest_id);

    (my $link_name = $link_node->{attr}{label} || $link_node->{name}) =~ s/->$//; # XXX hack
    my %attr = ( label => $link_name );

    if ($attr->{kind} and $attr->{kind} eq 'addr') {
        $attr{style} = 'dotted';
        $attr{arrowstyle} = 'closed';
        $attr{labelcolor} = 'grey50';
        $attr{color} = 'grey50';
    }
    else {
        $attr{style} = 'dotted' if not $attr->{hard};
    }
    $edge->set_attributes(\%attr);
}

sub emit_addr_node {
    my ($self, $addr, $labels, $attr) = @_;
    my $node = $self->graph->add_node($addr);

    my %attr = (
        label => join("\n", @$labels),
        color => "grey50",
        borderstyle => 'dotted',
    );

    $node->set_attributes(\%attr);
}

sub emit_item_node {
    my ($self, $item_node, $attr) = @_;
    my $node = $self->graph->add_node($item_node->{id});
    my %attr = (
        label => $attr->{label},
        'x-self_size' => $item_node->{self_size},
        'x-kids_size' => $item_node->{kids_size},
        'x-size'      => $item_node->{self_size}+$item_node->{kids_size},
    );
    $node->set_attributes(\%attr);
}

sub fmt_item_label {
    my ($self, $item_node) = @_;
    my @name;
    push @name, "\"$item_node->{attr}{label}\""
        if $item_node->{attr}{label};
    push @name, $item_node->{name};
    if ($item_node->{kids_size}) {
        push @name, sprintf " %s+%s=%s",
            fmt_size($item_node->{self_size}),
            fmt_size($item_node->{kids_size}),
            fmt_size($item_node->{self_size}+$item_node->{kids_size});
    }
    else {
        push @name, sprintf " +%s",
            fmt_size($item_node->{self_size});
    }
    push @name, "#$item_node->{id}" if $opt_showid && $item_node;
    encode_entities($_, '\x00-\x1f') for @name;
    return join("\n", @name);
}

} # END


# based on https://metacpan.org/source/SHLOMIF/Graph-Easy-0.72/lib/Graph/Easy/As_graphml.pm#L221
# and https://metacpan.org/source/SZABGAB/SVG-2.59/lib/SVG/XML.pm#L47
sub ::xml_escape {
    local $_ = shift
        or return $_;
    #carp "xml_escape called with undef" if not defined $_;

    s/&/&amp;/g;    # quote &
    s/>/&gt;/g;     # quote >
    s/</&lt;/g;     # quote <
    s/"/&quot;/g;   # quote "
    s/'/&apos;/g;   # quote '
    s/\\\\/\\/g;    # "\\" to "\"

    # Invalid XML characters are removed and warned about
    # Tabs (\x09) and newlines (\x0a) are valid.
    while ( s/([\x00-\x08\x0b\x1f])// ) {
        my $char = "'\\x".sprintf('%02X',ord($1))."'";
        Carp::carp("Removed $char from xml");
    }
    s/([\200-\377])/'&#'.ord($1).';'/ge;

    return $_;
}


=for This is out of date but gives you an idea of the data and stream

SV(PVAV) fill=1/1       [#1 @0] 
:   +64 sv =64 
:   +16 av_max =80 
:   AVelem->        [#2 @1] 
:   :   SV(RV)      [#3 @2] 
:   :   :   +24 sv =104 
:   :   :   RV->        [#4 @3] 
:   :   :   :   SV(PVAV) fill=-1/-1     [#5 @4] 
:   :   :   :   :   +64 sv =168 
:   AVelem->        [#6 @1] 
:   :   SV(IV)      [#7 @2] 
:   :   :   +24 sv =192 
192 at -e line 1.
=cut
__DATA__
N 1 0 SV(PVAV) fill=1/1
L 1 64 sv
L 1 16 av_max
N 2 1 AVelem->
N 3 2 SV(RV)
L 3 24 sv
N 4 3 RV->
N 5 4 SV(PVAV) fill=-1/-1
L 5 64 sv
N 6 1 AVelem->
N 7 2 SV(IV)
L 7 24 sv
