use 5.008003;
use strict;
use warnings;

package IPC::Run::Fused;

our $VERSION = '1.000001';

# ABSTRACT: Capture Stdout/Stderr simultaneously as if it were one stream, painlessly.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY







































































































our %FAIL_CONTEXT;

use Exporter qw(import);
sub run_fused;
our @EXPORT_OK = qw( run_fused _fail );

sub _stringify {
  my ($entry) = @_;
  return 'undef' if not defined $entry;
  return qq{`$entry`};
}

sub _fail {    ## no critic (Subroutines::RequireArgUnpacking)
  my (@message) = @_;
  my $errors = {
    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    q[$?]  => _stringify($?),
    q[$!]  => _stringify($!),
    q[$^E] => _stringify($^E),
    q[$@]  => _stringify($@),
    ( map { $_ => _stringify( $FAIL_CONTEXT{$_} ) } keys %FAIL_CONTEXT ),
  };
  my $message = q[];
  $message .= qq{\n} . $_ for @message;
  $message .= sprintf qq{\n\t%s => %s}, $_, $errors->{$_} for sort keys %{$errors};
  $message .= qq{\n};
  require Carp;
  @_ = $message;
  goto \&Carp::confess;
}

sub _win32_run_fused {
  require IPC::Run::Fused::Win32;
  goto \&IPC::Run::Fused::Win32::run_fused;
}

sub _posix_run_fused {
  require IPC::Run::Fused::POSIX;
  goto \&IPC::Run::Fused::POSIX::run_fused;
}

if ( 'MSWin32' eq $^O ) {
  *run_fused = \&_win32_run_fused;
}
else {
  *run_fused = \&_posix_run_fused;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Run::Fused - Capture Stdout/Stderr simultaneously as if it were one stream, painlessly.

=head1 VERSION

version 1.000001

=head1 SYNOPSIS

  use IPC::Run::Fused qw( run_fused );

  run_fused( my $fh, $stderror_filled_program, '--file', $tricky_filename, @moreargs ) || die "Argh $@";
  open my $fh, '>', 'somefile.txt' || die "NOO  $@";

  # Simple implementation of 'tee' like behaviour,
  # sending to stdout and to a file.

  while ( my $line = <$fh> ) {
    print $fh $line;
    print $line;
  }

=head1 DESCRIPTION

Have you ever tried to do essentially the same as you would in bash do to this:

  parentapp <( app 2>&1  )

And found massive road works getting in the way.

Sure, you can always do this style syntax:

  open my $fh, 'someapp --args foo 2>&1 |';

But that's not very nice, because

=over 4

=item 1. you're relying on a sub-shell to do that for you

=item 2. you have to manually escape everything

=item 3. you can't use list context.

=back

And none of this is very B<Modern> or B<Nice>

=head1 SIMPLEST THING THAT JUST WORKS

This code is barely tested, its here, because I spent hours griping about how the existing ways suck.

=head1 FEATURES

=over 4

=item 1. No String Interpolation.

Arguments after the first work as if you'd passed them directly to 'system'. You can be as dangerous or as
safe as you want with them. We recommend passing a list, but a string ( as a scalar reference ) should work

But if you're using a string, this modules probably not affording you much.

=item 2. No dicking around with managing multiple file handles yourself.

I looked at L<< C<IPC::Run>|IPC::Run >>, L<< C<IPC::Run3>|IPC::Run3 >> and L<< C<IPC::Open3>|IPC::Open3 >>, and they all seemed
very unfriendly, and none did what I wanted.

=item 3. Non-global file-handles supported by design.

All the competition seem to still have this thing for global file handles and you having to use them. Yuck!.

We have a few global file-handles inside our code, but they're only C<STDERR> and C<STDOUT>, at present I don't think I can
circumvent that. If I ever can, I'll endeavor to do so ☺

=back

=head1 EXPORTED FUNCTIONS

No functions are exported by default, be explicit with what you want.

At this time there is only one, and there are no plans for more.

=head2 run_fused

  run_fused( $fh, $executable, @params ) || die "$@";
  run_fused( $fh, \$command_string )     || die "$@";
  run_fused( $fh, sub { .. } )           || die "$@";

  # Recommended

  run_fused( my $fh, $execuable, @params ) || die "$@";

  # Somewhat supported

  run_fused( my $fh, \$command_string ) || die "$@";

$fh will be clobbered like 'open' does, and $cmd, @args will be passed, as-is, through to exec() or system().

$fh will point to an IO::Handle attached to the end of a pipe running back to the called application.

the command will be run in a fork, and C<STDERR> and C<STDOUT> "fused" into a singular pipe.

B<NOTE:> at present, C<STDIN>'s file-descriptor is left unchanged, and child processes will inherit parent C<STDIN>'s, and will thus block ( somewhere ) waiting for response.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
