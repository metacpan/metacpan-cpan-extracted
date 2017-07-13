package Log::ger::Format::None;

our $DATE = '2017-07-13'; # DATE
our $VERSION = '0.016'; # VERSION

sub get_hooks {
    return {
        create_formatter => [
            __PACKAGE__, 50,
            sub {
                [sub {shift}];
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

version 0.016

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

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
