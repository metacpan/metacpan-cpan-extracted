use strict;
use warnings;

package Log::Any::Adapter::Log4perl;
# ABSTRACT: Log::Any adapter for Log::Log4perl

use Log::Log4perl 1.32; # bug-free wrapper_register available
use Log::Any::Adapter::Util 1.03 qw(make_method);
use base qw(Log::Any::Adapter::Base);

our $VERSION = '0.09';

# Ensure %F, %C, etc. skip Log::Any related packages
Log::Log4perl->wrapper_register(__PACKAGE__);
Log::Log4perl->wrapper_register("Log::Any::Proxy");

sub init {
    my ($self) = @_;

    $self->{logger} = Log::Log4perl->get_logger( $self->{category} );
}

foreach my $method ( Log::Any->logging_and_detection_methods() ) {
    my $log4perl_method = $method;

    # Map log levels down to log4perl levels where necessary
    #
    for ($log4perl_method) {
        s/notice/info/;
        s/warning/warn/;
        s/critical|alert|emergency/fatal/;
    }

    make_method(
        $method,
        sub {
            my $self = shift;
            return $self->{logger}->$log4perl_method(@_);
        }
    );
}

sub structured {
    my ($adapter, $level, $category, @parts) = @_;
    my $context = ref($parts[-1]) eq 'HASH'
        ? pop @parts
        : {};
    my $mdc = Log::Log4perl::MDC->get_context;
    local @{$mdc}{keys %{$context}} = values %{$context};
    $adapter->$level(@parts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::Log4perl - Log::Any adapter for Log::Log4perl

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    use Log::Log4perl;
    Log::Log4perl::init('/etc/log4perl.conf');

    Log::Any::Adapter->set('Log::Log4perl');

=head1 DESCRIPTION

This Log::Any adapter uses L<Log::Log4perl|Log::Log4perl> for logging. log4perl
must be initialized before calling I<set>. There are no parameters.

=for Pod::Coverage init

=head1 LOG LEVEL TRANSLATION

Log levels are translated from Log::Any to Log4perl as follows:

    notice -> info
    warning -> warn
    critical -> fatal
    alert -> fatal
    emergency -> fatal

=head1 METHODS

=head2 structured

This adapter supports structured logging, introduced in Log-Any v1.700.

=head1 SEE ALSO

=over 4

=item *

L<Log::Any>

=item *

L<Log::Any::Adapter>

=item *

L<Log::Log4perl>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/preaction/Log-Any-Adapter-Log4perl/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/preaction/Log-Any-Adapter-Log4perl>

  git clone https://github.com/preaction/Log-Any-Adapter-Log4perl.git

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

David Golden <dagolden@cpan.org>

=item *

Doug Bell <preaction@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords Doug Bell Gianni Ceccarelli

=over 4

=item *

Doug Bell <doug@preaction.me>

=item *

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
