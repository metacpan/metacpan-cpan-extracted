package Git::Lint::Check::Commit;

use strict;
use warnings;

use parent 'Git::Lint::Check';

use Git::Lint::Command;

our $VERSION = '1.000';

sub diff {
    my $self = shift;

    my $diff_arref = $self->_diff_index( $self->_against );

    return $diff_arref;
}

sub _against {
    my $self = shift;

    my @git_head_cmd = (qw{ git show-ref --head });

    my $against;
    my ( $stdout, $stderr, $exit ) = Git::Lint::Command::run( \@git_head_cmd );

    # show-ref --head returns 1 if there are no prior commits, but doesn't
    # return a message to stderr.  since we need to halt for other errors and
    # can't rely on the error code alone, checking for stderr seems like the
    # least worst way to detect if we encountered any other errors.
    # checking the error string for 'fatal: Needed a single revision' was
    # the previous way we were checking for initial commit, but seemed more
    # brittle over the long term to check for a specific error string.
    if ( $exit && $stderr ) {
        die "$stderr\n";
    }

    if ($stdout) {
        $against = 'HEAD';
    }
    else {
        # Initial commit: diff against an empty tree object
        $against = '4b825dc642cb6eb9a060e54bf8d69288fbee4904';
    }

    return $against;
}

sub _diff_index {
    my $self    = shift;
    my $against = shift;

    my @git_diff_index_cmd = ( qw{ git diff-index -p -M --cached }, $against );

    my ( $stdout, $stderr, $exit ) = Git::Lint::Command::run( \@git_diff_index_cmd );

    die "$stderr\n" if $exit;

    return [ split( /\n/, $stdout ) ];
}

sub format_issue {
    my $self = shift;
    my $args = {
        filename => undef,
        check    => undef,
        lineno   => undef,
        @_,
    };

    foreach ( keys %{$args} ) {
        die "$_ is a required argument"
            unless defined $args->{$_};
    }

    my $message = $args->{check} . ' (line ' . $args->{lineno} . ')';

    return { filename => $args->{filename}, message => $message };
}

sub get_filename {
    my $self = shift;
    my $line = shift;

    my $filename;
    if ( $line =~ m|^diff --git a/(.*) b/\1$| ) {
        $filename = $1;
    }

    return $filename;
}

sub parse {
    my $self = shift;
    my $args = {
        input => undef,
        match => undef,
        check => undef,
        @_,
    };

    foreach ( keys %{$args} ) {
        die "$_ is a required argument"
            unless defined $args->{$_};
    }

    die 'match argument must be a code ref'
        unless ref $args->{match} eq 'CODE';

    my @issues;
    my $filename;
    my $lineno;

    foreach my $line ( @{ $args->{input} } ) {
        my $ret = $self->get_filename($line);
        if ($ret) {
            $filename = $ret;
            next;
        }

        if ( $line =~ /^@@ -\S+ \+(\d+)/ ) {
            $lineno = $1 - 1;
            next;
        }

        if ( $line =~ /^ / ) {
            $lineno++;
            next;
        }

        if ( $line =~ /^--- / || $line =~ /^\+\+\+ / ) {
            $lineno++;
            next;
        }

        if ( $line =~ s/^\+// ) {
            $lineno++;
            chomp $line;

            if ( $args->{match}->($line) ) {
                push @issues,
                    $self->format_issue(
                    filename => $filename,
                    check    => $args->{check},
                    lineno   => $lineno,
                    );
            }
        }
    }

    return @issues;
}

1;

__END__

=pod

=head1 NAME

Git::Lint::Check::Commit - parent module for commit check modules

=head1 SYNOPSIS

 use parent 'Git::Lint::Check::Commit';

 # inside of the child module, check method
 sub check {
     my $self  = shift;
     my $input = shift;

     my $match = sub {
         my $line = shift;
         return 1 if $line =~ /\s$/;
         return;
     };

     my @issues = $self->parse(
         input => $input,
         match => $match,
         check => $check_name
     );

     return @issues;
 }

=head1 DESCRIPTION

C<Git::Lint::Check::Commit> provides methods for L<Git::Lint> commit check modules.

This module is not meant to be initialized directly.

=head1 ADDING CHECK MODULES

To add check functionality to L<Git::Lint>, additional check modules can be created as child modules to C<Git::Lint::Check::Commit>.

For an example to start creating commit check modules, see L<Git::Lint::Check::Commit::Whitespace> or any message check module released within this distribution.

=head2 CHECK MODULE REQUIREMENTS

Child modules must implement the C<check> method which gathers, formats, and returns a list of issues.

The methods within this module can be used to parse and report the issues in the expected format, but are not required to be used.

The issues returned from commit check modules must be a list of hash refs each with filename and message keys and values.

 my @issues = (
     {
       'filename' => 'catalog.txt',
       'message' => 'trailing whitespace (line 1)',
     },
     {
       'filename' => 'catalog.txt',
       'message' => 'trailing whitespace (line 2)',
     },
 );
 
=head1 CONSTRUCTOR

=head2 new

This method is inherited from L<Git::Lint::Check>.

=head1 METHODS

=head2 diff

Gathers, parses, and returns the commit diff.

=head3 ARGUMENTS

None.

=head3 RETURNS

An array ref of the diff of the commit.

=head2 format_issue

Formats the match information into the expected issue format.

=head3 ARGUMENTS

=over

=item filename

The name of the file from the commit diff.

=item check

The check name or message to format.

=item lineno

The line number being checked.

=back

=head3 RETURNS

A hash ref with filename and message key and value.

=head2 get_filename

Parses the filename out of a single line of git diff output.

=head3 ARGUMENTS

None.

The git diff line to be checked for filename is passed as unnamed input.

=head3 RETURNS

The filename, if found.

=head2 parse

Parses the diff input for violations using the match subref check.

=head3 ARGUMENTS

=over

=item input

Array ref of the commit diff input to check.

=item match

Code ref (sub reference) containing the check logic.

=item check

The check name or message to use for reporting issues.

=back

=head3 RETURNS

A list of hashrefs of formatted issues.

=cut
