package Log::Dispatch::FileWriteRotate;

our $DATE = '2019-01-09'; # DATE
our $VERSION = '0.060'; # VERSION

use 5.010001;
use warnings;
use strict;

use File::Write::Rotate;
use Log::Dispatch::Output;
use base qw(Log::Dispatch::Output);

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my %args = @_;
    $self->_basic_init(%args);
    $self->_make_handle(%args);

    $self;
}

sub _make_handle {
    my $self = shift;
    my %args = @_;

    for (keys %args) {
        # XXX hook_*
        delete $args{$_} unless /\A(
                                     dir|prefix|suffix|period|size|histories|
                                     binmode|buffer_size|lock_mode|
                                     rotate_probability
                                 )\z/x;
    }
    $self->{_fwr} = File::Write::Rotate->new(%args);
}

sub log_message {
    my $self = shift;
    my %args = @_;

    $self->{_fwr}->write($args{message});
}

1;
# ABSTRACT: Log to files that archive/rotate themselves, w/ File::Write::Rotate

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::FileWriteRotate - Log to files that archive/rotate themselves, w/ File::Write::Rotate

=head1 VERSION

This document describes version 0.060 of Log::Dispatch::FileWriteRotate (from Perl distribution Log-Dispatch-FileWriteRotate), released on 2019-01-09.

=head1 SYNOPSIS

 use Log::Dispatch::FileWriteRotate;

 my $file = Log::Dispatch::FileWriteRotate(
     min_level => 'info',

     # will be passed to File::Write::Rotate
     dir       => '/var/log',
     prefix    => 'myapp',
     suffix    => '.log',
     period    => 'monthly',
     size      => 25*1024*1024,
     histories => 12,
 );

 $file->log(level => 'info', message => "Your comment\n");

=head1 DESCRIPTION

This module functions similarly to L<Log::Dispatch::FileRotate>, but uses
L<File::Write::Rotate> as backend, thus interoperates more easily with other
modules which use File::Write::Rotate as backend, e.g.
L<Tie::Handle::FileWriteRotate> or L<Process::Govern>.

=head1 METHODS

=head2 new(%args)

Constructor. This method takes a hash of parameters. The following options are
valid: C<min_level> and C<max_level> (see L<Log::Dispatch> documentation);
C<dir>, C<prefix>, C<suffix>, C<period>, C<size>, and C<histories> (see
L<File::Write::Rotate>).

=head2 log_message(message => STR)

Send a message to the appropriate output. Generally this shouldn't be called
directly but should be called through the C<log()> method (in
LLog::Dispatch::Output>).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-Dispatch-FileWriteRotate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-Dispatch-FileWriteRotate>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Dispatch-FileWriteRotate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::Dispatch>

L<File::Write::Rotate>

L<Log::Dispatch::FileRotate>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2015, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
