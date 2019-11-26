package Git::Diff;

use Git;
use utf8;
use 5.018;
use strict;
use warnings;

$Git::Diff::VERSION = '0.000102';

sub new {
    my $s_class = shift;
    return bless {@_}, $s_class;
}

sub _repository {
    my ($self) = @_;
    $self->{_repository} //= Git->repository( %{$self} );
    return $self->{_repository};
}

sub changes_by_line {
    my ($self) = @_;
    my $hr_files = $self->changed_lines();
    for my $s_file ( keys %{$hr_files} ) {
        my $hr_changed_lines = $hr_files->{$s_file}->{changed};
        for my $s_line_key ( keys %{$hr_changed_lines} ) {
            my ( $i_subtraction, $i_addition ) = ( $s_line_key =~ m/\-(\d+)(?:,\d+)*\s\+(\d+)/ );
            for my $s_changed_line ( split /^/, $hr_changed_lines->{$s_line_key} ) {
                if ( $s_changed_line =~ /^\+(.*)/ ) {
                    $hr_files->{$s_file}->{addition}->{ $i_addition++ } = $1;
                }
                elsif ( $s_changed_line =~ /^\-(.*)/ ) {
                    $hr_files->{$s_file}->{subtraction}->{ $i_subtraction++ } = $1;
                }
            }
        }
    }
    return $hr_files;
}

sub changed_lines {
    my ($self) = @_;
    my $s_gitresult = $self->diff( $self->{base_branch} // 'master', '-U0' );
    my @a_splitted  = split /^diff /ms, $s_gitresult;
    shift @a_splitted;
    my $hr_files = {};
    for my $s_line (@a_splitted) {
        my ($s_file_name) = ( $s_line =~ m/^--git .* b\/(.*)/ );
        my @a_lines = split /@@\s+/, $s_line;
        shift @a_lines if scalar @a_lines % 2 == 1;
        my %h_changed_lines = @a_lines;
        $hr_files->{$s_file_name} = { raw => $_, changed => \%h_changed_lines };
    }
    return $hr_files;
}

sub diff {
    my $self             = shift;
    my @a_command_params = @_;
    unshift @a_command_params, 'diff';
    return $self->_repository->command(@a_command_params);
}

1;

__END__

=encoding utf8

=head1 NAME

Git::Diff - Git submodule to convert git diff into a perl hash-ref

=head1 VERSION

Version 0.000102

=head1 SUBROUTINES/METHODS

=head2 new

Constructor with given params

=head2 changes_by_line

Returns the full categorized hashref with file changes

=head2 changed_lines

Returns non categorized file changes

=head2 diff

Returns string from git diff command

=head1 SYNOPSIS

    my $o_diff = Git::Diff->new(
        directory   => $ENV{GIT_DIR},
        worktree    => $ENV{GIT_WORK_TREE},
        base_branch => $ENV{BASE_BRANCH}
    );
    $o_diff->changes_by_line;

Returns following structure

    {
        some/file/in/git {
            addition      {
                23   "   my ( $string ) = @_;"
            },
            changed       {
                '-23 +23 '   "sub is_identifier {
        -   my ($string) = @_;
        +   my ( $string ) = @_;
        "
            },
            raw           undef,
            subtraction   {
                23   "   my ($string) = @_;"
            },
        }
    }

=head1 DIAGNOSTICS

perlcritic:

=head1 DEPENDENCIES

=over 4

=item * Internal usage

L<Git|Git>

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

A list of current bugs and issues can be found at the CPAN site

   https://gitlab.com/mziescha/git-diff/issues

To report a new bug or problem, use the link on this page.

=head1 DESCRIPTION

Run and prase git diff command for perl hash structure

=head1 CONFIGURATION AND ENVIRONMENT

Need same git configs like L<Git|Git>

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

=cut
