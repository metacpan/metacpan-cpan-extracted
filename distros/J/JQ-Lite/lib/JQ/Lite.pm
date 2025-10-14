package JQ::Lite;

use strict;
use warnings;
use JSON::PP;
use List::Util qw(sum min max);
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.99';

sub new {
    my ($class, %opts) = @_;
    my $self = {
        raw => $opts{raw} || 0,
    };
    return bless $self, $class;
}

sub run_query {
    my ($self, $json_text, $query) = @_;
    my $data = decode_json($json_text);
    
    if (!defined $query || $query =~ /^\s*\.\s*$/) {
        return ($data);
    }
    
    # instead of: my @parts = split /\|/, $query;
    my @parts = map { s/^\s+|\s+$//gr } split /\|/, $query;
    
    # detect .[] and convert to pseudo-command
    @parts = map {
        if ($_ eq '.[]') {
            'flatten'
        } elsif ($_ =~ /^\.(.+)$/) {
            $1
        } else {
            $_
        }
    } @parts;

    my @results = ($data);
    for my $part (@parts) {
        my @next_results;

        # support for flatten (alias for .[])
        if ($part eq 'flatten') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? @$_ : ()
            } @results;
            @results = @next_results;
            next;
        }

        # support for select(...)
        if ($part =~ /^select\((.+)\)$/) {
            my $cond = $1;
            @next_results = grep { _evaluate_condition($_, $cond) } @results;
            @results = @next_results;
            next;
        }

        # support for length
        if ($part eq 'length') {
            @next_results = map {
                if (!defined $_) {
                    0;
                }
                elsif (ref $_ eq 'ARRAY') {
                    scalar(@$_);
                }
                elsif (ref $_ eq 'HASH') {
                    scalar(keys %$_);
                }
                elsif (!ref $_ || ref($_) eq 'JSON::PP::Boolean') {
                    length("$_");
                }
                else {
                    0;
                }
            } @results;
            @results = @next_results;
            next;
        }

        # support for keys
        if ($part eq 'keys') {
            @next_results = map {
                ref $_ eq 'HASH' ? [ sort keys %$_ ] : undef
            } @results;
            @results = @next_results;
            next;
        }

        # support for keys_unsorted
        if ($part eq 'keys_unsorted' || $part eq 'keys_unsorted()') {
            @next_results = map {
                if (ref $_ eq 'HASH') {
                    [ keys %$_ ];
                }
                elsif (ref $_ eq 'ARRAY') {
                    [ 0 .. $#{$_} ];
                }
                else {
                    undef;
                }
            } @results;
            @results = @next_results;
            next;
        }

        # support for sort
        if ($part eq 'sort') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? [ sort { _smart_cmp()->($a, $b) } @$_ ] : $_
            } @results;
            @results = @next_results;
            next;
        }

        # support for sort_desc
        if ($part eq 'sort_desc') {
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $cmp = _smart_cmp();
                    [ sort { $cmp->($b, $a) } @$_ ];
                }
                else {
                    $_;
                }
            } @results;
            @results = @next_results;
            next;
        }

        # support for unique
        if ($part eq 'unique') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? [ _uniq(@$_) ] : $_
            } @results;
            @results = @next_results;
            next;
        }

        # support for unique_by(path)
        if ($part =~ /^unique_by\((.+?)\)$/) {
            my $raw_path = $1;
            $raw_path =~ s/^\s+|\s+$//g;

            my $key_path = $raw_path;
            $key_path =~ s/^['"](.*)['"]$/$1/;

            my $use_entire_item = ($key_path eq '' || $key_path eq '.');
            $key_path =~ s/^\.// unless $use_entire_item;

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my %seen;
                    my @deduped;

                    for my $element (@$_) {
                        my $key_value;

                        if ($use_entire_item) {
                            $key_value = $element;
                        } else {
                            my @values = _traverse($element, $key_path);
                            $key_value = @values ? $values[0] : undef;
                        }

                        my $signature;
                        if (defined $key_value) {
                            $signature = _key($key_value);
                        } else {
                            $signature = "\0__JQ_LITE_UNDEF__";
                        }

                        next if $seen{$signature}++;
                        push @deduped, $element;
                    }

                    \@deduped;
                } else {
                    $_;
                }
            } @results;

            @results = @next_results;
            next;
        }

        # support for first
        if ($part eq 'first') {
            @next_results = map {
                ref $_ eq 'ARRAY' && @$_ ? $$_[0] : undef
            } @results;
            @results = @next_results;
            next;
        }

        # support for last
        if ($part eq 'last') {
            @next_results = map {
                ref $_ eq 'ARRAY' && @$_ ? $$_[-1] : undef
            } @results;
            @results = @next_results;
            next;
        }

        # support for reverse
        if ($part eq 'reverse') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? [ reverse @$_ ] : $_
            } @results;
            @results = @next_results;
            next;
        }

        # support for limit(n)
        if ($part =~ /^limit\((\d+)\)$/) {
            my $limit = $1;
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $arr = $_;
                    my $end = $limit - 1;
                    $end = $#$arr if $end > $#$arr;
                    [ @$arr[0 .. $end] ]
                } else {
                    $_
                }
            } @results;
            @results = @next_results;
            next;
        }

        # support for drop(n)
        if ($part =~ /^drop\((\d+)\)$/) {
            my $count = $1;
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $arr = $_;
                    if ($count >= @$arr) {
                        [];
                    } else {
                        [ @$arr[$count .. $#$arr] ];
                    }
                } else {
                    $_;
                }
            } @results;
            @results = @next_results;
            next;
        }

        # support for tail(n)
        if ($part =~ /^tail\((\d+)\)$/) {
            my $count = $1;
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $arr = $_;

                    if ($count == 0 || !@$arr) {
                        [];
                    } else {
                        my $start = @$arr - $count;
                        $start = 0 if $start < 0;

                        [ @$arr[$start .. $#$arr] ];
                    }
                } else {
                    $_;
                }
            } @results;

            @results = @next_results;
            next;
        }

        # support for chunks(n)
        if ($part =~ /^chunks\((\d+)\)$/) {
            my $size = $1;
            $size = 1 if $size < 1;

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $arr = $_;
                    if (!@$arr) {
                        [];
                    } else {
                        my @chunks;
                        for (my $i = 0; $i < @$arr; $i += $size) {
                            my $end = $i + $size - 1;
                            $end = $#$arr if $end > $#$arr;
                            push @chunks, [ @$arr[$i .. $end] ];
                        }
                        \@chunks;
                    }
                } else {
                    $_;
                }
            } @results;

            @results = @next_results;
            next;
        }

        # support for range(...)
        if ($part =~ /^range\((.*)\)$/) {
            my $args_raw = $1;
            my @args     = _parse_range_arguments($args_raw);

            @next_results = ();
            for my $value (@results) {
                push @next_results, _apply_range($value, \@args);
            }

            @results = @next_results;
            next;
        }

        # support for map(...)
        if ($part =~ /^map\((.+)\)$/) {
            my $filter = $1;
            @next_results = map {
                ref $_ eq 'ARRAY'
                    ? [ grep { defined($_) } map { $self->run_query(encode_json($_), $filter) } @$_ ]
                    : $_
            } @results;
            @results = @next_results;
            next;
        }

        # support for map_values(filter)
        if ($part =~ /^map_values\((.+)\)$/) {
            my $filter = $1;
            @next_results = map { _apply_map_values($self, $_, $filter) } @results;
            @results      = @next_results;
            next;
        }

        # support for walk(filter)
        if ($part =~ /^walk\((.+)\)$/) {
            my $filter = $1;
            @next_results = map { _apply_walk($self, $_, $filter) } @results;
            @results      = @next_results;
            next;
        }

        # support for enumerate()
        if ($part =~ /^enumerate(?:\(\))?$/) {
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $arr = $_;
                    my @pairs;
                    for my $idx (0 .. $#$arr) {
                        push @pairs, { index => $idx, value => $arr->[$idx] };
                    }
                    \@pairs;
                } else {
                    $_;
                }
            } @results;

            @results = @next_results;
            next;
        }

        # support for to_entries
        if ($part eq 'to_entries') {
            @next_results = map { _to_entries($_) } @results;
            @results      = @next_results;
            next;
        }

        # support for from_entries
        if ($part eq 'from_entries') {
            @next_results = map { _from_entries($_) } @results;
            @results      = @next_results;
            next;
        }

        # support for with_entries(filter)
        if ($part =~ /^with_entries\((.+)\)$/) {
            my $filter = $1;
            @next_results = map { _apply_with_entries($self, $_, $filter) } @results;
            @results      = @next_results;
            next;
        }

        # support for transpose()
        if ($part eq 'transpose()' || $part eq 'transpose') {
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $outer = $_;

                    if (!@$outer) {
                        [];
                    }
                    elsif (grep { ref $_ ne 'ARRAY' } @$outer) {
                        $_;
                    }
                    else {
                        my @lengths = map { scalar(@$_) } @$outer;
                        my $limit   = @lengths ? min(@lengths) : 0;

                        if ($limit <= 0) {
                            [];
                        } else {
                            my @transposed;
                            for my $idx (0 .. $limit - 1) {
                                push @transposed, [ map { $_->[$idx] } @$outer ];
                            }
                            \@transposed;
                        }
                    }
                } else {
                    $_;
                }
            } @results;

            @results = @next_results;
            next;
        }

        # support for slice(start[, length])
        if ($part =~ /^slice(?:\((.*)\))?$/) {
            my $args_raw = defined $1 ? $1 : '';
            my @args     = _parse_arguments($args_raw);

            @next_results = map { _apply_slice($_, @args) } @results;
            @results      = @next_results;
            next;
        }

        # support for pluck(key)
        if ($part =~ /^pluck\((.+)\)$/) {
            my $key_path = $1;
            $key_path =~ s/^['"](.*)['"]$/$1/;
            $key_path =~ s/^\.//;

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my @collected = map {
                        my $item = $_;
                        my @values = _traverse($item, $key_path);
                        @values ? $values[0] : undef;
                    } @$_;
                    \@collected;
                } else {
                    $_;
                }
            } @results;

            @results = @next_results;
            next;
        }

        # support for pick(key1, key2, ...)
        if ($part =~ /^pick\((.*)\)$/) {
            my @keys = map { defined $_ ? "$_" : undef } _parse_arguments($1);
            @keys = grep { defined $_ } @keys;

            @next_results = map { _apply_pick($_, \@keys) } @results;
            @results      = @next_results;
            next;
        }

        # support for merge_objects()
        if ($part eq 'merge_objects()' || $part eq 'merge_objects') {
            @next_results = map { _apply_merge_objects($_) } @results;
            @results      = @next_results;
            next;
        }

        # support for add
        if ($part eq 'add') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? sum(map { 0 + $_ } @$_) : $_
            } @results;
            @results = @next_results;
            next;
        }

        # support for sum (alias for add)
        if ($part eq 'sum') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? sum(map { 0 + $_ } @$_) : $_
            } @results;
            @results = @next_results;
            next;
        }

        # support for sum_by(path)
        if ($part =~ /^sum_by\((.+)\)$/) {
            my $raw_path = $1;
            $raw_path =~ s/^\s+|\s+$//g;
            $raw_path =~ s/^['"](.*)['"]$/$1/;

            my $use_entire_item = ($raw_path eq '' || $raw_path eq '.');
            my $key_path        = $raw_path;
            $key_path =~ s/^\.// unless $use_entire_item;

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $sum        = 0;
                    my $has_number = 0;

                    for my $element (@$_) {
                        my @values = $use_entire_item
                            ? ($element)
                            : _traverse($element, $key_path);

                        for my $value (@values) {
                            next unless defined $value;

                            my $num = $value;
                            if (ref($num) eq 'JSON::PP::Boolean') {
                                $num = $num ? 1 : 0;
                            }

                            next if ref $num;
                            next unless looks_like_number($num);
                            $sum += $num;
                            $has_number = 1;
                        }
                    }

                    $has_number ? $sum : 0;
                }
                else {
                    $_;
                }
            } @results;

            @results = @next_results;
            next;
        }

        # support for median_by(path)
        if ($part =~ /^median_by\((.+)\)$/) {
            my ($key_path, $use_entire_item) = _normalize_path_argument($1);

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my @numbers;
                    for my $element (@$_) {
                        push @numbers, _project_numeric_values($element, $key_path, $use_entire_item);
                    }

                    if (@numbers) {
                        @numbers = sort { $a <=> $b } @numbers;
                        my $count  = @numbers;
                        my $middle = int($count / 2);
                        if ($count % 2) {
                            $numbers[$middle];
                        } else {
                            ($numbers[$middle - 1] + $numbers[$middle]) / 2;
                        }
                    } else {
                        undef;
                    }
                }
                else {
                    $_;
                }
            } @results;

            @results = @next_results;
            next;
        }

        # support for avg_by(path)
        if ($part =~ /^avg_by\((.+)\)$/) {
            my ($key_path, $use_entire_item) = _normalize_path_argument($1);

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $sum   = 0;
                    my $count = 0;

                    for my $element (@$_) {
                        my @values = $use_entire_item
                            ? ($element)
                            : _traverse($element, $key_path);

                        for my $value (@values) {
                            next unless defined $value;

                            my $num = $value;
                            if (ref($num) eq 'JSON::PP::Boolean') {
                                $num = $num ? 1 : 0;
                            }

                            next if ref $num;
                            next unless looks_like_number($num);
                            $sum   += $num;
                            $count += 1;
                        }
                    }

                    $count ? $sum / $count : 0;
                }
                else {
                    $_;
                }
            } @results;

            @results = @next_results;
            next;
        }

        # support for max_by(path)
        if ($part =~ /^max_by\((.+)\)$/) {
            my ($key_path, $use_entire_item) = _normalize_path_argument($1);

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    _extreme_by($_, $key_path, $use_entire_item, 'max');
                } else {
                    $_;
                }
            } @results;

            @results = @next_results;
            next;
        }

        # support for min_by(path)
        if ($part =~ /^min_by\((.+)\)$/) {
            my ($key_path, $use_entire_item) = _normalize_path_argument($1);

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    _extreme_by($_, $key_path, $use_entire_item, 'min');
                } else {
                    $_;
                }
            } @results;

            @results = @next_results;
            next;
        }

        # support for product
        if ($part eq 'product') {
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $product    = 1;
                    my $has_values = 0;
                    for my $val (@$_) {
                        next unless defined $val;
                        $product *= (0 + $val);
                        $has_values = 1;
                    }
                    $has_values ? $product : 1;
                } else {
                    $_;
                }
            } @results;
            @results = @next_results;
            next;
        }

        # support for min
        if ($part eq 'min') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? min(map { 0 + $_ } @$_) : $_
            } @results;
            @results = @next_results;
            next;
        }

        # support for max
        if ($part eq 'max') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? max(map { 0 + $_ } @$_) : $_
            } @results;
            @results = @next_results;
            next;
        }

        # support for avg
        if ($part eq 'avg') {
            @next_results = map {
                ref $_ eq 'ARRAY' && @$_ ? sum(map { 0 + $_ } @$_) / scalar(@$_) : 0
            } @results;
            @results = @next_results;
            next;
        }

        # support for abs
        if ($part eq 'abs') {
            @next_results = map {
                if (!defined $_) {
                    undef;
                }
                elsif (!ref $_) {
                    looks_like_number($_) ? abs($_) : $_;
                }
                elsif (ref $_ eq 'ARRAY') {
                    [ map { looks_like_number($_) ? abs($_) : $_ } @$_ ];
                }
                else {
                    $_;
                }
            } @results;
            @results = @next_results;
            next;
        }

        # support for ceil()
        if ($part eq 'ceil()' || $part eq 'ceil') {
            @next_results = map { _apply_numeric_function($_, \&_ceil) } @results;
            @results = @next_results;
            next;
        }

        # support for floor()
        if ($part eq 'floor()' || $part eq 'floor') {
            @next_results = map { _apply_numeric_function($_, \&_floor) } @results;
            @results = @next_results;
            next;
        }

        # support for round()
        if ($part eq 'round()' || $part eq 'round') {
            @next_results = map { _apply_numeric_function($_, \&_round) } @results;
            @results = @next_results;
            next;
        }

        # support for clamp(min, max)
        if ($part =~ /^clamp\((.*)\)$/) {
            my @args = _parse_arguments($1);
            my $min  = @args ? _normalize_numeric_bound($args[0]) : undef;
            my $max  = @args > 1 ? _normalize_numeric_bound($args[1]) : undef;

            if (defined $min && defined $max && $min > $max) {
                ($min, $max) = ($max, $min);
            }

            @next_results = map { _apply_clamp($_, $min, $max) } @results;
            @results      = @next_results;
            next;
        }

        # support for tostring()
        if ($part eq 'tostring()' || $part eq 'tostring') {
            @next_results = map { _apply_tostring($_) } @results;
            @results = @next_results;
            next;
        }

        # support for tojson()
        if ($part eq 'tojson()' || $part eq 'tojson') {
            @next_results = map { _apply_tojson($_) } @results;
            @results = @next_results;
            next;
        }

        # support for to_number()
        if ($part eq 'to_number()' || $part eq 'to_number') {
            @next_results = map { _apply_to_number($_) } @results;
            @results = @next_results;
            next;
        }

        # support for median
        if ($part eq 'median') {
            @next_results = map {
                if (ref $_ eq 'ARRAY' && @$_) {
                    my @numbers = sort { $a <=> $b }
                        map { 0 + $_ }
                        grep { looks_like_number($_) }
                        @$_;

                    if (@numbers) {
                        my $count  = @numbers;
                        my $middle = int($count / 2);
                        if ($count % 2) {
                            $numbers[$middle];
                        } else {
                            ($numbers[$middle - 1] + $numbers[$middle]) / 2;
                        }
                    } else {
                        undef;
                    }
                } else {
                    $_;
                }
            } @results;
            @results = @next_results;
            next;
        }

        # support for percentile(p)
        if ($part =~ /^percentile(?:\((.*)\))?$/) {
            my $args_raw = defined $1 ? $1 : '';
            my @args     = length $args_raw ? _parse_arguments($args_raw) : ();
            my $fraction = @args ? _normalize_percentile($args[0]) : 0.5;

            @next_results = map {
                if (ref $_ eq 'ARRAY' && @$_) {
                    my @numbers = sort { $a <=> $b }
                        map { 0 + $_ }
                        grep { looks_like_number($_) }
                        @$_;

                    if (@numbers) {
                        defined $fraction ? _percentile_value(\@numbers, $fraction) : undef;
                    }
                    else {
                        undef;
                    }
                }
                else {
                    $_;
                }
            } @results;

            @results = @next_results;
            next;
        }

        # support for mode
        if ($part eq 'mode') {
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    if (!@$_) {
                        undef;
                    } else {
                        my %counts;
                        my %values;
                        my %first_index;
                        my $max_count  = 0;
                        my $best_index = undef;
                        my $mode_key;

                        for (my $i = 0; $i < @{$_}; $i++) {
                            my $item = $_->[$i];
                            next unless defined $item;

                            my $key = _key($item);
                            next unless defined $key;

                            $counts{$key}++;
                            $values{$key}      //= $item;
                            $first_index{$key} //= $i;

                            my $count = $counts{$key};
                            my $index = $first_index{$key};

                            if (!defined $mode_key
                                || $count > $max_count
                                || ($count == $max_count
                                    && (!defined $best_index || $index < $best_index))) {
                                $mode_key   = $key;
                                $max_count  = $count;
                                $best_index = $index;
                            }
                        }

                        defined $mode_key ? $values{$mode_key} : undef;
                    }
                } else {
                    $_;
                }
            } @results;

            @results = @next_results;
            next;
        }

        # support for variance
        if ($part eq 'variance') {
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my @numbers = map { 0 + $_ }
                        grep { looks_like_number($_) }
                        @$_;

                    if (@numbers) {
                        my $mean = sum(@numbers) / @numbers;
                        sum(map { ($_ - $mean) ** 2 } @numbers) / @numbers;
                    }
                    else {
                        undef;
                    }
                }
                else {
                    $_;
                }
            } @results;

            @results = @next_results;
            next;
        }

        # support for stddev
        if ($part eq 'stddev') {
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my @numbers = map { 0 + $_ }
                        grep { looks_like_number($_) }
                        @$_;

                    if (@numbers) {
                        my $mean = sum(@numbers) / @numbers;
                        my $variance = sum(map { ($_ - $mean) ** 2 } @numbers) / @numbers;
                        sqrt($variance);
                    }
                    else {
                        undef;
                    }
                }
                else {
                    $_;
                }
            } @results;

            @results = @next_results;
            next;
        }

        # support for group_count(key)
        if ($part =~ /^group_count\((.+)\)$/) {
            my $key_path = $1;
            @next_results = map {
                _group_count($_, $key_path)
            } @results;
            @results = @next_results;
            next;
        }

        # support for group_by(key)
        if ($part =~ /^group_by\((.+)\)$/) {
            my $key_path = $1;
            @next_results = map {
                _group_by($_, $key_path)
            } @results;
            @results = @next_results;
            next;
        }

        # support for count
        if ($part eq 'count') {
            my $n = 0;
            for my $item (@results) {
                if (ref $item eq 'ARRAY') {
                    $n += scalar(@$item);
                } else {
                    $n += 1;  # count as 1 item
                }
            }
            @results = ($n);
            next;
        }

        # support for all() / all(expr)
        if ($part =~ /^all(?:\((.*)\))?$/) {
            my $expr = defined $1 ? $1 : undef;
            $expr = undef if defined($expr) && $expr eq '';

            @next_results = map { _apply_all($self, $_, $expr) } @results;
            @results      = @next_results;
            next;
        }

        # support for any() / any(expr)
        if ($part =~ /^any(?:\((.*)\))?$/) {
            my $expr = defined $1 ? $1 : undef;
            $expr = undef if defined($expr) && $expr eq '';

            @next_results = map { _apply_any($self, $_, $expr) } @results;
            @results      = @next_results;
            next;
        }

        # support for join(", ")
        if ($part =~ /^join\((.*?)\)$/) {
            my $sep = $1;
            $sep =~ s/^['"](.*?)['"]$/$1/;  # remove quotes around separator

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    join($sep, map { defined $_ ? $_ : '' } @$_)
                } else {
                    ''
                }
            } @results;
            @results = @next_results;
            next;
        }

        # support for sort_by(key)
        if ($part =~ /^sort_by\((.+?)\)$/) {
            my $key_path = $1;
            $key_path =~ s/^\.//;  # Remove leading dot
        
            my $cmp = _smart_cmp();
            @next_results = ();
        
            for my $item (@results) {
                if (ref $item eq 'ARRAY') {
                    my @sorted = sort {
                        my $a_val = (_traverse($a, $key_path))[0] // '';
                        my $b_val = (_traverse($b, $key_path))[0] // '';

                        $cmp->($a_val, $b_val);
                    } @$item;
        
                    push @next_results, \@sorted;
                } else {
                    push @next_results, $item;
                }
            }
        
            @results = @next_results;
            next;
        }

        # support for empty
        if ($part eq 'empty') {
            @results = ();  # discard all results
            next;
        }

        # support for values
        if ($part eq 'values') {
            @next_results = map {
                ref $_ eq 'HASH' ? [ values %$_ ] : $_
            } @results;
            @results = @next_results;
            next;
        }

        # support for arrays
        if ($part eq 'arrays()' || $part eq 'arrays') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? $_ : ()
            } @results;
            @results = @next_results;
            next;
        }

        # support for flatten()
        if ($part eq 'flatten()' || $part eq 'flatten') {
            @next_results = map {
                (ref $_ eq 'ARRAY') ? @$_ : ()
            } @results;
            @results = @next_results;
            next;
        }

        # support for flatten_all()
        if ($part eq 'flatten_all()' || $part eq 'flatten_all') {
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    _flatten_all($_);
                } else {
                    $_;
                }
            } @results;
            @results = @next_results;
            next;
        }

        # support for flatten_depth(n)
        if ($part =~ /^flatten_depth(?:\((.*)\))?$/) {
            my $args_raw = defined $1 ? $1 : '';
            my @args     = length $args_raw ? _parse_arguments($args_raw) : ();
            my $depth    = @args ? $args[0] : 1;

            if (!defined $depth || !looks_like_number($depth)) {
                $depth = 1;
            }

            $depth = int($depth);
            $depth = 0 if $depth < 0;

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    _flatten_depth($_, $depth);
                } else {
                    $_;
                }
            } @results;

            @results = @next_results;
            next;
        }

        # support for type()
        if ($part eq 'type()' || $part eq 'type') {
            @next_results = map {
                if (!defined $_) {
                    'null';
                }
                elsif (ref($_) eq 'ARRAY') {
                    'array';
                }
                elsif (ref($_) eq 'HASH') {
                    'object';
                }
                elsif (ref($_) eq '') {
                    if (/^-?\d+(?:\.\d+)?$/) {
                        'number';
                    } else {
                        'string';
                    }
                }
                elsif (ref($_) eq 'JSON::PP::Boolean') {
                    'boolean';
                }
                else {
                    'unknown';
                }
            } (@results ? @results : (undef)); 
            @results = @next_results;
            next;
        }

        # support for nth(n)
        if ($part =~ /^nth\((\d+)\)$/) {
            my $index = $1;
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    $_->[$index]
                } else {
                    undef
                }
            } @results;
            @results = @next_results;
            next;
        }

        # support for del(key)
        if ($part =~ /^del\((.+?)\)$/) {
            my $key = $1;
            $key =~ s/^['"](.*?)['"]$/$1/;  # remove quotes

            @next_results = map {
                if (ref $_ eq 'HASH') {
                    my %copy = %$_;  # shallow copy
                    delete $copy{$key};
                    \%copy
                } else {
                    $_
                }
            } @results;
            @results = @next_results;
            next;
        }

        # support for delpaths(paths_expr)
        if ($part =~ /^delpaths\((.*)\)$/) {
            my $filter = $1;
            $filter =~ s/^\s+|\s+$//g;

            @next_results = map { _apply_delpaths($self, $_, $filter) } @results;
            @results      = @next_results;
            next;
        }

        # support for compact()
        if ($part eq 'compact()' || $part eq 'compact') {
            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    [ grep { defined $_ } @$_ ]
                } else {
                    $_
                }
            } @results;
            @results = @next_results;
            next;
        }

        # support for titlecase()
        if ($part eq 'titlecase()' || $part eq 'titlecase') {
            @next_results = map { _apply_case_transform($_, 'titlecase') } @results;
            @results = @next_results;
            next;
        }

        # support for upper()
        if ($part eq 'upper()' || $part eq 'upper') {
            @next_results = map { _apply_case_transform($_, 'upper') } @results;
            @results = @next_results;
            next;
        }

        # support for lower()
        if ($part eq 'lower()' || $part eq 'lower') {
            @next_results = map { _apply_case_transform($_, 'lower') } @results;
            @results = @next_results;
            next;
        }

        # support for trim()
        if ($part eq 'trim()' || $part eq 'trim') {
            @next_results = map { _apply_trim($_) } @results;
            @results = @next_results;
            next;
        }

        # support for ltrimstr("prefix")
        if ($part =~ /^ltrimstr\((.+)\)$/) {
            my $needle = _parse_string_argument($1);
            @next_results = map { _apply_trimstr($_, $needle, 'left') } @results;
            @results      = @next_results;
            next;
        }

        # support for rtrimstr("suffix")
        if ($part =~ /^rtrimstr\((.+)\)$/) {
            my $needle = _parse_string_argument($1);
            @next_results = map { _apply_trimstr($_, $needle, 'right') } @results;
            @results      = @next_results;
            next;
        }

        # support for has(key)
        if ($part =~ /^has\((.+)\)$/) {
            my @args   = _parse_arguments($1);
            my $needle = @args ? $args[0] : undef;

            @next_results = map { _apply_has($_, $needle) } @results;
            @results      = @next_results;
            next;
        }

        # support for contains(value)
        if ($part =~ /^contains\((.+)\)$/) {
            my $needle = _parse_string_argument($1);
            @next_results = map { _apply_contains($_, $needle) } @results;
            @results = @next_results;
            next;
        }

        # support for startswith("prefix")
        if ($part =~ /^startswith\((.+)\)$/) {
            my $needle = _parse_string_argument($1);
            @next_results = map { _apply_string_predicate($_, $needle, 'start') } @results;
            @results = @next_results;
            next;
        }

        # support for endswith("suffix")
        if ($part =~ /^endswith\((.+)\)$/) {
            my $needle = _parse_string_argument($1);
            @next_results = map { _apply_string_predicate($_, $needle, 'end') } @results;
            @results = @next_results;
            next;
        }

        # support for explode()
        if ($part eq 'explode()' || $part eq 'explode') {
            @next_results = map { _apply_explode($_) } @results;
            @results      = @next_results;
            next;
        }

        # support for implode()
        if ($part eq 'implode()' || $part eq 'implode') {
            @next_results = map { _apply_implode($_) } @results;
            @results      = @next_results;
            next;
        }

        # support for replace(old, new)
        if ($part =~ /^replace\((.+)\)$/) {
            my ($search, $replacement) = _parse_arguments($1);
            $search      = defined $search      ? $search      : '';
            $replacement = defined $replacement ? $replacement : '';

            @next_results = map { _apply_replace($_, $search, $replacement) } @results;
            @results = @next_results;
            next;
        }

        # support for split("separator")
        if ($part =~ /^split\((.+)\)$/) {
            my $separator = _parse_string_argument($1);
            @next_results = map { _apply_split($_, $separator) } @results;
            @results = @next_results;
            next;
        }

        # support for substr(start[, length])
        if ($part =~ /^substr(?:\((.*)\))?$/) {
            my $args_raw = defined $1 ? $1 : '';
            my @args = _parse_arguments($args_raw);
            @next_results = map { _apply_substr($_, @args) } @results;
            @results = @next_results;
            next;
        }

        # support for indices(value)
        if ($part =~ /^indices\((.*)\)$/) {
            my @args   = _parse_arguments($1);
            my $needle = @args ? $args[0] : undef;

            @next_results = map { _apply_indices($_, $needle) } @results;
            @results      = @next_results;
            next;
        }

        # support for index(value)
        if ($part =~ /^index\((.*)\)$/) {
            my @args   = _parse_arguments($1);
            my $needle = @args ? $args[0] : undef;

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $array = $_;
                    my $found;
                    for my $i (0 .. $#$array) {
                        if (_values_equal($array->[$i], $needle)) {
                            $found = $i;
                            last;
                        }
                    }
                    defined $found ? $found : undef;
                }
                elsif (!ref $_ || ref($_) eq 'JSON::PP::Boolean') {
                    my $haystack = defined $_ ? "$_" : '';
                    my $fragment = defined $needle ? "$needle" : '';
                    my $pos      = index($haystack, $fragment);
                    $pos >= 0 ? $pos : undef;
                }
                else {
                    undef;
                }
            } @results;

            @results = @next_results;
            next;
        }

        # support for rindex(value)
        if ($part =~ /^rindex\((.*)\)$/) {
            my @args   = _parse_arguments($1);
            my $needle = @args ? $args[0] : undef;

            @next_results = map {
                if (ref $_ eq 'ARRAY') {
                    my $array = $_;
                    my $found;
                    for (my $i = $#$array; $i >= 0; $i--) {
                        if (_values_equal($array->[$i], $needle)) {
                            $found = $i;
                            last;
                        }
                    }
                    defined $found ? $found : undef;
                }
                elsif (!ref $_ || ref($_) eq 'JSON::PP::Boolean') {
                    my $haystack = defined $_ ? "$_" : '';
                    my $fragment = defined $needle ? "$needle" : '';
                    my $pos      = rindex($haystack, $fragment);
                    $pos >= 0 ? $pos : undef;
                }
                else {
                    undef;
                }
            } @results;

            @results = @next_results;
            next;
        }

        # support for paths()
        if ($part eq 'paths()' || $part eq 'paths') {
            @next_results = map { _apply_paths($_) } @results;
            @results      = @next_results;
            next;
        }

        # support for leaf_paths()
        if ($part eq 'leaf_paths()' || $part eq 'leaf_paths') {
            @next_results = map { _apply_leaf_paths($_) } @results;
            @results      = @next_results;
            next;
        }

        # support for getpath(path_expr)
        if ($part =~ /^getpath\((.*)\)$/) {
            my $path_expr = defined $1 ? $1 : '';

            @next_results = map { _apply_getpath($self, $_, $path_expr) } @results;
            @results      = @next_results;
            next;
        }

        # support for path()
        if ($part eq 'path') {
            @next_results = map {
                if (ref $_ eq 'HASH') {
                    [ sort keys %$_ ]
                }
                elsif (ref $_ eq 'ARRAY') {
                    [ 0..$#$_ ]
                }
                else {
                    ''
                }
            } @results;
            @results = @next_results;
            next;
        }

        # support for is_empty
        if ($part eq 'is_empty') {
            @next_results = map {
                (ref $_ eq 'ARRAY' && !@$_) || (ref $_ eq 'HASH' && !%$_)
                    ? JSON::PP::true
                    : JSON::PP::false
            } @results;
            @results = @next_results;
            next;
        }

        # support for default(value)
        if ($part =~ /^default\((.+)\)$/) {
            my $default_value = $1;
            $default_value =~ s/^['"](.*?)['"]$/$1/; 
        
            @results = @results ? @results : (undef);
        
            @next_results = map {
                defined($_) ? $_ : $default_value
            } @results;
            @results = @next_results;
            next;
        }

        # standard traversal
        for my $item (@results) {
            push @next_results, _traverse($item, $part);
        }
        @results = @next_results;
    }

    return @results;
}

sub _map {
    my ($self, $data, $filter) = @_;

    if (ref $data ne 'ARRAY') {
        warn "_map expects array reference";
        return ();
    }

    my @mapped;
    for my $item (@$data) {
        push @mapped, $self->run_query(encode_json($item), $filter);
    }

    return @mapped;
}

sub _apply_all {
    my ($self, $value, $expr) = @_;

    if (ref $value eq 'ARRAY') {
        return JSON::PP::true unless @$value;

        for my $item (@$value) {
            if (defined $expr) {
                my @evaluated = $self->run_query(encode_json($item), $expr);
                return JSON::PP::false unless @evaluated;
                return JSON::PP::false if grep { !_is_truthy($_) } @evaluated;
            }
            else {
                return JSON::PP::false unless _is_truthy($item);
            }
        }

        return JSON::PP::true;
    }

    if (defined $expr) {
        my @evaluated = $self->run_query(encode_json($value), $expr);
        return JSON::PP::false unless @evaluated;
        return grep { !_is_truthy($_) } @evaluated ? JSON::PP::false : JSON::PP::true;
    }

    return _is_truthy($value) ? JSON::PP::true : JSON::PP::false;
}

sub _apply_any {
    my ($self, $value, $expr) = @_;

    if (ref $value eq 'ARRAY') {
        return JSON::PP::false unless @$value;

        for my $item (@$value) {
            if (defined $expr) {
                my @evaluated = $self->run_query(encode_json($item), $expr);
                return JSON::PP::true if grep { _is_truthy($_) } @evaluated;
            }
            else {
                return JSON::PP::true if _is_truthy($item);
            }
        }

        return JSON::PP::false;
    }

    if (defined $expr) {
        my @evaluated = $self->run_query(encode_json($value), $expr);
        return grep { _is_truthy($_) } @evaluated ? JSON::PP::true : JSON::PP::false;
    }

    return _is_truthy($value) ? JSON::PP::true : JSON::PP::false;
}

sub _is_truthy {
    my ($value) = @_;

    return 0 unless defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        return $value ? 1 : 0;
    }

    if (ref $value eq 'ARRAY') {
        return @$value ? 1 : 0;
    }

    if (ref $value eq 'HASH') {
        return scalar(keys %$value) ? 1 : 0;
    }

    if (!ref $value) {
        return 0 if $value eq '';
        if (looks_like_number($value)) {
            return $value != 0 ? 1 : 0;
        }
        return 1;
    }

    return 1;
}

sub _apply_case_transform {
    my ($value, $mode) = @_;

    if (!defined $value) {
        return undef;
    }

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_case_transform($_, $mode) } @$value ];
    }

    if (!ref $value) {
        return uc $value      if $mode eq 'upper';
        return lc $value      if $mode eq 'lower';
        return _to_titlecase($value);
    }

    return $value;
}

sub _to_titlecase {
    my ($value) = @_;

    my $result = lc $value;
    $result =~ s/(^|[^\p{L}\p{N}])(\p{L})/$1 . uc($2)/ge;
    return $result;
}

sub _apply_trim {
    my ($value) = @_;

    if (!defined $value) {
        return undef;
    }

    if (!ref $value) {
        my $copy = $value;
        $copy =~ s/^\s+//;
        $copy =~ s/\s+$//;
        return $copy;
    }

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_trim($_) } @$value ];
    }

    return $value;
}

sub _apply_trimstr {
    my ($value, $needle, $mode) = @_;

    if (!defined $value) {
        return undef;
    }

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_trimstr($_, $needle, $mode) } @$value ];
    }

    if (ref $value) {
        return $value;
    }

    $needle = '' unless defined $needle;
    my $target = "$value";
    my $pattern = "$needle";
    my $len = length $pattern;

    return $target if $len == 0;

    if ($mode eq 'left') {
        return $target if index($target, $pattern) != 0;
        return substr($target, $len);
    }

    if ($mode eq 'right') {
        return $target if $len > length($target);
        return $target unless substr($target, -$len) eq $pattern;
        return substr($target, 0, length($target) - $len);
    }

    return $target;
}

sub _apply_paths {
    my ($value) = @_;

    if (!ref $value || ref($value) eq 'JSON::PP::Boolean') {
        return [ [] ];
    }

    my @paths;
    _collect_paths($value, [], \@paths);
    return \@paths;
}

sub _apply_leaf_paths {
    my ($value) = @_;

    if (_is_leaf_value($value)) {
        return [ [] ];
    }

    my @paths;
    _collect_leaf_paths($value, [], \@paths);
    return \@paths;
}

sub _apply_getpath {
    my ($self, $value, $expr) = @_;

    return undef unless defined $value;

    $expr //= '';
    $expr =~ s/^\s+|\s+$//g;
    return undef if $expr eq '';

    my @paths;

    my $decoded = eval { decode_json($expr) };
    if (!$@ && defined $decoded) {
        if (ref $decoded eq 'ARRAY') {
            if (@$decoded && ref $decoded->[0] eq 'ARRAY') {
                push @paths, map { [ @$_ ] } @$decoded;
            }
            else {
                push @paths, [ @$decoded ];
            }
        }
        else {
            push @paths, [ $decoded ];
        }
    }

    if (!@paths) {
        my @outputs = $self->run_query(encode_json($value), $expr);
        for my $output (@outputs) {
            next unless defined $output;

            if (ref $output eq 'ARRAY') {
                if (@$output && ref $output->[0] eq 'ARRAY') {
                    push @paths, grep { ref $_ eq 'ARRAY' } @$output;
                }
                elsif (!@$output || !ref $output->[0]) {
                    push @paths, [ @$output ];
                }
            }
            elsif (!ref $output || ref($output) eq 'JSON::PP::Boolean') {
                push @paths, [ $output ];
            }
        }
    }

    return undef unless @paths;

    my @values = map { _traverse_path_array($value, $_) } @paths;
    return @values == 1 ? $values[0] : \@values;
}

sub _collect_paths {
    my ($value, $current_path, $paths) = @_;

    if (ref $value eq 'HASH') {
        for my $key (sort keys %$value) {
            my $child = $value->{$key};
            my @next  = (@$current_path, $key);
            push @$paths, [@next];

            if (ref $child eq 'HASH' || ref $child eq 'ARRAY') {
                _collect_paths($child, \@next, $paths);
            }
        }
        return;
    }

    if (ref $value eq 'ARRAY') {
        for my $index (0 .. $#$value) {
            my $child = $value->[$index];
            my @next  = (@$current_path, $index);
            push @$paths, [@next];

            if (ref $child eq 'HASH' || ref $child eq 'ARRAY') {
                _collect_paths($child, \@next, $paths);
            }
        }
        return;
    }

    push @$paths, [@$current_path];
}

sub _traverse_path_array {
    my ($value, $path) = @_;

    return undef unless defined $value;
    return $value unless defined $path;
    return $value if ref($path) ne 'ARRAY';

    my $cursor = $value;
    for my $segment (@$path) {
        return undef unless defined $cursor;

        if (ref $cursor eq 'HASH') {
            my $key = defined $segment ? "$segment" : return undef;
            return undef unless exists $cursor->{$key};
            $cursor = $cursor->{$key};
            next;
        }

        if (ref $cursor eq 'ARRAY') {
            return undef unless defined $segment;

            my $index = "$segment";
            if ($index =~ /^-?\d+$/) {
                my $numeric = int($index);
                $numeric += @$cursor if $numeric < 0;
                return undef if $numeric < 0 || $numeric > $#$cursor;
                $cursor = $cursor->[$numeric];
                next;
            }

            return undef;
        }

        return undef;
    }

    return $cursor;
}

sub _collect_leaf_paths {
    my ($value, $current_path, $paths) = @_;

    if (ref $value eq 'HASH') {
        for my $key (sort keys %$value) {
            my $child = $value->{$key};
            my @next  = (@$current_path, $key);

            if (_is_leaf_value($child)) {
                push @$paths, [@next];
            }
            else {
                _collect_leaf_paths($child, \@next, $paths);
            }
        }
        return;
    }

    if (ref $value eq 'ARRAY') {
        for my $index (0 .. $#$value) {
            my $child = $value->[$index];
            my @next  = (@$current_path, $index);

            if (_is_leaf_value($child)) {
                push @$paths, [@next];
            }
            else {
                _collect_leaf_paths($child, \@next, $paths);
            }
        }
        return;
    }

    push @$paths, [@$current_path];
}

sub _is_leaf_value {
    my ($value) = @_;

    return 1 unless ref $value;
    return 1 if ref($value) eq 'JSON::PP::Boolean';
    return 0 if ref($value) eq 'ARRAY';
    return 0 if ref($value) eq 'HASH';
    return 1;
}

sub _apply_tostring {
    my ($value) = @_;

    if (!defined $value) {
        return 'null';
    }

    if (ref($value) eq 'JSON::PP::Boolean') {
        return $value ? 'true' : 'false';
    }

    if (!ref $value) {
        return "$value";
    }

    if (ref $value eq 'ARRAY' || ref $value eq 'HASH') {
        return encode_json($value);
    }

    return encode_json($value);
}

sub _apply_tojson {
    my ($value) = @_;

    return encode_json($value);
}

sub _apply_numeric_function {
    my ($value, $callback) = @_;

    return undef if !defined $value;

    if (!ref $value) {
        return looks_like_number($value) ? $callback->($value) : $value;
    }

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_numeric_function($_, $callback) } @$value ];
    }

    return $value;
}

sub _apply_clamp {
    my ($value, $min, $max) = @_;

    return undef if !defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        my $numeric = $value ? 1 : 0;
        return _clamp_scalar($numeric, $min, $max);
    }

    if (!ref $value) {
        return _clamp_scalar($value, $min, $max);
    }

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_clamp($_, $min, $max) } @$value ];
    }

    return $value;
}

sub _normalize_numeric_bound {
    my ($value) = @_;

    return undef if !defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        return $value ? 1 : 0;
    }

    return looks_like_number($value) ? 0 + $value : undef;
}

sub _clamp_scalar {
    my ($value, $min, $max) = @_;

    return $value unless looks_like_number($value);

    my $numeric = 0 + $value;
    $numeric = $min if defined $min && $numeric < $min;
    $numeric = $max if defined $max && $numeric > $max;

    return $numeric;
}

sub _apply_to_number {
    my ($value) = @_;

    return undef if !defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        return $value ? 1 : 0;
    }

    if (!ref $value) {
        return looks_like_number($value) ? 0 + $value : $value;
    }

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_to_number($_) } @$value ];
    }

    return $value;
}

sub _normalize_percentile {
    my ($value) = @_;

    return undef if !defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        $value = $value ? 1 : 0;
    }

    return undef if ref $value;
    return undef unless looks_like_number($value);

    my $fraction = 0 + $value;

    if ($fraction > 1) {
        $fraction /= 100 if $fraction <= 100;
    }

    $fraction = 0 if $fraction < 0;
    $fraction = 1 if $fraction > 1;

    return $fraction;
}

sub _percentile_value {
    my ($numbers, $fraction) = @_;

    return undef unless ref $numbers eq 'ARRAY';
    return undef unless @$numbers;

    $fraction = 0 if $fraction < 0;
    $fraction = 1 if $fraction > 1;

    return $numbers->[0] if @$numbers == 1;

    my $rank        = $fraction * (@$numbers - 1);
    my $lower_index = int($rank);
    my $upper_index = $lower_index == @$numbers - 1 ? $lower_index : $lower_index + 1;
    my $weight      = $rank - $lower_index;

    return $numbers->[$lower_index] if $upper_index == $lower_index;

    my $lower = $numbers->[$lower_index];
    my $upper = $numbers->[$upper_index];

    return $lower + ($upper - $lower) * $weight;
}

sub _apply_merge_objects {
    my ($value) = @_;

    if (ref $value eq 'ARRAY') {
        my %merged;
        my $saw_object = 0;

        for my $element (@$value) {
            next unless ref $element eq 'HASH';
            %merged = (%merged, %$element);
            $saw_object = 1;
        }

        return $saw_object ? \%merged : {};
    }

    if (ref $value eq 'HASH') {
        return { %$value };
    }

    return $value;
}

sub _to_entries {
    my ($value) = @_;

    if (ref $value eq 'HASH') {
        return [ map { { key => $_, value => $value->{$_} } } sort keys %$value ];
    }

    if (ref $value eq 'ARRAY') {
        return [ map { { key => $_, value => $value->[$_] } } 0 .. $#$value ];
    }

    return $value;
}

sub _from_entries {
    my ($value) = @_;

    return $value unless ref $value eq 'ARRAY';

    my %result;
    for my $entry (@$value) {
        my $normalized = _normalize_entry($entry);
        next unless $normalized;

        my $key = $normalized->{key};
        $result{$key} = $normalized->{value};
    }

    return \%result;
}

sub _apply_with_entries {
    my ($self, $value, $filter) = @_;

    return $value unless ref $value eq 'HASH' || ref $value eq 'ARRAY';

    my $entries = _to_entries($value);
    return $value unless ref $entries eq 'ARRAY';

    my @transformed;
    for my $entry (@$entries) {
        my @results = $self->run_query(encode_json($entry), $filter);
        for my $result (@results) {
            my $normalized = _normalize_entry($result);
            push @transformed, $normalized if $normalized;
        }
    }

    return _from_entries(\@transformed);
}

sub _apply_map_values {
    my ($self, $value, $filter) = @_;

    return $value if !defined $value;

    if (ref $value eq 'HASH') {
        my %result;
        for my $key (keys %$value) {
            my $original = $value->{$key};
            my @outputs  = $self->run_query(encode_json($original), $filter);
            next unless @outputs;
            $result{$key} = $outputs[0];
        }
        return \%result;
    }

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_map_values($self, $_, $filter) } @$value ];
    }

    return $value;
}

sub _apply_walk {
    my ($self, $value, $filter) = @_;

    if (ref $value eq 'HASH') {
        my %copy;
        for my $key (keys %$value) {
            $copy{$key} = _apply_walk($self, $value->{$key}, $filter);
        }
        $value = \%copy;
    }
    elsif (ref $value eq 'ARRAY') {
        my @copy = map { _apply_walk($self, $_, $filter) } @$value;
        $value   = \@copy;
    }

    my @results = $self->run_query(encode_json($value), $filter);
    return @results ? $results[0] : undef;
}

sub _apply_delpaths {
    my ($self, $value, $filter) = @_;

    return $value if !defined $value;
    return $value if !ref $value || ref($value) eq 'JSON::PP::Boolean';

    $filter //= '';
    $filter =~ s/^\s+|\s+$//g;
    return $value if $filter eq '';

    my @paths;
    my $decoded_paths = eval { decode_json($filter) };
    if (!$@ && defined $decoded_paths) {
        if (ref $decoded_paths eq 'ARRAY') {
            if (@$decoded_paths && ref $decoded_paths->[0] eq 'ARRAY') {
                push @paths, map { [ @$_ ] } @$decoded_paths;
            }
            elsif (!@$decoded_paths) {
                # no paths supplied
            }
            else {
                push @paths, [ @$decoded_paths ];
            }
        }
    }

    if (!@paths) {
        my @outputs = $self->run_query(encode_json($value), $filter);
        for my $output (@outputs) {
            next unless defined $output;

            if (ref $output eq 'ARRAY') {
                if (@$output && ref $output->[0] eq 'ARRAY') {
                    push @paths, grep { ref $_ eq 'ARRAY' } @$output;
                } elsif (!@$output || !ref $output->[0]) {
                    push @paths, $output;
                }
            }
        }
    }

    return $value unless @paths;

    if (grep { ref $_ eq 'ARRAY' && !@$_ } @paths) {
        return undef;
    }

    my $clone = _deep_clone($value);

    for my $path (@paths) {
        next unless ref $path eq 'ARRAY';
        next unless @$path;
        _delete_path_inplace($clone, [@$path]);
    }

    return $clone;
}

sub _deep_clone {
    my ($value) = @_;

    return $value if !defined $value;
    return $value if !ref $value || ref($value) eq 'JSON::PP::Boolean';

    my $json = encode_json($value);
    return decode_json($json);
}

sub _delete_path_inplace {
    my ($value, $path) = @_;

    return unless ref $value eq 'HASH' || ref $value eq 'ARRAY';
    return unless ref $path eq 'ARRAY';
    return unless @$path;

    my @segments = @$path;
    my $last     = pop @segments;

    my $cursor = $value;
    for my $segment (@segments) {
        if (ref $cursor eq 'HASH') {
            my $key = defined $segment ? "$segment" : return;
            return unless exists $cursor->{$key};
            $cursor = $cursor->{$key};
            next;
        }

        if (ref $cursor eq 'ARRAY') {
            my $index = _normalize_array_index($segment, scalar @$cursor);
            return if !defined $index;
            $cursor = $cursor->[$index];
            next;
        }

        return;
    }

    if (ref $cursor eq 'HASH') {
        my $key = defined $last ? "$last" : return;
        delete $cursor->{$key};
        return;
    }

    if (ref $cursor eq 'ARRAY') {
        my $index = _normalize_array_index($last, scalar @$cursor);
        return if !defined $index;
        splice @$cursor, $index, 1;
    }
}

sub _normalize_array_index {
    my ($value, $length) = @_;

    return if !defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        $value = $value ? 1 : 0;
    }

    return if ref $value;

    return if $value !~ /^-?\d+$/;

    my $index = int($value);
    $index += $length if $index < 0;

    return if $index < 0 || $index >= $length;

    return $index;
}

sub _normalize_entry {
    my ($entry) = @_;

    if (ref $entry eq 'HASH') {
        return unless exists $entry->{key};
        return { key => $entry->{key}, value => $entry->{value} };
    }

    if (ref $entry eq 'ARRAY') {
        return unless @$entry >= 2;
        return { key => $entry->[0], value => $entry->[1] };
    }

    return;
}

sub _traverse {
    my ($data, $query) = @_;
    my @steps = split /\./, $query;
    my @stack = ($data);

    for my $step (@steps) {
        my $optional = ($step =~ s/\?$//);
        my @next_stack;

        for my $item (@stack) {
            next if !defined $item;

            # index access: key[index]
            if ($step =~ /^(.*?)\[(\d+)\]$/) {
                my ($key, $index) = ($1, $2);
                if (ref $item eq 'HASH' && exists $item->{$key}) {
                    my $val = $item->{$key};
                    push @next_stack, $val->[$index]
                        if ref $val eq 'ARRAY' && defined $val->[$index];
                }
            }
            # array expansion: key[]
            elsif ($step =~ /^(.*?)\[\]$/) {
                my $key = $1;
                if (ref $item eq 'HASH' && exists $item->{$key}) {
                    my $val = $item->{$key};
                    if (ref $val eq 'ARRAY') {
                        push @next_stack, @$val;
                    }
                }
                elsif (ref $item eq 'ARRAY') {
                    for my $sub (@$item) {
                        if (ref $sub eq 'HASH' && exists $sub->{$key}) {
                            my $val = $sub->{$key};
                            push @next_stack, @$val if ref $val eq 'ARRAY';
                        }
                    }
                }
            }
            # standard access: key
            else {
                if (ref $item eq 'HASH' && exists $item->{$step}) {
                    push @next_stack, $item->{$step};
                }
                elsif (ref $item eq 'ARRAY') {
                    for my $sub (@$item) {
                        if (ref $sub eq 'HASH' && exists $sub->{$step}) {
                            push @next_stack, $sub->{$step};
                        }
                    }
                }
            }
        }

        # allow empty results if optional
        @stack = @next_stack;
        last if !@stack && !$optional;
    }

    return @stack;
}

sub _evaluate_condition {
    my ($item, $cond) = @_;

    # support for numeric expressions like: select(.a + 5 > 10)
    if ($cond =~ /^\s*(\.\w+)\s*([\+\-\*\/%])\s*(-?\d+(?:\.\d+)?)\s*(==|!=|>=|<=|>|<)\s*(-?\d+(?:\.\d+)?)\s*$/) {
        my ($path, $op1, $rhs1, $cmp, $rhs2) = ($1, $2, $3, $4, $5);
        my @values = _traverse($item, substr($path, 1));
        my $lhs = $values[0];
    
        return 0 unless defined $lhs && $lhs =~ /^-?\d+(?:\.\d+)?$/;
    
        my $expr = eval "$lhs $op1 $rhs1";
        return eval "$expr $cmp $rhs2";
    }

    # support for multiple conditions: split and evaluate recursively
    if ($cond =~ /\s+and\s+/i) {
        my @conds = split /\s+and\s+/i, $cond;
        for my $c (@conds) {
            return 0 unless _evaluate_condition($item, $c);
        }
        return 1;
    }
    if ($cond =~ /\s+or\s+/i) {
        my @conds = split /\s+or\s+/i, $cond;
        for my $c (@conds) {
            return 1 if _evaluate_condition($item, $c);
        }
        return 0;
    }

    # support for the contains operator: select(.tags contains "perl")
    if ($cond =~ /^\s*\.(.+?)\s+contains\s+"(.*?)"\s*$/) {
        my ($path, $want) = ($1, $2);
        my @vals = _traverse($item, $path);

        for my $val (@vals) {
            if (ref $val eq 'ARRAY') {
                return 1 if grep { $_ eq $want } @$val;
            }
            elsif (!ref $val && index($val, $want) >= 0) {
                return 1;
            }
        }
        return 0;
    }

    # support for the has operator: select(.meta has "key")
    if ($cond =~ /^\s*\.(.+?)\s+has\s+"(.*?)"\s*$/) {
        my ($path, $key) = ($1, $2);
        my @vals = _traverse($item, $path);

        for my $val (@vals) {
            if (ref $val eq 'HASH' && exists $val->{$key}) {
                return 1;
            }
        }
        return 0;
    }

    # support for the match operator (with optional 'i' flag)
    if ($cond =~ /^\s*\.(.+?)\s+match\s+"(.*?)"(i?)\s*$/) {
        my ($path, $pattern, $ignore_case) = ($1, $2, $3);
        my $re = eval {
            $ignore_case eq 'i' ? qr/$pattern/i : qr/$pattern/
        };
        return 0 unless $re;

        my @vals = _traverse($item, $path);
        for my $val (@vals) {
            next if ref $val;
            return 1 if $val =~ $re;
        }
        return 0;
    }
 
    # pattern for a single condition
    if ($cond =~ /^\s*\.(.+?)\s*(==|!=|>=|<=|>|<)\s*(.+?)\s*$/) {
        my ($path, $op, $value_raw) = ($1, $2, $3);

        my $value;
        if ($value_raw =~ /^"(.*)"$/) {
            $value = $1;
        } elsif ($value_raw eq 'true') {
            $value = JSON::PP::true;
        } elsif ($value_raw eq 'false') {
            $value = JSON::PP::false;
        } elsif ($value_raw =~ /^-?\d+(?:\.\d+)?$/) {
            $value = 0 + $value_raw;
        } else {
            $value = $value_raw;
        }

        my @values = _traverse($item, $path);
        my $field_val = $values[0];

        return 0 unless defined $field_val;

        my $is_number = (!ref($field_val) && $field_val =~ /^-?\d+(?:\.\d+)?$/)
                     && (!ref($value)     && $value     =~ /^-?\d+(?:\.\d+)?$/);

        if ($op eq '==') {
            return $is_number ? ($field_val == $value) : ($field_val eq $value);
        } elsif ($op eq '!=') {
            return $is_number ? ($field_val != $value) : ($field_val ne $value);
        } elsif ($is_number) {
            # perform numeric comparisons only when applicable
            if ($op eq '>') {
                return $field_val > $value;
            } elsif ($op eq '>=') {
                return $field_val >= $value;
            } elsif ($op eq '<') {
                return $field_val < $value;
            } elsif ($op eq '<=') {
                return $field_val <= $value;
            }
        }
    }

    return 0;
}

sub _smart_cmp {
    return sub {
        my ($a, $b) = @_;

        my $num_a = ($a =~ /^-?\d+(?:\.\d+)?$/);
        my $num_b = ($b =~ /^-?\d+(?:\.\d+)?$/);

        if ($num_a && $num_b) {
            return $a <=> $b;
        } else {
            return "$a" cmp "$b";  # explicitly perform string comparison
        }
    };
}

sub _extreme_by {
    my ($array_ref, $key_path, $use_entire_item, $mode) = @_;

    return undef unless ref $array_ref eq 'ARRAY';
    return undef unless @$array_ref;

    my $cmp = _smart_cmp();
    my ($best_item, $best_key);

    for my $element (@$array_ref) {
        my $candidate = _extract_extreme_key($element, $key_path, $use_entire_item);
        next unless defined $candidate;

        if (!defined $best_item) {
            ($best_item, $best_key) = ($element, $candidate);
            next;
        }

        my $comparison = $cmp->($candidate, $best_key);
        if (($mode eq 'max' && $comparison > 0)
            || ($mode eq 'min' && $comparison < 0)) {
            ($best_item, $best_key) = ($element, $candidate);
        }
    }

    return defined $best_item ? $best_item : undef;
}

sub _extract_extreme_key {
    my ($element, $key_path, $use_entire_item) = @_;

    my @values = $use_entire_item ? ($element) : _traverse($element, $key_path);
    return undef unless @values;

    my $value = $values[0];
    return _value_to_comparable($value);
}

sub _value_to_comparable {
    my ($value) = @_;

    return undef unless defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        return $value ? 1 : 0;
    }

    if (!ref $value) {
        return $value;
    }

    if (ref($value) eq 'HASH' || ref($value) eq 'ARRAY') {
        return encode_json($value);
    }

    return undef;
}

sub _normalize_path_argument {
    my ($raw_path) = @_;

    $raw_path = '' unless defined $raw_path;
    $raw_path =~ s/^\s+|\s+$//g;
    $raw_path =~ s/^['"](.*)['"]$/$1/;

    my $use_entire_item = ($raw_path eq '' || $raw_path eq '.');
    my $key_path        = $raw_path;
    $key_path =~ s/^\.// unless $use_entire_item;

    return ($key_path, $use_entire_item);
}

sub _project_numeric_values {
    my ($element, $key_path, $use_entire_item) = @_;

    my @values = $use_entire_item
        ? ($element)
        : _traverse($element, $key_path);

    my @numbers;
    for my $value (@values) {
        next unless defined $value;

        if (ref($value) eq 'JSON::PP::Boolean') {
            push @numbers, $value ? 1 : 0;
            next;
        }

        next if ref $value;
        next unless looks_like_number($value);

        push @numbers, 0 + $value;
    }

    return @numbers;
}

sub _uniq {
    my %seen;
    return grep { !$seen{_key($_)}++ } @_;
}

# generate a unique key for hash, array, or scalar values
sub _key {
    my ($val) = @_;
    if (ref $val eq 'HASH') {
        return join(",", sort map { "$_=$val->{$_}" } keys %$val);
    } elsif (ref $val eq 'ARRAY') {
        return join(",", map { _key($_) } @$val);
    } else {
        return "$val";
    }
}

sub _group_by {
    my ($array_ref, $path) = @_;
    return {} unless ref $array_ref eq 'ARRAY';

    my %groups;
    for my $item (@$array_ref) {
        my @keys = _traverse($item, $path);
        my $key = defined $keys[0] ? "$keys[0]" : 'null';
        push @{ $groups{$key} }, $item;
    }
    return \%groups;
}

sub _flatten_all {
    my ($value) = @_;

    return $value unless ref $value eq 'ARRAY';

    my @flattened;
    for my $item (@$value) {
        if (ref $item eq 'ARRAY') {
            my $flattened = _flatten_all($item);
            if (ref $flattened eq 'ARRAY') {
                push @flattened, @$flattened;
            } else {
                push @flattened, $flattened;
            }
        } else {
            push @flattened, $item;
        }
    }

    return \@flattened;
}

sub _flatten_depth {
    my ($value, $depth) = @_;

    return $value unless ref $value eq 'ARRAY';
    return $value if $depth <= 0;

    my @flattened;
    for my $item (@$value) {
        if (ref $item eq 'ARRAY') {
            my $flattened = _flatten_depth($item, $depth - 1);
            if (ref $flattened eq 'ARRAY') {
                push @flattened, @$flattened;
            } else {
                push @flattened, $flattened;
            }
        } else {
            push @flattened, $item;
        }
    }

    return \@flattened;
}

sub _apply_string_predicate {
    my ($value, $needle, $mode) = @_;

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_string_predicate($_, $needle, $mode) } @$value ];
    }

    return _string_predicate_result($value, $needle, $mode);
}

sub _string_predicate_result {
    my ($value, $needle, $mode) = @_;

    return JSON::PP::false if !defined $value;
    return JSON::PP::false if ref $value;

    $needle //= '';
    my $len = length $needle;

    if ($mode eq 'start') {
        return JSON::PP::true if $len == 0 || index($value, $needle) == 0;
        return JSON::PP::false;
    }

    if ($mode eq 'end') {
        return JSON::PP::true if $len == 0;
        return JSON::PP::false if length($value) < $len;
        return JSON::PP::true if substr($value, -$len) eq $needle;
        return JSON::PP::false;
    }

    return JSON::PP::false;
}

sub _parse_string_argument {
    my ($raw) = @_;

    return '' if !defined $raw;

    my $parsed = eval { decode_json($raw) };
    if (!$@) {
        $parsed = '' if !defined $parsed;
        return $parsed;
    }

    $raw =~ s/^\s+|\s+$//g;
    $raw =~ s/^['"]//;
    $raw =~ s/['"]$//;
    return $raw;
}

sub _apply_split {
    my ($value, $separator) = @_;

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_split($_, $separator) } @$value ];
    }

    return [] if !defined $value;
    return $value if ref $value;

    $separator = '' unless defined $separator;

    if ($separator eq '') {
        return [ split(//, $value) ];
    }

    my $pattern = quotemeta $separator;
    my @parts = split /$pattern/, $value, -1;
    return [ @parts ];
}

sub _apply_explode {
    my ($value) = @_;

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_explode($_) } @$value ];
    }

    return undef if !defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        $value = $value ? 'true' : 'false';
    }

    return $value if ref $value;

    my @chars = split(//u, "$value");
    return [ map { ord($_) } @chars ];
}

sub _apply_implode {
    my ($value) = @_;

    return undef if !defined $value;

    if (ref $value eq 'ARRAY') {
        my $has_nested = grep { ref $_ } @$value;

        if ($has_nested) {
            return [ map { _apply_implode($_) } @$value ];
        }

        my $string = '';
        for my $code (@$value) {
            next unless defined $code;
            next unless looks_like_number($code);
            $string .= chr(int($code));
        }
        return $string;
    }

    return $value;
}

sub _apply_substr {
    my ($value, @args) = @_;

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_substr($_, @args) } @$value ];
    }

    return undef if !defined $value;
    return $value if ref $value;

    my ($start, $length) = @args;
    $start = 0 unless defined $start;
    $start = int($start);

    if (defined $length) {
        $length = int($length);
        return substr($value, $start, $length);
    }

    return substr($value, $start);
}

sub _apply_slice {
    my ($value, @args) = @_;

    return undef if !defined $value;

    if (ref $value eq 'ARRAY') {
        my $array = $value;
        my $size  = @$array;

        return [] if $size == 0;

        my $raw_start = @args ? $args[0] : 0;
        my $start     = 0;

        if (defined $raw_start && looks_like_number($raw_start)) {
            $start = int($raw_start);
        }

        $start += $size if $start < 0;
        $start = 0       if $start < 0;
        return []        if $start >= $size;

        my $length;
        if (@args > 1 && defined $args[1] && looks_like_number($args[1])) {
            $length = int($args[1]);
        }

        my $end;
        if (defined $length) {
            return [] if $length <= 0;
            $end = $start + $length;
        }
        else {
            $end = $size;
        }

        $end = $size if $end > $size;

        return [] if $end <= $start;

        return [ @$array[$start .. $end - 1] ];
    }

    return $value;
}

sub _apply_replace {
    my ($value, $search, $replacement) = @_;

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_replace($_, $search, $replacement) } @$value ];
    }

    return $value if !defined $value;
    return $value if ref $value;

    return $value if looks_like_number($value);

    $search      = defined $search      ? "$search"      : '';
    $replacement = defined $replacement ? "$replacement" : '';

    return $value if $search eq '';

    my $pattern = quotemeta $search;
    (my $copy = "$value") =~ s/$pattern/$replacement/g;
    return $copy;
}

sub _apply_pick {
    my ($value, $keys) = @_;

    return $value unless @$keys;

    if (ref $value eq 'HASH') {
        my %subset;
        for my $key (@$keys) {
            next unless defined $key;
            next unless exists $value->{$key};
            $subset{$key} = $value->{$key};
        }
        return \%subset;
    }

    if (ref $value eq 'ARRAY') {
        return [ map { _apply_pick($_, $keys) } @$value ];
    }

    return $value;
}

sub _parse_arguments {
    my ($raw) = @_;

    return () unless defined $raw;

    my $parsed = eval { decode_json("[$raw]") };
    if (!$@ && ref $parsed eq 'ARRAY') {
        return @$parsed;
    }

    my @parts = split /,/, $raw;
    return map { s/^\s+|\s+$//gr } @parts;
}

sub _parse_range_arguments {
    my ($raw) = @_;

    return () unless defined $raw;

    $raw =~ s/^\s+|\s+$//g;
    return () if $raw eq '';

    my @segments;
    my $current    = '';
    my $in_single  = 0;
    my $in_double  = 0;
    my $escape     = 0;

    for my $char (split //, $raw) {
        if ($escape) {
            $current .= $char;
            $escape = 0;
            next;
        }

        if ($char eq '\\' && $in_double) {
            $current .= $char;
            $escape = 1;
            next;
        }

        if ($char eq '"' && !$in_single) {
            $in_double = !$in_double;
            $current  .= $char;
            next;
        }

        if ($char eq "'" && !$in_double) {
            $in_single = !$in_single;
            $current  .= $char;
            next;
        }

        if ($char eq ';' && !$in_single && !$in_double) {
            push @segments, $current;
            $current = '';
            next;
        }

        $current .= $char;
    }

    push @segments, $current;

    my @args;
    for my $segment (@segments) {
        next unless defined $segment;
        my $clean = $segment;
        $clean =~ s/^\s+|\s+$//g;
        next if $clean eq '';

        my @values = _parse_arguments($clean);
        my $value  = @values ? $values[0] : undef;
        push @args, $value;
    }

    return @args;
}

sub _apply_range {
    my ($value, $args_ref) = @_;

    my $sequence = _build_range_sequence($args_ref);
    return defined $sequence ? @$sequence : ($value);
}

sub _build_range_sequence {
    my ($args_ref) = @_;

    my @args = @$args_ref;
    return undef unless @args;

    @args = @args[0 .. 2] if @args > 3;

    my ($start, $end, $step);

    if (@args == 1) {
        $start = 0;
        $end   = _coerce_range_number($args[0]);
        $step  = 1;
    }
    elsif (@args == 2) {
        $start = _coerce_range_number($args[0]);
        $end   = _coerce_range_number($args[1]);
        $step  = 1;
    }
    else {
        $start = _coerce_range_number($args[0]);
        $end   = _coerce_range_number($args[1]);
        $step  = _coerce_range_number($args[2]);
    }

    return undef unless defined $start && defined $end;
    return undef if !defined $step;
    return []    if $step == 0;

    if ($step > 0) {
        return [] if $start >= $end;
        my @sequence;
        for (my $current = $start; $current < $end; $current += $step) {
            push @sequence, 0 + $current;
        }
        return \@sequence;
    }

    # negative step
    return [] if $start <= $end;

    my @sequence;
    for (my $current = $start; $current > $end; $current += $step) {
        push @sequence, 0 + $current;
    }

    return \@sequence;
}

sub _coerce_range_number {
    my ($value) = @_;

    return undef if !defined $value;

    if (ref($value) eq 'JSON::PP::Boolean') {
        return $value ? 1 : 0;
    }

    return looks_like_number($value) ? 0 + $value : undef;
}

sub _apply_contains {
    my ($value, $needle) = @_;

    if (ref $value eq 'ARRAY') {
        for my $item (@$value) {
            return JSON::PP::true if _values_equal($item, $needle);
        }
        return JSON::PP::false;
    }

    if (ref $value eq 'HASH') {
        return exists $value->{$needle} ? JSON::PP::true : JSON::PP::false;
    }

    return JSON::PP::false if !defined $value;

    if (!ref $value || ref($value) eq 'JSON::PP::Boolean') {
        my $haystack = "$value";
        my $fragment = defined $needle ? "$needle" : '';
        return index($haystack, $fragment) >= 0 ? JSON::PP::true : JSON::PP::false;
    }

    return JSON::PP::false;
}

sub _apply_indices {
    my ($value, $needle) = @_;

    if (ref $value eq 'ARRAY') {
        my @matches;
        for my $i (0 .. $#$value) {
            push @matches, $i if _values_equal($value->[$i], $needle);
        }
        return \@matches;
    }

    return [] if !defined $value;

    if (!ref $value || ref($value) eq 'JSON::PP::Boolean') {
        return [] unless defined $needle;

        my $haystack = "$value";
        my $fragment = "$needle";

        my @positions;
        if ($fragment eq '') {
            @positions = (0 .. length($haystack));
        }
        else {
            my $pos = -1;
            while (1) {
                $pos = index($haystack, $fragment, $pos + 1);
                last if $pos == -1;
                push @positions, $pos;
            }
        }

        return \@positions;
    }

    return [];
}

sub _apply_has {
    my ($value, $needle) = @_;

    return JSON::PP::false if !defined $needle;

    if (ref $value eq 'HASH') {
        return exists $value->{$needle} ? JSON::PP::true : JSON::PP::false;
    }

    if (ref $value eq 'ARRAY') {
        return JSON::PP::false unless looks_like_number($needle);

        my $index = int($needle);
        return ($index >= 0 && $index < @$value)
            ? JSON::PP::true
            : JSON::PP::false;
    }

    return JSON::PP::false;
}

sub _values_equal {
    my ($left, $right) = @_;

    return 1 if !defined $left && !defined $right;
    return 0 if !defined $left || !defined $right;

    if (ref($left) eq 'JSON::PP::Boolean' && ref($right) eq 'JSON::PP::Boolean') {
        return (!!$left) == (!!$right);
    }

    if (!ref $left && !ref $right) {
        if (looks_like_number($left) && looks_like_number($right)) {
            return $left == $right;
        }
        return "$left" eq "$right";
    }

    if (ref $left eq 'ARRAY' && ref $right eq 'ARRAY') {
        return 0 if @$left != @$right;
        for (my $i = 0; $i < @$left; $i++) {
            return 0 unless _values_equal($left->[$i], $right->[$i]);
        }
        return 1;
    }

    if (ref $left eq 'HASH' && ref $right eq 'HASH') {
        return 0 if keys(%$left) != keys(%$right);
        for my $key (keys %$left) {
            return 0 unless exists $right->{$key} && _values_equal($left->{$key}, $right->{$key});
        }
        return 1;
    }

    return 0;
}

sub _ceil {
    my ($number) = @_;

    return $number if int($number) == $number;
    return $number > 0 ? int($number) + 1 : int($number);
}

sub _floor {
    my ($number) = @_;

    return $number if int($number) == $number;
    return $number > 0 ? int($number) : int($number) - 1;
}

sub _round {
    my ($number) = @_;

    return $number if int($number) == $number;
    return $number >= 0 ? int($number + 0.5) : int($number - 0.5);
}

sub _group_count {
    my ($array_ref, $path) = @_;
    return {} unless ref $array_ref eq 'ARRAY';

    my %counts;
    for my $item (@$array_ref) {
        my @keys = _traverse($item, $path);
        my $key = defined $keys[0] ? "$keys[0]" : 'null';
        $counts{$key}++;
    }

    return \%counts;
}

1;
__END__

=encoding utf-8

=head1 NAME

JQ::Lite - A lightweight jq-like JSON query engine in Perl

=head1 VERSION

Version 0.99

=head1 SYNOPSIS

  use JQ::Lite;
  
  my $jq = JQ::Lite->new;
  my @results = $jq->run_query($json_text, '.users[].name');
  
  for my $r (@results) {
      print encode_json($r), "\n";
  }

=head1 DESCRIPTION

JQ::Lite is a lightweight, pure-Perl JSON query engine inspired by the
L<jq|https://stedolan.github.io/jq/> command-line tool.

It allows you to extract, traverse, and filter JSON data using a simplified
jq-like syntax — entirely within Perl, with no external binaries or XS modules.

=head1 FEATURES

=over 4

=item * Pure Perl (no XS, no external binaries required)

=item * Dot notation traversal (e.g. .users[].name)

=item * Optional key access using '?' (e.g. .nickname?)

=item * Array indexing and flattening (.users[0], .users[])

=item * Boolean filters via select(...) with ==, !=, <, >, and, or

=item * Pipe-style query chaining using | operator

=item * Built-in functions: length, keys, keys_unsorted, values, first, last, reverse, sort, sort_desc, sort_by, min_by, max_by, unique, unique_by, has, contains, any, all, group_by, group_count, join, split, explode, implode, count, empty, type, nth, del, delpaths, compact, upper, lower, titlecase, abs, ceil, floor, trim, ltrimstr, rtrimstr, substr, slice, startswith, endswith, add, sum, sum_by, avg_by, median_by, product, min, max, avg, median, mode, percentile, variance, stddev, drop, tail, chunks, range, enumerate, transpose, flatten_all, flatten_depth, clamp, tostring, tojson, to_number, pick, merge_objects, to_entries, from_entries, with_entries, map_values, walk, paths, leaf_paths, index, rindex, indices

=item * Supports map(...), map_values(...), walk(...), limit(n), drop(n), tail(n), chunks(n), range(...), and enumerate() style transformations

=item * Interactive mode for exploring queries line-by-line

=item * Command-line interface: C<jq-lite> (compatible with stdin or file)

=item * Decoder selection via C<--use> (JSON::PP, JSON::XS, etc.)

=item * Debug output via C<--debug>

=item * List all functions with C<--help-functions>

=back

=head1 CONSTRUCTOR

=head2 new

  my $jq = JQ::Lite->new;

Creates a new instance. Options may be added in future versions.

=head1 METHODS

=head2 run_query

  my @results = $jq->run_query($json_text, $query);

Runs a jq-like query against the given JSON string.
Returns a list of matched results. Each result is a Perl scalar
(string, number, arrayref, hashref, etc.) depending on the query.

=head1 SUPPORTED SYNTAX

=over 4

=item * .key.subkey

=item * .array[0] (index access)

=item * .array[] (flattening arrays)

=item * .key? (optional key access)

=item * select(.key > 1 and .key2 == "foo") (boolean filters)

=item * group_by(.field) (group array items by key)

=item * group_count(.field) (tally items by key)

=item * sum_by(.field) (sum numeric values projected from each array item)

=item * avg_by(.field) (average numeric values projected from each array item)

=item * median_by(.field) (median of numeric values projected from each array item)

=item * percentile(p) (return the requested percentile for numeric array values)

=item * min_by(.field) / max_by(.field) (select array element with smallest/largest projected value)

=item * sort_desc()

Sort array elements in descending order using smart numeric/string comparison.

Example:

  .scores | sort_desc

Returns:

  [100, 75, 42, 12]

=item * sort_by(.key) (sort array of objects by key)

=item * unique_by(.key) (remove duplicates based on a projected key)

=item * .key | count (count items or fields)

=item * .[] | select(...) | count (combine flattening + filter + count)

=item * .array | map(.field) | join(", ")

Concatenates array elements with a custom separator string.
Example:

  .users | map(.name) | join(", ")

Results in:

  "Alice, Bob, Carol"

=item * split(separator)

Split string values (and arrays of strings) using a literal separator.
Example:

  .users[0].name | split("")

Results in:

  ["A", "l", "i", "c", "e"]

=item * explode()

Convert strings into arrays of Unicode code points. When applied to arrays the
conversion happens element-wise, while non-string values (including hashes) are
passed through untouched. This mirrors jq's C<explode> helper and pairs with
C<implode> for round-trip transformations.

Example:

  .title | explode

Returns:

  [67, 79, 68, 69]

=item * implode()

Perform the inverse of C<explode> by turning arrays of Unicode code points back
into strings. Nested arrays are processed recursively so pipelines like
C<explode | implode> work over heterogeneous structures. Non-array inputs pass
through unchanged.

Example:

  .codes | implode

Returns:

  "CODE"


=item * keys_unsorted()

Returns the keys of an object without sorting them, mirroring jq's
C<keys_unsorted> helper. Arrays yield their zero-based indices, while
non-object/array inputs return C<undef> to match the behaviour of C<keys>.

Example:

  .profile | keys_unsorted

=item * values()

Returns all values of a hash as an array.
Example:

  .profile | values

=item * paths()

Enumerates every path within the current value, mirroring jq's C<paths>
helper. Each path is emitted as an array of keys and/or indices leading to
objects, arrays, and their nested scalars. Scalars (including booleans and
null) yield a single empty path, while empty arrays and objects contribute only
their immediate location.

Example:

  .user | paths

Returns:

  [ ["name"], ["tags"], ["tags",0], ["tags",1], ["active"] ]

=item * leaf_paths()

Enumerates only the paths that terminate in non-container values, mirroring
jq's C<leaf_paths> helper. This is equivalent to C<paths(scalars)> in jq.

Example:

  .user | leaf_paths

Returns:

  [ ["name"], ["tags",0], ["tags",1], ["active"] ]

=item * getpath(path)

Retrieves the value referenced by the supplied path array (or filter producing
path arrays), mirroring jq's C<getpath/1>. Literal JSON arrays can be passed
directly while expressions such as C<paths()> are evaluated against the current
input to collect candidate paths. When multiple paths are returned the helper
yields an array of values in the same order.

Examples:

  .profile | getpath(["name"])          # => "Alice"
  .profile | getpath(["emails", 1])     # => "alice.work\@example.com"
  .profile | getpath(paths())

=item * pick(key1, key2, ...)

Builds a new object containing only the supplied keys. When applied to arrays
of objects, each element is reduced to the requested subset while non-object
values pass through unchanged.

Example:

  .users | pick("name", "email")

Returns:

  [ { "name": "Alice", "email": "alice\@example.com" },
    { "name": "Bob" } ]

=item * merge_objects()

Merges arrays of objects into a single hash reference using last-write-wins
semantics. Non-object values within the array are ignored. When no objects are
found, an empty hash reference is returned. Applying the helper directly to an
object returns a shallow copy of that object.

Example:

  .items | merge_objects()

Returns:

  { "name": "Widget", "value": 2, "active": true }

=item * to_entries()

Converts objects (and arrays) into an array of entry hashes, each consisting of
C<key> and C<value> fields in the jq style. Array entries use zero-based index
values for the key so they can be transformed uniformly.

Example:

  .profile | to_entries
  .tags    | to_entries

=item * from_entries()

Performs the inverse of C<to_entries>. Accepts arrays containing
C<{ key => ..., value => ... }> hashes or C<[key, value]> tuples and rebuilds a
hash from them. Later entries overwrite earlier ones when duplicate keys are
encountered.

Example:

  .pairs | from_entries

=item * with_entries(filter)

Transforms objects by mapping over their entries with the supplied filter,
mirroring jq's C<with_entries>. Each entry is exposed as a C<{ key, value }>
hash to the filter, and any entries filtered out are dropped prior to
reconstruction.

Example:

  .profile | with_entries(select(.key != "password"))

=item * map_values(filter)

Applies the supplied filter to every value within an object, mirroring jq's
C<map_values>. When the filter returns no results for a key the entry is
removed, allowing constructs such as C<map_values(select(. > 0))> to prune
falsy values. Arrays are processed element-wise, so arrays of objects can be
transformed in a single step.

Example:

  .profile | map_values(tostring)

Returns:

  { "name": "Alice", "age": "42" }

=item * walk(filter)

Recursively traverses arrays and objects, applying the supplied filter to each
value after its children have been transformed, matching jq's C<walk/1>
behaviour. Arrays and hashes are rebuilt so nested values can be updated in a
single pass, while scalars pass directly to the filter.

Example:

  .profile | walk(upper)

Returns:

  { "name": "ALICE", "note": "TEAM LEAD" }

=item * empty()

Discards all output. Compatible with jq.
Useful when only side effects or filtering is needed without output.

Example:

  .users[] | select(.age > 25) | empty

=item * .[] as alias for flattening top-level arrays

=item * transpose()

Pivots an array of arrays from row-oriented to column-oriented form. When
rows have different lengths, the result truncates to the shortest row so that
every column contains the same number of elements.

Example:

  [[1, 2, 3], [4, 5, 6]] | transpose

Returns:

  [[1, 4], [2, 5], [3, 6]]

=item * flatten_all()

Recursively flattens nested arrays into a single-level array while preserving
non-array values.

Example:

  [[1, 2], [3, [4]]] | flatten_all

Returns:

  [1, 2, 3, 4]

=item * flatten_depth(n)

Flattens nested arrays up to C<n> levels deep while leaving deeper nesting
intact.

Example:

  [[1, [2]], [3, [4]]] | flatten_depth(1)

Returns:

  [1, [2], 3, [4]]


=item * arrays

Emits its input only when the value is an array reference, mirroring jq's
C<arrays> filter. Scalars and objects yield no output, making it convenient to
select array inputs prior to additional processing.

Example:

  .items[] | arrays

Returns only the array entries from C<.items>.

=item * type()

Returns the type of the value as a string:
"string", "number", "boolean", "array", "object", or "null".

Example:

  .name | type     # => "string"
  .tags | type     # => "array"
  .profile | type  # => "object"

=item * nth(n)

Returns the nth element (zero-based) from an array.

Example:

  .users | nth(0)   # first user
  .users | nth(2)   # third user

=item * del(key)

Deletes a specified key from a hash object and returns a new hash without that key.

Example:

  .profile | del("password")

If the key does not exist, returns the original hash unchanged.

If applied to a non-hash object, returns the object unchanged.

=item * delpaths(paths)

Removes multiple keys or indices identified by the supplied C<paths> expression.
The expression is evaluated against the current input (for example by using
C<paths()> or other jq-lite helpers) and should yield an array of path arrays,
mirroring jq's C<delpaths/1> behaviour.

Example:

  .profile | delpaths([["password"], ["tokens", 0]])

Paths can be generated dynamically using helpers such as C<paths()> before being
passed to C<delpaths>. When a referenced path is missing it is ignored.
Providing an empty path (C<[]> ) removes the entire input value, yielding C<null>.

=item * compact()

Removes undef and null values from an array.

Example:

  .data | compact()

Before: [1, null, 2, null, 3]

After:  [1, 2, 3]

=item * upper()

Converts strings to uppercase. When applied to arrays, each scalar element
is uppercased recursively, leaving nested hashes or booleans untouched.

Example:

  .title | upper      # => "HELLO WORLD"
  .tags  | upper      # => ["PERL", "JSON"]

=item * titlecase()

Converts strings to title case (first letter of each word uppercase). When
applied to arrays, each scalar element is transformed recursively, leaving
nested hashes or booleans untouched.

Example:

  .title | titlecase   # => "Hello World"
  .tags  | titlecase   # => ["Perl", "Json"]

=item * lower()

Converts strings to lowercase. When applied to arrays, each scalar element
is lowercased recursively, leaving nested hashes or booleans untouched.

Example:

  .title | lower      # => "hello world"
  .tags  | lower      # => ["perl", "json"]

=item * has(key)

Checks whether the current value exposes the supplied key or index.

* For hashes, returns true when the key is present.
* For arrays, returns true when the zero-based index exists.

Example:

  .meta  | has("version")   # => true
  .items | has(2)            # => true when at least 3 elements exist

=item * contains(value)

Checks whether the current value includes the supplied fragment.

* For strings, returns true when the substring exists.
* For arrays, returns true if any element equals the supplied value.
* For hashes, returns true when the key is present.

Example:

  .title | contains("perl")     # => true
  .tags  | contains("json")     # => true
  .meta  | contains("lang")     # => true

=item * all([filter])

Evaluates whether every element (optionally projected through C<filter>) is
truthy, mirroring jq's C<all/1> helper.

=over 4

=item * For arrays without a filter, returns true when every element is truthy
  (empty arrays yield true).

=item * For arrays with a filter, applies the filter to each element and
  requires every produced value to be truthy.

=item * When the current input is a scalar, falls back to checking the value's
  truthiness (or the filter's results when supplied).

=back

Examples:

  .flags | all            # => true when every element is truthy (empty => true)
  .users | all(.active)   # => true when every user is active

=item * any([filter])

Returns true when at least one value in the input is truthy. When a filter is
provided, it is evaluated against each array element (or the current value when
not operating on an array) and the truthiness of the filter's results is used.

* For arrays without a filter, returns true if any element is truthy.
* For arrays with a filter, returns true when the filter yields a truthy value
  for any element.
* For scalars, hashes, and other values, evaluates the value (or filter results)
  directly.

Example:

  .flags | any            # => true when any element is truthy
  .users | any(.active)   # => true when any user is active

=item * unique_by(".key")

Removes duplicate objects (or values) from an array by projecting each entry to
the supplied key path and keeping only the first occurrence of each signature.
Use C<.> to deduplicate by the entire value.

Example:

  .users | unique_by(.name)      # => keeps first record for each name
  .tags  | unique_by(.)          # => removes duplicate scalars

=item * startswith("prefix")

Returns true if the current string (or each string inside an array) begins with
the supplied prefix. Non-string values yield C<false>.

Example:

  .title | startswith("Hello")   # => true
  .tags  | startswith("j")       # => [false, true, false]

=item * endswith("suffix")

Returns true if the current string (or each string inside an array) ends with
the supplied suffix. Non-string values yield C<false>.

Example:

  .title | endswith("World")     # => true
  .tags  | endswith("n")         # => [false, true, false]

=item * substr(start[, length])

Extracts a substring from the current string using zero-based indexing.
When applied to arrays, each scalar element receives the same slicing
arguments recursively.

Examples:

  .title | substr(0, 5)       # => "Hello"
  .tags  | substr(-3)         # => ["erl", "SON"]

=item * slice(start[, length])

Returns a portion of the current array using zero-based indexing. Negative
start values count from the end of the array. When length is omitted, the
slice continues through the final element. Non-array inputs pass through
unchanged so pipelines can mix scalar and array values safely.

Examples:

  .users | slice(0, 2)        # => first two users
  .users | slice(-2)          # => last two users

=item * tail(n)

Returns the final C<n> elements of the current array. When C<n> is zero the
result is an empty array, and when C<n> exceeds the array length the entire
array is returned unchanged. Non-array inputs pass through untouched so the
helper composes cleanly inside pipelines that also yield scalars or objects.

Examples:

  .users | tail(2)            # => last two users
  .users | tail(10)           # => full array when shorter than 10

=item * range(start; end[, step])

Emits a numeric sequence that begins at C<start> (default C<0>) and advances
by C<step> (default C<1>) until reaching but not including C<end>. When the
step is negative the helper counts downward and stops once the value is less
than or equal to the exclusive bound. Non-numeric arguments result in the
input being passed through unchanged so pipelines remain resilient.

Examples:

  null | range(5)           # => 0,1,2,3,4
  null | range(2; 6; 2)     # => 2,4
  null | range(10; 2; -4)   # => 10,6

=item * enumerate()

Converts arrays into an array of objects pairing each element with its
zero-based index. Each object contains two keys: C<index> for the position and
C<value> for the original element. Non-array inputs are returned unchanged so
the helper composes inside pipelines that may yield scalars or hashes.

Examples:

  .users | enumerate()          # => [{"index":0,"value":...}, ...]
  .numbers | enumerate() | map(.index)

=item * index(value)

Returns the zero-based index of the first occurrence of the supplied value.
When the current result is an array, deep comparisons are used so nested
structures (hashes, arrays, booleans) work as expected. When the current value
is a string, the function returns the position of the substring, or null when
not found.

Example:

  .users | index("Alice")     # => 0
  .tags  | index("json")      # => 1

=item * rindex(value)

Returns the zero-based index of the final occurrence of the supplied value.
Array inputs are scanned from the end using deep comparisons, while string
inputs return the position of the last matching substring (or null when not
found).

Example:

  .users | rindex("Alice")    # => 3
  .tags  | rindex("perl")     # => 2
  "banana" | rindex("an")    # => 3

=item * indices(value)

Returns every zero-based index where the supplied value appears. For arrays,
deep comparisons are performed against each element and the matching indexes
are collected into an array. For strings, the helper searches for literal
substring matches (including overlapping ones) and emits each starting
position. When the fragment is empty, positions for every character boundary
are returned to mirror jq's behaviour.

Example:

  .users | indices("Alice")     # => [0, 3]
  "banana" | indices("an")      # => [1, 3]
  "perl"   | indices("")        # => [0, 1, 2, 3, 4]

=item * abs()

Returns absolute values for numbers. Scalars are converted directly, while
arrays are processed element-by-element with non-numeric entries preserved.

Example:

  .temperature | abs      # => 12
  .deltas      | abs      # => [3, 4, 5, "n/a"]

=item * ceil()

Rounds numbers up to the nearest integer. Scalars and array elements that look
like numbers are rounded upward, while other values pass through unchanged.

Example:

  .price   | ceil     # => 20
  .changes | ceil     # => [2, -1, "n/a"]

=item * floor()

Rounds numbers down to the nearest integer. Scalars and array elements that
look like numbers are rounded downward, leaving non-numeric values untouched.

Example:

  .price   | floor    # => 19
  .changes | floor    # => [1, -2, "n/a"]

=item * round()

Rounds numbers to the nearest integer using standard rounding (half up for
positive values, half down for negatives). Scalars and array elements that look
like numbers are adjusted, while other values pass through unchanged.

Example:

  .price   | round    # => 19
  .changes | round    # => [1, -2, "n/a"]

=item * clamp(min, max)

Constrains numeric values within the supplied inclusive range. Scalars and
array elements that look like numbers are coerced into numeric context and
clamped between the provided minimum and maximum. When a bound is omitted or
non-numeric, it is treated as unbounded on that side. Non-numeric values pass
through unchanged so pipelines remain lossless.

Example:

  .score  | clamp(0, 100)       # => 87
  .deltas | clamp(-5, 5)        # => [-5, 2, 5, "n/a"]

=item * tostring()

Converts the current value into a JSON string representation. Scalars are
stringified directly, booleans become C<"true">/C<"false">, and undefined
values are rendered as C<"null">. Arrays and objects are encoded to their JSON
text form so the output matches jq's behavior when applied to structured data.

Example:

  .score   | tostring   # => "42"
  .profile | tostring   # => "{\"name\":\"Alice\"}"

=item * tojson()

Encodes the current value as JSON text regardless of its original type,
mirroring jq's C<tojson>. Scalars, booleans, nulls, arrays, and objects all
produce a JSON string, allowing raw string inputs to be re-escaped safely for
embedding or subsequent decoding.

Example:

  .score   | tojson   # => "42"
  .name    | tojson   # => "\"Alice\""
  .profile | tojson   # => "{\"name\":\"Alice\"}"

=item * to_number()

Coerces values that look like numbers into actual numeric scalars. Strings are
converted with Perl's numeric semantics, booleans become 1 or 0, and arrays are
processed element-by-element. Non-numeric strings, objects, and other references
are returned unchanged so pipelines remain lossless.

Example:

  .score    | to_number   # => 42
  .strings  | to_number   # => [10, "n/a", 3.5]

=item * trim()

Removes leading and trailing whitespace from strings. Arrays are processed
recursively, while hashes and other references are left untouched.

Example:

  .title | trim          # => "Hello World"
  .tags  | trim          # => ["perl", "json"]

=item * ltrimstr("prefix")

Removes C<prefix> from the start of strings when present. Arrays are processed
recursively so nested string values receive the same treatment. Inputs that do
not begin with the supplied prefix are returned unchanged.

Example:

  .title | ltrimstr("Hello ")  # => "World"
  .tags  | ltrimstr("#")       # => ["perl", "json"]

=item * rtrimstr("suffix")

Removes C<suffix> from the end of strings when present. Arrays are processed
recursively so nested string values are handled consistently. Inputs that do
not end with the supplied suffix are returned unchanged.

Example:

  .title | rtrimstr(" World")  # => "Hello"
  .tags  | rtrimstr("ing")     # => ["perl", "json"]

=back

=head1 COMMAND LINE USAGE

C<jq-lite> is a CLI wrapper for this module.

  cat data.json | jq-lite '.users[].name'
  jq-lite '.users[] | select(.age > 25)' data.json
  jq-lite -r '.users[].name' data.json
  jq-lite '.[] | select(.active == true) | .name' data.json
  jq-lite '.users[] | select(.age > 25) | count' data.json
  jq-lite '.users | map(.name) | join(", ")'
  jq-lite '.users[] | select(.age > 25) | empty'
  jq-lite '.profile | values'

=head2 Interactive Mode

Omit the query to enter interactive mode:

  jq-lite data.json

You can then type queries line-by-line against the same JSON input.

=head2 Decoder Selection and Debug

  jq-lite --use JSON::PP --debug '.users[0].name' data.json

=head2 Show Supported Functions

  jq-lite --help-functions

Displays all built-in functions and their descriptions.

=head1 REQUIREMENTS

Uses only core modules:

=over 4

=item * JSON::PP

=back

Optional: JSON::XS, Cpanel::JSON::XS, JSON::MaybeXS

=head1 SEE ALSO

L<JSON::PP>, L<jq|https://stedolan.github.io/jq/>

=head1 AUTHOR

Kawamura Shingo E<lt>pannakoota1@gmail.comE<gt>

=head1 LICENSE

Same as Perl itself.

=cut

