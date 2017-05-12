use 5.006;
use strict;
use warnings;

=head1 NAME

EJS::Template::IO - Mix-in module to normalize input/output parameters for EJS::Template

=cut

package EJS::Template::IO;

use IO::Scalar;
use Scalar::Util qw(openhandle);

=head1 Methods

=head2 input

Normalizes input.

    $self->input('filepath.ejs');
    $self->input(\$source_text);
    $self->input($input_handle);
    $self->input(\*STDIN);

It returns a list in the form C<($input, $should_close)>, where C<$input> is
the normalized input handle and C<$should_close> indicates the file handle has
been opened and your code is responsible for closing it.

Alternatively, a callback can be given as the second argument, which will be invoked
with its argument set to the normalized C<$input>.

    $self->input('filepath.ejs', sub {
        my ($input) = @_;
        while (<$input>) {
            ...
        }
    });

If C<$input> is a file handle that has been opened by this C<input()> method, then
it will be closed automatically after the callback returns.
Even if C<die()> is invoked within the callback, the file handle will be closed if
necessary, and then this C<input()> method will forward C<die($@)>.

=cut

sub input {
    my ($self, $input, $callback) = @_;
    
    my $in;
    my $should_close = 0;
    
    if (!defined $input && defined $self->{in}) {
        $input = $self->{in};
    }
    
    if (defined $input) {
        if (openhandle($input)) {
            $in = $input;
        } elsif (ref $input) {
            $in = IO::Scalar->new($input);
            $should_close = 1;
        } else {
            open $in, $input or die "$!: $input";
            $should_close = 1;
        }
    } else {
        $in = \*STDIN;
    }
    
    if ($callback) {
        eval {
            local $self->{in} = $in;
            $callback->($in);
        };

        my $e = $@;
        close $in if $should_close;
        die $e if $e;
    } else {
        return ($in, $should_close);
    }
}

=head2 output

Normalizes output.

   $self->output('filepath.out');
   $self->output(\$result_text);
   $self->output($output_handle);
   $self->output(\*STDOUT);

It returns a list in the form C<($output, $should_close)>, where C<$output> is
the normalized output handle and C<$should_close> indicates the file handle has
been opened and your code is responsible for closing it.

Alternatively, a callback can be given as the second argument, which will be invoked
with its argument set to the normalized C<$output>.

    $self->output('filepath.out', sub {
        my ($output) = @_;
        while (<$output>) {
            ...
        }
    });

If C<$output> is a file handle that has been opened by this C<output()> method, then
it will be closed automatically after the callback returns.
Even if C<die()> is invoked within the callback, the file handle will be closed if
necessary, and then this C<output()> method will forward C<die($@)>.

=cut

sub output {
    my ($self, $output, $callback) = @_;
    
    my $out;
    my $should_close = 0;

    if (!defined $output && defined $self->{out}) {
        $output = $self->{out};
    }
    
    if (defined $output) {
        if (openhandle $output) {
            $out = $output;
        } elsif (ref $output) {
            $$output = '';
            $out = IO::Scalar->new($output);
            $should_close = 1;
        } else {
            open($out, '>', $output) or die "$!: $output";
            $should_close = 1;
        }
    } else {
        $out = \*STDOUT;
    }
    
    if ($callback) {
        eval {
            local $self->{out} = $out;
            $callback->($out);
        };

        my $e = $@;
        close $out if $should_close;
        die $e if $e;
    } else {
        return ($out, $should_close);
    }
}

=head2 print

Prints text to the current output target.

It can be invoked only within an execution context where the output file handle is open.

    $self->output('filepath.out', sub {
        $self->print(...);
    });

=cut

sub print {
    my $self = shift;
    my $out = $self->{out};

    unless ($out) {
        die "print() can be invoked only within an execution context where the output file handle is open";
    }

    print $out $_ for @_;
}

=head1 SEE ALSO

=over 4

=item * L<EJS::Template>

=back

=cut

1;
