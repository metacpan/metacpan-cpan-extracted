package JQ::Lite;

use strict;
use warnings;
use JSON::PP;

our $VERSION = '0.14';

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
    
    my @parts = split /\|/, $query;
    @parts = map {
        s/^\s+|\s+$//g;
        s/^\.//;
        $_;
    } @parts;

    my @results = ($data);
    for my $part (@parts) {
        my @next_results;

        # select(...) 対応
        if ($part =~ /^select\((.+)\)$/) {
            my $cond = $1;
            @next_results = grep { _evaluate_condition($_, $cond) } @results;
            @results = @next_results;
            next;
        }

        # length 対応
        if ($part eq 'length') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? scalar(@$_) :
                ref $_ eq 'HASH'  ? scalar(keys %$_) :
                0
            } @results;
            @results = @next_results;
            next;
        }

        # keys 対応
        if ($part eq 'keys') {
            @next_results = map {
                ref $_ eq 'HASH' ? [ sort keys %$_ ] : undef
            } @results;
            @results = @next_results;
            next;
        }

        # sort 対応
        if ($part eq 'sort') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? [ sort { _smart_cmp()->($a, $b) } @$_ ] : $_
            } @results;
            @results = @next_results;
            next;
        }

        # unique 対応
        if ($part eq 'unique') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? [ _uniq(@$_) ] : $_
            } @results;
            @results = @next_results;
            next;
        }

        # first 対応
        if ($part eq 'first') {
            @next_results = map {
                ref $_ eq 'ARRAY' && @$_ ? $$_[0] : undef
            } @results;
            @results = @next_results;
            next;
        }

        # last 対応
        if ($part eq 'last') {
            @next_results = map {
                ref $_ eq 'ARRAY' && @$_ ? $$_[-1] : undef
            } @results;
            @results = @next_results;
            next;
        }

        # reverse 対応
        if ($part eq 'reverse') {
            @next_results = map {
                ref $_ eq 'ARRAY' ? [ reverse @$_ ] : $_
            } @results;
            @results = @next_results;
            next;
        }

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

        # 通常トラバース
        for my $item (@results) {
            push @next_results, _traverse($item, $part);
        }
        @results = @next_results;
    }

    return @results;
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

            # 添字アクセス: key[index]
            if ($step =~ /^(.*?)\[(\d+)\]$/) {
                my ($key, $index) = ($1, $2);
                if (ref $item eq 'HASH' && exists $item->{$key}) {
                    my $val = $item->{$key};
                    push @next_stack, $val->[$index]
                        if ref $val eq 'ARRAY' && defined $val->[$index];
                }
            }
            # 配列展開: key[]
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
            # 通常アクセス: key
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

        # optional の場合は空でも許容
        @stack = @next_stack;
        last if !@stack && !$optional;
    }

    return @stack;
}

sub _evaluate_condition {
    my ($item, $cond) = @_;

    # 複数条件対応：分割して再帰評価
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

    # contains 演算子対応: select(.tags contains "perl")
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

    # has 演算子対応: select(.meta has "key")
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

    # match 演算子対応（iオプション付き）
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
 
    # 単一条件パターン
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
            # 数値比較は数値でしか行わない
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
            return "$a" cmp "$b";  # 明示的に文字列比較
        }
    };
}

sub _uniq {
    my %seen;
    return grep { !$seen{_key($_)}++ } @_;
}

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

1;
__END__

=encoding utf-8

=head1 NAME

JQ::Lite - A lightweight jq-like JSON query engine in Perl

=head1 VERSION

Version 0.14

=head1 SYNOPSIS

  use JQ::Lite;
  
  my $jq = JQ::Lite->new;
  my @results = $jq->run_query($json_text, '.domain[] | .name');
  
  for my $r (@results) {
      print encode_json($r), "\n";
  }

=head1 DESCRIPTION

JQ::Lite is a minimal Perl module that allows querying JSON data
using a simplified jq-like syntax.

Currently supported features:

=over 4

=item * Dot-based key access (e.g. .users[].name)

=item * Optional key access with ? (e.g. .nickname?)

=item * Array indexing and flattening (e.g. .users[0], .users[])

=item * Built-in functions: length, keys

=item * select(...) filters with comparison and logical operators

=back

=head1 METHODS

=head2 new

  my $jq = JQ::Lite->new;

Creates a new JQ::Lite instance.

=head2 run_query

  my @results = $jq->run_query($json_text, $query);

Runs a query string against the given JSON text.

=head1 REQUIREMENTS

This module uses only core Perl modules:

=over 4

=item * JSON::PP

=back

=head1 SEE ALSO

L<JSON::PP>

L<JQ::Lite on GitHub|https://github.com/kawamurashingo/JQ-Lite>


=head1 AUTHOR

Kawamura Shingo <pannakoota1@gmail.com>

=head1 LICENSE

Same as Perl itself.

=cut
