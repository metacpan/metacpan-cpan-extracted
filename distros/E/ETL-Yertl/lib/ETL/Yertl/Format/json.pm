package ETL::Yertl::Format::json;
our $VERSION = '0.039';
# ABSTRACT: JSON read/write support for Yertl

#pod =head1 SYNOPSIS
#pod
#pod =head1 DESCRIPTION
#pod
#pod =head1 SEE ALSO
#pod
#pod L<ETL::Yertl::FormatStream>
#pod
#pod =cut

use ETL::Yertl;
use base 'ETL::Yertl::Format';

sub _formatter_classes {
    return (
        [ 'JSON::XS' => 0 ],
        [ 'JSON::PP' => 0 ],
    );
}

sub _json_writer {
    my ( $self ) = @_;
    $self->{_json_writer} ||= do {
        my $json = $self->{formatter_class}->new->canonical->pretty->allow_nonref;
        if ( $self->{formatter_class} ne 'JSON::XS' ) {
            $json->indent_length(3);
        }
        $json;
    };
}

sub read_buffer {
    my ( $self, $buffref, $eof ) = @_;
    my $json = $self->{_json_reader} ||= $self->{formatter_class}->new->relaxed;
    my @docs;

    # Work around a bug in JSON::PP: incr_parse() only returns the
    # first item, see: https://github.com/makamaka/JSON-PP/pull/7
    # Adapted from IO::Async::JSONStream by Paul Evans
    $json->incr_parse( $$buffref );
    $$buffref = '';
    PARSE_ONE: {
        my $doc;

        my $fail = not eval {
            $doc = $json->incr_parse;
            1
        };
        chomp( my $e = $@ );

        if ( $doc ) {
            #; use Data::Dumper;
            #; say STDERR "## Got document " . Dumper $doc;
            push @docs, $doc;
            redo PARSE_ONE;
        }
        elsif ( $fail ) {
            # XXX: Parse failure
            $json->incr_skip;
            redo PARSE_ONE;
        }
        # else last
    }

    return @docs;
}

sub format {
    my ( $self, $doc ) = @_;
    my $json = $self->_json_writer;
    return $json->encode( $doc );
}

1;

__END__

=pod

=head1 NAME

ETL::Yertl::Format::json - JSON read/write support for Yertl

=head1 VERSION

version 0.039

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

L<ETL::Yertl::FormatStream>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
