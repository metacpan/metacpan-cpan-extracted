package Java::JCR::Base;

use strict;
use warnings;

use Inline::Java qw( cast );
use Scalar::Util qw( blessed );

our $VERSION = '0.02';

=head1 NAME

Java::JCR::Base - Base class for all JCR wrappers

=head1 DESCRIPTION

This class is used internally only and provides no functionality beyond what is required to make the Perl wrappers for the JCR library work.

=cut

sub _process_args {
    my @args;
    for my $arg (@_) {
        if (blessed $arg && $arg->isa('Java::JCR::Base')) {
            push @args, $arg->{obj};
        }
        else {
            push @args, $arg;
        }
    }

    return @args; 
}

sub _process_return {
    my $result = shift;
    my $java_package = shift;
    my $perl_package = shift;

    # Null is null
    if (!defined $result) {
        return $result;
    }

    # Process array results
    elsif ($java_package =~ /^Array:(.*)$/) {
        my $real_package = $1;
        return [
            map { bless { obj => cast($real_package, $_) }, $perl_package }
                @{ $result }
        ];
    }

    # Process scalar results
    else {
        return bless {
            obj => cast($java_package, $result),
        }, $perl_package;
    }
}

=head1 SEE ALSO

L<Java::JCR>

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2006 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
