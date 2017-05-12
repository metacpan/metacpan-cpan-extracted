package Hook::Output::File;

use strict;
use warnings;
use boolean qw(true false);

use Carp qw(croak);
use File::Spec ();
use Params::Validate ':all';
use Scalar::Util qw(blessed);

our $VERSION = '0.08';

validation_options(
    on_fail => sub
{
    my ($error) = @_;
    chomp $error;
    croak $error;
},
    stack_skip => 2,
);

sub redirect
{
    my $class = shift;
    croak 'Invoke with ' . __PACKAGE__ . "->redirect(...)\n"
      if defined blessed $class || $class ne __PACKAGE__;
    _validate(@_);
    my %opts = @_;

    my @keys   = keys   %opts;
    my @values = values %opts;
    delete @opts{@keys};
    @opts{map uc, @keys} = @values;

    my %streams = map {
        $_ => (exists $opts{$_} && defined $opts{$_}) ? true : false
    } qw(STDOUT STDERR);

    my %paths;
    foreach my $stream (grep $streams{$_}, qw(STDOUT STDERR)) {
        $paths{$stream} = File::Spec->rel2abs($opts{$stream});
    }

    my ($old_out, $old_err);

    if ($streams{'STDOUT'}) {
        open($old_out, '>&', STDOUT)         or croak "Cannot duplicate STDOUT: $!";
        open(STDOUT, '>>', $paths{'STDOUT'}) or croak "Cannot redirect STDOUT: $!";

        my $ofh = select STDOUT;
        $| = true;
        select $ofh;
    }
    if ($streams{'STDERR'}) {
        open($old_err, '>&', STDERR)         or croak "Cannot duplicate STDERR: $!";
        open(STDERR, '>>', $paths{'STDERR'}) or croak "Cannot redirect STDERR: $!";

        my $ofh = select STDERR;
        $| = true;
        select $ofh;
    }

    my %handles;
    $handles{'STDOUT'} = $old_out if $streams{'STDOUT'};
    $handles{'STDERR'} = $old_err if $streams{'STDERR'};

    return bless { handles => { %handles } }, $class;
}

sub _validate
{
    validate(@_, {
        stdout => {
            type => UNDEF | SCALAR,
            optional => true,
        },
        stderr => {
            type => UNDEF | SCALAR,
            optional => true,
        },
    });

    my %opts = @_;

    croak <<'EOT'
Hook::Output::File->redirect(stdout => 'file1',
                             stderr => 'file2');
EOT
      if not defined $opts{stdout}
          || defined $opts{stderr};
}

DESTROY
{
    my $self = shift;

    return unless blessed $self eq __PACKAGE__;

    my %handles = %{$self->{handles}};

    if (exists $handles{'STDOUT'}) {
        close(STDOUT);
        open(STDOUT, '>&', $handles{'STDOUT'}) or croak "Cannot restore STDOUT: $!";
        close($handles{'STDOUT'});
    }
    if (exists $handles{'STDERR'}) {
        close(STDERR);
        open(STDERR, '>&', $handles{'STDERR'}) or croak "Cannot restore STDERR: $!";
        close($handles{'STDERR'});
    }
}

1;
__END__

=head1 NAME

Hook::Output::File - Redirect STDOUT/STDERR to a file

=head1 SYNOPSIS

 use Hook::Output::File;

 {
     my $hook = Hook::Output::File->redirect(
         stdout => '/tmp/1.out',
         stderr => '/tmp/2.out',
     );

     saved();

     undef $hook; # restore previous state of streams

     not_saved();
 }

 sub saved {
     print STDOUT "..."; # STDOUT output is appended to file
     print STDERR "..."; # STDERR output is appended to file
 }

 sub not_saved {
     print STDOUT "..."; # STDOUT output goes to STDOUT (not to file)
     print STDERR "..."; # STDERR output goes to STDERR (not to file)
 }

=head1 DESCRIPTION

C<Hook::Output::File> redirects C<STDOUT/STDERR> to a file.

=head1 METHODS

=head2 redirect

 my $hook = Hook::Output::File->redirect(
     stdout => $stdout_file,
     # and/or
     stderr => $stderr_file,
 );

Installs a file-redirection hook for regular output streams (i.e.,
C<STDOUT/STDERR>) with lexical scope.

A word of caution: do not intermix the file paths for C<STDOUT/STDERR>
output or you will eventually receive unexpected results. The paths
may be relative or absolute; if no valid path is provided, an usage
help will be printed (because otherwise, the C<open()> call might
silently fail to satisfy expectations).

The hook may be uninstalled either explicitly or implicitly; doing it
the explicit way requires to unset the hook variable (more concisely,
it is a blessed object), whereas the implicit end of the hook will
automatically be triggered when leaving the scope the hook was
defined in.

 {
     my $hook = Hook::Output::File->redirect(
         stdout => '/tmp/1.out',
         stderr => '/tmp/2.out',
     );

     some_sub();

     undef $hook; # explicitly remove hook

     another_sub();
 }
 ... # hook implicitly removed

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
