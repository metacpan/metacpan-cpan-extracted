## no critic: TestingAndDebugging::RequireUseStrict
package Log::ger::Output::Null;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-06-10'; # DATE
our $DIST = 'Log-ger'; # DIST
our $VERSION = '0.040'; # VERSION

sub meta { +{
    v => 2,
} }

sub get_hooks {
    return {
        create_outputter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                $Log::ger::_outputter_is_null = 1;
                my $outputter = sub {0};
                [$outputter];
            }],
    };
}

1;
# ABSTRACT: Null output

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::Null - Null output

=head1 VERSION

version 0.040

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

This software is copyright (c) 2022, 2020, 2019, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
