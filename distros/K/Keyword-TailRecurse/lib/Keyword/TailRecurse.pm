package Keyword::TailRecurse;
use 5.014;
use strict;
use warnings;

our $VERSION = "0.02";

use Keyword::Declare;

my $subCallTailCompatible = 0;

my %imported;

sub import {
    my %option = map { $_ => 1 } @_;

    if( $option{tailrecurse} ) {
        keyword tailrecurse (Bareword $function, List? $parameters) {
            return "\@_ = ( $parameters ); goto &$function;";
        };
        $imported{tailrecurse} = 1;
    }

    if( $option{tail_recurse} ) {
        keyword tail_recurse (Bareword $function, List? $parameters) {
            return "\@_ = ( $parameters ); goto &$function;";
        };
        $imported{tail_recurse} = 1;
    }

    if( $option{tailRecurse} || ! keys %imported ) {
        keyword tailRecurse (Bareword $function, List? $parameters) {
            return "\@_ = ( $parameters ); goto &$function;";
        };
        $imported{tailRecurse} = 1;
    }

    if ( $option{subCallTail} ) {
        keyword tail (Bareword $function, List? $parameters) {
            return "\@_ = ( $parameters ); goto &$function;";
        };

        keyword tail (/\$[_a-zA-Z0-9]+\s*->\s*[_a-zA-Z0-9]+/ $methodCall, List? $parameters) {
            my ($object, $method) = split /\s*->\s*/, $methodCall;

            return "\@_ = ( $object, $parameters ); goto &{(ref $object) . '::$method'};";
        };

        $imported{subCallTail} = 1;
    }
}

sub unimport {
    if( $imported{tailRecurse} ) {
        unkeyword tailRecurse;
    }
    if( $imported{tailrecurse} ) {
        unkeyword tailrecurse;
    }
    if( $imported{tail_recurse} ) {
        unkeyword tail_recurse;
    }
    if( $imported{subCallTail} ) {
        unkeyword tail;
    }
}   


1;
__END__

=encoding utf-8

=head1 NAME

Keyword::TailRecurse - Enables true tail recursion

=head1 SYNOPSIS

    use Keyword::TailRecurse;

    sub fibonacci {
        my ( $count, $previous, $current ) = @_;

        return ( $previous // 0 ) if $count <= 0;

        $current //= 1;

        tailRecurse fibonacci ( $count - 1, $current, $previous + $current );
    }

    print fibonacci( 7 );


=head1 DESCRIPTION

Keyword::TailRecurse provides a C<tailRecurse> keyword that does proper tail
recursion that doesn't grow the call stack.

=head1 USAGE

After using the module you can precede a function call with the keyword
C<tailRecurse> and rather adding a new entry on the call stack the function
call will replace the current entry on the call stack.

=head1 ALIASES

By default the keyword C<tailRecurse> is added, but you can use the
C<tail_recurse> and/or C<tailrecurse> keywords to add the tail recursion
keyword in a form more suitable for different naming conventions.

=head2 Sub::Call::Tail compatability

If compatibility with C<Sub::Call::Tail> is required then you can use the
C<subCallTail> flag to enable the C<tail> keyword.

    use Keyword::TailRecurse 'subCallTail';

    sub fibonacci {
        my ( $count, $previous, $current ) = @_;

        return ( $previous // 0 ) if $count <= 0;

        $current //= 1;

        tail fibonacci ( $count - 1, $current, $previous + $current );
    }

    print fibonacci( 7 );

Note: with C<Sub::Call:Tail> compatibility enabled both the C<tailRecurse> and
C<tail> keywords are available.

=head1 REQUIRED PERL VERSION

C<Keyword::TailRecurse> requires features only available in Perl v5.14 and
above. In addition a C<Keyword::TailRecurse> dependency doesn't work in Perl
v5.20 due to a bug in regular expression compilation.

=head1 SEE ALSO

=over 4

=item L<Sub::Call::Recur|https://metacpan.org/pod/Sub::Call::Recur>

An C<XS> module that provides a form of tail recursion - limited to recursing
into the same function it's used from.

=item L<Sub::Call::Tail|https://metacpan.org/pod/Sub::Call::Tail>

An C<XS> module that provides a generic tail recursion.

=back


=head1 LICENSE

Copyright (C) Jason Cooper.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jason Cooper E<lt>JLCOOPER@cpan.orgE<gt>

=cut

