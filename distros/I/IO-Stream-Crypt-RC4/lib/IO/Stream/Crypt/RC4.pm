package IO::Stream::Crypt::RC4;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.0.1';

use IO::Stream::const;
use Crypt::RC4;


sub new {
    my ($class, $passphrase) = @_;
    croak 'usage: IO::Stream::Crypt::RC4->new("passphrase")'
        if !defined $passphrase;
    my $self = bless {
        out_buf     => q{},                 # modified on: OUT
        out_pos     => undef,               # modified on: OUT
        out_bytes   => 0,                   # modified on: OUT
        in_buf      => q{},                 # modified on: IN
        in_bytes    => 0,                   # modified on: IN
        ip          => undef,               # modified on: RESOLVED
        is_eof      => undef,               # modified on: EOF
        _rcrypt     => Crypt::RC4->new($passphrase),
        _wcrypt     => Crypt::RC4->new($passphrase),
        }, $class;
    return $self;
}

sub PREPARE {
    my ($self, $fh, $host, $port) = @_;
    $self->{_slave}->PREPARE($fh, $host, $port);
    return;
}

sub WRITE {
    my ($self) = @_;
    my $m = $self->{_master};
    my $s = substr $m->{out_buf}, $m->{out_pos}||0;
    my $n = length $s;
    $self->{out_buf} .= $self->{_wcrypt}->RC4($s);
    if (defined $m->{out_pos}) {
        $m->{out_pos} += $n;
    } else {
        $m->{out_buf} = q{};
    }
    $m->{out_bytes} += $n;
    $m->EVENT(OUT);
    $self->{_slave}->WRITE();
    return;
}

sub EVENT {
    my ($self, $e, $err) = @_;
    my $m = $self->{_master};
    if ($e & OUT) {
        $e &= ~OUT;
        return if !$e && !$err;
    }
    if ($e & IN) {
        $m->{in_buf}    .= $self->{_rcrypt}->RC4($self->{in_buf});
        $m->{in_bytes}  += $self->{in_bytes};
        $self->{in_buf}  = q{};
        $self->{in_bytes}= 0;
    }
    if ($e & RESOLVED) {
        $m->{ip} = $self->{ip};
    }
    if ($e & EOF) {
        $m->{is_eof} = $self->{is_eof};
    }
    $m->EVENT($e, $err);
    return;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

IO::Stream::Crypt::RC4 - Crypt::RC4 plugin for IO::Stream


=head1 VERSION

This document describes IO::Stream::Crypt::RC4 version v2.0.1


=head1 SYNOPSIS

    use IO::Stream;
    use IO::Stream::Crypt::RC4;

    IO::Stream->new({
        ...
        plugin => [
            ...
            rc4     => IO::Stream::Crypt::RC4->new($passphrase),
            ...
        ],
    });

=head1 DESCRIPTION

This module is plugin for L<IO::Stream> which allow you to encrypt all
data read/written by this stream using RC4.


=head1 INTERFACE 

=head2 new

    $plugin = IO::Stream::Crypt::RC4->new( $passphrase );

Create and return new IO::Stream plugin object.


=head1 DIAGNOSTICS

=over

=item C<< usage: IO::Stream::Crypt::RC4->new("passphrase") >>

You probably called new() without $passphrase parameter.

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-IO-Stream-Crypt-RC4/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-IO-Stream-Crypt-RC4>

    git clone https://github.com/powerman/perl-IO-Stream-Crypt-RC4.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=IO-Stream-Crypt-RC4>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/IO-Stream-Crypt-RC4>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-Stream-Crypt-RC4>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=IO-Stream-Crypt-RC4>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/IO-Stream-Crypt-RC4>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
