package Getopt::Long::Complete;

our $DATE = '2016-12-03'; # DATE
our $VERSION = '0.30'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
                    GetOptions
               );
our @EXPORT_OK = qw(
                    GetOptions
                    GetOptionsWithCompletion
               );

# default follows Getopt::Long
our $opt_permute = $ENV{POSIXLY_CORRECT} ? 0 : 1;
our $opt_pass_through = 0;

our $opt_bundling = 1; # in Getopt::Long the default is off

sub GetOptionsWithCompletion {
    my $comp = shift;

    my $hash;
    my $ospec;
    if (ref($_[0]) eq 'HASH') {
        $hash = shift;
        $ospec = { map {$_=>sub{}} @_ };
    } else {
        $ospec = {@_};
    }

    my $shell;
    if ($ENV{COMP_SHELL}) {
        ($shell = $ENV{COMP_SHELL}) =~ s!.+/!!;
    } elsif ($ENV{COMMAND_LINE}) {
        $shell = 'tcsh';
    } else {
        $shell = 'bash';
    }

    if ($ENV{COMP_LINE} || $ENV{COMMAND_LINE}) {
        my ($words, $cword);
        if ($ENV{COMP_LINE}) {
            require Complete::Bash;
            ($words,$cword) = @{ Complete::Bash::parse_cmdline(undef, undef, {truncate_current_word=>1}) };
            ($words,$cword) = @{ Complete::Bash::join_wordbreak_words($words, $cword) };
        } elsif ($ENV{COMMAND_LINE}) {
            require Complete::Tcsh;
            $shell //= 'tcsh';
            ($words, $cword) = @{ Complete::Tcsh::parse_cmdline() };
        }

        require Complete::Getopt::Long;

        shift @$words; $cword--; # strip program name
        my $compres = Complete::Getopt::Long::complete_cli_arg(
            words => $words, cword => $cword, getopt_spec => $ospec,
            completion => $comp,
            bundling => $opt_bundling,
        );

        if ($shell eq 'bash') {
            require Complete::Bash;
            print Complete::Bash::format_completion(
                $compres, {word=>$words->[$cword]});
        } elsif ($shell eq 'fish') {
            require Complete::Fish;
            print Complete::Bash::format_completion(
                $compres, {word=>$words->[$cword]});
        } elsif ($shell eq 'tcsh') {
            require Complete::Tcsh;
            print Complete::Tcsh::format_completion($compres);
        } elsif ($shell eq 'zsh') {
            require Complete::Zsh;
            print Complete::Zsh::format_completion($compres);
        } else {
            die "Unknown shell '$shell'";
        }

        exit 0;
    }

    require Getopt::Long;
    my $old_conf = Getopt::Long::Configure(
        'no_ignore_case',
        'no_getopt_compat',
        'gnu_compat',
        $opt_bundling ? 'bundling' : 'no_bundling',
        $opt_permute ? 'permute' : 'no_permute',
        $opt_pass_through ? 'pass_through' : 'no_pass_through',
    );
    if ($hash) {
        Getopt::Long::GetOptions($hash, @_);
    } else {
        Getopt::Long::GetOptions(@_);
    }
    Getopt::Long::Configure($old_conf);
}

sub GetOptions {
    GetOptionsWithCompletion(undef, @_);
}

1;
# ABSTRACT: A drop-in replacement for Getopt::Long, with shell tab completion

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Long::Complete - A drop-in replacement for Getopt::Long, with shell tab completion

=head1 VERSION

This document describes version 0.30 of Getopt::Long::Complete (from Perl distribution Getopt-Long-Complete), released on 2016-12-03.

=head1 SYNOPSIS

=head2 First example (simple)

You just replace C<use Getopt::Long> with C<use Getopt::Long::Complete> and your
program suddenly supports tab completion. This works for most/many programs (see
L</"INCOMPATIBILITIES">. For example, below is source code for C<delete-user>.

 use Getopt::Long::Complete;
 my %opts;
 GetOptions(
     'help|h'     => sub { ... },
     'on-fail=s'  => \$opts{on_fail},
     'user|U=s'   => \$opts{name},
     'force'      => \$opts{force},
     'verbose!'   => \$opts{verbose},
 );

Several shells are supported. To activate completion, see L</"DESCRIPTION">.
After activation, tab completion works:

 % delete-user <tab>
 --force --help --noverbose --no-verbose --on-fail --user --verbose -h
 % delete-user --h<tab>

=head2 Second example (additional completion)

The previous example only provides completion for option names. To provide
completion for option values as well as arguments, you need to provide more
hints. Instead of C<GetOptions>, use C<GetOptionsWithCompletion>. It's basically
the same as C<GetOptions> but accepts an extra coderef in the first argument.
The code will be invoked when completion to option value or argument is needed.
Example:

 use Getopt::Long::Complete qw(GetOptionsWithCompletion);
 use Complete::Unix qw(complete_user);
 use Complete::Util qw(complete_array_elem);
 my %opts;
 GetOptionsWithCompletion(
     sub {
         my %args  = @_;
         my $word  = $args{word}; # the word to be completed
         my $type  = $args{type}; # 'optname', 'optval', or 'arg'
         my $opt   = $args{opt};
         if ($type eq 'optval' && $opt eq '--on-fail') {
             return complete_array_elem(words=>[qw/die warn ignore/], word=>$word);
         } elsif ($type eq 'optval' && ($opt eq '--user' || $opt eq '-U')) {
             return complete_user(word=>$word);
         } elsif ($type eq 'arg') {
             return complete_user(word=>$word);
         }
         [];
     },
     'help|h'     => sub { ... },
     'on-fail=s'  => \$opts{on_fail},
     'user=s'     => \$opts{name},
     'force'      => \$opts{force},
     'verbose!'   => \$opts{verbose},
 );

=head1 DESCRIPTION

This module provides a quick and easy way to add shell tab completion feature to
your scripts, including scripts already written using the venerable
L<Getopt::Long> module. Currently bash and tcsh are directly supported; fish and
zsh are also supported via L<shcompgen>.

This module is basically just a thin wrapper for Getopt::Long. Its C<GetOptions>
function just checks for COMP_LINE/COMP_POINT environment variable (in the case
of bash) or COMMAND_LINE (in the case of tcsh) before passing its arguments to
C<Getopt::Long>'s C<GetOptions>. If those environment variable(s) are defined,
completion reply will be printed to STDOUT and then the program will exit.
Otherwise, Getopt::Long's GetOptions is called.

To keep completion quick, you should do C<GetOptions()> or
C<GetOptionsWithCompletion()> as early as possible in your script. Preferably
before loading lots of other Perl modules.

To activate tab completion in bash, put your script somewhere in C<PATH> and
execute this in the shell or put it into your bash startup file (e.g.
C</etc/bash.bashrc> or C<~/.bashrc>). Replace C<delete-user> with the actual
script name:

 complete -C delete-user delete-user

For tcsh:

 complete delete-user 'p/*/`delete-user`/'

For other shells (but actually for bash too) you can use L<shcompgen>.

=head1 VARIABLES

Because we are "bound" by providing a Getopt::Long-compatible function
interface, these variables exist to allow configuring Getopt::Long::GetOptions.
You can use Perl's C<local> to localize the effect.

=head2 $opt_permute => bool (default: 1 or 0 if POSIXLY_CORRECT)

=head2 $opt_pass_through => bool (default: 0)

=head2 $opt_bundling => bool (default: 1)

=head1 INCOMPATIBILITIES

Although you can use Getopt::Long::Complete (GLC) as a drop-in replacement for
Getopt::Long (GL) most of the time, there are some incompatibilities or
unsupported features:

=over

=item * GLC does not allow passing configure options during import

GLC only supports running under a specific set of modes anyway: C<bundling>,
C<no_ignore_case>. Other non-default settings have not been tested and probably
not supported.

=item * Aside from GetOptions, no other GL functions are currently supported

This include C<GetOptionsFromArray>, C<GetOptionsFromString>, C<Configure>,
C<HelpMessage>, C<VersionMessage>.

=back

=head1 FUNCTIONS

=head2 GetOptions([\%hash, ]@spec)

Will call Getopt::Long's GetOptions, except when COMP_LINE environment variable
is defined, in which case will print completion reply to STDOUT and exit.

B<Note: Will temporarily set Getopt::Long configuration as follow: bundling,
no_ignore_case, gnu_compat, no_getopt_compat, permute (if POSIXLY_CORRECT
environment is false). I believe this a sane default.> You can turn off bundling
via C<$opt_bundling>. You can turn on/off permute explicitly by via
C<$opt_permute>. You can turn on pass_through via C<$opt_pass_through>.

=head2 GetOptionsWithCompletion(\&completion, [\%hash, ]@spec)

Just like C<GetOptions>, except that it accepts an extra first argument
C<\&completion> containing completion routine for completing option I<values>
and arguments. This will be passed as C<completion> argument to
L<Complete::Getopt::Long>'s C<complete_cli_arg>. See that module's documentation
on details of what is passed to the routine and what return value is expected
from it.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Getopt-Long-Complete>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Getopt-Long-Complete>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Getopt-Long-Complete>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Getopt::Long::More>, another drop-in replacement for Getopt::Long with tab
completion support and more stuffs: default value, required value, summary in
auto_help.

L<Complete::Getopt::Long> (the backend for this module), C<Complete::Bash>,
C<Complete::Tcsh>.

Other option-processing modules featuring shell tab completion:
L<Getopt::Complete>.

L<Perinci::CmdLine> - an alternative way to easily create command-line
applications with completion feature.

L<shcompgen>

L<Pod::Weaver::Section::Completion::GetoptLongComplete>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
