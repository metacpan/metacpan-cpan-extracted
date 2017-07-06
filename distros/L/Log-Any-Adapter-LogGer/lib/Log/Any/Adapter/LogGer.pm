package Log::Any::Adapter::LogGer;

our $DATE = '2017-06-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Log::ger ();

use Log::Any;
use Log::Any::Adapter::Util qw(make_method);
use parent qw(Log::Any::Adapter::Base);

my $Time0;

my %LogGer_Objects;

my @logging_methods = Log::Any->logging_methods;
our %logging_levels;
for my $i (0..@logging_methods-1) {
    $logging_levels{$logging_methods[$i]} = $i;
}
# some common typos
$logging_levels{warn} = $logging_levels{warning};

sub init {
    my ($self) = @_;
}

for my $method (Log::Any->logging_methods()) {
    make_method(
        $method,
        sub {
            my ($self, $msg) = @_;
            my $cat = $self->{category};
            unless ($LogGer_Objects{$cat}) {
                $LogGer_Objects{$cat} =
                    Log::ger->get_logger(category => $cat);
            }
            my $lg_method = $method;
            $lg_method = "warn" if $lg_method eq 'warning';
            #if ($LogGer_Objects{$cat}->can($lg_method)) {
            $LogGer_Objects{$cat}->$lg_method($msg);
            #}
        }
    );
}

for my $method (Log::Any->detection_methods()) {
    my $level = $method; $level =~ s/^is_//;
    make_method(
        $method,
        sub {1},
    );
}

1;
# ABSTRACT: Send Log::Any logs to Log::ger

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::LogGer - Send Log::Any logs to Log::ger

=head1 VERSION

This document describes version 0.003 of Log::Any::Adapter::LogGer (from Perl distribution Log-Any-Adapter-LogGer), released on 2017-06-25.

=head1 SYNOPSIS

 use Log::Any::Adapter;
 Log::Any::Adapter->set('LogGer');

=head1 DESCRIPTION

=for Pod::Coverage ^(init)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-Any-Adapter-LogGer>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-Any-Adapter-LogGer>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Any-Adapter-LogGer>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger>

L<Log::Any>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
