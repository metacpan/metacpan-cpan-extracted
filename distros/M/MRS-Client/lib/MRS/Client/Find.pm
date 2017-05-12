#-----------------------------------------------------------------
# MRS::Client::Find
# Authors: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see MRS::Client pod.
#
# ABSTRACT: Representation of an MRS query - on a client side
# PODNAME: MRS::Client
#-----------------------------------------------------------------
use warnings;
use strict;
package MRS::Client::Find;

our $VERSION = '1.0.1'; # VERSION

use Carp;
use Math::BigInt;
use Data::Dumper;

#-----------------------------------------------------------------
# new (client, string)
# new (client, [string]) ... ref ARRAY
# new (client, args)     ... HASH or ref HASH
#-----------------------------------------------------------------
sub new {
    my $class = shift;
    my $self = bless {}, ref ($class) || $class;
    $self->{client} = shift;

    # parse the arguments and fill them into $self
    croak "Empty query request. Cannot do anything.\n" unless @_ > 0;
    if (@_ == 1) {
        my $arg = shift;
        if (ref ($arg) eq 'ARRAY') {
            push (@_, 'and' => $arg);
        } elsif (ref ($arg) eq 'HASH') {
            push (@_, %$arg);
        } elsif (MRS::Operator->contains ($arg)) {
            push (@_, query => $arg);
        } else {
            push (@_, 'and' => [$arg]);
        }
    }

    my (%args) = @_;
    foreach my $key (keys %args) {
        $self->{$key} = $args {$key};
    }

    # some arguments checking and filling default values
    $self->{format} = MRS::EntryFormat->PLAIN unless $self->{format};
    warn ("Unrecognized output format '" . $self->{format} . "'. Reversed to default.\n")
        and $self->{format} = MRS::EntryFormat->PLAIN
        unless MRS::EntryFormat->check ($self->{format}, $self->{client});

    unless ($self->{client} and $self->{client}->is_v6) {
        $self->{algorithm} = MRS::Algorithm->VECTOR unless $self->{algorithm};
        warn ("Unrecognized scoring algorithm '" . $self->{algorithm} . "'. Reversed to default.\n")
            and $self->{algorithm} = MRS::Algorithm->VECTOR
            unless MRS::Algorithm->check ($self->{algorithm});
    }

    $self->{offset} = 0 unless defined $self->{offset};
    warn ("Parameter 'offset' is not an integer. Reversed to zero.\n")
        and $self->{offset} = 0
        unless $self->_is_int ($self->{offset});
    warn ("Parameter 'offset' is negative: " . $self->{offset} . ". Reversed to zero.\n")
        and $self->{offset} = 0
        if $self->{offset} < 0;

    if (defined $self->{start}) {
        warn ("Parameter 'start' is not an integer. Reversed to one.\n")
            and $self->{start} = 1
            unless $self->_is_int ($self->{start});
        if ($self->{start} > 0) {
            $self->{offset} = $self->{start} - 1;
        } else {
            warn ("Parameter 'start' is not positive: " . $self->{start} . ". Ignored.\n");
        }
    }

    $self->{max_entries} = 0 unless $self->{max_entries};
    warn ("Parameter 'max_entries' is not an integer. Reversed to zero.\n")
        and $self->{max_entries} = 0
        unless $self->_is_int ($self->{max_entries});
    warn ("Parameter 'max_entries' is negative: " . $self->{max_entries} . ". Reversed to zero.\n")
        and $self->{max_entries} = 0
        if $self->{max_entries} < 0;

    # 'and' and 'or' should be refarrays
    $self->{and} = [ $self->{and} ] if $self->{and} and not ref ($self->{and});
    $self->{or} = [ $self->{or} ] if $self->{or} and not ref ($self->{or});

    warn ("Both 'and' and 'or' parameters given. The latter ignored.\n")
        and delete ($self->{or})
        if defined $self->{and} and defined $self->{or};

    $self->{and} = [$self->{query}] and undef ($self->{query})
        unless
        MRS::Operator->contains ($self->{query}) or
        (defined $self->{and} and @{ $self->{and} } > 0) or
        (defined $self->{or} and @{ $self->{or} } > 0);

    # if some terms contain boolean operators, move them to query
    if (defined $self->{and}) {
        my @terms = ();
        while (my $term = shift (@{ $self->{and} })) {
            if (MRS::Operator->contains ($term)) {
                $self->{query} = '' unless defined $self->{query};
                $self->{query} .= ' AND ' if $self->{query};
                $self->{query} .= $term;
            } else {
                push (@terms, $term);
            }
        }
        push (@{ $self->{and} }, $_) foreach @terms;
    }

    $self->{terms} = ($self->{and} or $self->{or});
    $self->{all_terms_required} = ($self->{and} ? 1 : 0);

    croak "Empty query request. Cannot do anything.\n"
        unless
        (defined $self->{terms} and @{ $self->{terms} } > 0) or
        $self->{query};

    # create, so far empty, buffer for hits/results
    $self->{count} = 0;
    $self->{hits} = [];     # buffer
    $self->{eod} = 0;       # 1 => no more data
    $self->{delivered} = 0; # how many hits already delivered

    # done
    return $self;
}

sub _is_int {
    my ($self, $str) = @_;
    $str =~ /^[+-]?\d+$/;
}

#-----------------------------------------------------------------
# Make a call and copy found hits $self->{hits}, and update
# $self->{offset} so it is ready for the next buffer filling.
# Return the next available hit, or undef if EOD.
#-----------------------------------------------------------------
sub _read_next_hits {
    my $self = shift;

    $self->{client}->_create_proxy ('search');

    # using ranked query, possibly combined with a boolean query
    my $params = {
        db               => $self->{db},
        queryterms       => $self->{terms},
        alltermsrequired => $self->{all_terms_required},
        booleanfilter    => ($self->{query} or ''),
        resultoffset     => $self->{offset},
        maxresultcount   => 200,
    };
    $params->{algorithm} = $self->{algorithm} unless $self->{client}->is_v6;

    my $answer = $self->{client}->_call (
        $self->{client}->{search_proxy}, 'Find', $params);

    if (defined $answer) {
        use Data::Dumper;
        # print Dumper ($answer);
        # $self->{count} = 0;
        my $response = $answer->{parameters}->{response};
        if ($response) {
            foreach my $data (@{ $answer->{parameters}->{response} }) {
                if ($data->{count} > 0) {
                    $self->{count} += $data->{count};
                }
                # warn ("Unexpected response length: " . (@$response+0) . "\n")
                #       if @$response > 1;   # developer's error

                # $self->{count} = $$response[0]->{count};
                # foreach my $hit (@{ $$response[0]->{hits} }) {
                #     push (@{ $self->{hits} }, MRS::Client::Hit->new (%$hit, db => $self->db));
                # }
                # $self->{offset} += @{ $self->{hits} };

                foreach my $hit (@{ $data->{hits} }) {
                    push (@{ $self->{hits} }, MRS::Client::Hit->new (%$hit, db => $self->{db}));
                }
                $self->{offset} += @{ $data->{hits} };
            }
        }
    }

    # we may be at the end
    $self->{eod} = 1 if @{ $self->{hits} } == 0;

    # return the next hit (or undef if EOD)
    return shift @{ $self->{hits} };
}

#-----------------------------------------------------------------
# return an entry represented by $hit; in the wanted format
#-----------------------------------------------------------------
sub _process_hit {
    my ($self, $hit) = @_;

    if ($self->{format} eq MRS::EntryFormat->HEADER) {
        return $hit;
    } else {
        return $self->{dbobj}->entry ($hit->{id}, $self->{format}, $self->{xformat});
    }
}

#-----------------------------------------------------------------
# return next hit or undef at EOD
#-----------------------------------------------------------------
sub next {
    my $self = shift;

    # are we at the end?
    return if $self->{eod} or
        ($self->max_entries > 0 and $self->{delivered} >= $self->max_entries);

    # do we have any not-yet delivered hits?
    my $next_hit = (shift @{ $self->{hits} } or $self->_read_next_hits);
    return unless $next_hit;
    $self->{delivered}++;
    return $self->_process_hit ($next_hit);
}

sub db                  { return shift->{db}; }
sub terms               { return shift->{terms}; }
sub all_terms_required  { return shift->{all_terms_required}; }
sub query               { return shift->{query}; }
#sub count               { return shift->{count}->bstr(); }
sub count               { return shift->{count}; }
sub max_entries         { return shift->{max_entries}; }

use overload q("") => "as_string";
sub as_string {
    my $self = shift;
    my $r = '';
    $r .= "databank:     " . $self->{db}          . "\n" if defined $self->{db};
    $r .= "terms:        " . join (", ", @{ $self->{terms} }) . "\n" if defined $self->{terms};
    $r .= "terms by AND: " . $self->{all_terms_required} . "\n";
    $r .= "query expr:   " . $self->{query}       . "\n" if defined $self->{query};
    $r .= "count:        " . $self->{count}       . "\n" if defined $self->{count};
    $r .= "format:       " . $self->{format}      . "\n" if defined $self->{format};
    $r .= "hits offset:  " . $self->{offset}      . "\n" if defined $self->{offset};
    $r .= "max entries:  " . $self->{max_entries} . "\n";
    $r .= "algorithm:    " . $self->{algorithm}   . "\n" if defined $self->{algorithm};
    return $r;
}

#-----------------------------------------------------------------
#
#  MRS::Client::MultiFind ... extended Find for more databanks
#
#-----------------------------------------------------------------
package MRS::Client::MultiFind;

our $VERSION = '1.0.1'; # VERSION

use Carp;
use base qw( MRS::Client::Find );

sub _read_next_hits {
    die "Method '_read_next_hits' should not be use on MultiFind. Developer's error.\n";
}
sub _process_hit {
    die "Method '_process_hit' should not be use on MultiFind. Developer's error.\n";
}

sub db { return 'all'; }
sub db_counts {
    my $self = shift;
    my %counts = ();
    foreach my $child (@{ $self->{children} }) {
        $counts{$child->db} = $child->count;
    }
    return %counts;
}

use overload q("") => "as_string";
sub as_string {
    my $self = shift;
    my $r = $self->SUPER::as_string;
    my %db_counts = $self->db_counts;
    foreach my $db (sort keys %db_counts ) {
        $r .= sprintf ("\t%-15s%9d\n", $db, $db_counts{$db});
    }
    return $r;
}

#-----------------------------------------------------------------
# Reads first few hits from all databanks. Fill the total
# count. Return ref array of Finds for individual databanks that have
# some hits.
# -----------------------------------------------------------------
sub _read_first_hits {
    my $self = shift;

    $self->{client}->_create_proxy ('search');

    # using ranked query, possibly combined with a boolean query
    my $params = {
        db               => 'all',
        queryterms       => $self->{terms},
        alltermsrequired => $self->{all_terms_required},
        booleanfilter    => ($self->{query} or ''),
        resultoffset     => $self->{offset},
        maxresultcount   => 5,  # maximum accepted by the MRS server
    };
    $params->{algorithm} = $self->{algorithm} unless $self->{client}->is_v6;
    my $answer = $self->{client}->_call (
        $self->{client}->{search_proxy}, 'Find', $params);

    my $total_count = Math::BigInt->new;
    my @finds = ();
    if (defined $answer) {
        foreach my $data (@{ $answer->{parameters}->{response} }) {
            if ($data->{count} > 0) {
                $total_count += $data->{count};

                # create an individual find (by cloning args from me)
                my $find = MRS::Client::Find->new ($self->{client}, @{ $self->{args} });
                $find->{db} = $data->{db};
                $find->{dbobj} = $self->{client}->db ($data->{db});

                # fill them with the hits we already have read
                $find->{count} = $data->{count};
                foreach my $hit (@{ $data->{hits} }) {
                    push (@{ $find->{hits} }, MRS::Client::Hit->new (%$hit, db => $find->{db}));
                }
                $find->{offset} += @{ $data->{hits} };

                # store it
                push (@finds, $find);
            }
        }
    }
    $self->{count} = $total_count;
    return \@finds;
}

#-----------------------------------------------------------------
# return next hit or undef at EOD - but read sequentially from all
# $self->{children} (the finds of individual databanks)
# -----------------------------------------------------------------
sub next {
    my $self = shift;

    # are we at the end?
    return if $self->{eod};

    # do we have any not-yet delivered hits?
    my $next_hit = (${ $self->{children}} [$self->{current}])->next;
    return $next_hit if $next_hit;

    # move to the next databank
    $self->{current}++;
    if ($self->{current} >= @{ $self->{children}}) {
        # we reached the ultimate end
        $self->{eod} = 1;
        return;
    } else {
        # start reading the next databank
        return $self->next;
    }
}

#-----------------------------------------------------------------
#
#  MRS::Client::Hit ... container for basics of a found result
#
#-----------------------------------------------------------------
package MRS::Client::Hit;

our $VERSION = '1.0.1'; # VERSION

sub new {
    my ($class, %hit) = @_;

    # create an object and fill it from $file
    my $self = bless {}, ref ($class) || $class;
    foreach my $key (keys %hit) {
        $self->{$key} = $hit {$key};
    }

    # done
    return $self;
}

sub db     { return shift->{db}; }
sub id     { return shift->{id}; }
sub title  { return shift->{title}; }
sub score  {
    my $score = shift->{score};
    return (ref ($score) ? $score->bstr() : $score);
}

use overload q("") => "as_string";
sub as_string {
    my $self = shift;
    $self->db . "\t" . $self->id . "\t" . $self->score . "\t" . $self->title;
}

1;


=pod

=head1 NAME

MRS::Client - Representation of an MRS query - on a client side

=head1 VERSION

version 1.0.1

=head1 NAME

MRS::Client::Find - part of a SOAP-based client accessing MRS databases

=head1 REDIRECT

For the full documentation of the project see please:

   perldoc MRS::Client

=head1 AUTHOR

Martin Senger <martin.senger@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Senger, CBRC - KAUST (Computational Biology Research Center - King Abdullah University of Science and Technology) All Rights Reserved..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

