package Log::ger::Like::Log4perl;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Log-ger-Like-Log4perl'; # DIST
our $VERSION = '0.003'; # VERSION

# IFUNBUILT
# use strict 'subs', 'vars';
# use warnings;
# END IFUNBUILT

sub get_logger {
    my ($package, $category) = @_;

    my $caller = caller(0);
    require Log::ger;
    require Log::ger::Plugin;
    my $log = Log::ger->get_logger(category => $category);
    Log::ger::Plugin->set({
        name        => 'Log4perl',
        target_type => 'object',
        target_name => $log,
    });
    Log::ger::Plugin->set({
        name        => 'Log4perl_Multi',
        target_type => 'object',
        target_name => $log,
    });
    $log;
}

sub import {
    my $pkg = shift;

    # export $TRACE, ...
    my $caller = caller(0);
    {
        no warnings 'once';
        for (keys %Log::ger::Levels) {
            *{"$caller\::".uc($_)} = \$Log::ger::Levels{$_};
        }
    }

    require Log::ger;
    require Log::ger::Plugin;
    Log::ger::Plugin->set({
        name        => 'Log4perl',
        target_type => 'package',
        target_name => $caller,
    });
    Log::ger::add_target(package => $caller, {});
    Log::ger::init_target(package => $caller, {});
}

1;
# ABSTRACT: Mimic Log::Log4perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Like::Log4perl - Mimic Log::Log4perl

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 use Log::ger::Like::Log4perl;

 sub mysub {
     DEBUG "Entering mysub ...";
     ...
 }

 my $log = Log::ger::Like::Log4perl->get_logger;

 $log->log($WARN, "Blah ...");
 $log->logdie("Blah ...");
 $log->logwarn("Blah ...");
 $log->error_die("Blah ...");
 $log->error_warn("Blah ...");

 $log->logcarp("Blah ...");
 $log->logcluck("Blah ...");
 $log->logcroak("Blah ...");
 $log->logconfess("Blah ...");

=head1 DESCRIPTION

This module does the following to mimic L<Log::Log4perl> to a certain extent:

=over

=item * Log4perl-like formatting

 $log->warn("a", "b", sub { "c", "d" })

will format the message as "abcd".

=item * Uppercase subroutine names

This module provides uppercase subroutine names: TRACE, DEBUG, INFO, ERROR,
WARN, FATAL like what you get when you "use Log::Log4perl ':easy'" instead of
the Log::ger default log_trace(), log_debug(), log_info(), log_warn(),
log_error(), log_fatal().

It also provides LOGDIE and LOGWARN.

=item * Export level constants

It exports the log level values: C<$TRACE>, C<$DEBUG>, C<$INFO>, C<$WARN>,
C<$ERROR>, C<$FATAL>.

=item * Additional logging methods

It provides additional log methods: log(), logdie(), logwarn(), error_warn(),
error_die(), logcarp(), logcluck(), logcroak(), logconfess() like you would get
in Log4perl.

=back

=for Pod::Coverage ^(get_logger)$

=head1 SEE ALSO

L<Log::ger>

L<Log::Log4perl> and L<Log::Log4perl::Tiny>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
