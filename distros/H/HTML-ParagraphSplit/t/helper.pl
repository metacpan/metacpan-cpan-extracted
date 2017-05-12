sub slurp {
    my ($filename) = @_;

    open my $slurpy_handle, $filename
        or die "could not open $filename: $!";

    my $result = do { local $/; <$slurpy_handle> };

    close $slurpy_handle
        or die "could not close $filename: $!";

    return $result;
}

sub remove_ignorable_whitespace {
    $_[0] =~ s/
          (?<=>)\s+          # match whitespace after a tag
        | \s+(?=<)           # match whitespace before a tag
        | ^\s+               # match whitespace at the start
        | \s+$               # match whitespace at the end
        //gx;                # delete the whitespace
    $_[0] =~ s[\s*/>][ />]g; # prior to empty tag end, have a single space
    return $_[0];
}

1
