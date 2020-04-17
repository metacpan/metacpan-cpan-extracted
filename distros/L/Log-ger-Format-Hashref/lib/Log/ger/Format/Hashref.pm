package Log::ger::Format::Hashref;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Log-ger-Format-Hashref'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %plugin_conf = @_;

    return {
        create_formatter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $formatter = sub {
                    if (@_ == 1) {
                        if (ref $_[0] eq 'HASH') {
                            return $_[0];
                        } else {
                            return {message=>$_[0]};
                        }
                    } elsif (@_ % 2) {
                        die "Please log an even number of arguments";
                    } else {
                        return {@_};
                    }
                };
                [$formatter];

            }],
    };
}

1;
# ABSTRACT: Format arguments as hashref

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Format::Hashref - Format arguments as hashref

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 use Log::ger::Format 'Hashref';
 use Log::ger;

 # single argument, not hashref
 log_debug "arg";                          # becomes  : {message=>"arg"}

 # single argument, hashref
 log_debug {msg=>"arg"};                   # unchanged: {msg=>"arg"}

 # multiple arguments, odd numbered
 log_debug "arg1", "arg2", "arg3";         # dies!

 # multiple arguments, even numbered
 log_debug "arg1", "arg2", "arg3", "arg4"; # becomes  : {arg1=>"arg2", arg3=>"arg4"}

 log_debug "Data for %s is %s", "budi", {foo=>'blah', bar=>undef};

=head1 DESCRIPTION

EXPERIMENTAL.

This formatter tries to produce a single hashref from the arguments.

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

Other C<Log::ger::Format::*> plugins.

L<Log::ger>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
