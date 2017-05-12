use strict;
use warnings;

package MetaCPAN::Moose;
$MetaCPAN::Moose::VERSION = '0.000003';
use Import::Into;

sub import {
    $_->import::into( scalar caller )
        for qw( Moose MooseX::StrictConstructor namespace::autoclean );
}

1;

=pod

=encoding UTF-8

=head1 NAME

MetaCPAN::Moose - Use Moose the MetaCPAN way

=head1 VERSION

version 0.000003

=head1 SYNOPSIS

    use MetaCPAN::Moose;

=head1 DESCRIPTION

MetaCPAN::Moose automatically imports L<MooseX::StrictConstructor> and
L<namespace::autcolean> for you.

=head1 ACKNOWLEDGEMENTS

I showed my code to Sawyer when it was ready to release.  He sat down and
rewrote it completely. :)

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Use Moose the MetaCPAN way

