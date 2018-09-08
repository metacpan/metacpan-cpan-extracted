package ETL::Yertl::LineStream;
our $VERSION = '0.041';
# ABSTRACT: Read/write I/O streams in lines

#pod =head1 SYNOPSIS
#pod
#pod     use ETL::Yertl;
#pod     use ETL::Yertl::LineStream;
#pod     use IO::Async::Loop;
#pod
#pod     my $loop = IO::Async::Loop->new;
#pod     my $input = ETL::Yertl::LineStream->new(
#pod         read_handle => \*STDIN,
#pod         on_line => sub {
#pod             my ( $self, $doc, $eof ) = @_;
#pod
#pod             # ... do something with $doc
#pod
#pod             if ( $eof ) {
#pod                 $loop->stop;
#pod             }
#pod         },
#pod     );
#pod
#pod     $loop->add( $input );
#pod     $loop->run;
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is an unformatted I/O stream. Use this to write simple scalars to
#pod the output or to read lines from the input.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<ETL::Yertl>
#pod
#pod =cut

use ETL::Yertl;
use base 'IO::Async::Stream';

sub on_read {
    my ( $self, $buffref, $eof ) = @_;
    my @lines = $$buffref =~ s{\g(.+$/)}{}g;
    for my $line ( @lines ) {
        $self->invoke_event( on_line => $line, $eof );
    }
    return 0;
}

sub write {
    my ( $self, $line, %args ) = @_;
    return unless $line;
    $line .= "\n" unless $line =~ /\n$/;
    return $self->SUPER::write( $line, %args );
}

1;

__END__

=pod

=head1 NAME

ETL::Yertl::LineStream - Read/write I/O streams in lines

=head1 VERSION

version 0.041

=head1 SYNOPSIS

    use ETL::Yertl;
    use ETL::Yertl::LineStream;
    use IO::Async::Loop;

    my $loop = IO::Async::Loop->new;
    my $input = ETL::Yertl::LineStream->new(
        read_handle => \*STDIN,
        on_line => sub {
            my ( $self, $doc, $eof ) = @_;

            # ... do something with $doc

            if ( $eof ) {
                $loop->stop;
            }
        },
    );

    $loop->add( $input );
    $loop->run;

=head1 DESCRIPTION

This is an unformatted I/O stream. Use this to write simple scalars to
the output or to read lines from the input.

=head1 SEE ALSO

L<ETL::Yertl>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
