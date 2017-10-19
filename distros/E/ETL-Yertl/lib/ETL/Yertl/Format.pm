package ETL::Yertl::Format;
our $VERSION = '0.035';
# ABSTRACT: Base class for input/output formats

use ETL::Yertl;
sub new {
    my ( $class, %args ) = @_;
    return bless \%args, $class;
}

1;

__END__

=pod

=head1 NAME

ETL::Yertl::Format - Base class for input/output formats

=head1 VERSION

version 0.035

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
