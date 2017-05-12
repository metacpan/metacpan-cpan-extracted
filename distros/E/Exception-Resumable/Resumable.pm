package Exception::Resumable;

=head1 NAME

Exception::Resumable -- resumable exceptions for Perl.

=head1 SYNOPSIS

    use Exception::Resumable;
    handle {
        ...
        raise $exception, @args;
        ...
    } exception_1 => sub { ...; return $value_to_use },
      qr/exception_2/ => sub { ...; raise $new_exception, @args },
      [qw(exception_3 exception_4)] => $value_to_use,
      { exception_5 => 1, exception_6 => 1 } => sub { ... };

=cut

$VERSION = '0.91';

require Exporter;
@ISA = 'Exporter';
@EXPORT = qw(handle raise);

sub handle(&@)
{
    my $body = shift;
    local @LAST_CATCH = @CATCH;
    local @CATCH = (@_, @CATCH);
    local (@_);
    if (wantarray) {
        my @ret = eval { $body->() };
        if ($@) {
            raise(ref($@) eq 'ARRAY' ? @{$@} : $@);
        } else {
            @ret;
        }
    } else {
        my $ret = eval { $body->() };
        if ($@) {
            raise(ref($@) eq 'ARRAY' ? @{$@} : $@);
        } else {
            $ret;
        }
    }
}

my $test;
if ($] < 5.010) {
    $test = <<'EOS';
              (ref $k eq 'CODE')
            ? $k->($err)
            : (ref $k eq 'Regexp')
            ? $err =~ /$k/
            : (ref $k eq 'ARRAY')
            ? grep { $_ eq $err } @$k
            : (ref $k eq 'HASH')
            ? exists $k->{$err}
            : $k eq $err
EOS
} else {
    $test = '$err ~~ $k';
}
eval q#
sub raise(*@)
{
    my $err = shift;
    my @c = @CATCH;
    local @CATCH = @LAST_CATCH;
    while (@c) {
        my ($k, $v) = splice @c, 0, 2;
        my $ok = # . $test . q#;
        return ref($v) eq 'CODE' ? $v->(@_) : $v if $ok;
    }
    die $err, @_;
}

sub test_raise(*)
{
    my $err = shift;
    my @c = @CATCH;
    local @CATCH = @LAST_CATCH;
    while (@c) {
        my ($k, $v) = splice @c, 0, 2;
        my $ok = # . $test . q#;
        return $k, $v if $ok;
    }
    return undef;
}
#;

1;
__END__

=head1 DESCRIPTION

This module implements a basic version of "resumable exceptions."
This means that a dynamically-bound handling function is called before
the stack is unwound, rather than afterwards (like C<die>).  The
appropriate handler is found by looking (in order) at
C<@Exception::Resumable::CATCH>.  If no appropriate handler is found,
C<die> is called instead.

=begin comment

An exception handler is a subroutine that receives the arguments to
C<raise>.  It should either return a value to be used, or re-raise an
appropriate exception.

=end comment

Why would you want to do this?  Perl's standard C<eval/die> exception
handling limits what you can do when something goes wrong: by the time
you get control again after something dies, the stack has already been
unwound to your C<eval>.  If you want to fix the problem and continue,
you have to get back to where the code died.

Sometimes this is fine: if your web server encountered a network
error, you probably want to clean up the connection and wait for the
user to hit "reload."  However, sometimes it's easier to fix the
problem right there and keep going: if a function receives invalid
input, you may want to ask the user for a better answer and continue.

=head2 C<handle BLOCK HANDLERS...>

Handle exceptions from within C<BLOCK> using C<HANDLERS>, a list of
key/value pairs.  The handlers defined by a C<handle> block are B<not>
active while they are called, so re-raising the same exception will
not cause an infinite loop.  A handler value may be either a function,
which will be called with the arguments passed to C<raise>, or a
scalar, which will be returned as-is.

On Perls older than 5.10, the key may be one of the following:

=over

=item C<\@ARRAY>

Catch the exception if it is (C<eq> to) a member of C<@ARRAY>.

=item C<\%HASH>

Catch the exception if it is a key in C<%HASH>.

=item C<qr/REGEXP/>

Catch the exception if it matches C<REGEXP>.

=item C<$SCALAR>

Catch the exception if it is C<eq> to C<$SCALAR>.

=back

On Perl 5.10 and newer, the key may be any scalar that can go on the
right side of a "smart match".

=head2 C<raise NAME, DETAILS...>

Raise exception C<NAME> with detailed information C<DETAILS>.

=head2 C<test_raise NAME>

See what would happen if you raise C<NAME>.  Return the C<$key,
$value> that would have handled C<NAME>, or C<undef> if it would have
died.

=head1 EXAMPLE

Say you have a program that watches some log files.  If one of the
files disappears all of a sudden, and it is running interactively, it
can ask the user to point it in the right direction.  If not, it
should just die:

    sub process_file
    {
        my $file = shift;
        if (!-f $file) {
            $file = raise "Missing file", $file;
        }
        # do stuff, now that we know $file is valid
    }
    
    sub get_a_file
    {
        print "Use what for $_[0]? "; chomp(my $f = <STDIN>);
        $f = raise "Missing file", $f unless -f $f;
        $f;
    }
    
    sub main
    {
        handle {
            # stuff that calls process_file
        } is_interactive() ? ('Missing file' => \&get_a_file) : ();
    }

=head1 SEE ALSO

C<Exception::*> (and especially L<Try::Tiny>) on CPAN, for many, many
flavors of exception handling.  Writing exception modules seems almost
as popular as writing test modules, sudoku solvers, and Fibonacci
functions.

See also the Common Lisp Hyperspec section 9.1, "Condition System
Concepts" and Common Lisp the Language's section 29, "Conditions."
Both are available online, and describe the error-handling model
partially emulated here.

=head1 AUTHOR

Sean O'Rourke, E<lt>seano@cpan.orgE<gt>

Bug reports welcome, patches even more welcome.

=head1 COPYRIGHT

Copyright (C) 2007-2011 Sean O'Rourke.  All rights reserved, some
wrongs reversed.  This module is distributed under the same terms as
Perl itself.

=cut
