package Log::ger::Output::Null;

our $DATE = '2017-06-21'; # DATE
our $VERSION = '0.004'; # VERSION

use Log::ger ();

sub PRIO_create_log_routine { 50 }

sub create_log_routine {
    $Log::ger::_log_is_null = 1;
    [sub {0}];
}

sub import {
    Log::ger::add_plugin('create_log_routine', __PACKAGE__, 'replace');
}

1;
# ABSTRACT: Null output

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::Null - Null output

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use Log::ger;
 use Log::ger::Output 'Null';

 log_warn "blah...";

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
