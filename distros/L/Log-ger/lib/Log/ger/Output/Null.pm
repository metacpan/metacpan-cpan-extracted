package Log::ger::Output::Null;

our $DATE = '2020-03-04'; # DATE
our $VERSION = '0.031'; # VERSION

sub get_hooks {
    return {
        create_log_routine => [
            __PACKAGE__, 50,
            sub {
                my %hook_args = @_;

                $Log::ger::_logger_is_null = 1;
                my $logger = sub {0};
                [$logger];
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

version 0.031

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

This software is copyright (c) 2020, 2019, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
