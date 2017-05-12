package Flower::Chronos::Report;

use strict;
use warnings;

use Time::Piece;
use JSON        ();
use Digest::MD5 ();
use Flower::Chronos::Utils qw(parse_time);
use Encode;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{log_file} = $params{log_file};
    $self->{where}    = $params{where};
    $self->{group_by} = $params{group_by};
    $self->{fields}   = $params{fields};
    $self->{from}     = $params{from};
    $self->{to}       = $params{to};

    return $self;
}

sub run {
    my $self = shift;

    my @group_by = split /\s*,\s*/, ($self->{group_by} || '');

    my $where_cb;
    if (my $where = $self->{where}) {
        $where =~ s{\$([a-z]+)}{\$_[0]->{$1}}g;
        $where = "sub {no warnings; $where }";

        $where_cb = eval $where or die $@;
    }

    open my $fh, '<', $self->{log_file} or die $!;

    my @from = (gmtime(time))[3 .. 5];
    my $from = join '-', ($from[2] + 1900), ($from[1] + 1), $from[0];
    $from = parse_time($from);
    my $to = time;

    $from = parse_time($self->{from}) if defined $self->{from};
    $to   = parse_time($self->{to})   if $self->{to};

    my @records;
    while (defined(my $line = <$fh>)) {
        chomp $line;
        next unless $line;

        my $record = eval { JSON::decode_json($line) };
        next unless $record;

        my $start = $record->{_start};
        my $end   = $record->{_end};
        next if !$start || !$end || $end < $start;

        next
          unless ($start >= $from && $start <= $to)
          || ($end >= $from && $end <= $to);
        if ($start < $from) {
            $start = $from;
        }
        if ($end > $to) {
            $end = $to;
        }

        next if $where_cb && !$where_cb->($record);

        $record->{_elapsed} = $end - $start;
        $record->{_sig} = calculate_sig($record, @group_by);
        push @records, $record;
    }

    my %groups;
    foreach my $record (@records) {
        if (exists $groups{$record->{_sig}}) {
            $groups{$record->{_sig}}->{_elapsed} += $record->{_elapsed};
        }
        else {
            $groups{$record->{_sig}} = $record;
        }
    }

    my @sorted_sig =
      sort { $groups{$b}->{_elapsed} <=> $groups{$a}->{_elapsed} } keys %groups;

    foreach my $sig (@sorted_sig) {
        my $record = $groups{$sig};
        $self->_print(sec2human($record->{_elapsed}), ' ');

        my @fields = split /\s*,\s*/, ($self->{fields} || '');
        @fields = @group_by unless @fields;
        foreach my $field (@fields) {
            $self->_print("$field=$record->{$field} ");
        }

        $self->_print("\n");
    }
}

sub calculate_sig {
    my ($record, @group_by) = @_;

    return '' unless @group_by;

    my $sig = '';
    foreach my $group_by (@group_by) {
        $record->{$group_by} //= '';
        $sig .= $record->{$group_by} . ':';
    }

    $sig = Encode::encode('UTF-8', $sig);
    return Digest::MD5::md5_hex($sig);
}

sub sec2human {
    my $sec = shift;

    return
        sprintf('%02d', int($sec / (24 * 60 * 60))) . 'd '
      . sprintf('%02d', ($sec / (60 * 60)) % 24) . ':'
      . sprintf('%02d', ($sec / 60) % 60) . ':'
      . sprintf('%02d', $sec % 60);
}

sub _print {
    my $self = shift;

    print @_;
}

1;
