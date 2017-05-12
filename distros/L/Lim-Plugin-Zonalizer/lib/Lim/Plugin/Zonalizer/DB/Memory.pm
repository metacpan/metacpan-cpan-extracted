package Lim::Plugin::Zonalizer::DB::Memory;

use utf8;
use common::sense;

use Carp;
use Scalar::Util qw(weaken);

use Data::UUID ();
use Lim::Plugin::Zonalizer qw(:err);
use URI::Escape::XS qw(uri_escape);
use Clone qw(clone);
use Lim ();

use base qw(Lim::Plugin::Zonalizer::DB);

our %FIELD = ( analysis => { map { $_ => 1 } ( qw(created updated) ) } );

=encoding utf8

=head1 NAME

Lim::Plugin::Zonalizer::DB::Memory - The in memory database for Zonalizer

=head1 METHODS

=over 4

=item Init

=cut

sub Init {
    my ( $self ) = @_;

    $self->{space}->{''}->{analysis}      = [];
    $self->{space}->{''}->{analyze}       = {};
    $self->{space}->{''}->{analyze_fqdn}  = {};
    $self->{space}->{''}->{analyze_rfqdn} = {};

    return;
}

=item Destroy

=cut

sub Destroy {
}

=item Name

=cut

sub Name {
    return 'Memory';
}

=item ReadAnalysis

=cut

sub ReadAnalysis {
    my ( $self, %args ) = @_;

    unless ( ref( $args{cb} ) eq 'CODE' ) {
        confess 'cb is not CODE';
    }
    undef $@;

    my $limit = defined $args{limit} ? $args{limit} : 0;
    if ( $limit == 0 ) {
        $args{cb}->();
        return;
    }
    unless ( $limit > 0 ) {
        $@ = ERR_INVALID_LIMIT;
        $args{cb}->();
        return;
    }

    my $search_fqdn;
    my $search_fqdn2;
    if ( defined $args{search} ) {
        if ( $args{search} =~ /^\../o ) {
            $search_fqdn2 = $args{search};
            $search_fqdn2 =~ s/^\.//o;
            unless ( $search_fqdn2 =~ /\.$/o ) {
                $search_fqdn2 .= '.';
            }
            $search_fqdn2 = join( '.', reverse( split( /\./o, $search_fqdn2 ) ) );
        }
        else {
            $search_fqdn = $args{search};
            unless ( $search_fqdn =~ /\.$/o ) {
                $search_fqdn .= '.';
            }
        }
    }

    my $space = $args{space} ? $args{space} : '';
    if ( $space and !exists $self->{space}->{$space} ) {
        $self->{space}->{''}->{analysis}      = [];
        $self->{space}->{''}->{analyze}       = {};
        $self->{space}->{''}->{analyze_fqdn}  = {};
        $self->{space}->{''}->{analyze_rfqdn} = {};
    }

    my @analysis;
    my ( $paging, $previous, $next ) = ( 0, 0, 0 );
    my $analysis = $self->{space}->{$space}->{analysis};

    if ( defined $search_fqdn ) {
        unless ( exists $self->{space}->{$space}->{analyze_fqdn}->{$search_fqdn} ) {
            $args{cb}->( undef );
            return;
        }

        $analysis = $self->{space}->{$space}->{analyze_fqdn}->{$search_fqdn};
    }
    elsif ( defined $search_fqdn2 ) {
        unless ( exists $self->{space}->{$space}->{analyze_rfqdn}->{$search_fqdn2} ) {
            $args{cb}->( undef );
            return;
        }

        $analysis = $self->{space}->{$space}->{analyze_rfqdn}->{$search_fqdn2};
    }

    if ( scalar @{$analysis} and defined $args{sort} ) {
        unless ( exists $analysis->[0]->{ $args{sort} } ) {
            $@ = ERR_INVALID_SORT_FIELD;
            $args{cb}->();
            return;
        }
        if ( $args{direction} eq 'descending' ) {
            my @sort;
            if ( exists $FIELD{analysis}->{ $args{sort} } ) {
                @sort = sort { $b->{ $args{sort} } <=> $a->{ $args{sort} } } @{$analysis};
            }
            else {
                @sort = sort { $b->{ $args{sort} } cmp $a->{ $args{sort} } } @{$analysis};
            }
            $analysis = \@sort;
        }
        else {
            my @sort;
            if ( exists $FIELD{analysis}->{ $args{sort} } ) {
                @sort = sort { $a->{ $args{sort} } <=> $b->{ $args{sort} } } @{$analysis};
            }
            else {
                @sort = sort { $a->{ $args{sort} } cmp $b->{ $args{sort} } } @{$analysis};
            }
            $analysis = \@sort;
        }
    }

    foreach my $analyze ( @$analysis ) {
        if ( $paging ) {
            $next = 1;
            last;
        }
        if ( defined $args{after} ) {
            if ( $analyze->{id} eq $args{after} ) {
                delete $args{after};
            }
            $previous = 1;
            next;
        }
        if ( defined $args{before} ) {
            if ( $analyze->{id} eq $args{before} ) {
                $next = 1;
                last;
            }
            if ( scalar @analysis == $limit ) {
                $previous = 1;
                shift( @analysis );
            }
        }

        push( @analysis, clone $analyze );

        if ( scalar @analysis == $limit && !defined $args{before} ) {
            $paging = 1;
        }
    }
    if ( $previous or $next ) {
        $paging = 1;
    }
    else {
        $paging = 0;
    }
    unless ( scalar @analysis ) {
        $paging = 0;
    }

    $args{cb}->(
        $paging
        ? {
            before   => $analysis[0]->{id},
            after    => $analysis[-1]->{id},
            previous => $previous,
            next     => $next,
            defined $search_fqdn || defined $search_fqdn2 ? ( extra => 'search=' . uri_escape( defined $search_fqdn ? $search_fqdn : ( '.' . $search_fqdn2 ) ) ) : ()
          }
        : undef,
        @analysis
    );
    return;
}

=item DeleteAnalysis

=cut

sub DeleteAnalysis {
    my ( $self, %args ) = @_;

    unless ( ref( $args{cb} ) eq 'CODE' ) {
        confess 'cb is not CODE';
    }
    undef $@;

    my $space = $args{space} ? $args{space} : '';
    if ( $space and !exists $self->{space}->{$space} ) {
        $self->{space}->{''}->{analysis}      = [];
        $self->{space}->{''}->{analyze}       = {};
        $self->{space}->{''}->{analyze_fqdn}  = {};
        $self->{space}->{''}->{analyze_rfqdn} = {};
    }

    my $deleted_analysis = scalar @{ $self->{space}->{$space}->{analysis} };

    if ( $space ) {
        delete $self->{space}->{$space};
    }
    else {
        $self->Init;
    }

    $args{cb}->( $deleted_analysis );
    return;
}

=item CreateAnalyze

=cut

sub CreateAnalyze {
    my ( $self, %args ) = @_;

    unless ( ref( $args{cb} ) eq 'CODE' ) {
        confess 'cb is not CODE';
    }
    $self->ValidateAnalyze( $args{analyze} );
    undef $@;

    if ( exists $args{analyze}->{_rev} ) {

        # uncoverable branch false
        Lim::ERR and $self->{logger}->error( 'Memory specific fields _rev existed during create' );
        $@ = ERR_INTERNAL_DATABASE;
        $args{cb}->();
        return;
    }

    my $space = $args{space} ? $args{space} : '';
    if ( $space and !exists $self->{space}->{$space} ) {
        $self->{space}->{''}->{analysis}      = [];
        $self->{space}->{''}->{analyze}       = {};
        $self->{space}->{''}->{analyze_fqdn}  = {};
        $self->{space}->{''}->{analyze_rfqdn} = {};
    }

    if ( exists $self->{space}->{$space}->{analyze}->{ $args{analyze}->{id} } ) {
        $@ = ERR_DUPLICATE_ID;
        $args{cb}->();
        return;
    }

    my $analyze = clone $args{analyze};
    $analyze->{_rev} = Data::UUID->new->create_str;

    push( @{ $self->{space}->{$space}->{analysis} }, $analyze );
    $self->{space}->{$space}->{analyze}->{ $args{analyze}->{id} } = $analyze;
    push( @{ $self->{space}->{$space}->{analyze_fqdn}->{ $args{analyze}->{fqdn} } }, $analyze );
    push( @{ $self->{space}->{$space}->{analyze_rfqdn}->{ join( '.', reverse( split( /\./o, $args{analyze}->{fqdn} ) ) ) } }, $analyze );

    $args{cb}->( clone $analyze );
    return;
}

=item ReadAnalyze

=cut

sub ReadAnalyze {
    my ( $self, %args ) = @_;

    unless ( ref( $args{cb} ) eq 'CODE' ) {
        confess 'cb is not CODE';
    }
    unless ( defined $args{id} ) {
        confess 'id is not defined';
    }
    undef $@;

    my $space = $args{space} ? $args{space} : '';
    if ( $space and !exists $self->{space}->{$space} ) {
        $self->{space}->{''}->{analysis}      = [];
        $self->{space}->{''}->{analyze}       = {};
        $self->{space}->{''}->{analyze_fqdn}  = {};
        $self->{space}->{''}->{analyze_rfqdn} = {};
    }

    unless ( exists $self->{space}->{$space}->{analyze}->{ $args{id} } ) {
        $@ = ERR_ID_NOT_FOUND;
        $args{cb}->();
        return;
    }

    $args{cb}->( clone $self->{space}->{$space}->{analyze}->{ $args{id} } );
    return;
}

=item UpdateAnalyze

=cut

sub UpdateAnalyze {
    my ( $self, %args ) = @_;

    unless ( ref( $args{cb} ) eq 'CODE' ) {
        confess 'cb is not CODE';
    }
    $self->ValidateAnalyze( $args{analyze} );
    undef $@;

    my $space = $args{space} ? $args{space} : '';
    if ( $space and !exists $self->{space}->{$space} ) {
        $self->{space}->{''}->{analysis}      = [];
        $self->{space}->{''}->{analyze}       = {};
        $self->{space}->{''}->{analyze_fqdn}  = {};
        $self->{space}->{''}->{analyze_rfqdn} = {};
    }

    if ( defined $args{space} and $args{space} ne $args{analyze}->{space} ) {
        $@ = ERR_SPACE_MISSMATCH;
        $args{cb}->();
        return;
    }
    if ( !defined $args{space} and $args{analyze}->{space} ne '' ) {
        $@ = ERR_SPACE_MISSMATCH;
        $args{cb}->();
        return;
    }
    unless ( exists $self->{space}->{$space}->{analyze}->{ $args{analyze}->{id} } ) {
        $@ = ERR_ID_NOT_FOUND;
        $args{cb}->();
        return;
    }
    unless ( defined $args{analyze}->{_rev} and $self->{space}->{$space}->{analyze}->{ $args{analyze}->{id} }->{_rev} eq $args{analyze}->{_rev} ) {
        $@ = ERR_REVISION_MISSMATCH;
        $args{cb}->();
        return;
    }

    my $analyze = $self->{space}->{$space}->{analyze}->{ $args{analyze}->{id} };
    foreach ( keys %$analyze ) {
        unless ( exists $args{analyze}->{$_} ) {
            delete $analyze->{$_};
        }
    }
    foreach ( keys %{ $args{analyze} } ) {
        $analyze->{$_} = $args{analyze}->{$_};
    }
    $analyze->{_rev} = Data::UUID->new->create_str;

    $args{cb}->( clone $analyze );
    return;
}

=item DeleteAnalyze

=cut

sub DeleteAnalyze {
    my ( $self, %args ) = @_;

    unless ( ref( $args{cb} ) eq 'CODE' ) {
        confess 'cb is not CODE';
    }
    unless ( defined $args{id} ) {
        confess 'id is not defined';
    }
    undef $@;

    my $space = $args{space} ? $args{space} : '';
    if ( $space and !exists $self->{space}->{$space} ) {
        $self->{space}->{''}->{analysis}      = [];
        $self->{space}->{''}->{analyze}       = {};
        $self->{space}->{''}->{analyze_fqdn}  = {};
        $self->{space}->{''}->{analyze_rfqdn} = {};
    }

    unless ( exists $self->{space}->{$space}->{analyze}->{ $args{id} } ) {
        $@ = ERR_ID_NOT_FOUND;
        $args{cb}->();
        return;
    }

    @{ $self->{space}->{$space}->{analyzes} } = grep { $_->{id} ne $args{id} } @{ $self->{space}->{$space}->{analyzes} };
    @{ $self->{space}->{$space}->{analyze_fqdn}->{ $self->{space}->{$space}->{analyze}->{ $args{id} }->{fqdn} } } = grep { $_->{id} ne $args{id} } @{ $self->{space}->{$space}->{analyze_fqdn}->{ $self->{space}->{$space}->{analyze}->{ $args{id} }->{fqdn} } };
    @{ $self->{space}->{$space}->{analyze_rfqdn}->{ join( '.', reverse( split( /\./o, $self->{space}->{$space}->{analyze}->{ $args{id} }->{fqdn} ) ) ) } } = grep { $_->{id} ne $args{id} } @{ $self->{space}->{$space}->{analyze_rfqdn}->{ join( '.', reverse( split( /\./o, $self->{space}->{$space}->{analyze}->{ $args{id} }->{fqdn} ) ) ) } };

    $args{cb}->();
    return;
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim-plugin-zonalizer/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Plugin::Zonalizer::DB::Memory

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim-plugin-zonalizer/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2016 Jerry Lundström
Copyright 2015-2016 IIS (The Internet Foundation in Sweden)

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Lim::Plugin::Zonalizer::DB::Memory
