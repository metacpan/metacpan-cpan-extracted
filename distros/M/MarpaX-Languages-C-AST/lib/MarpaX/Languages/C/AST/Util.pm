use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::C::AST::Util;

# ABSTRACT: C Translation to AST - Class method utilities

use Exporter 'import';
use Log::Any qw/$log/;
use Data::Dumper;
use Carp qw/croak/;
# Marpa follows Unicode recommendation, i.e:
#
#    a LF (line feed U+000A);
#    a CR (carriage return, U+000D), when it is not followed by a LF;
#    a CRLF sequence (U+000D,U+000A);
#    a NEL (next line, U+0085);
#    a VT (vertical tab, U+000B);
#    a FF (form feed, U+000C);
#    a LS (line separator, U+2028) or
#    a PS (paragraph separator, U+2029)
#
# BUT is accounting two lines when it sees a CRLF sequence
# I left this regexp alone and will change it to
# qr/(?>\x{0D}\x{0A}|\x{0D}|\x{0A}|\x{85}|\x{0B}|\x{0C}|\x{2028}|\x{2029})/
# when I know which version of Marpa fixes this issue.
#
# C.f. https://github.com/jeffreykegler/Marpa--R2/issues/217
#
our $NEWLINE_MARPA_REGEXP = qr/[\x{0D}|\x{0A}|\x{85}|\x{0B}|\x{0C}|\x{2028}|\x{2029}]/;
our $NEWLINE_CORRECT_REGEXP = qr/\R/;

our $VERSION = '0.48'; # VERSION
# CONTRIBUTORS

our @EXPORT_OK = qw/whoami whowasi traceAndUnpack logCroak showLineAndCol lineAndCol lastCompleted startAndLength rulesByDepth/;
our %EXPORT_TAGS = ('all' => [ @EXPORT_OK ]);


sub _cutbase {
    my ($rc, $base) = @_;
    if (defined($base) && "$base" && index($rc, "${base}::") == $[) {
      substr($rc, $[, length($base) + 2, '');
    }
    return $rc;
}

sub whoami {
    return _cutbase((caller(1))[3], @_);
}


sub whowasi {
    return _cutbase((caller(2))[3], @_);
}


sub traceAndUnpack {
    my $nameOfArgumentsp = shift;

    my $whowasi = whowasi();
    my @string = ();
    my $min1 = scalar(@{$nameOfArgumentsp});
    my $min2 = scalar(@_);
    my $min = ($min1 < $min2) ? $min1 : $min2;
    my $rc = {};
    foreach (0..--$min) {
      my ($key, $value) = ($nameOfArgumentsp->[$_], $_[$_]);
      my $string = Data::Dumper->new([$value], [$key])->Indent(0)->Sortkeys(1)->Quotekeys(0)->Terse(0)->Dump();
      $rc->{$key} = $value;
      #
      # Remove the ';'
      #
      substr($string, -1, 1, '');
      push(@string, $string);
    }
    #
    # Skip MarpaX::Languages::C::AST::if any
    #
    $whowasi =~ s/^MarpaX::Languages::C::AST:://;
    $log->tracef('%s(%s)', $whowasi, join(', ', @string));
    return($rc);
}


sub logCroak {
    my ($fmt, @arg) = @_;

    my $msg = sprintf($fmt, @arg);
    $log->fatalf('%s', $msg);
    if (! $log->is_fatal()) {
      #
      # Logging is not enabled at FATAL level: re do the message in croak
      #
      croak $msg;
    } else {
      #
      # Logging is enabled at FATAL level: no new message
      #
      croak;
    }
}


sub showLineAndCol {
    my ($line, $col, $sourcep) = @_;

    my $pointer = ($col > 0 ? '-' x ($col-1) : '') . '^';
    my $content = '';

    my $prevpos = pos(${$sourcep});
    pos(${$sourcep}) = undef;
    my $thisline = 0;
    my $nbnewlines = 0;
    my $eos = 0;
    while (${$sourcep} =~ m/\G(.*?)($NEWLINE_MARPA_REGEXP|\Z)/scmg) {
      if (++$thisline == $line) {
        $content = substr(${$sourcep}, $-[1], $+[1] - $-[1]);
        $eos = (($+[2] - $-[2]) > 0) ? 0 : 1;
        last;
      }
    }
    #
    # Revisit newlines count (column count fortunately remains unchanged)
    #
    if (length($content) > 0) {
      $content =~ s/\t/ /g;
      $nbnewlines = () = substr(${$sourcep}, 0, pos(${$sourcep})) =~ /$NEWLINE_CORRECT_REGEXP/g;
      if ($eos) {
        ++$nbnewlines; # End of string instead of newline
      }
    }
    pos(${$sourcep}) = $prevpos;
    #
    # We rely on any space being a true space for the pointer accuracy
    #
    $content =~ s/\s/ /g;

    return "At line $nbnewlines, column $col\n\n$content\n$pointer";
}


sub lineAndCol {
    my ($impl, $g1, $start) = @_;

    if (! defined($start)) {
      $g1 //= $impl->current_g1_location();
      ($start, undef) = $impl->g1_location_to_span($g1);
    }
    my ($line, $column) = $impl->line_column($start);
    return [ $line, $column ];
}


sub startAndLength {
    my ($impl, $g1) = @_;

    $g1 //= $impl->current_g1_location();
    my ($start, $length) = $impl->g1_location_to_span($g1);
    return [ $start, $length ];
}


sub lastCompleted {
    my ($impl, $symbol) = @_;
    return $impl->substring($impl->last_completed($symbol));
}


sub rulesByDepth {
    my ($impl, $subGrammar) = @_;

    $subGrammar ||= 'G1';

    #
    # We start by expanding all ruleIds to a LHS symbol id and RHS symbol ids
    #
    my %ruleIds = ();
    foreach ($impl->rule_ids($subGrammar)) {
      my $ruleId = $_;
      $ruleIds{$ruleId} = [ $impl->rule_expand($ruleId, $subGrammar) ];
    }
    #
    # We ask what is the start symbol
    #
    my $startSymbolId = $impl->start_symbol_id();
    #
    # We search for the start symbol in all the rules
    #
    my @queue = ();
    my %depth = ();
    foreach (keys %ruleIds) {
      my $ruleId = $_;
      if ($ruleIds{$ruleId}->[0] == $startSymbolId) {
        push(@queue, $ruleId);
        $depth{$ruleId} = 0;
      }
    }

    while (@queue) {
      my $ruleId = shift(@queue);
      my $newDepth = $depth{$ruleId} + 1;
      #
      # Get the RHS ids of this ruleId and select only those that are also LHS
      #
      my (undef, @rhsIds) = @{$ruleIds{$ruleId}};
      foreach (@rhsIds) {
        my $lhsId = $_;
        foreach (keys %ruleIds) {
          my $ruleId = $_;
          if (! exists($depth{$ruleId})) {
            #
            # Rule not already inserted
            #
            if ($ruleIds{$ruleId}->[0] == $lhsId) {
              #
              # And having an LHS id equal to one of the RHS ids we dequeued
              #
              push(@queue, $ruleId);
              $depth{$ruleId} = $newDepth;
            }
          }
        }
      }
    }

    my @rc = ();
    foreach (sort {($depth{$a} <=> $depth{$b}) || ($a <=> $b)} keys %depth) {
      my $ruleId = $_;
      my ($lhsId, @rhsIds) = @{$ruleIds{$ruleId}};
      push(@rc, {ruleId   => $ruleId,
                 ruleName => $impl->rule_name($ruleId),
                 lhsId    => $lhsId,
                 lhsName  => $impl->symbol_name($lhsId),
                 rhsIds   => [ @rhsIds ],
                 rhsNames => [ map {$impl->symbol_name($_)} @rhsIds ],
                 depth    => $depth{$ruleId}});
    }

    return \@rc;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::C::AST::Util - C Translation to AST - Class method utilities

=head1 VERSION

version 0.48

=head1 SYNOPSIS

    use MarpaX::Languages::C::AST::Util qw/:all/;

    my $whoami = whoami();
    my $whowasi = whowasi();
    callIt(0, '1', [2], {3 => 4});

    sub callIt {
        my $hash = traceAndUnpack(['var1', 'var2', 'array1p', 'hash1p'], @_);
    }

=head1 DESCRIPTION

This modules implements some function utilities.

=head1 EXPORTS

The methods whoami(), whowasi() and traceAndUnpack() are exported on demand.

=head1 SUBROUTINES/METHODS

=head2 whoami($base)

Returns the name of the calling routine. Optional $base prefix is removed. Typical usage is whoami(__PACKAGE__).

=head2 whowasi($base)

Returns the name of the parent's calling routine. Optional $base prefix is removed. Typical usage is whowasi(__PACKAGE__).

=head2 traceAndUnpack($nameOfArgumentsp, @arguments)

Returns a hash mapping @{$nameOfArgumentsp} to @arguments and trace it. The tracing is done using a method quite similar to Log::Any. Tracing and hash mapping stops at the end of @nameOfArguments or @arguments.

=head2 logCroak($fmt, @arg)

Formats a string using Log::Any, issue a $log->fatal with it, and croak with it.

=head2 showLineAndCol($line, $col, $sourcep)

Returns a string showing the request line, followed by another string that shows what is the column of interest, in the form "------^".

=head2 lineAndCol($impl, $g1)

Returns the output of Marpa's line_column at a given $g1 location. Default $g1 is Marpa's current_g1_location(). If $start is given, $g1 is ignored.

=head2 startAndLength($impl, $g1)

Returns the output of Marpa's g1_location_to_span at a given $g1 location. Default $g1 is Marpa's current_g1_location().

=head2 lastCompleted($impl, $symbol)

Returns the string corresponding the last completion of $symbol.

=head2 depth($impl, $subGrammar)

Returns an array of rules ordered by depth for optional sub grammar $subGrammar (default is 'G1'). Each array item is a hash reference with the following keys:

=over

=item ruleId

Rule Id

=item ruleName

Rule Id

=item lhsId

LHS id of this rule

=item lhsName

LHS name of this rule

=item rhsIds

Rhs ids of this rule as an array reference

=item rhsNames

Rhs names of this rule as an array reference

=item depth

Rule depth

=back

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
