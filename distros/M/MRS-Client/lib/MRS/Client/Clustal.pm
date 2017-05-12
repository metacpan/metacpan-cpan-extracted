#-----------------------------------------------------------------
# MRS::Client::Clustal
# Authors: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see MRS::Client pod.
#
# ABSTRACT: Clustal invocation and results
# PODNAME: MRS::Client
#-----------------------------------------------------------------
use warnings;
use strict;
package MRS::Client::Clustal;

our $VERSION = '1.0.1'; # VERSION

use Carp;

#-----------------------------------------------------------------
# rather internal, user should use rather Client->clustal
#-----------------------------------------------------------------
sub _new {
    my ($class, %args) = @_;

    # create an object
    my $self = bless {}, ref ($class) || $class;

    # fill object from $args
    foreach my $key (keys %args) {
        $self->{$key} = $args {$key};
    }

    # done
    return $self;
}

sub open_cost   { return shift->{open_cost}; }   # gap opening cost (integer)
sub extend_cost { return shift->{extend_cost}; } # gap extension cost (float)

use overload q("") => "as_string";
sub as_string {
    my $self = shift;
    my $r = '';
    $r .= "Gap opening cost:   " . $self->open_cost   . "\n" if $self->open_cost;
    $r .= "Gap extension cost: " . $self->extend_cost . "\n" if $self->extend_cost;
    return $r;
}

#-----------------------------------------------------------------
# execute clustalw with the given parameters; return result object
# -----------------------------------------------------------------
sub run {
    my ($self, %args) = @_;

    # set default values
    $self->{open_cost} = 11;
    $self->{extend_cost} = 1;

    # fill object from $args
    foreach my $key (keys %args) {
        $self->{$key} = $args {$key};
    }

    # arguments checking...
    croak ("Clustal cannot be run without a 'fasta_file' parameter.\n")
        unless $self->{fasta_file};

    # read multi fasta file
    my $sequences = [];  # elements are refhash
    {
        open (my $fasta, '<', $self->{fasta_file})
            or croak ("Cannot open file '" . $self->{fasta_file} . "':" . $! . "\n");
        local $/ = '>'; # record delimiter as expected in $fasta file

        (undef) = scalar <$fasta>; # discard the first (blank) record
        while (my $record = <$fasta>) {
            # split to lines
            my @lines = split "\n", $record;

            # discard the last line if necessary
            pop @lines if $lines[-1] eq '>';

            # take out what is needed
            my ($id) = (shift @lines) =~ /(\S+)/;
            if ($id) {
                push (@{ $sequences }, {id => $id, sequence => uc join ('', @lines)});
            }
        }
    }

    # run Clustal
    $self->{client}->_create_proxy ('clustal');
    my $answer = $self->{client}->_call (
        $self->{client}->{clustal_proxy}, 'ClustalW',
        { input     => $sequences,   # refarray
          gapOpen   => $self->open_cost,
          gapExtend => $self->extend_cost,
        });
    return ($answer ? MRS::Client::Clustal::Result->_new ($answer->{parameters}) : undef);
}

#-----------------------------------------------------------------
#
#  MRS::Client::Clustal::Result
#
#-----------------------------------------------------------------
package MRS::Client::Clustal::Result;

our $VERSION = '1.0.1'; # VERSION

sub _new {
    my ($class, $data) = @_;  # $data is a hashref (from $answer->{parameters})

    # create an object
    my $self = bless {}, ref ($class) || $class;

    $self->{stdout}  = $data->{diagnosticsOut};
    $self->{stderr} = $data->{diagnosticsErr};

    $self->{alignment} = [];  # MRS::Client::Clustal::Sequence
    if ($data->{alignment}) {
        foreach my $sequence (@{ $data->{alignment} }) {
            push (@{ $self->{alignment} },
                  MRS::Client::Clustal::Sequence->_new ($sequence));
        }
    }

    # done
    return $self;
}

sub diagnostics { return shift->{stdout}; }
sub failed      { return shift->{stderr}; }
sub alignment   { return shift->{alignment}; }  # refarray of Sequences

use overload q("") => "as_string";
sub as_string {
    my $self = shift;

    # find the lenth of the longest sequence ID
    my $max_id_len = 0;
    foreach my $seq (@{ $self->alignment }) {
        my $len = length $seq->id;
        $max_id_len = $len if $len > $max_id_len;
    }

    # format alignment
    my $format = "%-${max_id_len}s: %s\n";
    my $r = '';
    foreach my $seq (@{ $self->alignment }) {
        $r .= sprintf ($format, $seq->id, $seq->sequence);
    }
    return $r;
}

#-----------------------------------------------------------------
#
#  MRS::Client::Clustal::Sequence
#
#-----------------------------------------------------------------
package MRS::Client::Clustal::Sequence;

our $VERSION = '1.0.1'; # VERSION

sub _new {
    # $data is a hashref (from $answer->{parameters})
    my ($class, $data) = @_;

    # create an object
    my $self = bless {}, ref ($class) || $class;

    $self->{id} = $data->{id};
    $self->{sequence} = $data->{sequence};

    # done
    return $self;
}

sub id       { return shift->{id}; }
sub sequence { return shift->{sequence}; }

# does not have much sense because individual sequence is not
# important without showing how it aligns with other sequences
use overload q("") => "as_string";
sub as_string {
    my $self = shift;
    return $self->id . "\t" . $self->sequence;
}

1;


=pod

=head1 NAME

MRS::Client - Clustal invocation and results

=head1 VERSION

version 1.0.1

=head1 NAME

MRS::Client::Clustal - part of a SOAP-based client accessing MRS databases

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

