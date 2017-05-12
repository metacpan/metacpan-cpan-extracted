package Git::Reduce::Tests;
use strict;
our $VERSION = '0.10';
use Git::Wrapper;
use Carp;
use Data::Dumper;$Data::Dumper::Indent=1;
use File::Find qw( find );

=head1 NAME

Git::Reduce::Tests -  Create a branch with fewer test files for faster development

=head1 SYNOPSIS

    use Git::Reduce::Tests;

    my $self = Git::Reduce::Tests->new($params);
    my $reduced_branch = $self->prepare_reduced_branch();
    $self->push_to_remote($reduced_branch);

=head1 DESCRIPTION

Git::Reduce::Tests holds the implementation for command-line utility
F<reduce-tests>, which is stored in this distribution's F<scripts/> directory.
See that program's documentation (available after installation via C<perldoc
reduce-tests>) or the F<README> for an explanation of that program's
functionality.

This package exports no functions.

=head1 METHODS

Git::Reduce::Tests is currently structured as three publicly available methods
intended to be called in sequence.

=head2 C<new()>

=over 4

=item * Purpose

Git::Reduce::Tests constructor.  Checks that the directory passed to the
C<--dir> option is a git repository and that there are no files there with a
modified status.

=item * Arguments

    $self = Git::Reduce::Tests->new($params);

Reference to a hash of parameters, typically that provided by
C<Git::Reduce::Tests::Opts::process_options()>.  See that package's
documentation for a description of those parameters.

=item * Return Value

Git::Reduce::Tests object.

=back

=cut

sub new {
    my ($class, $params) = @_;
    my %data;

    while (my ($k,$v) = each %{$params}) {
        $data{params}{$k} = $v;
    }
    $data{git} = Git::Wrapper->new($params->{dir});

    # Make sure we can check out the branch needing testing.
    check_status(\%data);
    {
        local $@;
        eval {$data{git}->checkout($data{params}->{branch}) };
        croak($@) if $@;
    }
    return bless \%data, $class;
}

=head2 C<prepare_reduced_branch()>

=over 4

=item * Purpose

Creates a new branch whose name is that of the starting branch either (a)
prepended with the value of the C<--prefix> option or (b) appended with the
value of the C<--suffix> option -- but not B<both> (a) and (b).  C<--prefix>
is given preference and defaults to C<reduced_>.

The method then reduces the size of that branch's test suite either by
specifying a limited number of files to be B<included> in the test suite --
the comma-delimited argument to the C<--include> option -- or by specifying
those files to be B<excluded> from the test suite -- the comma-delimited
argument to the C<--exclude> option.

=item * Arguments

    $reduced_branch = $self->prepare_reduced_branch();

None.

=item * Return Value

String containing the name of the new branch with smaller test suite.

=back

=cut

sub prepare_reduced_branch {
    my $self = shift;

    # reduced_branch:  temporary branch whose test suite has been reduced in
    # size
    # Compose name for reduced_branch
    my $branches = $self->_get_branches();
    my $reduced_branch =
        defined($self->{params}->{suffix})
            ? $self->{params}->{branch} . $self->{params}->{suffix}
            : $self->{params}->{prefix} . $self->{params}->{branch};

    # Customarily, delete any existing branch with temporary branch's name.
    unless($self->{params}->{no_delete}) {
        if (exists($branches->{$reduced_branch})) {
            print "Deleting branch '$reduced_branch'\n"
                if $self->{params}->{verbose};
            $self->{git}->branch('-D', $reduced_branch);
        }
    }
    if ($self->{params}->{verbose}) {
        print "Current branches:\n";
        $self->_dump_branches();
    }

    # Create the reduced branch.
    {
        local $@;
        eval { $self->{git}->checkout('-b', $reduced_branch); };
        croak($@) if $@;
        print "Creating branch '$reduced_branch'\n"
            if $self->{params}->{verbose};
    }

    # Locate all test files.
    my @tfiles = ();
    find(
        sub {
            $_ =~ m/\.$self->{params}->{test_extension}$/ and
                push(@tfiles, $File::Find::name)
        },
        $self->{params}->{dir}
    );

    my (@includes, @excludes);
    if ($self->{params}->{include}) {
        @includes = split(',' => $self->{params}->{include});
        croak("Did not specify test files to be included in reduced branch")
            unless @includes;
    }
    if ($self->{params}->{exclude}) {
        @excludes = split(',' => $self->{params}->{exclude});
        croak("Did not specify test files to be exclude from reduced branch")
            unless @excludes;
    }
    if ($self->{params}->{verbose}) {
        print "Test files:\n";
        print Dumper [ sort @tfiles ];
        if ($self->{params}->{include}) {
            print "Included test files:\n";
            print Dumper(\@includes);
        }
        if ($self->{params}->{exclude}) {
            print "Excluded test files:\n";
            print Dumper(\@excludes);
        }
    }
    # Create lookup tables for test files to be included in,
    # or excluded from, the reduced branch.
    my %included = map { +qq{$self->{params}->{dir}/$_} => 1 } @includes;
    my %excluded = map { +qq{$self->{params}->{dir}/$_} => 1 } @excludes;
    my @removed = ();
    if ($self->{params}->{include}) {
        @removed = grep { ! exists($included{$_}) } sort @tfiles;
    }
    if ($self->{params}->{exclude}) {
        @removed = grep { exists($excluded{$_}) } sort @tfiles;
    }
    if ($self->{params}->{verbose}) {
        print "Test files to be removed:\n";
        print Dumper(\@removed);
    }

    # Remove undesired test files and commit the reduced branch.
    $self->{git}->rm(@removed);
    $self->{git}->commit( '-m', "Remove unwanted test files" );
    return ($reduced_branch);
}

=head2 C<push_to_remote()>

=over 4

=item * Purpose

Push the reduced branch to the remote specified in the C<--remote> option,
which defaults to C<origin>.  This, of course, assumes that the user has
permission to perform that action, has proper credentials such as SSH keys,
etc.

=item * Arguments

    $self->push_to_remote($reduced_branch);

String holding name of branch with reduced test suite -- typically the return
value of the C<prepare_reduced_branch()> method.

=item * Return Value

Implicitly returns a true value upon success.

=back

=cut

sub push_to_remote {
    my ($self, $reduced_branch) = @_;
    unless ($self->{params}->{no_push}) {
        local $@;
        eval { $self->{git}->push($self->{params}->{remote}, "+$reduced_branch"); };
        croak($@) if $@;
        print "Pushing '$reduced_branch' to $self->{params}->{remote}\n"
            if $self->{params}->{verbose};
    }
    print "Finished!\n" if $self->{params}->{verbose};
}

##### INTERNAL METHODS #####

sub _get_branches {
    my $self = shift;
    my @branches = $self->{git}->branch;
    my %branches;

    for (@branches) {
        if (m/^\*\s+(.*)/) {
            my $br = $1;
            $branches{$br} = 'current';
        }
        else {
            if (m/^\s+(.*)/) {
                my $br = $1;
                $branches{$br} = 1;
            }
            else {
                croak "Could not get branch";
            }
        }
    }
    return \%branches;
}

sub _dump_branches {
    my $self = shift;
    my $branches = $self->_get_branches();
    print Dumper $branches;
}

##### INTERNAL SUBROUTINE #####

sub check_status {
    my $dataref = shift;
    my $statuses = $dataref->{git}->status;
    if (! $statuses->is_dirty) {
        print "git status okay\n" if $dataref->{params}->{verbose};
        return 1;
    }
    my $msg = '';
    for my $type (qw<indexed changed unknown conflict>) {
        my @states = $statuses->get($type)
            or next;
        $msg .= "Files in state $type\n";
        for (@states) {
            $msg .= '  ' . $_->mode . ' ' . $_->from;
            if ($_->mode eq 'renamed') {
                $msg .= ' renamed to ' . $_->to;
            }
            $msg .= "\n";
        }
    }
    croak($msg);
}

=head1 BUGS

There are no bug reports outstanding as of the most recent
CPAN upload date of this distribution.

=head1 SUPPORT

Please report any bugs by mail to C<bug-Git-Reduce-Tests@rt.cpan.org>
or through the web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

James E. Keenan (jkeenan@cpan.org).  When sending correspondence, please
include 'reduce-tests' or 'Git-Reduce-Tests' in your subject line.

Creation date:  August 03 2014. Last modification date:  August 04 2014.

Development repository: L<https://github.com/jkeenan/git-reduce-tests>

=head1 COPYRIGHT

Copyright (c) 2014 James E. Keenan.  United States.  All rights reserved.
This is free software and may be distributed under the same terms as Perl
itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE ''AS IS'' WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;
