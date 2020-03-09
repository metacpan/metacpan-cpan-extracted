package Log::ger::Format::None;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-07'; # DATE
our $DIST = 'Log-ger'; # DIST
our $VERSION = '0.033'; # VERSION

sub get_hooks {
    return {
        create_formatter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"
                my $formatter = sub { shift };
                [$formatter];
            }],
    };
}

1;
# ABSTRACT: Perform no formatting on the message

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Format::None - Perform no formatting on the message

=head1 VERSION

version 0.033

=head1 SYNOPSIS

 use Log::ger::Format 'None';

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head1 SEE ALSO

L<Log::ger>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
