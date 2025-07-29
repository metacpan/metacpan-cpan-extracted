package Git::RemoteURL::Parse;

use 5.010;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(parse_git_remote_url);

our $VERSION = '0.01';

sub parse_git_remote_url {
    my ($url) = @_;

    # --- GitHub HTTPS URLs ---
    if ($url =~ m{^https://
                  (?:[^@]+@)?            # optional user:token@
                  github\.com/
                  ([\w.-]+)              # username
                  /([\w.-]+?)            # repo
                  (?:\.git)?$
               }x
       ) {
      return { service => 'github', user => $1, repo => $2 };
    }

    # --- GitHub SSH URLs ---
    elsif ($url =~ m{^git@
                     (github\.com|gh[-\w]+) # host: github.com or gh-alias
                     :
                     ([\w.-]+)              # username
                     /([\w.-]+?)            # repo
                     (?:\.git)?$
                  }x
          ) {
      return { service => 'github', user => $2, repo => $3 };
    }

    # --- GitLab HTTPS URLs ---
    if ($url =~ m{^https://
                  (?:[^@]+@)?            # optional user:token@
                  gitlab\.com/
                  ((?:[\w.-]+/)+)        # group path (at least one level, trailing slash)
                  ([\w.-]+?)             # repo
                  (?:\.git)?$
               }x
       ) {
      my ($groups, $repo) = ($1, $2);
      $groups =~ s!/$!!;
      return { service => 'gitlab', group_path => $groups, repo => $repo };
    }

    # --- GitLab SSH URLs ---
    elsif ($url =~ m{^git@
                     (gitlab\.com|gl[-\w]+) # host: gitlab.com or gl-alias
                     :
                     ((?:[\w.-]+/)+)        # group path with trailing slash
                     ([\w.-]+?)             # repo
                     (?:\.git)?$
                  }x
          ) {
      my ($groups, $repo) = ($2, $3);
      $groups =~ s!/$!!;
      return { service => 'gitlab', group_path => $groups, repo => $repo };
    }
    return;   # No match
}



1; # End of Git::RemoteURL::Parse

__END__

=head1 NAME

Git::RemoteURL::Parse - Parse and classify Git remote URLs (GitHub, GitLab)

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Git::RemoteURL::Parse;

    my $info = parse_git_remote_url('https://github.com/user/repo.git');

    if ($info) {
        if ($info->{service} eq 'github') {
            print "GitHub repo: $info->{user}/$info->{repo}\n";
        }
        elsif ($info->{service} eq 'gitlab') {
            print "GitLab repo: $info->{group_path}/$info->{repo}\n";
        }
    } else {
        warn "Not a recognized GitHub or GitLab URL\n";
    }

=head1 DESCRIPTION

This module provides a single function, C<parse_git_remote_url()>, which
analyzes a Git remote URL and identifies whether it points to a GitHub or
GitLab repository. It also extracts the repo and the user name or group path, respectively.

Supported URL formats include both HTTPS and SSH variants.

=head2 SUPPORTED FORMATS

=over 4

=item * GitHub HTTPS:

    https://github.com/user/repo.git
    https://token@github.com/user/repo

=item * GitHub SSH:

    git@github.com:user/repo.git
    git@gh-alias:user/repo

=item * GitLab HTTPS:

    https://gitlab.com/group/subgroup/repo.git

=item * GitLab SSH:

    git@gitlab.com:group/sub/repo.git
    git@gl-alias:group1/group2/repo.git

=back

=head2 FUNCTIONS

=over 4

=item C<parse_git_remote_url(I<URL>)>

    my $info = parse_git_remote_url($url);

Takes a Git remote I<C<URL>> string and returns a hash reference with the following structure:

=over 4

=item * For GitHub:

    {
        service => 'github',
        user    => 'USERNAME',
        repo    => 'REPO_NAME',
    }

=item * For GitLab:

    {
        service    => 'gitlab',
        group_path => 'group/subgroup/...',
        repo       => 'REPO_NAME',
    }

=back

Returns C<undef> if the URL is not recognized as a valid GitHub or GitLab URL.

=back

=head1 AUTHOR

Klaus Rindfrey, C<< <klausrin at cpan.org.eu> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-git-remoteurl-parse at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Git-RemoteURL-Parse>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Git::RemoteURL::Parse


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Git-RemoteURL-Parse>

=item * Search CPAN

L<https://metacpan.org/release/Git-RemoteURL-Parse>

=item * GitHub Repository

L<https://github.com/klaus-rindfrey/git-remoteurl-parse>

=back

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Klaus Rindfrey.

This module is free software. You may redistribute it and/or modify it under
the same terms as Perl itself.

=cut

