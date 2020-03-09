package Mail::TLSRPT;
# ABSTRACT: TLSRPT object
our $VERSION = '1.20200306.1'; # VERSION
use 5.20.0;
use Moo;
use Carp;
use Types::Standard qw{Str HashRef ArrayRef};
use Type::Utils qw{class_type};
use Mail::TLSRPT::Pragmas;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::TLSRPT - TLSRPT object

=head1 VERSION

version 1.20200306.1

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
