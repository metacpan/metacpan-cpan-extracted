use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Util;

# ABSTRACT: ECMAScript Translation to AST - Class method utilities

use Exporter 'import';
use Log::Any qw/$log/;
use Data::Dumper;
# Marpa follows Unicode recommendation, i.e. perl's \R, that cannot be in a character class
our $NEWLINE_REGEXP = qr/(?>\x0D\x0A|\v)/;

our $VERSION = '0.020'; # VERSION
# CONTRIBUTORS

our @EXPORT_OK = qw/whoami whowasi traceAndUnpack showLineAndCol lineAndCol lastCompleted startAndLength lastLexemeSpan/;
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
    # Skip MarpaX::Languages::ECMAScript::AST::if any
    #
    $whowasi =~ s/^MarpaX::Languages::ECMAScript::AST:://;
    $log->tracef('%s(%s)', $whowasi, join(', ', @string));
    return($rc);
}


sub showLineAndCol {
    my ($line, $col, $source) = @_;

    my $pointer = ($col > 0 ? '-' x ($col-1) : '') . '^';
    my $content = '';

    my $prevpos = pos($source);
    pos($source) = undef;
    my $thisline = 0;
    my $nbnewlines = 0;
    my $eos = 0;
    while ($source =~ m/\G(.*?)($NEWLINE_REGEXP|\Z)/scmg) {
      if (++$thisline == $line) {
        $content = substr($source, $-[1], $+[1] - $-[1]);
        $eos = (($+[2] - $-[2]) > 0) ? 0 : 1;
        last;
      }
    }
    $content =~ s/\t/ /g;
    if ($content) {
      $nbnewlines = (substr($source, 0, pos($source)) =~ tr/\n//);
      if ($eos) {
        ++$nbnewlines; # End of string instead of $NEWLINE_REGEXP
      }
    }
    pos($source) = $prevpos;

    return "line:column $line:$col (Unicode newline count) $nbnewlines:$col (\\n count)\n\n$content\n$pointer";
}


sub lineAndCol {
    my ($impl, $g1) = @_;

    $g1 //= $impl->current_g1_location();
    my ($start, $length) = $impl->g1_location_to_span($g1);
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


sub lastLexemeSpan {
    my ($impl) = @_;
    return $impl->g1_location_to_span($impl->current_g1_location());
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Util - ECMAScript Translation to AST - Class method utilities

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use MarpaX::Languages::ECMAScript::AST::Util qw/:all/;

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

=head2 showLineAndCol($line, $col, $source)

Returns a string showing the request line, followed by another string that shows what is the column of interest, in the form "------^".

=head2 lineAndCol($impl, $g1)

Returns the output of Marpa's line_column at a given $g1 location. Default $g1 is Marpa's current_g1_location().

=head2 startAndLength($impl, $g1)

Returns the output of Marpa's g1_location_to_span at a given $g1 location. Default $g1 is Marpa's current_g1_location().

=head2 lastCompleted($impl, $symbol)

Returns the string corresponding the last completion of $symbol.

=head2 lastLexemeSpan($impl)

Returns the span ($start, $length) corresponding the last lexeme.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
