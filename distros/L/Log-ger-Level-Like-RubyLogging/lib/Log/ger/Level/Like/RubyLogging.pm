package Log::ger::Level::Like::RubyLogging;

our $DATE = '2017-08-03'; # DATE
our $VERSION = '0.003'; # VERSION

use Log::ger ();

%Log::ger::Levels = (
    unknown => 0,
    fatal   => 10,
    error   => 20,
    warn    => 30,
    info    => 40,
    debug   => 50,
);

%Log::ger::Level_Aliases = (
    off => 0,
);

1;
# ABSTRACT: Define logging levels like Ruby's logging library

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Level::Like::RubyLogging - Define logging levels like Ruby's logging library

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 # load before 'use Log::ger' in any package/target
 use Log::ger::Level::Like::RubyLogging;

=head1 DESCRIPTION

From the documentation of the Logging library [1]: "Logging is a flexible
logging library for use in Ruby programs based on the design of Java's log4j
library. It features a hierarchical logging system, custom level names, multiple
output destinations per log event, custom formatting, and more."

This module changes the L<Log::ger> levels to:

    unknown => 0,
    fatal   => 10,
    error   => 20,
    warn    => 30,
    info    => 40,
    debug   => 50,

=head1 SEE ALSO

[1] L<http://www.rubydoc.info/gems/logging/file/README.md>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
