package Embedix::DB::Pg;

use strict;
use vars qw($AUTOLOAD);

# for warning message from the caller's perspective
use Carp;

# for loading data from files
use Embedix::ECD;

# for database support
use DBI;

# constructor
#_______________________________________
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    (@_ & 1) && croak("Odd number of parameters.");
    my %opt   = @_;

    my $dbh  = DBI->connect(@{$opt{source}}) || croak($DBI::errstr);
    my $self = {
        dbh        => $dbh,
        distro     => undef,    # hashref w/ info on current working distro
        path_cache => { },      # $path_cache->{node_id} eq $path
    };
    bless($self => $class);

    #self->workOnDistro(name => $opt{name}, board => $opt{board});
    return $self;
}

# destructor
#_______________________________________
sub DESTROY {
    my $self = shift;
    $self->{dbh}->disconnect();
}

# for when things go wrong...
#_______________________________________
sub rollbackAndCroak {
    my $self = shift;
    my $msg  = shift;
    my $dbh  = $self->{dbh};
    my $err  = $dbh->errstr . "\n$msg";
    $dbh->rollback;
    croak($err);
}

# $insert_statement = $hotel->buildInsertStatement (
#     table => "table",
#     data  => \%column
# );
#_______________________________________
sub buildInsertStatement {
    my $self = shift;
    my $dbh  = $self->{dbh};

    (@_ & 1) && croak "Odd number of parameters\n";
    my %opt    = @_;
    my $column = $opt{data};

    my $insert = "insert into $opt{table} ( ";
    $insert .= join(", ", keys %$column);
    $insert =~ s/, $//;
    $insert .= " ) values ( ";
    $insert .= join(", ", map { $dbh->quote($_) } values %$column);
    $insert =~ s/, $//;
    $insert .= " );";

    return $insert;
}

# $update_statement = $hotel->buildUpdateStatement (
#     table => "table",
#     data  => \%column,
#     where => "id = 'whatever'",
#     primary_key => 'id',
# );
#
# note that you should use 'where' xor 'primary_key'.
# do not use both at the same time
# use at least one of them.  ...xor
#_______________________________________
sub buildUpdateStatement {
    my $self = shift;
    my $dbh  = $self->{dbh};

    (@_ & 1) && croak "Odd number of parameters\n";
    my %opt    = @_;
    my $column = $opt{data};

    my $update = "update $opt{table} set ";
    foreach (keys %$column) {
        $update .= "$_ = " . $dbh->quote($column->{$_}) . ", ";
    }
    $update =~ s/, $//;

    $update .= " where ";
    if (defined $opt{where}) {
        $update .= "$opt{where};";
    } elsif (defined $opt{primary_key}) {
        my $pk = $opt{primary_key};
        $update .= "$pk = '$column->{$pk}';";
    } else {
        croak "buildUpdateStatement w/o a WHERE clause\n";
    }

    return $update;
}

# return the current value of a sequence.
# This is a front end to PostgreSQL's currval() function.
#_______________________________________
sub currval {
    my $self = shift;
    my $seq  = shift;
    my $dbh  = $self->{dbh};
    my $sth  = $dbh->prepare("select currval('$seq')");
    $sth->execute;
    my @val  = $sth->fetchrow_array;
    $sth->finish;
    return $val[0];
}

# return the next value of a sequence.
# This is a front end to PostgreSQL's currval() function.
#_______________________________________
sub nextval {
    my $self = shift;
    my $seq  = shift;
    my $dbh  = $self->{dbh};
    my $sth  = $dbh->prepare("select nextval('$seq')");
    $sth->execute;
    my @val  = $sth->fetchrow_array;
    $sth->finish;
    return $val[0];
}

# Set the distribution that database opererations will work on.
# If the distribution is not found, this method will croak().
#_______________________________________
sub workOnDistro {
    my $self = shift; (@_ & 1) && croak("Odd number of parameters.");
    my %opt  = @_;

    defined($opt{name})  || croak('name => REQUIRED!');
    defined($opt{board}) || croak('board => REQUIRED!');
    
    # get distro from database
    my $q = qq{ select * from distro where distro_name = ? and board = ? };
    my $dbh = $self->{dbh};
    my $sth = $dbh->prepare($q);
    
    $sth->execute($opt{name}, $opt{board});
    my $distro = $sth->fetchrow_hashref();
    $sth->finish;

    if (defined($distro)) {
        $self->{distro} = $distro;
    } else {
        croak("$opt{name} for $opt{board} was not found.");
    }

    # reinitialize caches
    $self->{path_cache} = { };

    return $self->{distro};
}

# adds an new entry into the distro table as well as an entry
# in the node table for the root node.
#_______________________________________
sub addDistro {
    my $self = shift; (@_ & 1) && croak("Odd number of parameters.");
    my %opt  = @_;
    my $dbh  = $self->{dbh};
    my ($sth1, $sth2, $q);

    # get root_node_id
    my $root_node_id = defined($opt{root_node_id})
        ? $opt{root_node_id}
        : $self->nextval('node_node_id_seq');

    # distro table entry
    my $distro = {
        distro_name  => $opt{name}          || croak("name required"),
        board        => $opt{board}         || croak("board required"),
        description  => $opt{description}   || "no description available",
        root_node_id => $root_node_id,
    };
    $q = $self->buildInsertStatement(table => "distro", data => $distro);
    $sth1 = $dbh->prepare($q);
    $sth1->execute || do { $self->rollbackAndCroak($q) };
    $sth1->finish;

    # get distro_id
    my $distro_id = $self->currval('distro_distro_id_seq');
    $distro->{distro_id} = $distro_id;

    # root node
    my $root = {
        node_id    => $root_node_id,
        node_name  => 'ecd',
        node_class => 'Root',
    };

    # make a root node if necessary
    unless (defined($opt{root_node_id})) {
        $q = $self->buildInsertStatement(table => "node", data => $root);
        $sth2 = $dbh->prepare($q);
        $sth2->execute || do { $self->rollbackAndCroak($q) };
        $sth2->finish;
        #rint STDERR "[edb relating: $root->{node_id} To: $distro->{distro_id}]\n";
        $self->relateNode(node => $root, distro => $distro);
    }
    $dbh->commit;
    return $distro;
}

# associate a node with a distro by adding an entry
# to the node_distro table
#_______________________________________
sub relateNode {
    my $self = shift; (@_ & 1) && croak("Odd number of parameters.");
    my %opt  = @_;
    defined ($opt{node})   || croak('node => REQUIRED!');
    defined ($opt{distro}) || croak('distro => REQUIRED!');
    my $dbh  = $self->{dbh};
    my $s    = qq/
        insert into node_distro (node_id, distro_id)
        values ($opt{node}{node_id}, $opt{distro}{distro_id})
    /;
    $dbh->do($s) || $self->rollbackAndCroak($s);
}

# remove association of node from distro by deleting an entry
# in the node_distro table
#_______________________________________
sub unrelateNode {
    my $self = shift; (@_ & 1) && croak("Odd number of parameters.");
    my %opt  = @_;
    defined ($opt{node})   || croak('node => REQUIRED!');
    defined ($opt{distro}) || croak('distro => REQUIRED!');
    my $dbh  = $self->{dbh};
    my $s    = qq/
        delete from node_distro 
         where node_id   = $opt{node}{node_id} 
           and distro_id = $opt{distro}{distro_id}
    /;
    $dbh->do($s) || $self->rollbackAndCroak($s);

}

# using the current working distro, make an exact
# clone for another architecture.
#_______________________________________
sub cloneDistro {
    my $self = shift; (@_ & 1) && croak("Odd number of parameters.");
    my %opt  = @_;
    my $dbh  = $self->{dbh};

    defined($opt{board}) || croak('board => REQUIRED!');

    # get root_node_id
    my $root_node_id = $self->{distro}{root_node_id};

    # cloned distro entry
    my $distro = $self->{distro};
    my $clone  = $self->addDistro (
        name         => $distro->{distro_name},
        board        => $opt{board},
        description  => $opt{description} || $distro->{description},
        root_node_id => $root_node_id,
    );

    # get distro_id
    my $distro_id = $self->currval('distro_distro_id_seq');
    $clone->{distro_id} = $distro_id;

    # node_id collection
    my $s = qq/
        select n.node_id
          from node n, node_distro nd
         where n.node_id = nd.node_id
               and nd.distro_id = $self->{distro}{distro_id}
    /;
    my $node_list = $dbh->selectall_arrayref($s);

    # node_distro manipulation
    $s = qq/ insert into node_distro (node_id, distro_id) values (?, ?) /;
    my $sth = $dbh->prepare_cached($s);
    my $node;
    foreach $node (@$node_list) {
        $sth->execute($node->[0], $distro_id) 
            || $self->rollbackAndCroak($node->[0]);
    }
    $sth->finish;
    $dbh->commit;
    return $clone;
}

# delete a node and all its children
#_______________________________________
sub deleteNode {
    my $self = shift; (@_ & 1) && croak("Odd number of parameters.");
    my %opt  = @_;
    my $dbh  = $self->{dbh};

    $dbh->do("delete from node where node_id = $opt{node_id}")
        || $self->rollbackAndCroak("failed delete");
}

#_______________________________________
sub selectNode {
    my $self = shift; (@_ & 1) && croak("Odd number of parameters.");
    my %opt  = @_;

    my $q = qq(
        select n.node_id,
               n.node_class,
               n.node_name,
               n.value,
               n.value_type,
               n.default_value,
               n.range,
               n.help,
               n.prompt,
               n.srpm,
               n.specpatch,
               n.static_size, n.min_dynamic_size, 
               n.storage_size, n.startup_time
          from node n, node_parent np, node_distro nd
         where n.node_id        = np.node_id
               and n.node_id    = nd.node_id
               and nd.distro_id = $self->{distro}{distro_id}
               and n.node_name  = ?
               and np.parent_id = ?
    );

    my $dbh = $self->{dbh};
    my $sth = $dbh->prepare($q);
    my ($name, $parent_id);
    if (defined $opt{path}) {

        # XXX => implement getIdForPath()

    } else {
        $name      = $opt{name};
        $parent_id = $opt{parent_id};
    }
    $sth->execute($name, $parent_id);
    my $node = $sth->fetchrow_hashref;  # there can only be one
    $sth->finish;
    return $node;
}

# prereq => no provides entry for $node_id must exist
#_______________________________________
sub insertProvides {
    my $self     = shift;
    my $provides = shift;
    return unless ($provides);
    my $node_id  = shift || croak("node_id REQUIRED!");
    my $dbh      = $self->{dbh};
    my %item;

    my $s = qq{ insert into provides (node_id, entry) values ( ?, ? ) };
    my $sth = $dbh->prepare($s);
    $provides = [ $provides ] unless (ref($provides));
    foreach (@$provides) {
        next if /^$/;
        if (defined $item{$_}) {
            carp("[ $node_id, $_ ] already exists");
        } else {
            $item{$_} = 1;
            $sth->execute($node_id, $_) ||
                croak("[ $node_id, $_ ] " . $dbh->errstr);
        }
    }
    $sth->finish;
}

# prereq => no keeplist entry for $node_id must exist
#_______________________________________
sub insertKeeplist {
    my $self     = shift;
    my $keeplist = shift;
    return unless ($keeplist);
    my $node_id  = shift || croak("node_id REQUIRED!");
    my $dbh      = $self->{dbh};
    my %item;

    my $s = qq{ insert into keeplist (node_id, entry) values ( ?, ? ) };
    my $sth = $dbh->prepare($s);
    $keeplist = [ $keeplist ] unless (ref($keeplist));
    foreach (@$keeplist) {
        next if /^$/;
        if (defined $item{$_}) {
            carp("[ $node_id, $_ ] already exists");
        } else {
            $item{$_} = 1;
            $sth->execute($node_id, $_) ||
                croak("[ $node_id, $_ ] " . $dbh->errstr);
        }
    }
    $sth->finish;
}

# prereq => no build_vars entry for $node_id must exist
#_______________________________________
sub insertBuildVars {
    my $self     = shift;
    my $build_vars = shift;
    return unless ($build_vars);
    my $node_id  = shift || croak("node_id REQUIRED!");
    my $dbh      = $self->{dbh};
    my %item;

    my $s = 'insert into build_vars (node_id, name, value) values (?, ?, ?)';
    my $sth = $dbh->prepare($s);
    $build_vars = [ $build_vars ] unless (ref($build_vars));
    foreach (@$build_vars) {
        next if /^$/;
        my ($n, $v) = split(/\s*=\s*/);
        if (defined $item{$n}) {
            carp("[ $node_id, $n ] already exists");
        } else {
            $item{$n} = 1;
            $sth->execute($node_id, $n, $v) ||
                croak("[ $node_id, $_ ] " . $dbh->errstr);
        }
    }
    $sth->finish;
}

#_______________________________________
sub insertNode {
    my $self = shift; (@_ & 1) && croak("Odd number of parameters.");
    my %opt  = @_;

    my $ecd  = $opt{ecd} || croak('ecd => REQUIRED!');

    # insert into node table
    my $node = $self->hashrefFromECD($ecd);
    my $s    = $self->buildInsertStatement(table => "node", data => $node);
    my $dbh  = $self->{dbh};
    my $sth  = $dbh->prepare($s);

    $sth->execute || do { $self->rollbackAndCroak($s) };
    $sth->finish;
    my $id = $node->{node_id} = $self->currval('node_node_id_seq');

    # insert aggregate attributes
    eval {
        $self->insertProvides($ecd->provides, $id);
        $self->insertKeeplist($ecd->keeplist, $id);
        $self->insertBuildVars($ecd->build_vars, $id);
    };
    if ($@) { $self->rollbackAndCroak($@) }

    # insert into node_parent table
    my $np   = { node_id => $id, parent_id => $opt{parent_id} };
    my $s2   = $self->buildInsertStatement(table=> "node_parent", data=> $np);
    my $sth2 = $dbh->prepare($s2);
    $sth2->execute || do { $self->rollbackAndCroak($s2) };
    $sth2->finish;

    # insert into node_distro_table
    $self->relateNode(node => $node, distro => $self->{distro});

    $dbh->commit;
    return $node;
}

# XXX : deal w/ aggregate attributes
#_______________________________________
sub updateNode {
    my $self = shift; (@_ & 1) && croak("Odd number of parameters.");
    my %opt  = @_;

    my $ecd  = $opt{ecd} || croak('ecd => REQUIRED!');

    my $node = $self->hashrefFromECD($ecd);
    $node->{node_id} = $opt{node_id} || croak('node_id => REQUIRED!');
    my $s    = $self->buildUpdateStatement(
        table       => "node", 
        data        => $node,
        primary_key => "node_id",
    );
    my $dbh  = $self->{dbh};
    my $sth  = $dbh->prepare($s);

    $sth->execute || do { $self->rollbackAndCroak($s) };
    $sth->finish;

    # nuke aggregate attributes from orbit (it's the only way to be sure)

    # insert aggregate attributes XXX

    $dbh->commit;
    return $node;
}

# Create a hashref suitable for insertion into the node table.
# This does NOT handle aggregates (but it does handle the range pair).
#_______________________________________
my @node_attribute = qw(
    value type default_value range help prompt srpm specpatch 
    requires requiresexpr
);
my @node_eval_attribute = qw(
    static_size min_dynamic_size storage_size startup_time
);
sub hashrefFromECD {
    my $self = shift;
    my $ecd  = shift;
    my %node = (
        node_class => $ecd->getNodeClass(),
        node_name  => $ecd->name(),
    );
    my $attr;
    foreach (@node_attribute) {
        if (defined($attr = $ecd->getAttribute($_))) {
            if (ref($attr)) {
                $attr = join("\n", @$attr);
            }
            if ($_ eq "range") {
                my ($x, $y) = split($attr, ":");    # turn it into a pg array
                $attr = "{$x, $y}";
            }
            $node{$_} = $attr;
        }
    }
    foreach (@node_eval_attribute) {
        if (defined($attr = $ecd->getAttribute($_))) {
            my $eval_method = "eval_$_";
            my ($size, $give_or_take) = $ecd->$eval_method();
            $attr = "{$size, $give_or_take}";
            $node{$_} = $attr;
        }
    }
    if (defined $node{type}) {
        $node{value_type} = $node{type};
        delete($node{type});
    }
    warn("$node{node_name} has a requires and requiresexpr which is bad.")
        if (defined $node{requires} && defined($node{requiresexpr}));
    if (defined $node{requires}) {
        $node{requires_type} = 'list';
    }
    if (defined $node{requiresexpr}) {
        $node{requires_type} = 'expr';
        $node{requires} = $node{requiresexpr};
        delete($node{requiresexpr});
    };
    return \%node;
}

# add info in $ecd to current working distribution
#_______________________________________
sub updateDistro {
    my $self = shift; (@_ & 1) && croak("Odd number of parameters.");
    my %opt  = @_;
    my $ecd       = $opt{ecd}       || croak("ecd => REQUIRED!");
    my $parent_id = $opt{parent_id} || undef;
    my ($child, $node);

    unless (defined($self->{distro})) {
        croak("Cannot add an ECD until a distribution to work on is selected.");
    }

    if ($ecd->getDepth == 0) {
        # handle root nodes (root node identification could be more robust)
        $node = { };
        $node->{node_id} = $self->{distro}{root_node_id};
    } else {
        # all other nodes
        $node = $self->selectNode(
            name      => $ecd->name(),
            parent_id => $parent_id,
        );
        if (defined($node)) {
            $node = $self->updateNode(ecd => $ecd, node_id => $node->{node_id});
        } else {
            $node = $self->insertNode(ecd => $ecd, parent_id => $parent_id);
        };
    }

    foreach $child ($ecd->getChildren) {
        $self->updateDistro(ecd => $child, parent_id => $node->{node_id});
    }
}

# get node_id for a given path
#_______________________________________
sub getIdForPath {
    my $self = shift;
    my $path = shift;

}

# return full path of a node
#_______________________________________
sub getNodePath {
    my $self = shift;
    my $id   = shift;
    my $p    = $self->{path_cache};

    my $root_node_id = $self->{distro}{root_node_id};
    if ($id == $root_node_id) {
        return '/';
    }
    my $distro_id = $self->{distro}{distro_id};

    unless (defined $p->{$id}) {
        my $q = qq{ 
            select n.node_id, n.node_name, np.parent_id 
              from node n, 
                   node_parent np, 
                   node_distro nd
             where n.node_id        = np.node_id
                   and n.node_id    = nd.node_id
                   and nd.distro_id = $distro_id
                   and n.node_id    = ?
        };
        my $sth = $self->{dbh}->prepare($q);
        my $i   = $id;
        my @path;
        my $node;
        do {
            $sth->execute($i);
            $node = $sth->fetchrow_hashref;
            $i = $node->{parent_id};
            unshift(@path, $node->{node_name});
            $sth->finish;
        } while ($i != $root_node_id);
        $p->{$id} = '/' . join('/', @path);
    }
    return $p->{$id};
}

# return an arrayref of component names of the form
# [ 
#   [ "category0", [ $node, ... ] ],
#   [ "category1", [ $node, ... ] ],
#   ...
# ] 
# where $node is [ n.node_id, n.node_name ], and it's all SORTED -- yay!
#_______________________________________
sub getComponentList {
    my $self = shift;
    my $dbh  = $self->{dbh};

    my $q = qq#
        select np.parent_id, n.node_id, n.node_name 
          from node n, 
               node_parent np, 
               node_distro nd
         where n.node_id        = np.node_id
               and n.node_id    = nd.node_id
               and n.node_class = 'Component'
               and nd.distro_id = $self->{distro}{distro_id}
    #;

    # get them all categorized
    my (%cat, $path, $comp, $list);
    $list = $dbh->selectall_arrayref($q);
    foreach $comp (@$list) {
        $path = $self->getNodePath($comp->[0]);
        if (defined $cat{$path}) {
            push(@{$cat{$path}}, [$comp->[1], $comp->[2]]);
        } else {
            my $first   = [ [$comp->[1], $comp->[2]] ];
            $cat{$path} = $first;
        }
    }

    # sort each category
    my @cl;
    foreach (sort keys %cat) {
        $list = $cat{$_};
        my $sorted_list = [ sort { $a->[1] cmp $b->[1] } @$list ];
        push @cl, [ $_, $sorted_list ];
    }
    return \@cl;
}

#
#_______________________________________
sub getDistroList {
    my $self = shift;
    my $dbh  = $self->{dbh};
    my $q    = qq/select distro_name, board, description from distro/;
    my $list = $dbh->selectall_arrayref($q);

    # get them grouped by distribution
    my (%board_list, $distro, $cat);
    foreach $distro (@$list) {
        $cat = $board_list{$distro->{distro_name}} ||= [ ];
        push @$cat, $distro;
    }

    # sort
    my @dl;
    foreach (sort keys %board_list) {
        $list = $board_list{$_};
        my $sorted_list = [ sort { $a->[0] cmp $b->[0] } @$list ];
        push @dl, [ $_, $sorted_list ];
    }
    return \@dl;
}

# need to do something clever here
#_______________________________________
sub AUTOLOAD {
    croak('Help beppu@cpan.org think of a clever use for AUTOLOAD.');
}

1;

__END__

=head1 NAME

Embedix::DB::Pg - PostgreSQL back-end for Embedix::DB

=head1 SYNOPSIS

The API presented here is subject to change.  I haven't figured
out all the details, yet.

instantiation

    $ebx = Embedix::DB::Pg->new (
        source => [ 
            'dbi:Pg:dbname=embedix', $user, $pass, 
            { AutoCommit => 0 } 
        ],
    );

adding a new distribution

    $ebx->addDistro (
        arch        => 'm68k',      # maybe in the future?
        name        => 'uClinux',
        description => 'Linux for MMU-less architectures',
    );

selecting a default distro to work on

    $ebx->workOnDistro('Embedix 1.2');

updating a distro with information from an ECD

    my $ecd = Embedix::ECD->newFromFile('apache.ecd');
    $ebx->updateDistro($ecd);

=head1 REQUIRES

=over 4

=item Embedix::ECD

=item DBI

=item DBD::Pg

=back

=head1 DESCRIPTION

a brief summary of the module written with users in mind.

=head1 METHODS

=head2 Constructor

=over 4

=item new(backend => ..., source => [ ... ])

    $edb = Embedix::DB::Pg->new (
        backend => 'Pg',
        source  => [ 'dbi:Pg:dbname=embedix', $user, $password ],
    );

=back

=head2 Administration Methods

=over 4

=item addDistro( name => ..., description => ...)

    $distro = $edb->addDistro (
        name        => $string,
        description => $another_string,
    );      

=item workOnDistro('name of distribution')

    $distro = $edb->workOnDistro(
        distro => 'Embedix 1.2',
        board  => 'i386',
    );

=item updateDistro(ecd => $ecd, parent_id => $id)

    $edb->updateDistro(ecd => $ecd);

=item cloneDistro(board => ...);

    $edb->cloneDistro(board => $_) foreach qw(ppc mips m68k sh);

=back

=head2 Client Methods

=over 4

=item getComponentList

    my $cl = $edb->getComponentList;

=item getDistroList

    my $dl = $edb->getDistroList;

=back

=head1 DIAGNOSTICS

error messages

=head1 COPYRIGHT

Copyright (c) 2000,2001 John BEPPU.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 AUTHOR

John BEPPU <beppu@lineo.com>

=head1 SEE ALSO

=over 4

=item related perl modules

=item the latest version

=back

=cut
