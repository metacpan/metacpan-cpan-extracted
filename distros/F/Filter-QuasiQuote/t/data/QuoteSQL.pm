package t::data::QuoteSQL;

require Filter::QuasiQuote;
our @ISA = qw( Filter::QuasiQuote );

sub sql {
    my ($self, $s, $file, $line, $col) = @_;
    my $package = ref $self;
    #warn "SQL: $file: $line: $s\n";
    $s =~ s/\n+/ /g;
    $s =~ s/^\s+|\s+$//g;
    $s =~ s/\\/\\\\/g;
    $s =~ s/"/\\"/g;
    $s =~ s/\$\w+\b/".${package}::Q($&)."/g;
    $s = qq{"$s"};
    $s =~ s/\.""$//;
    $s;
}

sub Q {
    my $s = shift;
    $s =~ s/'/''/g;
    $s =~ s/\\/\\\\/g;
    $s =~ s/\n/ /g;
    "'$s'";
}

1;

