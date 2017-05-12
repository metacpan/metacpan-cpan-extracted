package Devel::Chitin::OpTree::PVOP;
use base 'Devel::Chitin::OpTree';

our $VERSION = '0.10';

use strict;
use warnings;

sub pp_dump {
    'dump ' . shift->op->pv;
}

sub pp_goto {
    'goto ' . shift->op->pv;
}

sub pp_next {
    'next ' . shift->op->pv;
}

sub pp_last {
    'last ' . shift->op->pv;
}

sub pp_redo {
    'redo ' . shift->op->pv;
}

sub pp_trans {
    my $self = shift;

    my $priv_flags = $self->op->private;
    my($from, $to) = tr_decode_byte($self->op->pv, $priv_flags);

    my $flags = join('', map { $priv_flags & $_->[0] ? $_->[1] : () }
                             ([ B::OPpTRANS_COMPLEMENT, 'c' ],
                              [ B::OPpTRANS_DELETE, 'd' ],
                              [ B::OPpTRANS_SQUASH, 's' ]));

    "tr/${from}/${to}/$flags";
}

sub pp_transr {
    shift->pp_trans . 'r';
}

# These are from B::Deparse

# Only used by tr///, so backslashes hyphens
sub pchr { # ASCII
    my($n) = @_;
    if ($n == ord '\\') {
        return '\\\\';
    } elsif ($n == ord "-") {
        return "\\-";
    } elsif ($n >= ord(' ') and $n <= ord('~')) {
        return chr($n);
    } elsif ($n == ord "\a") {
        return '\\a';
    } elsif ($n == ord "\b") {
        return '\\b';
    } elsif ($n == ord "\t") {
        return '\\t';
    } elsif ($n == ord "\n") {
        return '\\n';
    } elsif ($n == ord "\e") {
        return '\\e';
    } elsif ($n == ord "\f") {
        return '\\f';
    } elsif ($n == ord "\r") {
        return '\\r';
    } elsif ($n >= ord("\cA") and $n <= ord("\cZ")) {
        return '\\c' . chr(ord("@") + $n);
    } else {
        return '\\' . sprintf("%03o", $n);
    }
}

sub collapse {
    my(@chars) = @_;
    my($str, $c, $tr) = ("");
    for ($c = 0; $c < @chars; $c++) {
    $tr = $chars[$c];
    $str .= pchr($tr);
    if ($c <= $#chars - 2 and $chars[$c + 1] == $tr + 1 and
        $chars[$c + 2] == $tr + 2)
    {
        for (; $c <= $#chars-1 and $chars[$c + 1] == $chars[$c] + 1; $c++)
          {}
        $str .= "-";
        $str .= pchr($chars[$c]);
    }
    }
    return $str;
}

sub tr_decode_byte {
    my($table, $flags) = @_;
    my(@table) = unpack("s*", $table);
    splice @table, 0x100, 1;   # Number of subsequent elements
    my($c, $tr, @from, @to, @delfrom, $delhyphen);
    if ($table[ord "-"] != -1
        and
        $table[ord("-") - 1] == -1
        ||
        $table[ord("-") + 1] == -1
    ) {
        $tr = $table[ord "-"];
        $table[ord "-"] = -1;
        if ($tr >= 0) {
            @from = ord("-");
            @to = $tr;
        } else { # -2 ==> delete
            $delhyphen = 1;
        }
    }
    for ($c = 0; $c < @table; $c++) {
        $tr = $table[$c];
        if ($tr >= 0) {
            push @from, $c; push @to, $tr;
        } elsif ($tr == -2) {
            push @delfrom, $c;
        }
    }
    @from = (@from, @delfrom);
    if ($flags & B::OPpTRANS_COMPLEMENT) {
        my @newfrom = ();
        my %from;
        @from{@from} = (1) x @from;
        for ($c = 0; $c < 256; $c++) {
            push @newfrom, $c unless $from{$c};
        }
        @from = @newfrom;
    }
    unless ($flags & B::OPpTRANS_DELETE || !@to) {
        pop @to while $#to and $to[$#to] == $to[$#to -1];
    }
    my($from, $to);
    $from = collapse(@from);
    $to = collapse(@to);
    $from .= "-" if $delhyphen;
    return ($from, $to);
}

sub tr_chr {
    my $x = shift;
    if ($x == ord "-") {
    return "\\-";
    } elsif ($x == ord "\\") {
    return "\\\\";
    } else {
    return chr $x;
    }
}

# XXX This doesn't yet handle all cases correctly either

sub tr_decode_utf8 {
    my($swash_hv, $flags) = @_;
    my %swash = $swash_hv->ARRAY;
    my $final = undef;
    $final = $swash{'FINAL'}->IV if exists $swash{'FINAL'};
    my $none = $swash{"NONE"}->IV;
    my $extra = $none + 1;
    my(@from, @delfrom, @to);
    my $line;
    foreach $line (split /\n/, $swash{'LIST'}->PV) {
        my($min, $max, $result) = split(/\t/, $line);
        $min = hex $min;
        if (length $max) {
            $max = hex $max;
        } else {
            $max = $min;
        }
        $result = hex $result;
        if ($result == $extra) {
            push @delfrom, [$min, $max];
        } else {
            push @from, [$min, $max];
            push @to, [$result, $result + $max - $min];
        }
    }
    for my $i (0 .. $#from) {
        if ($from[$i][0] == ord '-') {
            unshift @from, splice(@from, $i, 1);
            unshift @to, splice(@to, $i, 1);
            last;
        } elsif ($from[$i][1] == ord '-') {
            $from[$i][1]--;
            $to[$i][1]--;
            unshift @from, ord '-';
            unshift @to, ord '-';
            last;
        }
    }
    for my $i (0 .. $#delfrom) {
        if ($delfrom[$i][0] == ord '-') {
            push @delfrom, splice(@delfrom, $i, 1);
            last;
        } elsif ($delfrom[$i][1] == ord '-') {
            $delfrom[$i][1]--;
            push @delfrom, ord '-';
            last;
        }
    }
    if (defined $final and $to[$#to][1] != $final) {
        push @to, [$final, $final];
    }
    push @from, @delfrom;
    if ($flags & B::OPpTRANS_COMPLEMENT) {
        my @newfrom;
        my $next = 0;
        for my $i (0 .. $#from) {
            push @newfrom, [$next, $from[$i][0] - 1];
            $next = $from[$i][1] + 1;
        }
        @from = ();
        for my $range (@newfrom) {
            if ($range->[0] <= $range->[1]) {
            push @from, $range;
            }
        }
    }
    my($from, $to, $diff);
    for my $chunk (@from) {
        $diff = $chunk->[1] - $chunk->[0];
        if ($diff > 1) {
            $from .= tr_chr($chunk->[0]) . "-" . tr_chr($chunk->[1]);
        } elsif ($diff == 1) {
            $from .= tr_chr($chunk->[0]) . tr_chr($chunk->[1]);
        } else {
            $from .= tr_chr($chunk->[0]);
        }
    }
    for my $chunk (@to) {
        $diff = $chunk->[1] - $chunk->[0];
        if ($diff > 1) {
            $to .= tr_chr($chunk->[0]) . "-" . tr_chr($chunk->[1]);
        } elsif ($diff == 1) {
            $to .= tr_chr($chunk->[0]) . tr_chr($chunk->[1]);
        } else {
            $to .= tr_chr($chunk->[0]);
        }
    }
    #$final = sprintf("%04x", $final) if defined $final;
    #$none = sprintf("%04x", $none) if defined $none;
    #$extra = sprintf("%04x", $extra) if defined $extra;
    #print STDERR "final: $final\n none: $none\nextra: $extra\n";
    #print STDERR $swash{'LIST'}->PV;
    return (escape_str($from), escape_str($to));
}

1;

__END__

=pod

=head1 NAME

Devel::Chitin::OpTree::PVOP - Deparser class for string-related OPs

=head1 DESCRIPTION

This package contains methods to deparse PVOPs (goto, trans, etc).

=head1 SEE ALSO

L<Devel::Chitin::OpTree>, L<Devel::Chitin>, L<B>, L<B::Deparse>, L<B::DeparseTree>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2016, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.
