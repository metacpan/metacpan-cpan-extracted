package Localizer::BuiltinFunctions;
use strict;
use warnings;
use utf8;
use 5.010_001;

sub sprintf { sprintf(shift, @_) }

# imported by Locale::Maketext
sub numf {
    my($num) = @_[0,1];
    if($num < 10_000_000_000 and $num > -10_000_000_000 and $num == int($num)) {
        $num += 0;  # Just use normal integer stringification.
        # Specifically, don't let %G turn ten million into 1E+007
    }
    else {
        $num = CORE::sprintf('%G', $num);
        # "CORE::" is there to avoid confusion with the above sub sprintf.
    }
    while( $num =~ s/^([-+]?\d+)(\d{3})/$1,$2/s ) {1}  # right from perlfaq5
    # The initial \d+ gobbles as many digits as it can, and then we
    #  backtrack so it un-eats the rightmost three, and then we
    #  insert the comma there.

    return $num;
}

# imported by Locale::Maketext
sub numerate {
    # return this lexical item in a form appropriate to this number
    my($num, @forms) = @_;
    my $s = ($num == 1);

    return '' unless @forms;
    if(@forms == 1) { # only the headword form specified
        return $s ? $forms[0] : ($forms[0] . 's'); # very cheap hack.
    }
    else { # sing and plural were specified
        return $s ? $forms[0] : $forms[1];
    }
}

# imported by Locale::Maketext
sub quant {
    my($num, @forms) = @_;

    return $num if @forms == 0; # what should this mean?
    return $forms[2] if @forms > 2 and $num == 0; # special zeroth case

    # Normal case:
    # Note that the formatting of $num is preserved.
    return( numf($num) . ' ' . numerate($num, @forms) );
    # Most human languages put the number phrase before the qualified phrase.
}

1;

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

