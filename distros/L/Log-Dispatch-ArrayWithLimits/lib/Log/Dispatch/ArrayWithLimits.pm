package Log::Dispatch::ArrayWithLimits;

use 5.010001;
use warnings;
use strict;

use parent qw(Log::Dispatch::Output);

our $DATE = '2015-01-03'; # DATE
our $VERSION = '0.04'; # VERSION

sub new {
    my ($class, %args) = @_;
    my $self = {};
    $self->{array} = $args{array} // [];
    if (!ref($self->{array})) {
        no strict 'refs';
        say "$self->{array}";
        $self->{array} = \@{"$self->{array}"};
    }
    $self->{max_elems} = $args{max_elems} // undef;
    bless $self, $class;
    $self->_basic_init(%args);
    $self;
}

sub log_message {
    my $self = shift;
    my %args = @_;

    push @{$self->{array}}, $args{message};

    if (defined($self->{max_elems}) && @{$self->{array}} > $self->{max_elems}) {
        # splice() is not supported for threads::shared-array, so we use
        # repeated shift
        while (@{$self->{array}} > $self->{max_elems}) {
            shift @{$self->{array}};
        }
    }
}

1;
# ABSTRACT: Log to array, with some limits applied

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::ArrayWithLimits - Log to array, with some limits applied

=head1 VERSION

This document describes version 0.04 of Log::Dispatch::ArrayWithLimits (from Perl distribution Log-Dispatch-ArrayWithLimits), released on 2015-01-03.

=head1 SYNOPSIS

 use Log::Dispatch::ArrayWithLimits;

 my $file = Log::Dispatch::ArrayWithLimits(
     min_level     => 'info',
     array         => $ary,    # default: [], you can always refer by name e.g. 'My::array' to refer to @My::array
     max_elems     => 100,     # defaults unlimited
 );

 $file->log(level => 'info', message => "Your comment\n");

=head1 DESCRIPTION

This module functions similarly to L<Log::Dispatch::Array>, with a few
differences:

=over

=item * only the messages (strings) are stored

=item * allow specifying array variable name (e.g. "My::array" instead of \@My:array)

This makes it possible to use in L<Log::Log4perl> configuration, which is a text
file.

=item * can apply some limits

Currently only max_elems (the maximum number of elements in the array) is
available. Future limits will be added.

=back

Logging to an in-process array can be useful when debugging/testing, or when you
want to let users of your program connect to your program to request viewing the
ogs being produced.

=head1 METHODS

=head2 new(%args)

Constructor. This method takes a hash of parameters. The following options are
valid: C<min_level> and C<max_level> (see L<Log::Dispatch> documentation);
C<array> (a reference to an array, or if value is string, will be taken as name
of array variable; this is so this module can be used/configured e.g. by
L<Log::Log4perl> because configuration is specified via a text file),
C<max_elems>.

=head2 log_message(message => STR)

Send a message to the appropriate output. Generally this shouldn't be called
directly but should be called through the C<log()> method (in
LLog::Dispatch::Output>).

=head1 SEE ALSO

L<Log::Dispatch>

L<Log::Dispatch::Array>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-Dispatch-ArrayWithLimits>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Log-Dispatch-ArrayWithLimits>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Dispatch-ArrayWithLimits>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
