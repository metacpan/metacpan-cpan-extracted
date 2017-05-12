## no critic (Moose::RequireMakeImmutable)
package Test::Meta::Grapher::Moose;

use strict;
use warnings;

use B;
use Class::MOP ();
use File::Spec;
use List::Util 1.45 qw( uniq );
use Meta::Grapher::Moose::Constants qw( CLASS ROLE P_ROLE ANON_ROLE );
use Meta::Grapher::Moose::Renderer::Graphviz;
use Meta::Grapher::Moose::Renderer::Test;
use Meta::Grapher::Moose;
use Moose ();
use Moose::Meta::Class;
use Moose::Meta::Role;
use Moose::Util qw( find_meta );
use MooseX::Role::Parameterized ();
use Test2::API qw( context );
use Test2::Bundle::Extended;

use Exporter qw( import );

our @EXPORT_OK = qw( test_graphing_for );

{
    my $prefix = 'Test001';

    sub test_graphing_for {
        my $package_to_test = shift;
        my %packages        = @_;

        _define_packages( $prefix, %packages );

        my $root_package = join '::', $prefix, $package_to_test;

        # run a grapher with the ::Test renderer that simply records what
        # it was asked to render
        my $renderer = Meta::Grapher::Moose::Renderer::Test->new;
        my $grapher  = Meta::Grapher::Moose->new(
            package  => $root_package,
            renderer => $renderer,
        )->run;

        if ( $ENV{OUTPUT_TEST_GRAPHS} ) {
            Meta::Grapher::Moose->new(
                package  => $root_package,
                renderer => Meta::Grapher::Moose::Renderer::Graphviz->new(
                    output => "/tmp/$prefix.png",
                ),
            )->run;
        }

        # check each of the nodes
        my @conditions;
        for my $package ( sort keys %packages ) {
            my $name = $prefix . '::' . $package;
            if ( $package =~ /ParamRole/ ) {
                push @conditions, hash {
                    field id    => $name;
                    field label => $name;
                    field type  => P_ROLE;
                };
                push @conditions, hash {
                    field id    => match(qr/__ANON__/);
                    field label => $name;
                    field type  => ANON_ROLE;
                };
            }
            else {
                push @conditions, hash {
                    field id    => $name;
                    field label => $name;
                };
            }
        }
        is(
            $renderer->nodes_for_comparison,
            \@conditions,
            'correct nodes'
        );

        my %real_package_to_anonymouse_package;
        for my $node ( @{ $renderer->nodes_for_comparison } ) {
            next unless $node->{type} eq ANON_ROLE;
            $real_package_to_anonymouse_package{ $node->{label} }
                = $node->{id};
        }

        # check each of the edges
        my @expected_edges;
        for my $package ( keys %packages ) {
            my $full_package    = $prefix . '::' . $package;
            my $package_details = $packages{$package};

            for my $extends_or_with (qw( extends with role_block_with )) {
                for my $package_to_link_from (
                    _listify( $package_details->{$extends_or_with} ) ) {
                    my $full_package_to_link_from
                        = $prefix . '::' . $package_to_link_from;
                    my $full_package_to_link_to
                        = ( $extends_or_with eq 'role_block_with' )
                        ? $real_package_to_anonymouse_package{$full_package}
                        : $full_package;

                    my $anon_package = $real_package_to_anonymouse_package{
                        $full_package_to_link_from};
                    if ($anon_package) {
                        push @expected_edges, {
                            from => $full_package_to_link_from,
                            to   => $anon_package,
                            }, {
                            from => $anon_package,
                            to   => $full_package_to_link_to,
                            };
                        next;
                    }

                    push @expected_edges, {
                        from => $full_package_to_link_from,
                        to   => $full_package_to_link_to,
                    };
                }
            }
        }

        # add the prefixes, to allow extra fields, make sure the
        # order is consistent
        @expected_edges = sort { $a cmp $b }
            uniq map {"$_->{from} - $_->{to}"} @expected_edges;

        my @got_edges = sort { $a cmp $b }
            map {"$_->{from} - $_->{to}"}
            @{ $renderer->edges_for_comparison };

        is(
            \@got_edges,
            \@expected_edges,
            'correct edges'
        );

        return ( $prefix++, $grapher );
    }
}

sub _define_packages {
    my $prefix   = shift;
    my %packages = @_;

    _define_one_package( $prefix, $_, \%packages ) for keys %packages;

    return;
}

sub _define_one_package {
    my $prefix   = shift;
    my $name     = shift;
    my $packages = shift;

    my $full_name = join '::', $prefix, $name;

    return $full_name if find_meta($full_name);

    my @roles
        = map { _define_one_package( $prefix, $_, $packages ) }
        _listify( $packages->{$name}{with} );

    if ( $name =~ /^Class/ ) {
        my @super
            = map { _define_one_package( $prefix, $_, $packages ) }
            _listify( $packages->{$name}{extends} );

        Moose::Meta::Class->create(
            $full_name,
            ( @roles ? ( roles        => \@roles ) : () ),
            ( @super ? ( superclasses => \@super ) : () ),
        );
    }
    elsif ( $name =~ /^Role/ ) {
        Moose::Meta::Role->create(
            $full_name,
            ( @roles ? ( roles => \@roles ) : () ),
        );
    }
    elsif ( $name =~ /^ParamRole/ ) {
        my @role_block_roles
            = map { _define_one_package( $prefix, $_, $packages ) }
            _listify( $packages->{$name}{role_block_with} );

        ## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
        my $outer_with_list = join ', ',
            map { B::perlstring($_) } @roles;

        my $inner_with_list = join ', ',
            map { B::perlstring($_) } @role_block_roles;
        ## use critic

        ## no critic (BuiltinFunctions::ProhibitStringyEval, ErrorHandling::RequireCheckingReturnValueOfEval)
        eval <<"EOF";
package $full_name;
use MooseX::Role::Parameterized;

with $outer_with_list if length q{$outer_with_list};

role {
    with $inner_with_list if length q{$inner_with_list};
};
EOF

        die $@ if $@;
        ## use critic
    }
    else {
        die "unknown prefix for package - $name";
    }

    return $full_name;
}

sub _listify {
    return () unless $_[0];
    return ref $_[0] ? @{ $_[0] } : $_[0];
}

1;
