package File::Feed::Util;

use Text::Glob qw(glob_to_regex);

sub pat2rx {
    my ($pat) = @_;
    return qr/.?/ if !defined $pat;
    return qr/$pat/ if $pat =~ s/^(pcre|regexp)://;
    return qr/$1/ if $pat =~ m{^/(.+)/$};
    $pat =~ s/^glob://;
    return glob_to_regex($pat);
}

# expand('%(foo)/%(bar)', { 'foo' => 123, 'bar' => 'xyz' }) => '123/xyz' 
# expand('%(path[-1])', { 'path' => [qw(foo bar baz)] }     => 'baz'
sub expand {
    my ($str, $var) = @_;
    my $rx = qr//;
    my $out = '';
    while ($str =~ m{
        \\(.)
        |
        \%\( ([^\s()]+) \)
        |
        ([^\\%]+)
    }xgc) {
        $out .= defined($1) ? $1 : defined($3) ? $3 : keyval($var, ".$2", $var)
    }
    return $out;
}

sub keyval {
    my ($val, $key, $func) = @_;
    my $rval = ref($val);
    $func ||= {};
    while ($key =~ s{
        ^
        (?:
            \[ (-?\d+) (?: \.\. (-?\d+) )? \]
            |
            \. ([^\s.:\[\]\(\)]+)
            |
            :: ([^\s.:\[\]\(\)]+)
        )
    }{}xgc) {
        my ($l, $r, $k, $f) = ($1, $2, $3, $4);
        if (defined $f) {
            die "No such function: $f" if !$func->{$f} ;
            $val = $func->{$f}->($val);
        }
        elsif ($rval eq 'HASH') {
            die if defined $l or defined $r;
            $val = $val->{$k};
        }
        elsif ($rval eq 'ARRAY') {
            die if defined $k;
            $val = defined $r ? [ @$val[$l..$r] ] : $val->[$l];
        }
        else {
            die "Can't subval: ref = '$rval'";
        }
        $rval = ref $val;
    }
    die if length $key;
    return join('', @$val) if $rval eq 'ARRAY';
    return join('', values %$val) if $rval eq 'HASH';
    return $val;
}

1;
