package Devel::Chitin::Eval;

use strict;
use warnings;

our $VERSION = '0.12';

# Count how many stack frames we should discard when we're
# interested in the debugged program's stack frames
sub _first_program_frame {
    for(my $level = 1;
        my ($package, $filename, $line, $subroutine) = caller($level);
        $level++
    ) {
        if ($subroutine eq 'DB::DB') {
            return $level;
        }
    }
    return;
}


package DB;

our($single, $trace, $usercontext, @saved);

# Needs to live in package DB because of the way eval works.
# when run on package DB, it searches back for the first stack
# frame that's _not_ package DB, and evaluates the expr there.

sub _eval_in_program_context {
    my($eval_string, $wantarray, $cb) = @_;

    local($^W) = 0;  # no warnings

    my $eval_result;
    {
        # Try to keep the user code from messing  with us. Save these so that
        # even if the eval'ed code changes them, we can put them back again.
        # Needed because the user could refer directly to the debugger's
        # package globals (and any 'my' variables in this containing scope)
        # inside the eval(), and we want to try to stay safe.
        my $orig_trace   = $trace;
        my $orig_single  = $single;
        my $orig_cd      = $^D;

        # Untaint the incoming eval() argument.
        { ($eval_string) = $eval_string =~ /(.*)/s; }

        # Fill in the appropriate @_
        () = caller(Devel::Chitin::Eval::_first_program_frame() );
        #@_ = @DB::args;
        my $do_eval = sub { eval "$usercontext $eval_string;\n" };

        if ($wantarray) {
            #my @eval_result = eval "$usercontext $eval_string;\n";
            my @eval_result = $do_eval->(@DB::args);
            $eval_result = \@eval_result;
        } elsif (defined $wantarray) {
            #$eval_result = eval "$usercontext $eval_string;\n";
            $eval_result = $do_eval->(@DB::args);
        } else {
            #eval "$usercontext $eval_string;\n";
            $do_eval->(@DB::args);
        }

        # restore old values
        $trace  = $orig_trace;
        $single = $orig_single;
        $^D     = $orig_cd;
    }

    my $exception = $@;  # exception from the eval
    # Since we're only saving $@, we only have to localize the array element
    # that it will be stored in.
    local $saved[0];    # Preserve the old value of $@
    eval { &DB::save };

    $cb->($eval_result, $exception) if $cb;
    return ($eval_result, $exception);
}

1;

__END__

=pod

=head1 NAME

Devel::Chitin::Eval - Implementation for Devel::Chitin::eval()

=head1 DESCRIPTION

This module is responsible for evaluating a string in the context of the
debugged program.  One idiosyncrasy in the process is that this eval is
done in the context of the closest stack frame not in package DB.  That's
why Devel::Chitin::eval() works as it does, requiring a debugger subclass
to cede control back and delivering the result via a callback.

If you can arrange for your debugger code to be in package DB, and for all
the stack frames up to the debugged program to be in package DB, then you
can call DB::_eval_in_program_context directly without the callback, and
get the result back directly.

=head1 SEE ALSO

L<Devel::Chitin>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2016, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.

