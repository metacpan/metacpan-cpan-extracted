package Log::ger::Level::Like::Mojo;

our $DATE = '2019-06-08'; # DATE
our $VERSION = '0.001'; # VERSION

use Log::ger ();

%Log::ger::Levels = (
    fatal     => 10,
    error     => 20,
    warn      => 30,
    info      => 40,
    debug     => 50,
);

%Log::ger::Level_Aliases = (
    off => 0,
);

1;
# ABSTRACT: Define logging levels like Mojo::Log

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Level::Like::Mojo - Define logging levels like Mojo::Log

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 # load before 'use Log::ger' in any package/target
 use Log::ger::Level::Like::Mojo;

=head1 DESCRIPTION

This module changes the L<Log::ger> levels to:

    fatal     => 10,
    error     => 20,
    warn      => 30,
    info      => 40,
    debug     => 50,

which is just like the default except for the absence of C<trace>.

=head1 SEE ALSO

L<Log::Any>

L<Mojo::Log>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
