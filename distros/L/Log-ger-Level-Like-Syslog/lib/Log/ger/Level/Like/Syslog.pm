package Log::ger::Level::Like::Syslog;

our $DATE = '2018-05-28'; # DATE
our $VERSION = '0.001'; # VERSION

use Log::ger ();

%Log::ger::Levels = (
    emergency =>  0, # system is unusable
    alert     =>  6, # action must be taken immediately
    critical  => 10, # critical conditions
    error     => 20, # error conditions
    warning   => 30, # warning conditions
    notice    => 35, # normal but significant condition
    info      => 40, # informational messages
    debug     => 50, # debug level messages
);

%Log::ger::Level_Aliases = (
    off => 0,
);

1;
# ABSTRACT: Define logging levels like those described in RFC 3164 (syslog protocol)

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Level::Like::Syslog - Define logging levels like those described in RFC 3164 (syslog protocol)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 # load before 'use Log::ger' in any package/target
 use Log::ger::Level::Like::Syslog;

=head1 DESCRIPTION

This module changes the L<Log::ger> levels to:

    emergency =>  0, # system is unusable
    alert     =>  6, # action must be taken immediately
    critical  => 10, # critical conditions
    error     => 20, # error conditions
    warning   => 30, # warning conditions
    notice    => 35, # normal but significant condition
    info      => 40, # informational messages
    debug     => 50, # debug level messages

which are priorities defined in RFC 3164 (the BSD Syslog protocol).

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
