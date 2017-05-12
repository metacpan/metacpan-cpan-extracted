package t::data::QuoteEval;

require Filter::QuasiQuote;
our @ISA = qw( Filter::QuasiQuote );

sub eval {
    my ($self, $s, $file, $line, $col) = @_;
    $s = eval($s);
    return '"' . quotemeta($s) . '"';
}

1;

