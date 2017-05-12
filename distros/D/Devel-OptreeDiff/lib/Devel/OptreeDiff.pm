package Devel::OptreeDiff;
BEGIN {
  $Devel::OptreeDiff::VERSION = '2.3';
}
use strict;
use warnings;
use base 'Exporter';
use Algorithm::Diff qw();
use B qw( svref_2object class cstring sv_undef walkoptree );
use B::Utils qw();
use vars qw( @EXPORT_OK
    %SIDES
    %ADDR %DONE_GV %LINKS @NODES @specialsv_name );

@EXPORT_OK = 'fmt_optree_diff';

@specialsv_name
    = qw( Nullsv &PL_sv_undef &PL_sv_yes &PL_sv_no (SV*)pWARN_ALL (SV*)pWARN_NONE (SV*)pWARN_STD );

# Create several functions as a wrapper over the functions from
# Algorithm::Diff.
BEGIN {
    for my $method (
        qw( LCS
        diff
        sdiff
        traverse_sequences
        traverse_balanced )
        )
    {
        push @EXPORT_OK, "optree_$method";

        ## no critic eval
        eval "sub " . __PACKAGE__ . "::optree_$method {
            local %SIDES;
            my \@a = as_string( a =>
                                svref_2object( \$_[0] )->ROOT );
            my \@b = as_string( b =>
                                svref_2object( \$_[1] )->ROOT );
            my \@a_names = map { s/^(\\S+) // ? \$1 : \$_ } \@a;
            my \@b_names = map { s/^(\\S+) // ?\$1 : \$_ } \@b;

            my \@diff = 
            Algorithm::Diff::$method
            ( # The first two parameters are transformed into the
              # data that this module will be capable of handling
              # a diff on.
              \\\@a, \\\@b,
              
              # All the additional parameters, if any are passed
              # directly through to Algorithm::Diff::$method
              \@_[ 2 .. \$#_ ]);

           for my \$chunk ( \@diff )
           {
               for my \$line ( \@\$chunk )
               {
                   \$line->[2] = ( \$line->[0] eq '+'
                                   ? \$b_names[\$line->[1]]
                                   : \$a_names[\$line->[1]] )
                                 . \".\$line->[2]\";
                   \$line->[2] =~ s/^([^.]+)\\.\\1\\s*/\$1/;
               }
           }
           \@diff;
        }

        1 "
            or die $@;
    }
}

sub fmt_optree_diff {
    my @chunks = map join( "", map "$_->[0] $_->[2]\n", @$_ ), &optree_diff;
    for my $chunk (@chunks) {
        my %seen;

        # Elide redundant node paths
        $chunk =~ s((?<=^..)([^.\s]+)){
            ( $seen{$1}++
              ? ( ' ' x length $1 )
              : $1 )
            }meg;
    }
    @chunks;
}

sub as_string {
    my ( $side, $op ) = @_;

    local %ADDR;
    local %DONE_GV;
    local @NODES;
    local %LINKS;

    # Serialize the optree
    walkoptree( $op, 'OptreeDiff_as_string' );

    # Delete empty elements
    #    for my $n ( @NODES )
    #    {
    #        delete @{$n}{ grep !defined( $n->{$_ } ), keys %$n };
    #    }

    augment_nodes_with_node_path();

    map( {  my $node = $_;

                my @keys = (
                sort {
                    (     ( $a eq 'name' and $b ne 'name' ) ? -1
                        : ( $a ne 'name' and $b eq 'name' ) ? 1
                        : ( $a cmp $b )
                        )
                    }
                    keys %$node
                );

                map( +(
                    $_ eq 'name' ? $node->{'node path'}
                    : defined $node->{$_}
                    ? "$node->{'node path'} $_ = $node->{$_}"
                    : ()
                ),
                grep( +( $_ ne 'node path' && $_ ne 'class' && $_ ne 'addr' ),
                    @keys ) );
    } @NODES );
}

sub augment_nodes_with_node_path {
    for my $n (@NODES) {
        my $addr     = $n->{'addr'};
        my $rel_from = $LINKS{$addr};

        if ( not $rel_from ) {
            $n->{'node path'} = "/$n->{'name'}";
        }
        else {
            $n->{'node path'} = $n->{'name'};
            while ($rel_from) {
                my $prev;
                if ( grep $_ eq 'first', keys %$rel_from ) {
                    $prev = $rel_from->{'first'}{'prev'};
                    $n->{'node path'}
                        = "$rel_from->{'first'}{'name'}/$n->{'node path'}";
                }
                elsif ( grep $_ eq 'sibling', keys %$rel_from ) {
                    $prev = $rel_from->{'sibling'}{'prev'};
                    $n->{'node path'}
                        = "$rel_from->{'sibling'}{'name'}*$n->{'node path'}";
                }

                $rel_from = $LINKS{$prev};
            }
            $n->{'node path'} = "/$n->{'node path'}";
        }
    }
}

sub ADDR {
    return 0;
    return 0 if not $_[0];

    0xADD + ( $ADDR{ $_[0]->oldname }{ $_[0] } ||= scalar keys %ADDR );
}

sub add_link {
    my %p    = @_;
    my $from = ${ $p{'op'} };
    my $rel  = lc $p{'rel'};

    my $to = $p{'op'}->$rel;
    return if not ref $to;
    $to = $$to;

    return if not( $from and $to );

    #    $LINKS{ $rel }{ $to } = $from;
    $LINKS{$to}{$rel} = {
        'prev' => $from,
        'name' => $p{'op'}->oldname
    };
}

BEGIN {
    for (qw( SIBLING FIRST )) {
        ## no critic eval
        eval "sub ${_}_CHECK {
            return if not \$LINKS{ '\L$_\E' }{ \$_[0] };
            push \@NODES, \"->$_\";
        }
        1 "
            or die $@;
    }
}

# Now inject lots of methods into the B::*OP namespace so it can
# be called by B::walkoptree( $ROOT, 'OptreeDiff_as_string' )

sub B::OP::OptreeDiff_as_string {
    my ($op) = @_;

    return if not $$op;

    my $class = class $op;
    bless $op, 'B::OP' if $class eq 'NULL';

    push(
        @NODES,
        {   addr  => $$op,
            name  => $op->oldname,
            class => $class,
            map( +( "op_$_", $op->$_ ), ( 'targ', 'flags', 'private' ) )
        }
    );
    add_link(
        op  => $op,
        rel => 'SIBLING'
    );
    SIBLING_CHECK($op);
    FIRST_CHECK($op);
}

sub B::UNOP::OptreeDiff_as_string {
    my ($op) = @_;
    add_link(
        op  => $op,
        rel => 'first'
    );

    $op->B::OP::OptreeDiff_as_string(),;
}

sub B::BINOP::OptreeDiff_as_string {
    my ($op) = @_;

    $op->B::UNOP::OptreeDiff_as_string(),;
}

sub B::LOOP::OptreeDiff_as_string {
    my ($op) = @_;
    $op->B::BINOP::OptreeDiff_as_string(),
        $NODES[-1]{"op_$_"} = ADDR( ${ $op->$_ } )
        for (qw( redoop nextop lastop ));
}

sub B::LOGOP::OptreeDiff_as_string {
    my ($op) = @_;
    $op->B::UNOP::OptreeDiff_as_string(),
        $NODES[-1]{"op_other"} = ADDR( ${ $op->other } );
}

sub B::LISTOP::OptreeDiff_as_string {
    my ($op) = @_;
    $op->B::BINOP::OptreeDiff_as_string(),;
}

sub B::PMOP::OptreeDiff_as_string {
    my ($op) = @_;

    $op->B::LISTOP::OptreeDiff_as_string(),
        $NODES[-1]{"op_$_"} = ADDR( ${ $op->$_ } )
        for (qw( pmreplroot pmreplstart pmnext ));
    $NODES[-1]{"op_pmflags"}           = ${ $op->pmflags };
    $NODES[-1]{'op_pmregexp->precomp'} = cstring( $op->precomp );

    # Now recurse down for whatever the pmreplroot is.
    $op->pmreplroot->OptreeDiff_as_string;
}

sub B::COP::OptreeDiff_as_string {
    my ($op) = @_;

    $op->B::OP::OptreeDiff_as_string();
    $NODES[-1]{"cop_$_"} = eval { ${ $op->$_ } }
        for (qw( label stashpv arybase ));
    $NODES[-1]{'cop_warnings'} = ${ $op->warnings };
    $NODES[-1]{'cop_io'}       = cstring(
        class( $op->io ) eq 'SPECIAL'
        ? ''
        : $op->io->as_string
    );
}

sub B::SVOP::OptreeDiff_as_string {
    my ($op) = @_;

    $op->B::OP::OptreeDiff_as_string(),

        $op->sv->OptreeDiff_as_string;
}

sub B::PVOP::OptreeDiff_as_string {
    my ($op) = @_;

    $op->B::OP::OptreeDiff_as_string(),
        $NODES[-1]{"op_pv"} = cstring( $op->pv );
}

sub B::PADOP::OptreeDiff_as_string {
    my ($op) = @_;

    $op->B::OP::OptreeDiff_as_string(), $NODES[-1]{'op_padix'} = $op->padix;
}

sub B::NULL::OptreeDiff_as_string {
    my ($sv) = @_;

    push(
        @NODES,
        {   null => (
                $$sv == ${ sv_undef() }
                ? "&sv_undef\n"
                : ADDR($$sv)
            )
        }
    );
}

sub B::SV::OptreeDiff_as_string {
    my ($sv) = @_;

    push( @NODES, { class => class($sv) } );
    if ($$sv) {
        $NODES[-1]{'addr'} = ADDR($$sv);
        $NODES[-1]{"sv $_"} = $sv->$_ for ( 'REFCNT', 'FLAGS' );
    }
}

sub B::RV::OptreeDiff_as_string {
    my ($rv) = @_;

    B::SV::OptreeDiff_as_string($rv), $NODES[-1]{'RV'} = ADDR( ${ $rv->RV } );

    # Recurse and push another node onto the list
    $rv->RV->OptreeDiff_as_string;
}

sub B::PV::OptreeDiff_as_string {
    my ($sv) = @_;

    my $pv = $sv->PV();
    $pv = '' if not defined $pv;

    $sv->B::SV::OptreeDiff_as_string(), $NODES[-1]{'xpv_pv'} = cstring($pv);
    $NODES[-1]{'xpv_cur'} = length $pv;
}

sub B::IV::OptreeDiff_as_string {
    my ($sv) = @_;

    $sv->B::SV::OptreeDiff_as_string(), $NODES[-1]{'xiv_iv'} = $sv->IV;
}

sub B::NV::OptreeDiff_as_string {
    my ($sv) = @_;

    $sv->B::IV::OptreeDiff_as_string(), $NODES[-1]{'xnv_nv'} = $sv->NV;
}

sub B::PVIV::OptreeDiff_as_string {
    my ($sv) = @_;

    $sv->B::PV::OptreeDiff_as_string(), $NODES[-1]{'xiv_iv'} = $sv->IV;
}

sub B::PVNV::OptreeDiff_as_string {
    my ($sv) = @_;

    $sv->B::PVIV::OptreeDiff_as_string(), $NODES[-1]{'xnv_nv'} = $sv->NV;
}

sub B::PVLV::OptreeDiff_as_string {
    my ($sv) = @_;

    $sv->B::PVNV::OptreeDiff_as_string(), $NODES[-1]{"xlv_\L$_"} = $sv->$_
        for ( 'TARGOFF', 'TARGLEN' );
    $NODES[-1]{'xlv_type'} = cstring( chr $sv->TYPE );
}

sub B::BM::OptreeDiff_as_string {
    my ($sv) = @_;

    $sv->B::PVNV::OptreeDiff_as_string(), $NODES[-1]{"xbm_\L$_"} = $sv->$_
        for ( 'USEFUL', 'PREVIOUS' );
    $NODES[-1]{'xbm_rare'} = cstring( chr $sv->RARE );
}

sub B::CV::OptreeDiff_as_string {
    my ($sv)      = @_;
    my ($stash)   = $sv->STASH;
    my ($start)   = $sv->START;
    my ($root)    = $sv->ROOT;
    my ($padlist) = $sv->PADLIST;
    my ($gv)      = $sv->GV;

    $sv->B::PVNV::OptreeDiff_as_string();

    $NODES[-1]{$_} = ADDR( ${ $sv->$_ } )
        for ( 'STASH', 'START', 'ROOT', 'GV', 'PADLIST', 'OUTSIDE' );
    $NODES[-1]{'DEPTH'} = $sv->DEPTH;

    $_->OptreeDiff_as_string
        for grep $_,
        map $sv->$_,
        ( 'GV', 'PADLIST', 'ROOT', 'START' );
}

sub B::AV::OptreeDiff_as_string {
    my ($av)    = @_;
    my (@array) = $av->ARRAY;

    $av->B::SV::OptreeDiff_as_string,
        $NODES[-1]{'ARRAY'} = join( ", ", map ADDR($$_), @array );
    $NODES[-1]{'FILL'} = scalar @array;
    $NODES[-1]{$_} = $av->$_ for qw( MAX OFF AvFLAGS );
}

sub B::GV::OptreeDiff_as_string {
    my ($gv) = @_;

    $NODES[-1]{'GV'} = join( "::", $gv->STASH->NAME, $gv->SAFENAME );
}

sub B::SPECIAL::OptreeDiff_as_string {
    my ($sv) = @_;

    $NODES[-1] .= join "", $specialsv_name[$$sv], "\n";
}

1;
__END__

=head1 NAME

Devel::OptreeDiff - Produces diffs of optrees

=head1 SYNOPSIS

  use Devel::OptreeDiff 'fmt_optree_diff';
  use Data::Dumper 'Dumper';
  print map "$_\n",
            fmt_optree_diff( sub { print @_ or die $! },
                             sub { print @_ } ) );
  
  - /leavesub/lineseq/nextstate*print
  + /leavesub/lineseq/nextstate*null
  +                                 .op_flags = 4
  +                                 .op_private = 1
  +                                 .op_targ = 0
  + /leavesub/lineseq/nextstate*null/or
  +                                    .op_flags = 4
  +                                    .op_other = 0
  +                                    .op_private = 1
  +                                    .op_targ = 0
  + /leavesub/lineseq/nextstate*null/or/print
  
  - /leavesub/lineseq/nextstate*print/pushmark
  + /leavesub/lineseq/nextstate*null/or/print/pushmark
  
  - /leavesub/lineseq/nextstate*print/pushmark*rv2av
  + /leavesub/lineseq/nextstate*null/or/print/pushmark*rv2av
  
  - /leavesub/lineseq/nextstate*print/pushmark*rv2av/gv
  + /leavesub/lineseq/nextstate*null/or/print/pushmark*rv2av/gv
  
  + /leavesub/lineseq/nextstate*null/or/print/pushmark*rv2av/gv.op_flags = 2
  +                                                            .op_private = 0
  +                                                            .op_targ = 0
  + /leavesub/lineseq/nextstate*null/or/print*die
  +                                              .op_flags = 6
  +                                              .op_private = 1
  +                                              .op_targ = 2
  + /leavesub/lineseq/nextstate*null/or/print*die/pushmark
  +                                                       .op_flags = 2
  +                                                       .op_private = 0
  +                                                       .op_targ = 0
  + /leavesub/lineseq/nextstate*null/or/print*die/pushmark*rv2sv
  +                                                             .op_flags = 6
  +                                                             .op_private = 1
  +                                                             .op_targ = 15
  + /leavesub/lineseq/nextstate*null/or/print*die/pushmark*rv2sv/gvsv
  +                                                                  .GV = main::!

=head1 DESCRIPTION

Runs Algorithm::Diff against two functions to make writing macros
easier.

=head2 OPTIONAL EXPORTS

=over 4

=item fmt_optree_diff( \&code_a, \&code_b, ... )

This is like optree_diff except that it returns a list of nicely formatted
text descriptions of the changes to the optree.

=item optree_diff( \&code_a, \&code_b, ... )

A wrapped call to Algorithm::Diff::diff(). fmt_optree_diff uses this as
input.

=item optree_sdiff( \&code_a, \&code_b, ... )

Algorithm::Diff::sdiff( ... )

=item optree_traverse_sequences( \&code_a, \&code_b, ... )

Algorithm::Diff::traverse_sequences( ... )

=item optree_traverse_balanced( \&code_a, \&code_b, ... )

Algorithm::Diff::traverse_balanced( ... )

=head1 CAVEATs

This module is still under development. While the code works mostly
correctly, the test 3-and-or.t expresses a wish that redundant
information not be included in the output. This module will change in
small ways until I can get the output looking proper.

=head1 AUTHOR

Joshua b. Jore E<lt>jjore@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

B::Keywords supplies seven arrays of keywords: @Scalars, @Arrays, @Hashes,
@Filehandles, @Symbols, @Functions and @Barewords. The @Symbols array includes
the contents of each of @Scalars, @Arrays, @Hashes and @Filehandles.
Similarly, @Barewords adds a few non-function keywords (like __DATA__, NULL)
to the @Functions array.

All additions and modifications are welcome.

=cut
