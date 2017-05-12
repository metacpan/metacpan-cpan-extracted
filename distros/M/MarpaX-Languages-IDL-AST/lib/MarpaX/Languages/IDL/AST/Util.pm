use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::IDL::AST::Util;

# ABSTRACT: Translate an IDL source to an AST - Tools

our $VERSION = '0.007'; # VERSION

# Marpa follows Unicode recommendation, i.e. perl's \R, that cannot be in a character class
our $NEWLINE_REGEXP = qr/(?>\x0D\x0A|\v)/;



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

    # return "line:column $line:$col (Unicode newline count) $nbnewlines:$col (\\n count)\n\n$content\n$pointer";
    return "line:column $nbnewlines:$col\n\n$content\n$pointer";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::IDL::AST::Util - Translate an IDL source to an AST - Tools

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use MarpaX::Languages::IDL::AST::Util;

=head2 showLineAndCol($line, $col, $source)

Pretty-printing of line No $line, column No $col in $source.

=head1 DESCRIPTION

This module contain some tools used by IDL to AST

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
