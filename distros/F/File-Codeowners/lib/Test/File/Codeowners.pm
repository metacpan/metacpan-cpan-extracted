package Test::File::Codeowners;
# ABSTRACT: Write tests for CODEOWNERS files


use warnings;
use strict;

use Encode qw(encode);
use File::Codeowners::Util qw(find_codeowners_in_directory find_nearest_codeowners git_ls_files git_toplevel);
use File::Codeowners;
use FindBin qw($Bin);
use Test::Builder;

our $VERSION = '0.53'; # VERSION

my $Test = Test::Builder->new;

sub import {
    my $self = shift;
    my $caller = caller;
    no strict 'refs';   ## no critic (TestingAndDebugging::ProhibitNoStrict)
    *{$caller.'::codeowners_syntax_ok'} = \&codeowners_syntax_ok;
    *{$caller.'::codeowners_git_files_ok'} = \&codeowners_git_files_ok;

    $Test->exported_to($caller);
    $Test->plan(@_);
}


sub codeowners_syntax_ok {
    my $filepath = shift || find_nearest_codeowners($Bin);

    if (!$filepath) {
        $Test->ok(0, "Check syntax: <missing>");
        $Test->diag('No CODEOWNERS file could be found.');
        return;
    }

    eval { File::Codeowners->parse($filepath) };
    my $err = $@;

    $Test->ok(!$err, "Check syntax: $filepath");
    $Test->diag($err) if $err;
}


sub codeowners_git_files_ok {
    my $repopath = shift || $Bin;

    my $git_toplevel = git_toplevel($repopath);
    if (!$git_toplevel) {
        $Test->skip('No git repo could be found.');
        return;
    }

    my $filepath = find_codeowners_in_directory($git_toplevel);
    if (!$filepath) {
        $Test->ok(0, "Check syntax: <missing>");
        $Test->diag("No CODEOWNERS file could be found in repo $repopath.");
        return;
    }

    $Test->subtest('codeowners_git_files_ok' => sub {
        local $Test::Builder::Level = $Test::Builder::Level + 3;

        my $codeowners = eval { File::Codeowners->parse($filepath) };
        if (my $err = $@) {
            $Test->plan(tests => 1);
            $Test->ok(0, "Parse $filepath");
            $Test->diag($err);
            return;
        }

        my ($proc, @files) = git_ls_files($git_toplevel);
        if ($proc->wait != 0) {
            $Test->plan(skip_all => 'git ls-files failed');
            return;
        }

        $Test->plan(tests => scalar @files);

        for my $filepath (@files) {
            my $msg = encode('UTF-8', "Check file: $filepath");

            my $match = $codeowners->match($filepath);
            my $is_unowned = $codeowners->is_unowned($filepath);

            if (!$match && !$is_unowned) {
                $Test->ok(0, $msg);
                $Test->diag("File is unowned\n");
            }
            elsif ($match && $is_unowned) {
                $Test->ok(0, $msg);
                $Test->diag("File is owned but listed as unowned\n");
            }
            else {
                $Test->ok(1, $msg);
                if ($match) {
                    my $owners = encode('UTF-8', join(',', @{$match->{owners}}));
                    $Test->note("File is owned by $owners");
                }
            }
        }
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::File::Codeowners - Write tests for CODEOWNERS files

=head1 VERSION

version 0.53

=head1 SYNOPSIS

    use Test::More;

    eval 'use Test::File::Codeowners';
    plan skip_all => 'Test::File::Codeowners required for testing CODEOWNERS' if $@;

    codeowners_syntax_ok();
    done_testing;

=head1 DESCRIPTION

This package has assertion subroutines for testing F<CODEOWNERS> files.

=head1 FUNCTIONS

=head2 codeowners_syntax_ok

    codeowners_syntax_ok();     # search up the tree for a CODEOWNERS file
    codeowners_syntax_ok($filepath);

Check the syntax of a F<CODEOWNERS> file.

=head2 codeowners_git_files_ok

    codeowners_git_files_ok();  # use git repo in cwd
    codeowners_git_files_ok($repopath);

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/File-Codeowners/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
