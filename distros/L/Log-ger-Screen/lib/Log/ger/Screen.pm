package Log::ger::Screen;

use strict;
use warnings;

use Log::ger::Level::FromVar;
use Log::ger::Level::FromEnv;
use Log::ger::Output 'Screen' => (colorize_tags=>1);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-18'; # DATE
our $DIST = 'Log-ger-Screen'; # DIST
our $VERSION = '0.005'; # VERSION

sub import {
    my ($package, %per_target_conf) = @_;

    require Log::ger;
    my $caller = caller(0);
    Log::ger::_import_to($package, $caller, %per_target_conf);
}

1;
# ABSTRACT: Convenient packaging of Log::ger + Lg:Output::Screen + Lg:Level::FromVar + Lg:Level::FromEnv for one-liner

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Screen - Convenient packaging of Log::ger + Lg:Output::Screen + Lg:Level::FromVar + Lg:Level::FromEnv for one-liner

=head1 VERSION

version 0.005

=head1 SYNOPSIS

Mostly in one-liners:

 % perl -MLog::ger::Screen -E'log_warn "blah..."; ...'

Set level from package variable (see L<Log::ger::Level::FromVar> for more
details):

 % perl -E'BEGIN { $Default_Log_Level = 'info' } use Log::ger::Screen; ...'

Set level from environment variable (see L<Log::ger::Level::FromEnv> for more
details):

 % TRACE=1 perl ...

But you can certainly use this module in your CLI script, as a more lightweight
alternative to L<Log::ger::App> when you only want to output log to screen:

 #!perl
 use strict;
 use warnings;
 BEGIN { our $Default_Log_Level = 'info' }
 use Log::ger::Screen;
 use Log::ger;

 use Getopt::Long;

 log_debug "Starting program ...";
 ...
 log_debug "Ending program ...";

=head1 DESCRIPTION

This is just a convenient packaging of:

 use Log::ger::Level::FromVar;
 use Log::ger::Level::FromEnv;
 use Log::ger::Output 'Screen';
 use Log::ger; # in the caller's package

mostly for one-liner usage, but you are also welcome to use it in your CLI
scripts.

=head1 SEE ALSO

L<Log::ger::App>

L<Log::ger>

L<Log::ger::Level::FromVar>

L<Log::ger::Level::FromEnv>

L<Log::ger::Output::Screen>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
