package Devel::StackTrace::WithLexicals;
use strict;
use warnings;
use 5.008001;
use base 'Devel::StackTrace';

use Devel::StackTrace::WithLexicals::Frame;

use PadWalker 'peek_my';

our $VERSION = '2.01';

# mostly copied from Devel::StackTrace 2.00
sub _record_caller_data {
    my $self = shift;

    my $filter = $self->{filter_frames_early} && $self->_make_frame_filter();

    # We exclude this method by starting at least one frame back.
    my $x = 1 + ( $self->{skip_frames} || 0 );

    # PadWalker ignores eval block and eval string, so we have to keep
    # a different frame count for it
    my $walker = 0;
    for my $caller_count (0..$x) {
        my $sub = (caller($caller_count))[3];
        ++$walker unless $sub eq '(eval)';
    }

    while (
        my @c
        = $self->{no_args}
        ? caller( $x++ )
        : do {
            package    # the newline keeps dzil from adding a version here
                DB;
            @DB::args = ();
            caller( $x++ );
        }
        ) {

        my @args;

        @args = $self->{no_args} ? () : @DB::args;

        my $raw = {
            caller => \@c,
            args   => \@args,
        };

        my $sub = $c[3];
        if ($sub ne '(eval)') {
            $raw->{lexicals} = peek_my($walker++);
        }

        next if $filter && !$filter->($raw);

        unless ( $self->{unsafe_ref_capture} ) {
            $raw->{args} = [ map { ref $_ ? $self->_ref_to_string($_) : $_ }
                    @{ $raw->{args} } ];
            for (values %{ $raw->{lexicals} }) {
                $_ = $$_ if ref($_) eq 'REF';
                $_ = $self->_ref_to_string($_);
            }
        }

        push @{ $self->{raw} }, $raw;
    }
}

sub _frame_class { "Devel::StackTrace::WithLexicals::Frame" }

sub _make_frames {
    my $self = shift;

    my $filter = !$self->{filter_frames_early} && $self->_make_frame_filter();

    my $raw = delete $self->{raw};
    for my $r ( @{$raw} ) {
        next if $filter && !$filter->($r);

        $self->_add_frame( $r->{caller}, $r->{args}, $r->{lexicals} );
    }
}

sub _add_frame {
    my $self = shift;
    my $c    = shift;
    my $p    = shift;
    my $lexicals = shift;

    # eval and is_require are only returned when applicable under 5.00503.
    push @$c, ( undef, undef ) if scalar @$c == 6;

    push @{ $self->{frames} },
        $self->_frame_class->new(
        $c,
        $p,
        $self->{respect_overload},
        $self->{max_arg_length},
        $self->{message},
        $self->{indent},
        $lexicals,
        );
}


1;

__END__

=head1 NAME

Devel::StackTrace::WithLexicals - Devel::StackTrace + PadWalker

=head1 SYNOPSIS

    use Devel::StackTrace::WithLexicals;

    sub process_user {
        my $item_count = 20;
        price_items();
        print "$item_count\n";    # prints 21
    }

    sub price_items {
        my $trace = Devel::StackTrace::WithLexicals->new(
            unsafe_ref_capture => 1    # warning: can cause memory leak
        );
        while ( my $frame = $trace->next_frame() ) {
            my $item_count_ref = $frame->lexical('$item_count');
            ${$item_count_ref}++ if ref $item_count_ref eq 'SCALAR';
        }
    }

    process_user();

=head1 DESCRIPTION

L<Devel::StackTrace> is pretty good at generating stack traces.

L<PadWalker> is pretty good at the inspection and modification of your callers'
lexical variables.

L<Devel::StackTrace::WithLexicals> is pretty good at generating stack traces
with all your callers' lexical variables.

=head1 METHODS

All the same as L<Devel::StackTrace>, except that frames (in class
L<Devel::StackTrace::WithLexicals::Frame>) also have a C<lexicals> method. This
returns the same hashref as returned by L<PadWalker>.

Unless the C<unsafe_ref_capture> option to L<Devel::StackTrace> is
used, then each reference is stringified. This can be useful to avoid
leaking memory.

Simple, really.

=head1 AUTHOR

Shawn M Moore, C<sartak@gmail.com>

=head1 BUGS

I had to copy and paste some code from L<Devel::StackTrace> to achieve this
(it's hard to subclass). There may be bugs lingering here.

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Shawn M Moore.

Some portions written by Dave Rolsky, they belong to him.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

