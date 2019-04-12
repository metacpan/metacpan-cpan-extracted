package Log::ger::Plugin;

our $DATE = '2019-04-12'; # DATE
our $VERSION = '0.026'; # VERSION

use strict;
use warnings;

use Log::ger::Util;

sub set {
    my $pkg = shift;

    my %args;
    if (ref $_[0] eq 'HASH') {
        %args = %{shift()};
    } else {
        %args = (name => shift, conf => {@_});
    }

    $args{prefix} ||= $pkg . '::';
    $args{replace_package_regex} = $pkg->_replace_package_regex;
    Log::ger::Util::set_plugin(%args);
}

sub set_for_current_package {
    my $pkg = shift;

    my %args;
    if (ref $_[0] eq 'HASH') {
        %args = %{shift()};
    } else {
        %args = (name => shift, conf => {@_});
    }

    my $caller = caller(0);
    $args{target} = 'package';
    $args{target_arg} = $caller;

    set($pkg, \%args);
}

sub _import_sets_for_current_package { 0 }

sub _replace_package_regex { undef }

sub import {
    if (@_ > 1) {
        if ($_[0]->_import_sets_for_current_package) {
            goto &set_for_current_package;
        } else {
            goto &set;
        }
    }
}

1;
# ABSTRACT: Use a plugin

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Plugin - Use a plugin

=head1 VERSION

version 0.026

=head1 SYNOPSIS

To set globally:

 use Log::ger::Plugin;
 Log::ger::Plugin->set('OptAway');

or:

 use Log::ger::Plugin 'OptAway';

To set for current package only:

 use Log::ger::Plugin;
 Log::ger::Plugin->set_for_current_package('OptAway');

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<Log::ger::Format>

L<Log::ger::Layout>

L<Log::ger::Output>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
