package Plack::Handler::Gepok;

use 5.010;
use strict;
use warnings;

use Gepok;

our $VERSION = '0.291'; # VERSION

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;

    $self->{daemonize} //= 0;

    # translate different option names
    if ($self->{port}) {
        $self->{http_ports} //= [($self->{host} // "") . ":" . $self->{port}];
        delete $self->{port};
        delete $self->{host};
    }
    $self;
}

sub run {
    my($self, $app) = @_;
    Gepok->new(%$self)->run($app);
}

1;
# ABSTRACT: Plack adapter for Gepok

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Handler::Gepok - Plack adapter for Gepok

=head1 VERSION

This document describes version 0.291 of Plack::Handler::Gepok (from Perl distribution Gepok), released on 2019-07-08.

=head1 SYNOPSIS

  plackup -s Gepok

=for Pod::Coverage ^(new|run)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Gepok>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Gepok>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Gepok>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Gepok>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
