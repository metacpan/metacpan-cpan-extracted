# NAME

Iterator::ToArray - create array or arrayref from iterator

# SYNOPSIS

    use Iterator::ToArray qw/to_array/;
    

    my $iterator = Your::Iterator->new();

    # OO style
    my $to_array = Iterator::ToArray->new($iterator);
    my $coderef  = sub { $_ * $_ };
    my $array = $to_array->apply($coderef);

    # function style
    my $array    = to_array $iter, sub { $_* $_ };

# DESCRIPTION

Iterator::ToArray convert iterator to array using coderef.

# AUTHOR

Yoshihiro Sasaki <ysasaki {at} cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
