#!/usr/bin/env perl
package Gentoo::App::Pram;

our $VERSION = '0.100100';

use warnings;
use strict;

use Term::ANSIColor qw/colored/;
use File::Basename qw/basename/;
use File::Which qw/which/;
use Encode qw/decode/;
use File::Temp;
use HTTP::Tiny;

use constant E_ERROR => colored('ERROR', 'red');
use constant E_NO    => colored('NO',    'red');
use constant E_YES   => colored('YES',   'green');
use constant E_OK    => colored('OK',    'green');
use constant E_MERGE => colored('MERGE', 'blue');

use constant CLOSES_GITHUB => qr#\ACloses: https?://github\.com#;

use Getopt::Long;
use Pod::Usage;

sub new {
    my ($class, @args) = @_;
    return bless { ref $args[0] ? %{ $args[0] } : @args }, $class;
}

sub new_with_opts {
    my ($class) = @_;
    my @opts = (
        'repository|r=s',
        'closes|c=s',
        'editor|e=s',
        'signoff|s',
        'bug|b=s',
        'help|h',
        'man|m'
    );
    my %opts;
    if (!GetOptions(\%opts, @opts)) {
        print "\n";
        pod2usage(-verbose => 1)
    }
    $opts{pr_number} = shift @ARGV;
    return $class->new(\%opts);
}

sub run {
    my ($self) = @_;

    my $pr_number = $self->{pr_number};
    my $closes = $self->{closes};
    my $bug = $self->{bug};

    $| = 1;

    $self->{help} and pod2usage(-verbose => 1);
    $self->{man} and pod2usage(-verbose => 2);

    $bug and $closes and pod2usage(
        -message => E_ERROR . qq#! --bug and --closes options are mutually exclusive!\n#,
        -verbose => 1
    );

    run_checks($pr_number, "You must specify a Pull Request number!");
    $bug and run_checks($bug, "You must specify a bug number when using --bug!");
    $closes and run_checks($closes, "You must specify a bug number when using --closes!");

    # Defaults to 'gentoo/gentoo' because we're worth it.
    my $repo_name   = $self->{repository} || 'gentoo/gentoo';
    my $editor      = $self->{editor} || $ENV{EDITOR} || 'less';

    my $git_command = which('git') . ' am --keep-cr -S';
    $self->{signoff} and $git_command = "$git_command -s";

    my $patch_url   = "https://patch-diff.githubusercontent.com/raw/$repo_name/pull/$pr_number.patch";
    $self->{pr_url} = "https://github.com/$repo_name/pull/$pr_number";
    
    # Go!
    $self->apply_patch(
        $editor,
        $git_command,
        $self->modify_patch(
            $self->fetch_patch($patch_url)
        )
    );
}

sub run_checks {
    @_ == 2 || die qq#Usage: run_checks(obj, error_msg)#;
    my ($obj, $error_msg) = @_;

    $obj || pod2usage(
        -message => E_ERROR . qq#! $error_msg\n#,
        -verbose => 1
    );

    $obj =~ /^\d+$/ || pod2usage(
        -message => E_ERROR . qq#! "$obj" is NOT a number!\n#,
        -verbose => 1
    );
}

sub my_sleep {
    select(undef, undef, undef, 0.50);
}

sub fetch_patch {
    @_ == 2 || die qq#Usage: fetch_patch(patch_url)\n#;
    my ($self, $patch_url) = @_;

    print "Fetching $patch_url ... ";

    my $response = HTTP::Tiny->new->get($patch_url);
    my $status = $response->{status};
    
    $status != 200 and die "\n" . E_ERROR . qq#! Unreachable URL! Got HTTP status $status!\n#;
    my $patch = $response->{content};

    print E_OK . "!\n";
    
    return decode('UTF-8', $patch);
}

sub add_header {
    @_ == 3 || die qq#Usage: add_header(patch, header, msg)\n#;
    my ($patch, $header, $msg) = @_;

    print qq#$msg#;
    my_sleep();
    my $confirm = E_ERROR;
    my $is_sub = $patch =~ s#---#$header#;
    $is_sub and $confirm = E_OK;
    print "$confirm!\n";
    my_sleep();
    return $patch;
}

sub modify_patch {
    @_ == 2 || die qq#Usage: modify_patch(patch)\n#;
    my ($self, $patch) = @_;

    if (not $patch =~ CLOSES_GITHUB) {
        my $pr_url = $self->{pr_url};
        $patch = add_header(
            $patch,
            qq#Closes: $pr_url\n---#,
            qq#Adding Github "Closes:" header ... #
        );
    }

    if ($self->{bug}) {
        my $bug = $self->{bug};
        $patch = add_header(
            $patch,
            qq#Bug: https://bugs.gentoo.org/$bug\n---#,
            qq#Adding Gentoo "Bug:" header with bug $bug ... #
        );
    }

    if ($self->{closes}) {
        my $closes = $self->{closes};
        $patch = add_header(
            $patch,
            qq#Closes: https://bugs.gentoo.org/$closes\n---#,
            qq#Adding Gentoo "Closes:" header with bug $closes ... #
        );
    }

    return $patch;
}

sub apply_patch {
    @_ == 4 || die qq#Usage: apply_patch(editor, git_command, patch)\n#;
    my ($self, $editor, $git_command, $patch) = @_;

    my $patch_location = File::Temp->new() . '.patch';
    open my $fh, '>:encoding(UTF-8)', $patch_location || die E_ERROR . qq#! Can't write to $patch_location: $!!\n#;
    print $fh $patch;
    close $fh;

    print "Opening $patch_location with $editor ... ";
    my_sleep();
    my $exit = system $editor => $patch_location;
    $exit eq 0 || die E_ERROR . qq#! Could not open $patch_location: $!!\n#;
    print E_OK . "!\n";
    
    print E_MERGE . "? Do you want to apply this patch and merge this PR? [y/n] ";

    chomp(my $answer = <STDIN>);

    if ($answer =~ /^[Yy]$/) {
        $git_command = "$git_command $patch_location";
        print E_YES . "!\n";
        print "Launching '$git_command' ... \n";
        $exit = system join ' ', $git_command;
        $exit eq 0 || die E_ERROR . qq#! Error when launching '$git_command': $!!\n#;
        print E_OK . "!\n";
    } else {
        print E_NO . "!\nBailing out.\n";
    }
    
    print "Removing $patch_location ... ";
    unlink $patch_location || die E_ERROR . qq#! Couldn't remove '$patch_location'!\n#;
    print E_OK . "!\n";
}

1;

__END__

=head1 NAME

Gentoo::App::Pram - Library to fetch a GitHub Pull Request as an am-like patch.

=head1 DESCRIPTION

The purpose of this module is to fetch Pull Requests from GitHub's CDN as
am-like patches in order to facilitate the merging and closing of Pull
Requests. This module also takes care of adding "Closes:" and "Bug:" headers to
patches when necessary. See GLEP 0066.

=head1 FUNCTIONS

=over 4

=item * fetch_patch($patch_url)

Fetch patch from $patch_url. Return patch as a string.

=item * modify_patch($patch)

Modify the patch headers. This function only modifies the headers of the first
commit. Namely:

* Add a "Closes: https://github.com/XXX" header. Check first if it wasn't added
already by the contributor. This header is parsed by the Github bot upon merge.
The bot then automatically closes the pull request. See
https://help.github.com/articles/closing-issues-using-keywords for more info.

* Add a "Bug: https://bugs.gentoo.org/XXX" header when the `--bug XXX` option
is given. This header is parsed by the Gentoo Bugzilla bot upon merge. The bot
then writes a message in the bug report. See GLEP 0066 for more info.

* Add a "Closes: https://bugs.gentoo.org/XXX" header when the `--closes XXX`
option is given. This header is parsed by the Gentoo Bugzilla bot upon merge.
The bot then automatically closes the bug report. See GLEP 0066 for more info.

=item * apply_patch($editor, $git_command, $patch)

Apply $patch onto HEAD of the current git repository using $git_command. This
functions also shows $patch in $editor for a final review.

=back

=head1 VERSION

version 0.100100

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Patrice Clement.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Patrice Clement <monsieurp@gentoo.org>

Kent Fredric <kentnl@gentoo.org>

=cut
