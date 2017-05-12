package Magpie::Util;
$Magpie::Util::VERSION = '1.163200';
# ABSTRACT: Common utility functions

#-------------------------------------------------------------------------------
# internal convenience for regularizing potentially uneven lists of name/param
# hash pairs
#-------------------------------------------------------------------------------
sub make_tuples {
    my @in = @_;
    my @out = ();
    for (my $i = 0; $i < scalar @in; $i++ ) {
        next if ref( $in[$i] ) eq 'HASH';
        my $args = {};
        if ( ref( $in[$i + 1 ]) eq 'HASH' ) {
            $args = $in[$i + 1 ];
        }
        push @out, [$in[$i], $args];
    }
    return @out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Magpie::Util - Common utility functions

=head1 VERSION

version 1.163200

=head1 AUTHORS

=over 4

=item *

Kip Hampton <kip.hampton@tamarou.com>

=item *

Chris Prather <chris.prather@tamarou.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Tamarou, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
