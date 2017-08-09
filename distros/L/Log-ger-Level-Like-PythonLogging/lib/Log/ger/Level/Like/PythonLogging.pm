package Log::ger::Level::Like::PythonLogging;

our $DATE = '2017-08-03'; # DATE
our $VERSION = '0.001'; # VERSION

use Log::ger ();

%Log::ger::Levels = (
    notset => 0,
    critical => 10,
    error => 20,
    warning => 30,
    info => 40,
    debug => 50,
);

%Log::ger::Level_Aliases = (
    off => 0,
);

1;
# ABSTRACT: Define logging levels like Python's logging facility

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Level::Like::PythonLogging - Define logging levels like Python's logging facility

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 # load before 'use Log::ger' in any package/target
 use Log::ger::Level::Like::PythonLogging;

=head1 DESCRIPTION

This module changes the L<Log::ger> levels to:

    notset => 0,
    critical => 10,
    error => 20,
    warning => 30,
    info => 40,
    debug => 50,

=head1 SEE ALSO

[1] https://docs.python.org/3/library/logging.html

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
