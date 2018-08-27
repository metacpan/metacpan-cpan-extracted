package ETL::Yertl::FormatStream;
our $VERSION = '0.039';
# ABSTRACT: Read/write I/O stream with Yertl formatters

#pod =head1 SYNOPSIS
#pod
#pod     use ETL::Yertl;
#pod     use ETL::Yertl::FormatStream;
#pod     use ETL::Yertl::Format;
#pod     use IO::Async::Loop;
#pod
#pod     my $loop = IO::Async::Loop->new;
#pod     my $format = ETL::Yertl::Format->get( "json" );
#pod
#pod     my $input = ETL::Yertl::FormatStream->new(
#pod         read_handle => \*STDIN,
#pod         format => $format,
#pod         on_doc => sub {
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
#pod =head1 SEE ALSO
#pod
#pod L<ETL::Yertl::Format>
#pod
#pod =cut

use ETL::Yertl;
use base 'IO::Async::Stream';
use ETL::Yertl::Format;
use Carp qw( croak );

sub configure {
    my ( $self, %args ) = @_;

    $self->{format} = delete $args{format} || ETL::Yertl::Format->get_default;

    for my $event ( qw( on_doc ) ) {
        $self->{ $event } = delete $args{ $event } if exists $args{ $event };
    }
    if ( $self->read_handle ) {
        $self->can_event( "on_doc" )
            or croak "Expected either an on_doc callback or to be able to ->on_doc";
    }

    $self->SUPER::configure( %args );
}

sub on_read {
    my ( $self, $buffref, $eof ) = @_;
    my @docs = $self->{format}->read_buffer( $buffref, $eof );
    for my $doc ( @docs ) {
        $self->invoke_event( on_doc => $doc, $eof );
    }
    return 0;
}

sub write {
    my ( $self, $doc, @args ) = @_;
    my $str = $self->{format}->format( $doc );
    return $self->SUPER::write( $str, @args );
}

1;

__END__

=pod

=head1 NAME

ETL::Yertl::FormatStream - Read/write I/O stream with Yertl formatters

=head1 VERSION

version 0.039

=head1 SYNOPSIS

    use ETL::Yertl;
    use ETL::Yertl::FormatStream;
    use ETL::Yertl::Format;
    use IO::Async::Loop;

    my $loop = IO::Async::Loop->new;
    my $format = ETL::Yertl::Format->get( "json" );

    my $input = ETL::Yertl::FormatStream->new(
        read_handle => \*STDIN,
        format => $format,
        on_doc => sub {
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

=head1 SEE ALSO

L<ETL::Yertl::Format>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
