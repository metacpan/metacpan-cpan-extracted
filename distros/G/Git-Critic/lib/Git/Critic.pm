package Git::Critic;

# ABSTRACT: Only run Perl::Critic on lines changed in the current branch
use v5.10.0;
use strict;
use warnings;
use autodie ":all";

use Capture::Tiny 'capture_stdout';
use Carp;
use File::Basename 'basename';
use File::Temp 'tempfile';
use List::Util 1.44 qw(uniq);
use Moo;
use Types::Standard qw( ArrayRef Bool Int Str);

our $VERSION = '0.6';

#
# Moo attributes
#

has primary_target => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has current_target => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_current_target',
);

has max_file_size => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);

has severity => (
    is      => 'ro',
    isa     => Int | Str,
    default => 5,
);

has profile => (
    is      => 'ro',
    isa     => Str,
    default => '',
);

has verbose => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

# this is only for tests
has _run_test_queue => (
    is       => 'ro',
    isa      => ArrayRef,
    default  => sub { [] },
    init_arg => undef,
);

#
# Builders
#

sub _build_current_target {
    my $self = shift;
    return $self->_run( 'git', 'rev-parse', '--abbrev-ref', 'HEAD' );
}

#
# The following methods are for the tests
#

# return true if we have any data in our test queue
sub _run_queue_active {
    my $self = shift;
    return scalar @{ $self->_run_test_queue };
}

sub _add_to_run_queue {
    my ( $self, $result ) = @_;
    push @{ $self->_run_test_queue } => $result;
}

sub _get_next_run_queue_response {
    my $self = shift;
    shift @{ $self->_run_test_queue };
}

#
# These call system commands
#

# if we have a response added to the run queue via _add_to_run_queue, return
# that instead of calling the system command. Let it die if the system command
# fails

sub _run {
    my ( $self, @command ) = @_;
    if ( $self->_run_queue_active ) {
        return $self->_get_next_run_queue_response;
    }

    if ( $self->verbose ) {
        say STDERR "Running command: @command";
    }

    # XXX yeah, this needs to be more robust
    chomp( my $result = capture_stdout { system(@command) } );
    return $result;
}

# same as _run, but don't let it die
sub _run_without_die {
    my ( $self, @command ) = @_;
    if ( $self->verbose ) {
        say STDERR "Running command: @command";
    }
    chomp(
        my $result = capture_stdout {
            no autodie;
            system(@command);
        }
    );
    return $result;
}

# get Perl files which have been changed in the current branch
sub _get_modified_perl_files {
    my $self           = shift;
    my $primary_target = $self->primary_target;
    my $current_target = $self->current_target;
    my @files          = uniq sort grep { /\S/ && $self->_is_perl($_) }
      split /\n/ => $self->_run( 'git', 'diff', '--name-only',
        "$primary_target...$current_target" );
    return @files;
}

# get the diff of the current file
sub _get_diff {
    my ( $self, $file ) = @_;
    my $primary_target = $self->primary_target;
    my $current_target = $self->current_target;
    my @diff =
      split /\n/ =>
      $self->_run( 'git', 'diff', "$primary_target...$current_target", $file );
    return @diff;
}

# remove undefined arguments. This makes a command line
# script easier to follow
around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;

    my $arg_for = $class->$orig(@args);
    foreach my $arg ( keys %$arg_for ) {
        if ( not defined $arg_for->{$arg} ) {
            delete $arg_for->{$arg};
        }
    }
    return $arg_for;
};

sub run {
    my $self = shift;

    my $primary_target = $self->primary_target;
    my $current_target = $self->current_target;
    if ( $primary_target eq $current_target ) {

        # in the future, we might want to allow you to check the primary
        # branch X commits back
        return;
    }

    # We walking through every file you've changed and parse the diff to
    # figure out the start and end of every change you've made. Any perlcritic
    # failures which are *not* on those lines are ignored
    my @files = $self->_get_modified_perl_files;
    my @failures;
  FILE: foreach my $file (@files) {
        my %reported;

        my $file_text = $self->_run( 'git', 'show', "${current_target}:$file" )
          or next FILE;
        if ( $self->max_file_size ) {
            # we want the length in bytes, not characters
            use bytes;
            next FILE
              unless length($file_text) <= $self->max_file_size;    # large files are very slow
        }

        my ($fh, $filename) = tempfile();
        print $fh $file_text;
        close $fh;
        my $severity = $self->severity;
        my $profile = $self->profile;
        my @arguments = ("--severity=$severity");
        push @arguments, "--profile=$profile" if $profile;
        push @arguments, $filename;
        my $critique =
          $self->_run_without_die( 'perlcritic', @arguments );
        next FILE unless $critique; # should never happen unless perlcritic dies
        my @critiques = split /\n/, $critique;

        # unified diff format
        # @@ -3,8 +3,9 @@ 
        # @@ from-file-line-numbers to-file-line-numbers @@
        my @chunks = map {
            /^ \@\@\s+ -\d+,\d+\s+
                    \+(?<start>\d+)
                    ,(?<lines>\d+)
               \s+\@\@/xs
              ? [ $+{start}, $+{start} + $+{lines} ]
              : ()
        } $self->_get_diff($file);
        my $max_line_number = $chunks[-1][-1];
      CRITIQUE: foreach my $this_critique (@critiques) {
            next CRITIQUE if $this_critique =~ / source OK$/;
            $this_critique =~ /\bline\s+(?<line_number>\d+)/;
            unless ( defined $+{line_number} ) {
                warn "Could not find line number in critique $this_critique";
                next;
            }

            # no need to keep processing
            last CRITIQUE if $+{line_number} > $max_line_number;

            foreach my $chunk (@chunks) {
                my ( $min, $max ) = @$chunk;
                if ( $+{line_number} >= $min && $+{line_number} <= $max ) {
                    unless ($reported{$this_critique}) {
                        push @failures => "$file: $this_critique"
                    }
                    $reported{$this_critique}++;
                    next CRITIQUE;
                }
            }
        }
    }
    return @failures;
}

# a heuristic to determine if the file in question is Perl. We might allow
# a client to override this in the future
sub _is_perl {
    my ( $self, $file ) = @_;
    return unless -e $file;    # sometimes we get non-existent files
    return 1 if $file =~ /\.(?:p[ml]|t)$/;

    # if we got to here, let's check to see if "perl" is in a shebang
    open my $fh, '<', $file;
    my $first_line = <$fh>;
    close $fh;
    if ( $first_line =~ /^#!.*\bperl\b/ ) {
        say STDERR "Found changed Perl file: $file" if $self->verbose;
        return $file;
    }
    return;
}

# vim: filetype=perl

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Critic - Only run Perl::Critic on lines changed in the current branch

=head1 VERSION

version 0.6

=head1 SYNOPSIS

    my $critic = Git::Critic->new( primary_target => 'main' );
    my @critiques = $critic->run;
    say foreach @critiques;

=head1 DESCRIPTION

Running L<Perl::Critic|https://metacpan.org/pod/Perl::Critic> on legacy code
is often useless. You're flooded with tons of critiques, even if you use the
gentlest critique level. This module lets you only report C<Perl::Critic>
errors on lines you've changed in your current branch.

=head1 COMMAND LINE

We include a C<git-perl-critic> command line tool to make this easier. You
probably want to check those docs instead.

=head1 CONSTRUCTOR ARGUMENTS

=head2 C<primary_target>

This is the only required argument.

This is the branch or commit SHA-1 you will diff against. Usually it's C<main>,
C<master>, C<development>, and so on, but you may specify another branch name
if you prefer.

=head2 C<current_target>

Optional.

This is the branch or commit SHA-1 you wish to critique. Defaults to the
currently checked out branch.

=head2 C<max_file_size>

Optional.

Positive integer representing the max file size of file you wish to critique.
C<Perl::Critic> can be slow on large files, so this can speed things up by
passing a value, but at the cost of ignoring some C<Perl::Critic> failures.

=head2 C<severity>

Optional.

This is the C<Perl::Critic> severity level. You may pass a string or an integer. If omitted, the
default severity level is "gentle" (5).

    SEVERITY NAME   ...is equivalent to...   SEVERITY NUMBER
    --------------------------------------------------------
    -severity => 'gentle'                     -severity => 5
    -severity => 'stern'                      -severity => 4
    -severity => 'harsh'                      -severity => 3
    -severity => 'cruel'                      -severity => 2
    -severity => 'brutal'                     -severity => 1

=head2 C<profile>

Optional.

This is a filepath to a C<Perl::Critic> configuration file.

=head2 C<verbose>

Optional.

If passed a true value, will print messages to C<STDERR> explaining various things the
module is doing. Useful for debugging.

=head1 METHODS

=head2 C<run>

    my $critic = Git::Critic->new(
        primary_target => 'main' 
        current_target => 'my-development-branch',
        severity       => 'harsh',
        max_file_size  => 20_000,
    );
    my @critiques = $critic->run;
    say foreach @critiques;

Returns a list of all C<Perl::Critic> failures in changed lines in the current branch.

If the current branch and the primary branch are the same, returns nothing.
This may change in the future.

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
