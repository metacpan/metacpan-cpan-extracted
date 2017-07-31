package MARC::Indexer;

use strict;
use warnings;

$MARC::Indexer::VERSION = '0.04';

use MARC::Indexer::Config;
use MARC::Loop qw(marcparse TAG VALREF);
use Unicode::Normalize;
use POSIX qw(strftime);

sub new {
    my $cls = shift;
    bless { @_ }, $cls;
}

sub compile {
    my ($self) = @_;
    if (!$self->{'is_compiled'}) {
        my %source2eval;
        $self->{'source2eval'} = \%source2eval;
        foreach my $term (values %{ $self->{'terms'} }) {
            my ($name, $source, $derived, $norm, $match, $repeat)
                = @$term{qw(name source derived norm match repeat)};
            my $eval;
            if ($derived) {
                $eval = derived2eval($term);
            }
            else {
                $eval = $source2eval{$source} ||= source2eval($source);
                $self->{'want'}{source2tag($source)} = 1;
            }
            $term->{'eval'} = $eval;
            $term->{'norm'} = mknorm(@$norm);
        }
    }
    $self->{'is_compiled'} = 1;
}

sub mknorm {
    return sub { $_ } if !@_ || !defined $_[0];
    my @subs = map { __PACKAGE__->can('norm_'.trim($_)) || die "Unknown normalizer: $_" } @_;
    return sub {
        my ($v) = @_;
        return if !defined $v;
        foreach my $sub (@subs) {
            $v = $sub->($v);
            return if !defined $v;
        }
        return $v;
    };
}

sub derived2eval {
    my ($term) = @_;
    if ($term->{'permuted'}) {

    }
    else {

    }
}

sub source2tag {
    return 'M' if $_[0] =~ /^::/;
    return 'L' if $_[0] =~ /^(?:L|leader)\b/;
    return $1 if $_[0] =~ /^raw:(...)/;
    return substr($_[0], 0, 3);
}

sub index {
    my ($self, $marc) = @_;
    my $marcref = ref($marc) ? $marc : \$marc;
    # 1. Compile the indexing code if needed
    $self->compile if !$self->{'is_compiled'};
    # 2. Gather all fields used for indexing
    my $data = marcdata($marcref, $self->{'want'});
    # 3. Index each term
    my %index;
    while (my ($name, $term) = each %{ $self->{'terms'} }) {
        next if $term->{'derived'};
        my $tag = source2tag($term->{'source'});
        my @vals = @{ $data->{$tag} or next };
        my $eval = $term->{'eval'} or next;
        my $norm = $term->{'norm'};
        @vals = map { $eval->($_) } @vals;
        @vals = map { $norm->($_) } @vals if $norm;
        next if !@vals;
        splice @vals, 1 if !$term->{'repeat'};
        push @{ $index{$name} ||= [] }, @vals;
    }
    return \%index;
}

sub marcdata {
    my ($marcref, $want) = @_;
    my %data;
    $data{'M'} = [$marcref];
    $data{'L'} = [substr($$marcref, 0, 24)] if $want->{'L'};
    my $baseaddr = substr($$marcref, 12, 5) + 0;
    pos($$marcref) = 24;
    while ($$marcref =~ /\G([0-9A-Za-z]{3})([0-9]{4})([0-9]{5})/gc) {
        push @{ $data{$1} ||= [] }, substr($$marcref, $baseaddr + $3, $2 - 1) if $want->{$1};
    }
    return \%data;
}

sub source2eval {
    my ($source) = @_;
    if ($source =~ m{^(?:L|leader)/(\d+)$}) {
        my $pos = $1;
        return sub { substr($_, $pos, 1) };
    }
    elsif ($source =~ m{^(00[0-9A-Za-z])(?:/(\d+)(?:-(\d+))?)?$}) {
        my ($tag, $b1, $bn) = ($1, $2, $3);
        return sub { substr($_, $b1,$bn-$b1+1) } if defined $bn;
        return sub { substr($_, $b1,        1) } if defined $b1;
        return sub { $_ };
    }
    elsif ($source =~ m{^::(\w+)}) {
        my $sub = __PACKAGE__->can('src_'.$1) || die "Unknown source function: $1";
        return sub {
            my ($marcref) = @_;
            return $sub->($marcref);
        }
    }
    elsif ($source =~ m{^(raw:)?([0-9A-Za-z]{3})\$(.+)$}) {
        my ($raw, $tag, @subs) = ($1, $2, split //, $3);
        my %want = map { $_ => 1 } @subs;
        if ($raw) {
            return sub {
                my @pieces = ( substr($_, 0, 2) );
                pos($_) = 2;
                while (/(\x1f([^\x1f])[^\x1f]+)/gc) {
                    push @pieces, $1 if $want{$2};
                }
                return if @pieces < 2;
                return join('', @pieces);
            };
        }
        else {
            return sub {
                pos($_) = 2;
                my @subs;
                while (/\x1f([^\x1f])([^\x1f]+)/gc) {
                    push @subs, $2 if $want{$1};
                }
                return if !@subs;
                return join(' ', @subs);
            };
        }
    }
}

sub trim {
    local $_ = shift;
    s/^\s+|\s+$//g;
    return $_;
}

sub norm_blank2hash {
    local $_ = shift;
    tr/ /#/;
    return $_;
}

sub norm_date2unix {
    local $_ = shift;
    /^([0-9]{4})-?([0-9]{2})-?([0-9]{2})T?([0-9]{2}):?([0-9]{2}):?([0-9]{2})/ or return 0;
    return strftime('%s', $6, $5, $4, $3, $2-1, $1-1900);
}

sub norm_nfc {
    NFC(shift);
}

sub norm_nfd {
    NFD(shift);
}

sub norm_alpha {
    local $_ = shift;
    tr{'}{}d;
    tr{-=./()[],:;"?!}{ };
    s/[^[:alpha] ]//g;
    tr{ }{}s;
    s/^ | $//g;
    return $_
}

sub norm_uppercase {
    uc shift;
}

sub norm_lowercase {
    lc shift;
}

sub norm_numeric {
    local $_ = shift;
    die if !/^[0-9]+$/;
    $_ + 0;  # This strips leading zeroes
}

sub norm_trim {
    local $_ = shift;
    tr/ / /s;
    s/^ | $//g;
    return $_;
}

sub norm_isbn {
    local $_ = shift;
    tr/-//d;
    my $n = length;
    die if $n != 10 && $n != 13;
    norm_trim(uc $_);
}

sub norm_delnf1 { unshift @_, 1; goto &_remove_non_filing_chars }
sub norm_delnf2 { unshift @_, 2; goto &_remove_non_filing_chars }
sub norm_cook {
    local $_ = shift;
    s/^..\x1f.//;
    s/\x1f./ /g;
    return $_;
}

sub src_pub_date {
    my ($marcref) = @_;
    my ($leader, $fields) = marcparse($marcref);
    my ($f008) = grep { $_->[TAG] eq '008' } @$fields;
    return ($1) if defined($f008) && ${ $f008->[VALREF] } =~ /^.{7}([0-9]{4})/;
    my ($f260) = grep { $_->[TAG] eq '260' } @$fields;
    return ($1) if defined($f260) && ${ $f260->[VALREF] } =~ /\x1fc([0-9]{4})/;
    return ();
}

sub _remove_non_filing_chars {
    my $ind = shift;
    local $_ = shift;
    my $n = substr($_, $ind-1, 1);
    if ($n =~ /[1-9]/) {
        s/(?<=\x1fa)([^\x1f]+)/length($1) <= $n ? $1 : substr($1, $n)/e;
    }
    return $_;
}

1;

=pod

=head1 NAME

MARC::Indexer - index MARC records

=head1 SYNOPSIS

    $indexer = MARC::Indexer->new(
        'index_points' => [
            { 'name' => 'ctrlnum',
              'tag' => '001' },
            { 'name' => 'title',
              'tag' => '245',
              'extract' => 'subfields:abcdnp',
              'normalize' => [qw(text nfd uc)],
            },
            { 'name' => 'subjtopic',
              'tag' => '650',
              'repeatable' => 1,
              ...
            },
            ...
        ],
    );
    $idx = $indexer->index($marc);
    $idx_title = $idx->{'title'};

=cut

