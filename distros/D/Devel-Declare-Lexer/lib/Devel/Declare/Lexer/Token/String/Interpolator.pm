package Devel::Declare::Lexer::Token::String::Interpolator;

use strict;
use warnings;

use Data::Dumper;

my $DEBUG = $Devel::Declare::Lexer::DEBUG;

sub interpolate {
    my ($string, @values) = @_;

    my $vars = deinterpolate($string);
    my @varlist = (@$vars);
    $DEBUG and print STDERR Dumper(@varlist) . "\n";
    my $i = 0;
    $DEBUG and print STDERR "old string: $string\n";
    my $offset = 0;
    for my $var (@varlist) {
        $DEBUG and print STDERR "offset: $offset\n";
        substr( $string, $var->{start} + $offset, $var->{length} ) = $values[$i];
        my $oldlen = $var->{length};
        my $newlen = length $values[$i];
        $offset += ($newlen - $oldlen);
        $DEBUG and print STDERR "new offset: $offset\n";
        $i++;
    }
    $DEBUG and print STDERR "new string: $string\n";
    return $string;
}

sub deinterpolate {
    my ($string) = @_;

    my @vars = ();

    $DEBUG and print STDERR "Deinterpolating '$string'\n";

    my @chars = split //, $string;

    my @procd = ();
    my $tok = '';
    my $pos = -1;
    for my $char (@chars) {
        push @procd, $char;
        $pos++;
        $DEBUG and print STDERR "Got char '$char' at pos $pos\n";

        if($char =~ /[^\w_{}\[\]:@\$]/ && $tok) {
            $DEBUG and print STDERR "Captured token '$tok' at pos $pos (eot)\n";
            push @vars, {
                token => $tok,
                start => $pos - (length $tok),
                end => $pos,
                length => (length $tok)
            };
            $tok = '';
            next;
        }
        #if($tok && ($char !~ /[\$\@\%]/ || length $tok == 1)) {
        if($tok && ($char !~ /[\$\@]/ || length $tok == 1)) {
        $DEBUG and print STDERR "Got tok '$tok' so far\n";
            my $eot = 0;
            if($char =~ /[':]/) {
                # do some forwardlooking
                my $c = $chars[$pos + 1];
                #if($c && $c =~ /[\s\$\%\@]/) {
                if($c && $c =~ /[\s\$\@]/) { # hashes are only interpolated with $name{key} syntax
                    $eot = 1;
                }
            }
            if(!$eot) {
                $tok .= $char;
                next;
            }
        }
        #if($char =~ /[\$\@\%]/ || $tok) {
        if($char =~ /[\$\@]/ || $tok) {
            #if($char =~ /[\$\@\%]/ && $tok && $tok !~ /^[\$\@\%]+$/) {
            if( $tok && (($char =~ /[\$\@]/ && $tok !~ /^[\$\@]+$/))) {
                $DEBUG and print STDERR "Captured token '$tok' at pos $pos\n";
                push @vars, {
                    token => $tok,
                    start => $pos - (length $tok),
                    end => $pos,
                    length => (length $tok)
                };
                $tok = '';
            }
            my $capture = 0;
            $DEBUG and print STDERR "Got tok '$tok' in varcap\n";
            if(!$tok) {
                # do some backtracking
                my $ec = 0;
                for(my $i = $pos - 1; $i >= 0; $i--) {
                    my $c = $procd[$i];
                    last if $c !~ /\\/;
                    $ec++;
                    $DEBUG and print STDERR "Got char '$c' at pos $i, ec $ec\n";
                }
                $capture = $ec % 2 == 0 ? 1 : 0;
                #if($ec % 2 == 0) {
                #    print "probably a token\n";
                #} else {
                #    print "probably not a token\n";
                #}
            }
            $DEBUG and print STDERR "Got capture $capture\n\n";
            $tok = $char if $capture;
            next;
        }
    }

    if(wantarray) {
        $DEBUG and print STDERR "Returning array of token names\n";
        return map { $_->{token} } @vars;
    }
    $DEBUG and print STDERR "Returning arrayref\n";
    return \@vars;
}

1;
