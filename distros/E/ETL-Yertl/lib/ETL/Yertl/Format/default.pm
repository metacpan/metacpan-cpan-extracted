package ETL::Yertl::Format::default;
our $VERSION = '0.037';
# ABSTRACT: The default format for intra-Yertl communication

#pod =head1 SYNOPSIS
#pod
#pod     my $out_formatter = ETL::Yertl::Format::default->new;
#pod     print $formatter->write( $document );
#pod
#pod     my $in_formatter = ETL::Yertl::Format::default->new(
#pod         input => \*STDIN,
#pod     );
#pod     my $document = $formatter->read;
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is the default format for Yertl programs talking to each other. By
#pod default, this is C<YAML>, but it can be set to C<JSON> by setting the
#pod C<YERTL_FORMAT> environment variable to C<"json">.
#pod
#pod Setting the default format to something besides YAML can help
#pod interoperate with other programs like
#pod L<jq|https://stedolan.github.io/jq/> or L<recs|App::RecordStream>.
#pod
#pod =cut

use ETL::Yertl;
use Module::Runtime qw( use_module );

#pod =method new
#pod
#pod     my $formatter = ETL::Yertl::Format::default->new( %args );
#pod
#pod Get an instance of the default formatter. The arguments will be passed
#pod to the correct formatter module.
#pod
#pod =cut

sub new {
    my ( $class, @args ) = @_;
    my $format = $ENV{YERTL_FORMAT} || 'yaml';
    my $format_class = "ETL::Yertl::Format::$format";
    return use_module( $format_class )->new( @args );
}

1;

__END__

=pod

=head1 NAME

ETL::Yertl::Format::default - The default format for intra-Yertl communication

=head1 VERSION

version 0.037

=head1 SYNOPSIS

    my $out_formatter = ETL::Yertl::Format::default->new;
    print $formatter->write( $document );

    my $in_formatter = ETL::Yertl::Format::default->new(
        input => \*STDIN,
    );
    my $document = $formatter->read;

=head1 DESCRIPTION

This is the default format for Yertl programs talking to each other. By
default, this is C<YAML>, but it can be set to C<JSON> by setting the
C<YERTL_FORMAT> environment variable to C<"json">.

Setting the default format to something besides YAML can help
interoperate with other programs like
L<jq|https://stedolan.github.io/jq/> or L<recs|App::RecordStream>.

=head1 METHODS

=head2 new

    my $formatter = ETL::Yertl::Format::default->new( %args );

Get an instance of the default formatter. The arguments will be passed
to the correct formatter module.

=head1 SEE ALSO

=over 4

=item L<ETL::Yertl::Format::yaml>

The YAML formatter

=item L<ETL::Yertl::Format::json>

The JSON formatter

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
