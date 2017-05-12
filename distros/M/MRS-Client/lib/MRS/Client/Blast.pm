#-----------------------------------------------------------------
# MRS::Client::Blast
# Authors: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see MRS::Client pod.
#
# ABSTRACT: Blast invocation and results
# PODNAME: MRS::Client
#-----------------------------------------------------------------
use warnings;
use strict;
package MRS::Client::Blast;

our $VERSION = '1.0.1'; # VERSION

use Carp;
use MRS::Constants;

# all created jobs
our %jobs = ();

#-----------------------------------------------------------------
# rather internal, user should use rather Client->blast
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

#-----------------------------------------------------------------
# create and run a job with the given parameters; once you get back
# Job's ID, remember it together with previously run jobs
# -----------------------------------------------------------------
sub run {
    my ($self, %args) = @_;

    my $job = MRS::Client::Blast::Job->_new (client => $self->{client});
    $job->_run (%args);
    $jobs{ $job->{id} } = $job;
    return $job;
}

#-----------------------------------------------------------------
#
# -----------------------------------------------------------------
sub find_job {
    my ($self, $jobid) = @_;
    return $jobs{$jobid};
}

#-----------------------------------------------------------------
# Find or recreate job by its ID.
# -----------------------------------------------------------------
sub job {
    my ($self, $jobid, %args) = @_;
    return $jobs{$jobid} if $jobs{$jobid};
    my $job = MRS::Client::Blast::Job->_new (client => $self->{client},
                                             id     => $jobid);
    $job->_set_parameters (%args) if %args;  # good for XML output
    $jobs{ $job->{id} } = $job;
    return $job;
}

#-----------------------------------------------------------------
# The MRS server does the cleaning this way:
#
# "Blast results are kept for an hour or until the the cache contains
# more than a hundred entries or until databanks are reloaded,
# whichever comes first."
#
# Therefore, this method is not really useful/needed... [I guess].
# -----------------------------------------------------------------
sub remove_job {
    my ($self, $jobid) = @_;
    delete $jobs{$jobid};
}

#-----------------------------------------------------------------
#
#  MRS::Client::Blast::Job ... a Blast execution and results
#
#-----------------------------------------------------------------
package MRS::Client::Blast::Job;

our $VERSION = '1.0.1'; # VERSION

use Carp;

#-----------------------------------------------------------------
# In arguments, it should get: client, [jobid]
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

sub id          { return shift->{id}; }          # Job ID
sub db          { return shift->{db}; }          # databank
sub fasta       { return shift->{fasta}; }       # input query
sub fasta_file  { return shift->{fasta_file}; }  # input file with a query
sub filter      { return shift->{filter}; }      # low complexity filter (boolean)
sub expect      { return shift->{expect}; }      # E-value cuttoff (float)
sub word_size   { return shift->{word_size}; }   # word size (integer)
sub matrix      { return shift->{matrix}; }      # scoring matrix
sub open_cost   { return shift->{open_cost}; }   # gap opening cost (integer)
sub extend_cost { return shift->{extend_cost}; } # gap extension cost (integer)
sub query       { return shift->{query}; }       # MRS query to limit the search space
sub max_hits    { return shift->{max_hits}; }    # limit reported hits (integer)
sub gapped      { return shift->{gapped}; }      # performs gapped alignment  (boolean)
sub program     { return shift->{program}; }     # only blastp (so-far)

use overload q("") => "as_string";
sub as_string {
    my $self = shift;
    my $input;
    if ($self->{fasta}) {
        ($input) = $self->{fasta} =~ m/(^.+\n)/;
    }
    my $r = '';
    $r .= "Job ID:             " . $self->id          . "\n" if $self->id;
    $r .= "Databank:           " . $self->db          . "\n" if $self->db;
    $r .= "Low complexity:     " . $self->filter      . "\n" if $self->filter;
    $r .= "E-value cutoff:     " . $self->expect      . "\n" if $self->expect;
    $r .= "Word size:          " . $self->word_size   . "\n" if $self->word_size;
    $r .= "Matrix:             " . $self->matrix      . "\n" if $self->matrix;
    $r .= "Gap opening cost:   " . $self->open_cost   . "\n" if $self->open_cost;
    $r .= "Gap extension cost: " . $self->extend_cost . "\n" if $self->extend_cost;
    $r .= "MRS query:          " . $self->query       . "\n" if $self->query;
    $r .= "Max hits number:    " . $self->max_hits    . "\n" if $self->max_hits;
    $r .= "Gapped alignment:   " . $self->gapped      . "\n" if $self->gapped;
    $r .= "Program:            " . $self->program     . "\n" if $self->program;
    $r .= "Input:              " . $input if $input;
    return $r;
}

#-----------------------------------------------------------------
# Set default values, swallow run arguments. Return itself.
# -----------------------------------------------------------------
sub _set_parameters {
    my ($self, %args) = @_;

    # set default values
    $self->{filter} = 1;
    $self->{expect} = 10.0;
    $self->{word_size} = 3;
    $self->{matrix} = 'BLOSUM62';
    $self->{open_cost} = 11;
    $self->{extend_cost} = 1;
    $self->{gapped} = 1;
    $self->{max_hits} = 250;
    $self->{program} = 'blastp';

    # fill object from $args
    foreach my $key (keys %args) {
        $self->{$key} = $args {$key};
    }

    # some arguments checking and dealing with
    croak ("Blast cannot be run without a 'db' parameter.\n")
        unless $self->{db};
    warn "Both arguments 'fasta' and 'fasta_file' are given. The 'fasta_file' will be ignored.\n"
        and delete $self->{fasta_file}
        if $self->fasta and $self->fasta_file;

    # slurp the input fasta file
    if ($self->{fasta_file}) {
        open (my $fasta, '<', $self->{fasta_file})
            or croak ("Cannot open file '" . $self->{fasta_file} . "':" . $! . "\n");
        local $/ = undef;
        $self->{fasta} = <$fasta>;
        close $fasta;
    }
    my ($seq_id, $seq_desc);
    if ($self->{fasta}) {
        ($seq_id, $seq_desc) = $self->{fasta} =~ m/^>(\S+)\s*(.+)?\n/;
    }
    my ($seq) = $self->{fasta} =~ m/^>[^\n]*\n(.*)/s;
    $self->{seq_id} = $seq_id if $seq_id;
    $self->{seq_desc} = $seq_desc if $seq_desc;
    $self->{seq_len} = length ($seq) if $seq;

    # more checking...
    croak ("Blast cannot be run without a 'fasta' or 'fasta_file' parameter.\n")
        unless $self->{fasta};

    return $self;
}

#-----------------------------------------------------------------
# Set default values, swallow arguments, and run a blast job. At the
# end, fill in the job ID and return itself.
# -----------------------------------------------------------------
sub _run {
    my $self = shift;
    $self->_set_parameters (@_);

    # start Blast
    my $params = {
        matrix              => $self->matrix,
        wordSize            => $self->word_size,
        expect              => $self->expect,
        lowComplexityFilter => ($self->filter ? 1 : 0),
        gapped              => ($self->gapped ? 1 : 0),
        gapOpen             => $self->open_cost,
        gapExtend           => $self->extend_cost,
    };

    $self->{client}->_create_proxy ('blast');
    my $args = {
        query           => $self->fasta,
        program         => $self->program,
        db              => $self->db,
        reportLimit     => ($self->max_hits),
        params          => $params,
    };
    $args->{mrsBooleanQuery} = ($self->{query} ? $self->query : '')
        unless $self->{client}->is_v6;
    my $answer = $self->{client}->_call (
        $self->{client}->{blast_proxy}, 'Blast', $args);

    $self->{id} =  $answer->{parameters}->{jobId};
    $self->{status} = MRS::JobStatus->UNKNOWN;
    return $self;
}

#-----------------------------------------------------------------
#
# -----------------------------------------------------------------
sub status {
    my $self = shift;

    return $self->{status} if $self->_done;

    $self->{client}->_create_proxy ('blast');
    my $answer = $self->{client}->_call (
        $self->{client}->{blast_proxy}, 'BlastJobStatus',
        { jobId => $self->{id} });

    $self->{status} = $answer->{parameters}->{status};
    return  $self->{status};
}

# check if completed but without going to the server; which means that
# returning false does not mean that it was not completed
sub _done {
    my $self = shift;
    return 0 unless $self->{status};
    return
        $self->{status} eq MRS::JobStatus->FINISHED or
        $self->{status} eq MRS::JobStatus->ERROR;
}

#-----------------------------------------------------------------
# Return 1 if the current job status is either finished or error.
# -----------------------------------------------------------------
sub completed {
    my $self = shift;
    $self->status;
    return $self->_done;
}

#-----------------------------------------------------------------
# Return 1 if the current job status is an error.
# -----------------------------------------------------------------
sub failed {
    my $self = shift;
    $self->status;
    return $self->{status} eq MRS::JobStatus->ERROR;
}

#-----------------------------------------------------------------
# Return error message; or undef if the job is not in the error
# status.
# -----------------------------------------------------------------
sub error {
    my $self = shift;
    return unless $self->failed;

    $self->{client}->_create_proxy ('blast');
    my $answer = $self->{client}->_call (
        $self->{client}->{blast_proxy}, 'BlastJobError',
        { jobId => $self->{id} });
    # # TBD
    # use Data::Dumper;
    # print Dumper ($answer);
    return $answer->{parameters}->{error};
}

#-----------------------------------------------------------------
# Return results; or undef if the job is not completed, or if it
# is in the error state.
# $format should be one of MRS::BlastOutputFormat; default is HITS.
# -----------------------------------------------------------------
sub results {
    my ($self, $format) = @_;
    return unless $self->completed;
    return if $self->failed;
    $format = MRS::BlastOutputFormat->HITS
        unless MRS::BlastOutputFormat->check ($format);

    $self->{client}->_create_proxy ('blast');
    my $answer = $self->{client}->_call (
        $self->{client}->{blast_proxy}, 'BlastJobResult',
        { jobId => $self->{id} });

    $answer->{parameters}->{format} = $format;
    return MRS::Client::Blast::Result->_new ($answer->{parameters}, $self);
}

#-----------------------------------------------------------------
#
#  MRS::Client::Blast::Result
#
#-----------------------------------------------------------------
package MRS::Client::Blast::Result;

our $VERSION = '1.0.1'; # VERSION

use File::Basename;

sub _new {
    my ($class, $data, $job) = @_;  # $data is a hashref (from $answer->{parameters})

    # create an object
    my $self = bless {}, ref ($class) || $class;

    $self->{job}  = $job;
    $self->{format}    = $data->{format};

    # in MRS 6, the result itself is hidden deeper in $data
    if (exists $data->{result}) {
        $data = $data->{result};
    }

    $self->{db_count}  = $data->{dbCount};
    $self->{db_length} = $data->{dbLength};
    $self->{db_space}  = $data->{effectiveSearchSpace};
    $self->{kappa}     = $data->{kappa};
    $self->{lambda}    = $data->{lambda};
    $self->{entropy}   = $data->{entropy};

    $self->{hits} = [];  # MRS::Client::Blast::Hit
    if ($data->{hits}) {
        foreach my $hit (@{ $data->{hits} }) {
            push (@{ $self->{hits} },
                  MRS::Client::Blast::Hit->_new ($hit, $self->{format}));
        }
    }

    # done
    return $self;
}

sub db_count  { return shift->{db_count}; }   # unsigned int
sub db_length { return shift->{db_length}; }  # unsigned long
sub db_space  { return shift->{db_space}; }   # unsigned long (effective search space)
sub kappa     { return shift->{kappa}; }      # double
sub lambda    { return shift->{lambda}; }     # double
sub entropy   { return shift->{entropy}; }    # double
sub hits      { return shift->{hits}; }       # refarray of Hits

use overload q("") => "as_string";
sub as_string {
    my $self = shift;
    return $self->convert2xml
        if $self->{format} eq MRS::BlastOutputFormat->XML;
    my $r = '';
    if ($self->{format} eq MRS::BlastOutputFormat->STATS or
        $self->{format} eq MRS::BlastOutputFormat->FULL) {
        $r .= "DB count:     " . $self->db_count  . "\n" if defined $self->db_count;
        $r .= "DB length:    " . $self->db_length . "\n" if defined $self->db_length;
        $r .= "Search space: " . $self->db_space  . "\n" if defined $self->db_space;
        $r .= "Kappa:        " . $self->kappa     . "\n" if defined $self->kappa;
        $r .= "Lambda:       " . $self->lambda    . "\n" if defined $self->lambda;
        $r .= "Entropy:      " . $self->entropy   . "\n" if defined $self->entropy;
    }
    unless ($self->{format} eq MRS::BlastOutputFormat->STATS) {
        $r .= $_ foreach @{ $self->{hits} };
    }
    return $r;
}

sub convert2xml {
    my $self = shift;
    my $template_file = 'blast.result.xml.template';
    my $r =
        MRS::Client::_readfile ( (fileparse (__FILE__))[-2] . $template_file );

    # output general header and used parameters
    $r =~ s/\${JOBID}/$self->{job}->{id}/eg;
    if ($self->{job}->{seq_desc}) {
        $r =~ s/\${SEQDESC}/$self->{job}->{seq_desc}/eg;
    } elsif ($self->{job}->{seq_id}) {
        $r =~ s/\${SEQDESC}/$self->{job}->{seq_id}/eg;
    } else {
        $r =~ s/\${SEQDESC}//g;
    }
    $r =~ s/\${DB}/($self->{job}->{db} ? $self->{job}->{db} : '')/e;
    $r =~ s/\${SEQLEN}/($self->{job}->{seq_len} ? $self->{job}->{seq_len} : '')/e;
    $r =~ s/\${PARMATRIX}/($self->{job}->matrix ? $self->{job}->matrix : '')/e;
    $r =~ s/\${PAREXPECT}/($self->{job}->expect ? $self->{job}->expect : '')/e;
    $r =~ s/\${PARGAPOPEN}/($self->{job}->open_cost ? $self->{job}->open_cost : '')/e;
    $r =~ s/\${PARGAPEXTEND}/($self->{job}->extend_cost ? $self->{job}->extend_cost : '')/e;
    $r =~ s/\${PARFILTER}/($self->{job}->filter ? "<Parameters_filter>S<\/Parameters_filter>" : '')/e;

    $r =~ s/\${DBCOUNT}/($self->db_count ? $self->db_count : '0')/e;
    $r =~ s/\${DBLENGTH}/($self->db_length ? $self->db_length : '0')/e;
    $r =~ s/\${DBSPACE}/($self->db_space ? $self->db_space : '0')/e;
    $r =~ s/\${KAPPA}/($self->kappa ? $self->kappa : '0')/e;
    $r =~ s/\${LAMBDA}/($self->lambda ? $self->lambda : '0')/e;
    $r =~ s/\${ENTROPY}/($self->entropy ? $self->entropy : '0')/e;

    # output hits
    my $hits = '';
    my ($hit_template) = $r =~ m|\$\$HITSTART(.*)\$\$HITEND|s;
    my $hit_count = 1;
    foreach my $hit (@{ $self->{hits} }) {
        next unless $hit->id;   # probably paranoia
        my $rh = $hit_template; # clone the template
        $rh =~ s/\${HITNR}/$hit_count/;
        $rh =~ s/\${HITID}/$hit->id/eg;
        if ($hit->sequences and @{ $hit->sequences }>0) {
            $rh =~ s/\${HITSEQID}/"<Hit_sequenceId>".@{ $hit->sequences }[0]."<\/Hit_sequenceId>"/e;
        } else {
            $rh =~ s/\${HITSEQID}//;
        }
        if ($hit->hsps and @{ $hit->hsps } > 0) {
            $rh =~ s/\${HITSUBLEN}/@{ $hit->hsps }[0]->subject_length/e;

            # output HSPs
            my $hsps = '';
            my ($hsp_template) = $rh =~ m|\$\$HSPSTART(.*)\$\$HSPEND|s;
            my $hsp_count = 1;
            foreach my $hsp (@{ $hit->{hsps} }) {
                my $rhs = $hsp_template; # clone the template

                $rhs =~ s/\${HSPNR}/$hsp_count/;
                $rhs =~ s/\${HSPBITSCORE}/($hsp->bit_score ? $hsp->bit_score : '0')/e;
                $rhs =~ s/\${HSPSCORE}/($hsp->score ? $hsp->score : '0')/e;
                $rhs =~ s/\${HSPEXPECT}/($hsp->expect ? sprintf ("%e", $hsp->expect) : '0')/e;
                $rhs =~ s/\${HSPIDENTITY}/($hsp->identity ? $hsp->identity : '0')/e;
                $rhs =~ s/\${HSPPOSITIVE}/($hsp->positive ? $hsp->positive : '0')/e;
                $rhs =~ s/\${HSPMIDLINE}/($hsp->midline ? $hsp->midline : '')/e;

                my $query_from = ($hsp->query_start ? $hsp->query_start+1 : '1');
                my $query_to = $query_from;
                my $subject_from = ($hsp->subject_start ? $hsp->subject_start+1 : '1');
                my $subject_to = $subject_from;
                my $query_align = ($hsp->query_align ? $hsp->query_align : '');
                my $subject_align = ($hsp->subject_align ? $hsp->subject_align : '');

                my $query_align_len = length ($query_align);
                for (my $offset = 0; $offset < $query_align_len; ++$offset) {
                    my $strlen = $query_align_len - $offset;
                    $strlen = 60 if $strlen > 60;  # kMaxStringLength
                    my $q = substr ($query_align, $offset, $strlen);
                    my $s = substr ($subject_align, $offset, $strlen);
                    my $q_dash_count = ($q =~ tr/-//);
                    $query_to += (length ($q) - $q_dash_count);
                    my $s_dash_count = ($s =~ tr/-//);
                    $subject_to += (length ($s) - $s_dash_count);

                    $offset += $strlen - 1;
                }
                $rhs =~ s/\${HSPQFROM}/$query_from/;
                $rhs =~ s/\${HSPQTO}/$query_to/;
                $rhs =~ s/\${HSPHFROM}/$subject_from/;
                $rhs =~ s/\${HSPHTO}/$subject_to/;
                $rhs =~ s/\${HSPALIGNLEN}/$query_align_len/;
                $rhs =~ s/\${HSPQALIGN}/$query_align/;
                $rhs =~ s/\${HSPSUBALIGN}/$subject_align/;

                $hsps .= $rhs;
                $hsp_count++;
            }
            $rh =~ s/\$\$HSPSTART(.*)\$\$HSPEND/$hsps/s;
        } else {
            $rh =~ s/\$\$HSPSTART(.*)\$\$HSPEND//s;
        }
        $hits .= $rh;
        $hit_count++;
    }
    $r =~ s/\$\$HITSTART(.*)\$\$HITEND/$hits/s;
    return $r;
}

#-----------------------------------------------------------------
#
#  MRS::Client::Blast::Hit
#
#-----------------------------------------------------------------
package MRS::Client::Blast::Hit;

our $VERSION = '1.0.1'; # VERSION

sub _new {
    # $data is a hashref (from $answer->{parameters}->{hits})
    my ($class, $data, $format) = @_;

    # create an object
    my $self = bless {}, ref ($class) || $class;

    $self->{id}  = $data->{id};
    $self->{title} = $data->{title};
    $self->{sequences} = ($data->{sequenceId} or []);
    $self->{format}  = $format;

    $self->{hsps} = [];  # refarray of MRS::Client::Blast::HSP
    if ($data->{hsps}) {
        foreach my $hsp (@{ $data->{hsps} }) {
            push (@{ $self->{hsps} }, MRS::Client::Blast::HSP->_new ($hsp));
        }
    }

    # done
    return $self;
}

sub id        { return shift->{id}; }
sub title     { return shift->{title}; }
sub sequences { return shift->{sequences}; }  # refarray of sequence IDs
sub hsps      { return shift->{hsps}; }       # refarray of HSPs

use overload q("") => "as_string";
sub as_string {
    my $self = shift;
    my $seqs = join (",", @{ $self->sequences });
    $seqs = " ($seqs)" if $seqs;
    if ($self->{format} eq MRS::BlastOutputFormat->FULL) {
        return sprintf ("[%-20s] %s %s\n%s\n",
                        ($self->id or ''),
                        ($self->title or ''),
                        $seqs,
                        join ("\n", @{ $self->hsps }));
    } else {
        my $bit_score = 0;
        my $expect = 0;
        my $hsps_size = 0;
        if ($self->hsps and @{ $self->hsps } > 0) {
            $hsps_size = scalar @{ $self->hsps };
            $bit_score = $self->hsps->[0]->bit_score;
            $expect = $self->hsps->[0]->expect;
        }
        return sprintf ("%7.1f %15e  [%-20s]%3d %s %s\n",
                        $bit_score,
                        $expect,
                        ($self->id or ''),
                        $hsps_size,
                        ($self->title or ''),
                        $seqs);
    }
}

#-----------------------------------------------------------------
#
#  MRS::Client::Blast::HSP ... high-scoring seqment pairs
#
#-----------------------------------------------------------------
package MRS::Client::Blast::HSP;

our $VERSION = '1.0.1'; # VERSION

sub _new {
    my ($class, $data) = @_;  # $data is a hashref (from $answer->{parameters}->{hits})

    # create an object
    my $self = bless {}, ref ($class) || $class;

    $self->{score}          = $data->{score};
    $self->{bit_score}      = $data->{bitScore};
    $self->{expect}         = $data->{expect};
    $self->{query_start}    = $data->{queryStart};
    $self->{subject_start}  = $data->{subjectStart};
    $self->{identity}       = $data->{identity};
    $self->{positive}       = $data->{positive};
    $self->{gaps}           = $data->{gaps};
    $self->{subject_length} = $data->{subjectLength};
    $self->{query_align}    = $data->{queryAlignment};
    $self->{subject_align}  = $data->{subjectAlignment};
    $self->{midline}        = $data->{midline};

    # done
    return $self;
}

sub score          { return shift->{score}; }          # unsigned int
sub bit_score      { return shift->{bit_score}; }      # double
sub expect         { return shift->{expect}; }         # double
sub query_start    { return shift->{query_start}; }    # unsigned int
sub subject_start  { return shift->{subject_start}; }  # unsigned int
sub identity       { return shift->{identity}; }       # unsigned int
sub positive       { return shift->{positive}; }       # unsigned int
sub gaps           { return shift->{gaps}; }           # unsigned int
sub subject_length { return shift->{subject_length}; } # unsigned int
sub query_align    { return shift->{query_align}; }    # string
sub subject_align  { return shift->{subject_align}; }  # string
sub midline        { return shift->{midline}; }        # string

use overload q("") => "as_string";
sub add { return $_[0] . $_[1] . "\n" if defined $_[1]; }
sub as_string {
    my $self = shift;
    my $r = '';
    $r .= add ("Score:             ", $self->score);
    $r .= add ("Bit Score:         ", $self->bit_score);
    $r .= add ("Expect:            ", $self->expect);
    $r .= add ("Query start:       ", $self->query_start);
    $r .= add ("Subject start:     ", $self->subject_start);
    $r .= add ("Identity:          ", $self->identity);
    $r .= add ("Positive:          ", $self->positive);
    $r .= add ("Gaps:              ", $self->gaps);
    $r .= add ("Subject length:    ", $self->subject_length);
    $r .= add ("Query alignment:   ", $self->query_align);
    $r .= add ("Subject alignment: ", $self->subject_align);
    $r .= add ("Midline:           ", $self->midline);
    return $r;
}

1;


=pod

=head1 NAME

MRS::Client - Blast invocation and results

=head1 VERSION

version 1.0.1

=head1 NAME

MRS::Client::Blast - part of a SOAP-based client accessing MRS databases

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

