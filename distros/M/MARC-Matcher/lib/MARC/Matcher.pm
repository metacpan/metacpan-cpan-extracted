package MARC::Matcher;

use strict;
use warnings;

use Text::LevenshteinXS qw(distance);
use MARC::Loop qw(marcparse marcfield marcbuild TAG VALREF SUBS SUB_ID SUB_VALREF);

use vars qw($VERSION $a $b);  # Silly warning...

$VERSION = '0.02';

# $matcher = MARC::Matcher->new(
#     'matchpoints' => $file_or_file_handle_or_hash,
# );
# $matcher->target($marc);
# while (<STDIN>) {
#     ($score, @details) = $matcher->match($_);
#     print if $score > 50;
# }

sub new {
    my $cls = shift;
    bless { @_ }, $cls;
}

sub target {
    my $self = shift;
    return ${ $self->{'tref'} } if !@_;
    delete $self->{'mkey2tvals'};
    my $marc = shift;
    $self->{'tref'} = ref($marc) ? $marc : \$marc;
    return $marc;
}

sub matchpoints {
    my $self = shift;
    my $m = $self->{'matchpoints'} ||= [];
    return @$m if !@_;
    @$m = (@_ == 1 && ref($_[0]) eq 'ARRAY') ? @{ shift() } : @_;
    return @$m;
}

sub prepare {
    my ($self) = @_;
    my $m = $self->{'matchpoints'} || die "No matchpoints";
    foreach (@$m) {
        $_->{'threshold'} = 0.0 if !defined $_->{'threshold'};
        $_->{'weight'} or die;
        $_->{'minscore'} = 0     if !defined $_->{'minscore'};
        $_->{'maxscore'} = 2**31 if !defined $_->{'maxscore'};
        $_->{'comparison'} ||=
            $_->{'exact'}
                ? sub { $a cmp $b }
                : sub {
                    my $alen = length $a;
                    my $blen = length $b;
                    return 1.0 if !$alen || !$blen;
                    my $d = distance($a, $b);
                    return $d / ($alen > $blen ? $alen : $blen);
                };
        next if defined $_->{'key'};
        my ($tdef, $cdef) = @$_{qw(target candidate)};
        $_->{'key'} = join('::', $_->{'target'}{'key'}, $_->{'candidate'}{'key'});
    }
    return $self;
}

sub match {
    my $self = shift;
    my ($cleader, $cfields);
    if (@_ == 2) {
        ($cleader, $cfields) = @_;
    }
    elsif (@_ == 1) {
        my $cand = shift;
        my $ref = ref $cand;
        my ($cleader, $cfields) = 
            $ref eq ''       ? marcparse(\$cand) :
            $ref eq 'SCALAR' ? marcparse($cand)  :
            $ref eq 'ARRAY'  ? @$cand            :
            die "Can't match a $ref"
        ;
    }
    else {
        die;
    }
    my $mkey2tvals = $self->{'mkey2tvals'} ||= $self->build_target_values;
    my $score = 0;
    my @details;
    foreach my $m ($self->matchpoints) {
        my ($mkey, $tdef, $cdef, $thr, $w, $smin, $smax, $cmp)
            = @$m{qw(key target candidate threshold weight minscore maxscore comparison)};
        my @cvals = $self->build_values($cdef, $cleader, $cfields);
        my $tbest = $tdef->{'best'};
        my $cbest = $cdef->{'best'};
        my @results;
        foreach my $tval (@{ $mkey2tvals->{$mkey} }) {
            foreach my $cval (@cvals) {
                local $a = $tval;
                local $b = $cval;
                my $d = my $raw_distance = $cmp->();
                next if !defined $d;
                # abs($d) == 0  -> exactly equal
                # abs($d) == 1  -> totally dissimilar
                $d = abs $d;         # Map [-1,0) to (0,1]
                $d = 1 if $d > 1;    # Pin to [0,1]
                my $s = 1 - $d;      # Similarity = 1 - distance
                next if $s < $thr;   # Skip if too small
                push @results, {
                    'score' => $w * $s,
                    'raw_distance' => $raw_distance,
                    'target' => $tval,
                    'candidate' => $cval,
                };
            }
        }
        if (defined $tbest) {
            # TODO: use the best n values
            die "Not yet implemented";
        }
        if (defined $cbest) {
            # TODO: use the best n values
            die "Not yet implemented";
        }
        # Comparison is done for the purposes of this matchpoint
        my $mscore = 0;
        foreach my $r (@results) {
            my ($s, $t, $c) = @$r{qw(score target candidate)};
            $mscore += $s;
        }
        $mscore = $smax if $mscore > $smax;
        my $drop = ( $mscore < $smin );
        push @details, {
            'matchpoint' => $m,
            'score' => $mscore,
            'results' => \@results,
            'dropped' => $drop,
        };
        next if $drop;
        $score += $mscore;
    }
    return $score, @details;
}

sub build_target_values {
    my ($self) = @_;
    $self->prepare;
    my $tref = $self->{'tref'} || die "No target specified";
    my ($tleader, $tfields) = marcparse($tref);
    my %tvals;
    foreach my $m ($self->matchpoints) {
        my ($mkey, $tdef, $cdef) = @$m{qw(key target candidate)};
        my @values = $self->build_values($tdef, $tleader, $tfields);
        $tvals{$mkey} = \@values;
    }
    return \%tvals;
}

sub build_values {
    my ($self, $valdef, $leader, $fields) = @_;
    my $field = $valdef->{'field'};
    my @norm = @{ $valdef->{'normalize'} || [] };
    my @values;
    if ($field eq 'leader') {
        my ($b, $n) = @{ $valdef->{'leader'} };
        @values = ( substr($leader, $b, $n) );
    }
    else {
        my @fields = grep { $_->[TAG] eq $field } @$fields;
        return if !@fields;
        my $index = $valdef->{'index'};
        if ($index && $index ne '*') {
            if ($index > 0) {
                # First $index instance(s)
                splice @fields, $index;
            }
            else {
                # Last -$index instance(s)
                splice @fields, 0, $index;
            }
        }
        my $subseq = $valdef->{'subfields'};
        my (@subs, %want_sub);
        if (defined $subseq && length $subseq) {
            @subs = split //, $subseq;
            %want_sub = map { $_ => 1 } @subs;
        }
        foreach my $f (@fields) {
            if ($field lt '010') {
                my $val = ${ $f->[VALREF] };
                $val = $_->($val) for @norm;
                push @values, $val;
            }
            else {
                my $val;
                if (%want_sub) {
                    my %subval;
                    foreach my $sub (@$f[SUBS..$#$f]) {
                        my ($id, $valref) = @$sub;
                        next if !$want_sub{$id};
                        $subval{$id} = $$valref;
                    }
                    $val = join(' ', grep { defined && length } map { $subval{$_} } @subs);
                    $val = $_->($val) for @norm;
                }
                else {
                    $val = ${ $f->[VALREF] };
                    $val =~ s/^..\x1f.//;
                    $val =~ s/\x1f./ /g;
                    $val = $_->($val) for @norm;
                }
                push @values, $val if defined $val && length $val;
            }
        }
    }
    return @values;
}

1;
