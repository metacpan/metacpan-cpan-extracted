package Lab::SCPI;
$Lab::SCPI::VERSION = '3.901';
#ABSTRACT: Match L<SCPI|http://www.ivifoundation.org/scpi/> headers and parameters against keywords

use v5.20;

use warnings;
no warnings 'recursion';
use strict;

use Carp;
use English;    # avoid editor nonsense with odd special variables
use Exporter 'import';

our @EXPORT = qw( scpi_match scpi_parse scpi_canon
    scpi_flat scpi_parse_sequence );

our $WS = qr/[\x00-\x09\x0b-\x20]/;    # whitespace std488-2 7.4.1.2


sub scpi_match {
    my $header   = shift;
    my $keyword  = shift;
    my @keywords = split '\|', $keyword, -1;
    for my $part (@keywords) {
        if ( match_keyword( $header, $part ) ) {
            return 1;
        }
    }
    return 0;
}

sub parse_keyword {
    my $keyword = shift;

    # For the first part, the colon is optional.
    my $start_mnemonic_regex = qr/(?<mnemonic>:?[a-z][a-z0-9_]*)/i;
    my $mnemonic_regex       = qr/(?<mnemonic>:[a-z][a-z0-9_]*)/i;
    my $keyword_regex        = qr/\[$mnemonic_regex\]|$mnemonic_regex/;
    my $start_regex = qr/\[$start_mnemonic_regex\]|$start_mnemonic_regex/;

    # check if keyword is valid
    if ( length($keyword) == 0 ) {
        croak "keyword with empty length";
    }

    if ( $keyword !~ /^${start_regex}${keyword_regex}*$/ ) {
        croak "invalid keyword: '$keyword'";
    }

    if ( $keyword !~ /\[/ ) {

        # no more optional parts
        return $keyword;
    }

    #recurse
    return (
        parse_keyword( $keyword =~ s/\[(.*?)\]/$1/r ),
        parse_keyword( $keyword =~ s/\[(.*?)\]//r )
    );
}


sub scpi_shortform {
    my $string = shift;
    $string =~ s/^${WS}*//;    # strip leading spaces
    if ( length($string) <= 4 ) {
        return $string;
    }

    # common mnemonics start with '*' and are not shortenable
    # note that standard IEEE488 common mnemonics are length 4,
    # but some extensions result in longer common mnemonics

    if ( $string =~ /^\*/ ) {
        return $string;
    }

    # mnemonics can have following digits (ex: CHANNEL3)
    # the digits should be kept
    # if followed by a '?', keep that too

    # mnemonics in the form (letter)(letter|digit|underscore)*
    # but need to separate the "digit" part at end

    if ( $string =~ /^([a-z]\w*[a-z_])(\d*)(\??)/i ) {
        $string = substr( $1, 0, 4 );
        my $n = $2;
        my $q = $3;
        if ( $string =~ /^...[aeiou]/i ) {
            $string = substr( $string, 0, 3 );
        }
        return $string . $n . $q;
    }
    else {    # not a standard form mnemonic, bail
        return $string;
    }

}

# Return 1 for equal, 0 if not.
sub compare_headers {
    my $a = shift;
    my $b = shift;

    my @a = split( /:/, $a, -1 );
    my @b = split( /:/, $b, -1 );

    if ( @a != @b ) {
        return 0;
    }
    while (@a) {
        my $a = shift @a;
        my $b = shift @b;
        $a = "\L$a";
        $b = "\L$b";
        if ( $b ne $a and $b ne scpi_shortform($a) ) {
            return 0;
        }
    }
    return 1;
}

# Return 1 for match, 0 for no match.
sub match_keyword {
    my $header  = shift;
    my $keyword = shift;

    # strip leading and trailing whitespace
    $header =~ s/^\s*//;
    $header =~ s/\s*$//;

    my @combinations = parse_keyword($keyword);
    for my $combination (@combinations) {
        if ( compare_headers( $combination, $header ) ) {
            return 1;
        }
    }
    return 0;
}


sub scpi_parse {
    my $str = shift;
    my $d   = shift;
    $d = {} unless defined($d);
    _gMem( $str, 0, $d, $d );
    return $d;
}

# "get Mnemonic"
# recursive parse _gMem(string,level,treetop,treebranch)
# level = 0 is the top of the tree, descend as elements
# of the scpi command are parsed: :lev0:lev1:lev2;lev2;lev2:lev3;lev3 ...

sub _gMem {
    my $str   = shift;
    my $level = shift;
    my $dtop  = shift;
    my $d     = shift;

    if ( $str =~ /^${WS}*(;|\s*$)/ ) {
        return '';
    }

    while (1) {
        $str =~ s/^${WS}*//;
        last if $str =~ /^\s*$/;

        if ( $level == 0 ) {
            if ( $str =~ /^(\*\w+\??)${WS}*(;|\s*$)/i ) {    #common
                $dtop->{$1} = {} unless exists $dtop->{$1};
                $str = $POSTMATCH;
                next;
            }
            elsif ( $str =~ /^(\*\w+\??)${WS}+/i ) {    # common with params
                $dtop->{$1} = {} unless exists $dtop->{$1};
                $str = _scpi_value( $POSTMATCH, $dtop->{$1} );
                if ( $str =~ /^${WS}*(;|\s*$)/ ) {
                    $str = $POSTMATCH;
                    next;
                }
                else {
                    croak("parse error after common command");
                }
            }
            elsif ( $str =~ /^:/ ) {                    # leading :
                $d = $dtop;
                $str =~ s/^://;
            }
        }
        else {
            if ( $str =~ /^\*/ ) {
                croak("common command on level>0");
            }
            if ( $str =~ /^:/ ) {
                croak("leading : on level > 0");
            }
        }

        $str =~ s/^${WS}*//;
        last if $str =~ /^\s*$/;

        if ( $str =~ /^;/ ) {    # another branch, same or top level
            $str =~ s/^;${WS}*//;
            last if $str =~ /^\s*$/;
            my $nlev = $level;
            $nlev = 0 if $str =~ /^[\*\:]/;

            #	    print "level=$level nlev=$nlev str=$str\n";
            $str = _gMem( $str, $nlev, $dtop, $d );
            next;
        }

        if ( $str =~ /^(\w+\??)${WS}*(;|\s*$)/i ) {    # leaf, no params
            $d->{$1} = {} unless exists $d->{$1};
            return $POSTMATCH;
        }
        elsif ( $str =~ /^(\w+)${WS}*:/i ) {    # branch, go down a level
            $d->{$1} = {} unless exists $d->{$1};
            $str = _gMem( $POSTMATCH, $level + 1, $dtop, $d->{$1} );
        }
        elsif ( $str =~ /^(\w+\??)${WS}+/i ) {    # leaf with params
            $d->{$1} = {} unless exists $d->{$1};
            $str = $POSTMATCH;
            $str = _scpi_value( $str, $d->{$1} );
        }
        else {
            croak("parse error on '$str'");
        }
    }
    return $str;
}

sub _scpi_value {
    my $str = shift;
    my $d   = shift;

    $d->{_VALUE} = '';
    my $lastsp = 0;
    while ( $str !~ /^${WS}*$/ ) {
        $str =~ s/^${WS}*//;

        if ( $str =~ /^;/ ) {
            $d->{_VALUE} =~ s/\s*$// if $lastsp;

            return $str;
        }
        elsif ( $str =~ /^\#([1-9])/ ) {    # counted arbitrary
            my $nnd = $1;
            my $nd = substr( $str, 2, $nnd );
            $d->{_VALUE} .= substr( $str, 0, $nd + 2 + $nnd );
            if ( length($str) > $nd + 2 + $nnd ) {
                $str = substr( $str, $nd + 2 + $nnd );
            }
            else {
                $str = '';
            }
            $lastsp = 0;
        }
        elsif ( $str =~ /^\#0/ ) {          #uncounted arbitrary
            $d->{_VALUE} .= $str;
            $str = '';
            return $str;
        }
        elsif ( $str =~ /^(\"(?:([^\"]+|\"\")*)\")${WS}*/ )
        {                                   # double q string
            $d->{_VALUE} .= $1 . ' ';
            $str    = $POSTMATCH;
            $lastsp = 1;
        }
        elsif ( $str =~ /^(\'(?:([^\']+|\'\')*)\')${WS}*/ )
        {                                   # single q string
            $d->{_VALUE} .= $1 . ' ';
            $str    = $POSTMATCH;
            $lastsp = 1;
        }
        elsif ( $str =~ /^([\w\-\+\.\%\!\#\~\=\*]+)${WS}*/i )
        {                                   #words, numbers
            $d->{_VALUE} .= $1 . ' ';
            $str    = $POSTMATCH;
            $lastsp = 1;
        }
        else {
            croak("parse error, parameter not matched  with '$str'");
        }
        if ( $str =~ /^${WS}*,/ ) {         #parameter separator
            $str = $POSTMATCH;
            $d->{_VALUE} =~ s/${WS}*$// if $lastsp;
            $d->{_VALUE} .= ',';
            $lastsp = 0;
        }
    }
    $d->{_VALUE} =~ s/\s*$// if $lastsp;
    return $str;
}


sub scpi_parse_sequence {
    my $str = shift;
    my $d   = shift;
    $d = [] unless defined($d);

    $str =~ s/^${WS}+//;
    $str = ':' . $str unless $str =~ /^[\*:]/;
    $str = $str . ';' unless $str =~ /;$/;       #  :string; form

    my (@cur) = ();
    my $level = 0;

    while (1) {
        $str =~ s/^${WS}+//;
        if ( $str =~ /^;/ ) {
            $str =~ s/^;${WS}*//;
            my $ttop = {};
            my $t    = $ttop;

            for ( my $j = 0; $j <= $#cur; $j++ ) {
                my $k = $cur[$j];
                if ( $k eq '_VALUE' ) {
                    $t->{$k} = $cur[ $j + 1 ];
                    last;
                }
                else {
                    $t->{$k} = undef;
                    $t->{$k} = {} if $j < $#cur;
                    $t       = $t->{$k};
                }
            }
            push( @{$d}, $ttop );
        }

        last if $str =~ /^\s*;?\s*$/;    # handle trailing newline too

        #	print "lev=$level str='$str'\n";
        if ( $level == 0 ) {

            # starting from prev command
            if ( $str =~ /^\w/i ) {      # prev  A:b  or A:b:_VALUE:v
                pop(@cur);
                my $v = pop(@cur);
                if ( defined($v) && $v eq '_VALUE' ) {
                    pop(@cur);
                }
                else {
                    push( @cur, $v ) if defined($v);
                }
                $level = 1;

            }
            else {
                if ( $str =~ /^:/ ) {
                    $str =~ s/^:${WS}*//;
                }
                next if $str =~ /^\s*;?\s*$/;
                @cur = ();
                if ( $str =~ /^(\*\w+\??)${WS}*;/i ) {

                    # common, no arg
                    push( @cur, $1 );
                    $str = ';' . $POSTMATCH;

                }
                elsif ( $str =~ /^(\*\w+\??)${WS}+/i ) {

                    # common, arguments
                    push( @cur, $1 );
                    my $tmp = {};
                    $str = _scpi_value( $POSTMATCH, $tmp );
                    push( @cur, '_VALUE' );
                    push( @cur, $tmp->{_VALUE} );

                }
                elsif ( $str =~ /^(\w+)${WS}*:/i ) {

                    # start of tree, more coming
                    push( @cur, $1 );
                    $str   = $POSTMATCH;
                    $level = 1;

                }
                elsif ( $str =~ /^(\w+\??)${WS}*;/i ) {

                    # tree end
                    push( @cur, "$1" );
                    $str = ';' . $POSTMATCH;

                }
                elsif ( $str =~ /^(\w+\??)${WS}*/i ) {

                    # tree end, args
                    push( @cur, $1 );
                    my $tmp = {};
                    $str = _scpi_value( $POSTMATCH, $tmp );
                    push( @cur, '_VALUE' );
                    push( @cur, $tmp->{_VALUE} );

                }
                else {
                    croak("parse error str='$str'");
                }
            }

        }
        $str =~ s/^${WS}+//;
        next if $str =~ /^\s*;?\s*$/;

        if ( $level > 0 ) {    # level > 0
            if ( $str =~ /^[\*:]/ ) {
                croak("common|root at level > 0");
            }
            if ( $str =~ /^(\w+)${WS}*:/i ) {    #down another level
                push( @cur, $1 );
                $str = $POSTMATCH;

                #		$level++;

            }
            elsif ( $str =~ /^(\w+\??)${WS}*;/i ) {    # end tree
                push( @cur, $1 );
                $str   = ';' . $POSTMATCH;
                $level = 0;

            }
            elsif ( $str =~ /^(\w+\??)${WS}+/i ) {     #arguments

                push( @cur, $1 );
                my $tmp = {};
                $str = _scpi_value( $POSTMATCH, $tmp );
                push( @cur, '_VALUE' );
                push( @cur, $tmp->{_VALUE} );
                $level = 0;

            }
            else {
                croak("parse error str='$str'");
            }
        }

    }

    return $d;
}


sub scpi_canon {
    my $h        = shift;
    my $override = shift;
    my $top      = shift;
    $override = {} unless defined $override;
    $top      = 1  unless defined $top;
    my $n = {};
    my $s;

    foreach my $k ( keys( %{$h} ) ) {

        if ( $k eq '_VALUE' ) {
            $n->{$k} = $h->{$k};
        }
        else {
            if ($top) {
                if ( $k =~ /^(\*\w+\??)/i ) {    #common
                    $n->{ uc($1) } = undef;
                    if ( defined( $h->{$k} ) ) {
                        croak("common command with subcommand");
                    }
                    next;
                }
            }

            if ( $k =~ /^([a-z]\w*[a-z_])${WS}*(\d*)(\??)/i ) {
                my $m   = $1;
                my $num = $2;
                $num = '' unless defined $num;
                my $q = $3;
                $q = '' unless defined $q;

                my $ov = 0;
                foreach my $ko ( keys( %{$override} ) ) {
                    my $shorter = $ko;
                    $shorter =~ s/[a-z]\w*$//;
                    if ( uc($ko) eq uc($m) || $shorter eq uc($m) ) {
                        $m = $shorter;
                        $s = "$m$num$q";
                        $n->{$s}
                            = scpi_canon( $h->{$k}, $override->{$ko}, 0 );
                        $ov = 1;
                        last;
                    }
                }
                next if $ov;

                $s = uc( scpi_shortform($m) ) . $num . $q;
                $n->{$s}
                    = scpi_canon( $h->{$k}, {}, 0 );   # no override lower too
            }
            else {
                croak("parse error, mnemonic '$k'");
            }

        }

    }
    return $n;
}


sub scpi_flat {
    my $h  = shift;
    my $ov = shift;

    if ( ref($h) eq 'HASH' ) {
        my $f = {};
        my $c = scpi_canon( $h, $ov );
        _scpi_fnode( '', $f, $c );
        return $f;
    }
    elsif ( ref($h) eq 'ARRAY' ) {
        my $fa = [];
        foreach my $hx ( @{$h} ) {
            my $f = {};
            my $c = scpi_canon( $hx, $ov );
            _scpi_fnode( '', $f, $c );
            push( @{$fa}, $f );
        }
        return $fa;
    }
    else {
        croak( "wrong type passed to scpi_flat:" . ref($h) );
    }

}

sub _scpi_fnode {
    my $fk = shift;
    my $f  = shift;
    my $h  = shift;

    my (@keys);
    if ( ref($h) eq '' ) {
        $fk =~ s/\:_VALUE$//;
        $f->{$fk} = $h;
        return;
    }
    else {
        @keys = keys( %{$h} );
        if (@keys) {
            $fk .= ':' if $fk ne '';
            foreach my $k (@keys) {
                _scpi_fnode( "$fk$k", $f, $h->{$k} );
            }
        }
        else {
            $f->{$fk} = undef;
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::SCPI - Match L<SCPI|http://www.ivifoundation.org/scpi/> headers and parameters against keywords

=head1 VERSION

version 3.901

=head1 Interface

This module exports a single function:

=head2 scpi_match($header, $keyword)

Return true, if C<$header> matches the SCPI keyword expression C<$keyword>.

=head3 Examples

The calls

 scpi_match($header, 'voltage[:APERture]')
 scpi_match($header, 'voltage|CURRENT|resistance')
 scpi_match($header, '[:abcdef]:ghi[:jkl]')

are convenient replacements for

 $header =~ /^(voltage:aperture|voltage:aper|voltage|volt:aperture|volt:aper|volt)$/i
 $header =~ /^(voltage|volt|current|curr|resistance|res)$/i
 $header =~ /^(:abcdef:ghi:jkl|:abcdef:ghi|:abcd:ghi:jkl|:abcd:ghi|:ghi:jkl|:ghi)$/i

respectively.

Leading and trailing whitespace is removed from the first argument, before
 matching against the keyword.

=head3 Keyword Structure

See Sec. 6 "Program Headers" in the SCPI spec. Always give the long form of a
keyword; the short form will be derived automatically. The colon is optional
for the first mnemonic. There must be at least one non-optional mnemonic in the
keyword.

C<scpi_match> will throw, if it is given an invalid keyword.

=head2 scpi_shortform($keyword)

returns the "short form" of the input keyword, according to the 
SCPI spec. Note that the keyword can have an appended number,
that needs to be preserved: sweep1 -> SWE1. Any trailing '?' is
also preserved, which is useful for general SCPI parsing purposes.

BEWARE: some instruments have ambivalant 'shortform' when
constructed using normal rules:
(Tektronix DPO4104  ACQUIRE:NUMENV  and ACQUIRE:NUMAVG)
you have to be aware of the mnemonic heirarchy for this,
so "scpi_canon" has a way to deal with such special cases. 

"Common" keywords (that start with '*') are returned unchanged.

SCPI 6.2.1:
The short form mnemonic is usually the first four characters of the long form 
command header. The exception to this is when the long form consists of more 
than four characters and the fourth character is a vowel. In such cases, the 
vowel is dropped and the short form becomes the first three characters of 
the long form. 

Got to watch out for that "usually".  See scpi_canon for how to handle
the more general case.

=head2 scpi_parse(string [,hash])

$hash = scpi_parse(string [,hash])
parse scpi command or response string, create
a tree structure with hash keys for the mnemonic
components, entries for the values.

example $string = ":Source:Voltage:A 3.0 V;B 2.7V;:Source:Average ON"
results in $hash{Source}->{Voltage}->{A}->{_VALUE} = '3.0 V'
           $hash{Source}->{Voltage}->{B}->{_VALUE} = '2.7V'
           $hash{Source}->{Average}->{_VALUE} = 'ON'

If a hash is given as a parameter of the call, the
information parsed from the string is combined with
the input hash.

=head2 arrayref = scpi_parse_sequence(string[,arrayref])

returns an array of hashes, each hash is a tree structure
corresponding to a single scpi command (like scpi_parse)
Useful for when the sequence of commands is significant.

If an arrayref is passed in, the parsed string results are
appended as new entries.

=head2 $canonhash = scpi_canon($hash[,$overridehash])

revise a hash tree of scpi mnemonics to use
the 'shorter' forms, in uppercase

The "override" hash has the same form as the mnemonic
hash (but with no _VALUE leaves on the tree), but each
key is in the form 'MESSage' where uppercase is the 
shorter form. This is to allow shortening of mnemonics
where the normal shortening rules don't work. 

=head2 $flat = scpi_flat($thing[,$override])

convert the tree structure  to a 'flat'
key space:  h->{a}->{b}->{INPUT3} ->  f{A:B:INP3}, canonicalizing the keys
This is useful for comparing values between two hash structures

if $thing = hash ref -> flat is corresponding hash
if $thing = array ref -> flat is an array ref to flat hashes

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2016       Charles Lane, Simon Reinhardt
            2017       Andreas K. Huettel
            2019       Simon Reinhardt
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
