# Nothing special, just any utility sub(s) shared across test suites.

# Count the number of entries in the specified namespace that are/have code
sub sub_count
{
    no strict 'refs';

    my $pkg = shift;
    my $stab = \%{"${pkg}::"};

    my $count = 0;
    $count++ for (grep(defined(&{$stab->{$_}}), keys %$stab));

    $count;
}

1;
