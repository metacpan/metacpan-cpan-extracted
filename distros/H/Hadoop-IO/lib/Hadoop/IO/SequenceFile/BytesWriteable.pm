package Hadoop::IO::SequenceFile::BytesWriteable;
$Hadoop::IO::SequenceFile::BytesWriteable::VERSION = '0.003';
use 5.010;
use strict;
use warnings;


use constant {
    CLASS_NAME => "org.apache.hadoop.io.BytesWritable",
};


sub class_name { CLASS_NAME }


sub encode {
    my ($self, $data) = @_;
    my $len = pack "L>", length $data;
    return $len . $data;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hadoop::IO::SequenceFile::BytesWriteable

=head1 VERSION

version 0.003

=head1 NAME

Hadoop::IO::SequenceFile::BytesWriteable - Hadoop compatible BytesWritable serializer.

=head1 METHODS

=over

=item $class->class_name() -> $string

Get java class name for BytesWriteable.

=item $class->encode($data) -> $encoded

Encode a perl string, containing (possibly) binary data into the format compatible with how BytesWriteable is serialized by Hadoop.

=back

=head1 AUTHORS

=over 4

=item *

Philippe Bruhat

=item *

Sabbir Ahmed

=item *

Somesh Malviya

=item *

Vikentiy Fesunov

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
