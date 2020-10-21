package File::FormatIdentification::Regex;

our $VERSION = '0.04'; # VERSION

# ABSTRACT helper module to combine and optimize regexes

use feature qw(say);
use strict;
use warnings;
use String::LCSS;

use Regexp::Assemble;
use Regexp::Optimizer;
use Carp;
use Exporter 'import';    # gives you Exporter's import() method directly
our @EXPORT =
  qw(and_combine or_combine calc_quality simplify_two_or_combined_regex peep_hole_optimizer )
  ;                       # symbols to export on request
our @EXPORT_OK = qw( hex_replace_from_bracket hex_replace_to_bracket );




sub and_combine (@) {
    my @rx_groups = map {
        my $rx     = $_;
        my $rxfill = "";
        my $ret    = '';
        if    ( $rx =~ m#^\^$# ) { $ret = $rx; }
        elsif ( $rx =~ m#^\$$# ) { $ret = $rx; }
        else {
            if ( $rx =~ m#\$$# ) {
                $rxfill = ".*";
            }
            $ret = "(?=$rxfill$rx)";
        }
        $ret;
    } @_;
    my $combined = join( "", @rx_groups );

    #my $rx = Regexp::Assemble->new;
    #$rx->add( $combined );
    #return $rx->as_string;
    #my $o  = Regexp::Optimizer->new;
    #my $rcomb = qr/$combined/;
    #return $o->as_string($rcomb);
    return $combined;
}

sub or_combine (@) {
    my $ro = Regexp::Assemble->new;
    foreach my $rx (@_) {
        $ro->add($rx);
    }
    return $ro->as_string;
}

sub simplify_two_or_combined_regex($$) {
    my $rx1    = $_[0];
    my $rx2    = $_[1];
    my $rx = qr#\([A-Za-z0-9]*\)#;
    return "" if (($rx1 !~ m/$rx/) || ($rx2 !~ m/$rx/));
    # only left simplify supported yet
    return String::LCSS::lcss( $rx1, $rx2 );
}

sub hex_replace_to_bracket {
    my $regex = shift;
    $regex =~ s#(?<=\\x)([0-9A-F]{2})#{$1}#g;
    return $regex;
}

sub hex_replace_from_bracket {
    my $regex = shift;
    $regex =~ s#(?<=\\x)\{([0-9A-F]{2})\}#$1#g;
    return $regex;
}

sub peep_hole_optimizer ($) {
    my $regex = $_[0]; # only works if special Regexes within File::FormatIdentification:: used

    #$regex = hex_replace_to_bracket($regex);
    if ($regex =~ m/\\x[0-9]+/) {
        confess "regex '$regex' has invalid \\x sequences, use \\x{} instead!";
    }
    my $oldregex = $regex;
    ##### first optimize bracket-groups
    my $subrg =
      qr#(?:[A-Za-z0-9])|(?:\\x\{[0-9A-F]{2}\})#;   # matches: \x00-\xff or text
        #my $subrg = qr#(?:\($subra\))#;
    my $subre = qr#(?:\($subrg(?:\|$subrg)+\))|(?:$subrg)#
      ;    # matches (…|…) or (…|…|…) ...
           #$regex =~ s#\(\(($subra*)\)\)(?!\|)#(\1\)#g; # matches ((…))
    $regex =~ s#\(\(($subre+)\)\)#($1)#g;
    $regex =~ s#\(\((\([^)|]*\)(\|\([^)|]*\))+)\)\)#($1)#g;
    ##### optimize common subsequences
    ##### part1, combine bar|baz -> ba(r|z)
    #say "BEFORE: regex=$regex";
    while (
        $regex =~ m#\(($subrg*)\)\|\(($subrg*)\)# ||
        $regex =~ m#($subrg*)\|($subrg*)#
    ) {
        my $rx1 = $1;
        my $rx2 = $2;

        #say "common subseq: $regex -> rx1=$rx1 rx2=$rx2";

        my $common = String::LCSS::lcss( $rx1, $rx2 );
        if ( !defined $common || length($common) == 0 ) { last; }
        if ( $common !~ m#^$subrg+$# ) { last; }

        #say "!ok: $regex -> common=$common";

        # common prefix
        if ( $rx1 =~ m#^(.*)$common$# && $rx2 =~ m#^(.*)$common$# ) {

            #say "suffix found";
            $rx1 =~ m#^(.*)$common$#;
            my $rx1_prefix = $1;
            $rx2 =~ m#^(.*)$common$#;
            my $rx2_prefix = $1;
            my $subst      = "($rx1_prefix|$rx2_prefix)$common";
            if ( $regex =~ m#\(($subrg*)\)\|\(($subrg*)\)# ) {
                $regex =~ s#\($subrg*\)\|\($subrg*\)#$subst#g;
            }
            elsif ( $regex =~ m#($subrg*)\|($subrg*)# ) {
                $regex =~ s#$subrg*\|$subrg*#$subst#g;
            }
        }

        # common suffix
        elsif ( $rx1 =~ m#^$common(.*)$# && $rx2 =~ m#^$common(.*)$# ) {

            #say "prefix found";
            $rx1 =~ m#^$common(.*)$#;
            my $rx1_suffix = $1;
            $rx2 =~ m#^$common(.*)$#;
            my $rx2_suffix = $1;
            my $subst      = "$common($rx1_suffix|$rx2_suffix)";

            #say "subst=$subst";
            if ( $regex =~ m#\(($subrg*)\)\|\(($subrg*)\)# ) {
                $regex =~ s#\($subrg*\)\|\($subrg*\)#$subst#g;
            }
            elsif ( $regex =~ m#($subrg*)\|($subrg*)# ) {
                $regex =~ s#$subrg*\|$subrg*#$subst#g;
            }

            #say "regex=$regex";
        }
        else {
            last;
        }
    }
    ##### part2, combine barbara -> (bar){2}a
    while ( $regex =~ m#($subrg{3,}?)(\1+)(?!$subrg*\})# ) {
        my $sub = $1;
        if ( $sub =~ m#^($subrg)\1+$# ) {
            last;
        }
        my $l1      = length($1);
        my $l2      = length($2);
        my $matches = 1 + ( $l2 / $l1 );

#say "Found1 in regex='$regex' sub='$sub' with \$2=$2 l1=$l1 l2=$l2 matches=$matches";

        if ( $sub =~ m#^$subrg$# ) {
            $regex =~ s#($subrg{3,}?)\1+(?!$subrg*\})#$sub\{$matches\}#;
        }
        else {
            $regex =~ s#($subrg{3,}?)\1+(?!$subrg*\})#($sub)\{$matches\}#;
        }
    }
    ##### part2, combine toooor -> to{4}r
    while ( $regex =~ m#($subrg)(\1{3,})(?!$subrg*\})# ) {
        my $sub     = $1;
        my $l1      = length($1);
        my $l2      = length($2);
        my $matches = 1 + ( $l2 / $l1 );

#say "Found2 in regex='$regex' sub='$sub' with \$2=$2 l1=$l1 l2=$l2 matches=$matches";

        if ( $sub =~ m#^$subrg$# ) {
            $regex =~ s#($subrg)\1{3,}(?!$subrg*\})#$sub\{$matches\}#;
        }
        else {
            $regex =~ s#($subrg)\1{3,}(?!$subrg*\})#($sub)\{$matches\}#;
        }
    }
    ##### part2, combine foooo -> fo{4}
    #while ($regex =~ m#($subrg)\1{3,}(?!$subrg*\})#) {
    #    my $sub = $1;
    #    my $matches = $#+; $matches++;
    #        say "Found in regex='$regex' sub='$sub' with matches=$matches";
    #        $regex =~ s#($subrg)\1{3,}(?!$subrg*\}#$sub\{$matches\}#;
    #}

    return $regex;
}

# calc regex quality, if more specific the quality is higher
sub calc_quality ($) {
    my $regex = shift;

    # replace all \xff with #
    # replace all . with ( | | | | )
    # replace all [abc] with (a|b|c)
    # replace all [^abc] with (d|e|f|..|)
    # then $len = count of # and $or = count of |
    # divide it with $len / (1+$or)
    my $len = 0;
    my $alt = 0;
    while ( $regex =~ s/\\x[0-9a-f]{2}// ) {
        $len++;
    }
    while ( $regex =~ s/\[\^(.*?)\]// ) {
        $alt += ( 256 - length($1) );
        $len++;
    }
    while ( $regex =~ s/\[(.*?)\]// ) {
        $alt += length($1);
        $len++;
    }
    while ( $regex =~ s/\.// ) {
        $alt += 256;
        $len++;
    }
    while ( $regex =~ s/[A-Za-z0-9 ]// ) {
        $len++;
    }
    my $tmp = $len / ( 1 + $alt );

    my $quality = ( $tmp == 0 ) ? 0 : int( 1000 * log($tmp) ) / 1000;

    #say "rest: $regex len=$len alt=$alt quality=$quality ($tmp)";
    return $quality;
}

# see https://stackoverflow.com/questions/869809/combine-regexp#870506

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::FormatIdentification::Regex

=head1 VERSION

version 0.04

=head1 AUTHOR

Andreas Romeyke <pause@andreas-romeyke.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
