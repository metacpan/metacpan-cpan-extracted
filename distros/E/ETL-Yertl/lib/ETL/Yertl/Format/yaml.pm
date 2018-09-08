package ETL::Yertl::Format::yaml;
our $VERSION = '0.041';
# ABSTRACT: YAML read/write support for Yertl

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

sub new {
    my ( $class, @args ) = @_;
    my $self = $class->SUPER::new( @args );
    no strict 'refs';
    $self->{_load} = \&{ $self->{formatter_class} . '::Load' };
    $self->{_dump} = \&{ $self->{formatter_class} . '::Dump' };
    return $self;
}

sub _formatter_classes {
    return (
        [ 'YAML::XS' => 0 ],
        [ 'YAML::Syck' => 0 ],
        # [ 'YAML' => 0 ], # Disabled: YAML::Old changes have broke something here...
        [ 'YAML::Tiny' => 0 ],
    );
}

sub read_buffer {
    my ( $self, $buffref, $eof ) = @_;
    my @docs;
    $self->{_doc_buf} ||= '';
    while ( $$buffref =~ s/^(.*\n)// ) {
        my $line = $1;
        if ( $line =~ /^---/ && $self->{_doc_buf} ) {
            #; say STDERR "## Got document\n$self->{_doc_buf}";
            push @docs, $self->{_load}->( $self->{_doc_buf} );
            $self->{_doc_buf} = '';
        }
        else {
            $self->{_doc_buf} .= $line;
        }
    }
    if ( $eof && $self->{_doc_buf} ) {
        #; say STDERR "## Got document\n$self->{_doc_buf}";
        push @docs, $self->{_load}->( $self->{_doc_buf} );
    }
    return @docs;
}

sub format {
    my ( $self, $doc ) = @_;
    return $self->{_dump}->( $doc );
}

1;

__END__

=pod

=head1 NAME

ETL::Yertl::Format::yaml - YAML read/write support for Yertl

=head1 VERSION

version 0.041

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

L<ETL::Yertl::FormatStream>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
