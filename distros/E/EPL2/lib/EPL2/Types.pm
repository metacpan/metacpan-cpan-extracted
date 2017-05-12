package EPL2::Types;
# ABSTRACT: EPL2::Types (Library for EPL2 types)
$EPL2::Types::VERSION = '0.001';

# predeclare our own types
use MooseX::Types -declare => [qw/Natural Positive Rotation Font Mult Reverse Human Text Barcode Padwidth Padheight/];

# import builtin types
use MooseX::Types::Moose qw/Int Str/;

# declare our constants
use constant { MAX_PADWIDTH => 832, MAX_PADHEIGHT => 65535 };

# type definition.
subtype Natural,
    as Int,
    where { $_ >= 0 },
    message { "Value($_) is not Natural [ 0, 1, 2, 3, 4, ... ]" };

subtype Positive,
    as Int,
    where { $_ >= 1 },
    message { "Value($_) is not Positive [ 1, 2, 3, 4, ... ]" };

subtype Rotation,
    as Natural,
    where { $_ < 4 },
    message { "Value($_) is not a Rotation [ 0, 1, 2, 3 ]" };

subtype Font,
    as Natural,
    where { $_ > 0 && $_ < 6 },
    message { "Value($_) is not a Font [ 1, 2, 3, 4, 5 ]" };

subtype Mult,
    as Natural,
    where { $_ > 0 && $_ < 10 },
    message { "Value($_) is not a Mult [ 1 - 9 ]" };

subtype Reverse,
    as Str,
    where { /^(N|R)$/ },
    message { "Value($_) is not a Reverse [ N, R ]" };

subtype Text,
    as Str,
    where { /^".+"$/ || /^V\d[1-9]$/ || /^C\d$/ || /^T(T|D)$/ },
    message { "Value($_) is not Text -- Literal Text \"\" or Variable V01-V99 or Counter C0-C9 or TimeCode [TT, TD]" };

subtype Human,
    as Str,
    where { /^(B|N)$/ },
    message { "Value($_) is not Human [ B, N ]" };

subtype Barcode,
    as Str,
    where {
           /^(0|K|P|J|L|M)$/
        || /^1(A|B|C|E)?$/
        || /^2(C|D|G|U)?$/
        || /^3C?$/
        || /^E(80|82|85|30|32|35)$/
        || /^U(A0|A2|A5|E0|E2|E5)$/
    },
    message { "Value($_) is not Barcode Type" };

subtype Padwidth,
    as Natural,
    where { $_ <= MAX_PADWIDTH },
    message { "Value($_) is not < " . MAX_PADWIDTH };

subtype Padheight,
    as Natural,
    where { $_ <= MAX_PADHEIGHT },
    message { "Value($_) is not < " . MAX_PADHEIGHT };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

EPL2::Types - EPL2::Types (Library for EPL2 types)

=head1 VERSION

version 0.001

=head1 SEE ALSO

L<EPL2>

=head1 AUTHOR

Ted Katseres <tedkat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ted Katseres.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
