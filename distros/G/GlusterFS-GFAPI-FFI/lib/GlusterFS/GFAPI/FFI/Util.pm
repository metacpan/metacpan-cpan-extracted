package GlusterFS::GFAPI::FFI::Util;

BEGIN
{
    our $AUTHOR  = 'cpan:potatogim';
    our $VERSION = '0.4';
}

use strict;
use warnings;
use utf8;

use FFI::Platypus;
use Carp;
use Sub::Exporter
        -setup =>
        {
            exports => [qw/libgfapi_soname valid_so/],
        };

sub libgfapi_soname
{
    my %args = @_;

    my @sonames = qw(libgfapi.so libgfapi.so.0 libgfapi.so.0.0.0);

    my $soname;

    foreach my $so (@sonames)
    {
        if (valid_so($so))
        {
            $soname = $so;
            last;
        }
    }

    if (!defined($soname))
    {
        croak("Could not find libgfapi: tried: ${\join(', ', @sonames)}");
    }

    return $soname;
}

sub valid_so
{
    my $so  = shift;
    my $ffi = FFI::Platypus->new(lib => $so, ignore_not_found => 1);

    return defined($ffi);
}

1;

__END__

=encoding utf8

=head1 NAME

GlusterFS::GFAPI::FFI::Util - GlusterFS::GFAPI::FFI convenience functions

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

Ji-Hyeon Gim E<lt>potatogim@gluesys.comE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright 2017-2018 by Ji-Hyeon Gim.

This is free software; you can redistribute it and/or modify it under the same terms as the GPLv2/LGPLv3.

=cut

