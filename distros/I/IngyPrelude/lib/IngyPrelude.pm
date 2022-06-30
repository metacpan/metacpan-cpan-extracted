package IngyPrelude;

use v5.10;
use strict;
use warnings;

use base 'Exporter';

our $VERSION = '0.0.1';

our @EXPORT = qw( file_read file_write );

sub file_read {
    my ($path) = @_;
    open my $fh, '<', $path or die $!;
    local $/;
    return <$fh>;
}

sub file_write {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die $!;
    print $fh $text;
}

1;

=encoding utf8

=head1 NAME

Ingy döt Net's Standard Prelude

=head1 SYNOPSIS

    use IngyPrelude;

    my $text = file_read 'foo.txt';
    file_write 'FOO.TXT', uc($text);

=head1 DESCRIPTION

This module exports a number of common functions.

=head1 AUTHOR

Ingy döt Net <ingy@ingy.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2022. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
