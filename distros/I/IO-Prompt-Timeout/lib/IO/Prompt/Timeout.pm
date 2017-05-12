package IO::Prompt::Timeout;
use 5.008001;
use strict;
use warnings;

use IO::Select;

use parent qw(Exporter);
our @EXPORT_OK = qw(prompt has_prompt_timed_out);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use Carp ();

our $VERSION = "0.04";

my $HAS_TIMED_OUT;
my $DEFAULT_TIMEOUT_SEC = 60;

sub prompt {
    my $message = shift;
    unless ($message) {
        Carp::croak(q["prompt" called without any argument!]);
    }

    # Clear timeout info.
    undef $HAS_TIMED_OUT;

    my %opt = _parse_args(@_);

    my $isa_tty = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ;

    my $default_answer = exists $opt{default_answer} ? $opt{default_answer} : q{};
    my $dispdef = $default_answer ? "[$default_answer]" : q{ };

    local $| = 1;
    local $\;
    print "$message $dispdef";

    my $answer;
    if ($ENV{PERL_IOPT_USE_DEFAULT} || (!$isa_tty && eof STDIN)) {
        print "$default_answer\n";
    } else {
        my $timeout = $opt{timeout} || $DEFAULT_TIMEOUT_SEC;
        my $is = IO::Select->new;
        $is->add(\*STDIN);
        if (my @readable = $is->can_read($timeout)) {
            my $stdin = shift @readable;
            $answer = <$stdin>;
        } else {
            $HAS_TIMED_OUT = 1;
        }

        if (defined $answer) {
            chomp $answer;
        } else {
            # User hit ctrl-D
            # Or timed out.
            print "\n";
        }
    }

    $answer = defined $answer ? $answer : q{};
    return $answer || $default_answer;
}

sub has_prompt_timed_out { $HAS_TIMED_OUT; }

sub _parse_args {
    my %args = @_;
    return (
        default_answer => $args{default} || q{},
        timeout        => $args{timeout},
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

IO::Prompt::Timeout - Simple prompt interface with timeout.

=head1 SYNOPSIS

    use IO::Prompt::Timeout qw(:all);
    my $answer = prompt('Yes or No? (y/n)', %option);
    my $is_timeout = has_prompt_timed_out();

    # Specifying timeout seconds
    my $answer = prompt('Yes or No? (y/n) Answer in 10 seconds.', timeout => 10);

    # Specifying default answer
    my $answer = prompt('Yes or No? (y/n)', default => 'n');

=head1 DESCRIPTION

B<IO::Prompt::Timeout> provides I<prompt> subroutine most of which comes from
L<ExtUtils::MakeMaker>.

It also has timeout feature just like L<Prompt::Timeout>.
The default timeout seconds is 60. When prompt timed out, the default answer
can be taken when it's set by option.

Unlike Prompt::Timeout, this module uses L<IO::Select> for timeout procedure.
The function of clearing timer by a single key click is not supported which is
implemented in Prompt::Timeout.

=head1 SUBROUTINES

=head2 prompt : Answer(SCALAR)

Show prompt and returns the answer by user's input.

=head2 has_prompt_timed_out : BOOL

Called after a I<prompt> call.
Returns if I<prompt> subroutine has timed out or not.

=head1 ENVIRONMENT VARIABLES

=over 4

=item B<$ENV{PERL_IOPT_USE_DEFAULT}>

If set true, I<prompt> will always return the default answer without waiting for
user input.

=back

=head1 SEE ALSO

L<ExtUtils::MakeMaker>,
L<IO::Prompt::Tiny>,
L<Prompt::Timeout>,
L<IO::Select>

=head1 LICENSE

Copyright (C) YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=cut

