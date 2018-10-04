package ETL::Yertl::Format;
our $VERSION = '0.043';
# ABSTRACT: Base class for input/output formats

#pod =head1 SYNOPSIS
#pod
#pod     use ETL::Yertl::Format;
#pod     my $json_format = ETL::Yertl::Format->get( "json" );
#pod     my $default_format = ETL::Yertl::Format->get_default;
#pod
#pod =head1 DESCRIPTION
#pod
#pod Formatters handle parsing input strings into document hashes and
#pod formatting document hashes into output strings.
#pod
#pod Formatter objects are given to L<ETL::Yertl::FormatStream> objects.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<ETL::Yertl::FormatStream>
#pod
#pod =cut

use ETL::Yertl;
use ETL::Yertl::Util qw( load_module );
use Module::Runtime qw( use_module );

sub new {
    my ( $class, %opt ) = @_;
    $opt{formatter_class} ||= $class->_find_formatter_class;
    return bless \%opt, $class;
}

#pod =method get
#pod
#pod     my $format = ETL::Yertl::Format->get( $name, %args );
#pod
#pod Get the formatter with the given name. C<$name> should be the last word
#pod in the C<ETL::Yertl::Format> subclass (like C<yaml> for
#pod C<ETL::Yertl::Format::yaml>). C<%args> will be passed-in to the
#pod formatter constructor.
#pod
#pod =cut

sub get {
    my ( $class, $type, @args ) = @_;
    load_module( format => $type )->new( @args );
}

#pod =method get_default
#pod
#pod     my $format = ETL::Yertl::Format->get_default;
#pod
#pod Get the default format for Yertl programs to communicate with each
#pod other. By default, this is C<YAML>, but it can be set to C<JSON> by
#pod setting the C<YERTL_FORMAT> environment variable to C<"json">.
#pod
#pod Setting the default format to something besides YAML can help
#pod interoperate with other programs like
#pod L<jq|https://stedolan.github.io/jq/> or L<recs|App::RecordStream>.
#pod
#pod =cut

sub get_default {
    my ( $class ) = @_;
    my $format = $ENV{YERTL_FORMAT} || 'yaml';
    return $class->get( $format );
}

sub _formatter_classes {
    die '_formatter_classes must be overridden';
}

sub _find_formatter_class {
    my ( $class ) = @_;
    my @class_versions = $class->_formatter_classes;
    for my $class_version ( @class_versions ) {
        eval {
            # Prototypes on use_module() make @$class_version not work correctly
            use_module( $class_version->[0], $class_version->[1] );
        };
        if ( !$@ ) {
            return $class_version->[0];
        }
    }
    die "Could not load a formatter for $class. Please install one of the following modules:\n"
        . join( "",
            map { sprintf "\t%s (%s)", $_->[0], $_->[1] ? "version $_->[1]" : "Any version" }
            @class_versions
        )
        . "\n";
}

1;

__END__

=pod

=head1 NAME

ETL::Yertl::Format - Base class for input/output formats

=head1 VERSION

version 0.043

=head1 SYNOPSIS

    use ETL::Yertl::Format;
    my $json_format = ETL::Yertl::Format->get( "json" );
    my $default_format = ETL::Yertl::Format->get_default;

=head1 DESCRIPTION

Formatters handle parsing input strings into document hashes and
formatting document hashes into output strings.

Formatter objects are given to L<ETL::Yertl::FormatStream> objects.

=head1 METHODS

=head2 get

    my $format = ETL::Yertl::Format->get( $name, %args );

Get the formatter with the given name. C<$name> should be the last word
in the C<ETL::Yertl::Format> subclass (like C<yaml> for
C<ETL::Yertl::Format::yaml>). C<%args> will be passed-in to the
formatter constructor.

=head2 get_default

    my $format = ETL::Yertl::Format->get_default;

Get the default format for Yertl programs to communicate with each
other. By default, this is C<YAML>, but it can be set to C<JSON> by
setting the C<YERTL_FORMAT> environment variable to C<"json">.

Setting the default format to something besides YAML can help
interoperate with other programs like
L<jq|https://stedolan.github.io/jq/> or L<recs|App::RecordStream>.

=head1 SEE ALSO

L<ETL::Yertl::FormatStream>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
