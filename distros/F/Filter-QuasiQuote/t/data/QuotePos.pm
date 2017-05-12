package t::data::QuotePos;

require t::data::QuoteEval;
our @ISA = qw( t::data::QuoteEval );

sub pos {
    my ($self, $s, $file, $line, $col) = @_;
    $s = "Line $line, Col $col, File $file";
    return '"' . quotemeta($s) . '"';
}

1;

