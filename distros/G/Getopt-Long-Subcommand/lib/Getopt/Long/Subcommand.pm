package Getopt::Long::Subcommand;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-30'; # DATE
our $DIST = 'Getopt-Long-Subcommand'; # DIST
our $VERSION = '0.104'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::ger;

require Exporter;
our @ISA = qw(Exporter);
## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT = qw(
                    GetOptions
            );
## use critic

# XXX completion & configure are actually only allowed at the top-level
my @known_cmdspec_keys = qw(
    options
    subcommands
    default_subcommand
    summary description
    completion
    configure
);

sub _cmdspec_opts_to_gl_ospec {
    my ($cmdspec_opts, $is_completion, $res) = @_;
    return { map {
        if ($is_completion) {
            # we don't want side-effects during completion (handler printing or
            # existing, etc), so we set an empty coderef for all handlers.
            ($_ => sub{});
        } else {
            my $k = $_;
            my $v = $cmdspec_opts->{$k};
            my $handler = ref($v) eq 'HASH' ? $v->{handler} : $v;
            if (ref($handler) eq 'CODE') {
                my $orig_handler = $handler;
                $handler = sub {
                    my ($cb, $val) = @_;
                    $orig_handler->($cb, $val, $res);
                };
            }
            ($k => $handler);
        }
    } keys %$cmdspec_opts };
}

sub _gl_getoptions {
    require Getopt::Long;

    my ($ospec, $configure, $pass_through, $res) = @_;

    my @configure = @{
        $configure //
            ['no_ignore_case', 'no_getopt_compat', 'gnu_compat', 'bundling']
        };
    if ($pass_through) {
        push @configure, 'pass_through'
            unless grep { $_ eq 'pass_through' } @configure;
    } else {
        @configure = grep { $_ ne 'pass_through' } @configure;
    }
    #log_trace('[comp][glsubc] Performing Getopt::Long::GetOptions (configure: %s)',
    #          $pass_through, \@configure);

    my $old_conf = Getopt::Long::Configure(@configure);
    local $SIG{__WARN__} = sub {} if $pass_through;

    # ugh, this is ugly. the problem we're trying to solve: in the case of 'subc
    # --help', 'subc' is consumed first by Getopt::Long and thus removed from
    # @ARGV. when --help handler wants to find out the subcommand name ('subc'),
    # it doesn't have anywhere to look for. so we give it in $res which is
    # passed as the third argument to the handler.
    local $res->{_non_options_argv} = [];

    #log_trace('[comp][glsubc] @ARGV before Getopt::Long::GetOptions: %s', \@ARGV);
    #log_trace('[comp][glsubc] spec for Getopt::Long::GetOptions: %s', $ospec);
    my $gl_res = Getopt::Long::GetOptions(
        %$ospec,
        '<>' => sub { push @{ $res->{_non_options_argv} }, $_[0] },
    );
    @ARGV = @{ $res->{_non_options_argv} };

    #log_trace('[comp][glsubc] @ARGV after Getopt::Long::GetOptions: %s', \@ARGV);
    Getopt::Long::Configure($old_conf);
    $gl_res;
}

sub _GetOptions {
    my ($cmdspec, $is_completion, $res, $stash) = @_;

    $res //= {success=>undef};
    $stash //= {
        path => '', # for displaying error message
        level => 0,
    };

    # check command spec
    {
        #log_trace("[comp][glsubc] Checking cmdspec keys: %s", [keys %$cmdspec]);
        for my $k (keys %$cmdspec) {
            (grep { $_ eq $k } @known_cmdspec_keys)
                or die "Unknown command specification key '$k'" .
                    ($stash->{path} ? " (under $stash->{path})" : "") . "\n";
        }
    }

    my $has_subcommands = $cmdspec->{subcommands} &&
        keys(%{$cmdspec->{subcommands}});
    #log_trace("TMP:has_subcommands=%s", $has_subcommands);
    my $pass_through = $has_subcommands || $is_completion;

    my $ospec = _cmdspec_opts_to_gl_ospec(
        $cmdspec->{options}, $is_completion, $res);
    unless (_gl_getoptions(
        $ospec, $cmdspec->{configure}, $pass_through, $res)) {
        $res->{success} = 0;
        return $res;
    }

    # for doing completion
    if ($is_completion) {
        $res->{comp_ospec} //= {};
        for (keys %$ospec) {
            $res->{comp_ospec}{$_} = $ospec->{$_};
        }
    }

    if ($has_subcommands) {
        # for doing completion of subcommand names
        if ($is_completion) {
            my $scnames = $res->{comp_subcommand_names}[$stash->{level}] =
                [sort keys %{$cmdspec->{subcommands}}];
            $res->{comp_subcommand_summaries}[$stash->{level}] =
                [map {$cmdspec->{subcommands}{$_}{summary}} @$scnames];
        }

        $res->{subcommand} //= [];

        my $push;
        my $sc_name;

        if (defined $res->{subcommand}[ $stash->{level} ]) {
            # subcommand has been set, e.g. by option handler
            $sc_name = $res->{subcommand}[ $stash->{level} ];
        } elsif (@ARGV) {
            $sc_name = shift @ARGV;
            $push++; # we need to push to $res->{subcommand} later
        } elsif (defined $cmdspec->{default_subcommand}) {
            $sc_name = $cmdspec->{default_subcommand};
            $push++;
        } else {
            # no subcommand
            $res->{success} = 1;
            return $res;
        }

        # for doing completion of subcommand names
        if ($is_completion) {
            push @{ $res->{comp_subcommand_name} }, $sc_name;
        }

        my $sc_spec = $cmdspec->{subcommands}{$sc_name};
        unless ($sc_spec) {
            warn "Unknown subcommand '$sc_name'".
                ($stash->{path} ? " for $stash->{path}":"")."\n"
                    unless $is_completion;
            $res->{success} = 0;
            return $res;
        };
        push @{ $res->{subcommand} }, $sc_name if $push;
        local $stash->{path} = ($stash->{path} ? "/" : "") . $sc_name;
        local $stash->{level} = $stash->{level}+1;
        _GetOptions($sc_spec, $is_completion, $res, $stash);
    }
    $res->{success} //= 1;

    #log_trace('[comp][glsubc] Final @ARGV: %s', \@ARGV) unless $stash->{path};
    #log_trace('[comp][glsubc] TMP: stash=%s', $stash);
    #log_trace('[comp][glsubc] TMP: res=%s', $res);
    $res;
}

sub GetOptions {
    my %cmdspec = @_;

    # figure out if we run in completion mode
    my ($is_completion, $shell, $words, $cword);
  CHECK_COMPLETION:
    {
        if ($ENV{COMP_SHELL}) {
            ($shell = $ENV{COMP_SHELL}) =~ s!.+/!!;
        } elsif ($ENV{COMMAND_LINE}) {
            $shell = 'tcsh';
        } else {
            $shell = 'bash';
        }

        if ($ENV{COMP_LINE} || $ENV{COMMAND_LINE}) {
            if ($ENV{COMP_LINE}) {
                $is_completion++;
                require Complete::Bash;
                ($words, $cword) = @{ Complete::Bash::parse_cmdline(
                    undef, undef, {truncate_current_word=>1}) };
                ($words, $cword) = @{ Complete::Bash::join_wordbreak_words(
                    $words, $cword) };
            } elsif ($ENV{COMMAND_LINE}) {
                $is_completion++;
                require Complete::Tcsh;
                $shell = 'tcsh';
                ($words, $cword) = @{ Complete::Tcsh::parse_cmdline() };
            } else {
                last CHECK_COMPLETION;
            }

            shift @$words; $cword--; # strip program name
            @ARGV = @$words;
        }
    }

    my $res = _GetOptions(\%cmdspec, $is_completion);

    if ($is_completion) {
        my $ospec = $res->{comp_ospec};
        require Complete::Getopt::Long;
        my $compres = Complete::Getopt::Long::complete_cli_arg(
            words => $words, cword => $cword, getopt_spec=>$ospec,
            extras => {
                stash => $res->{stash},
            },
            bundling => do {
                if (!$cmdspec{configure}) {
                    1;
                } elsif (grep { $_ eq 'bundling' } @{ $cmdspec{configure} }) {
                    1;
                } elsif (grep { $_ eq 'no_bundling' } @{ $cmdspec{configure} }) {
                    0;
                } else {
                    0;
                }
            },
            completion => sub {
                my %args = @_;

                my $word  = $args{word} // '';
                my $type  = $args{type};
                my $stash = $args{stash};

                # complete subcommand names
                if ($type eq 'arg' &&
                        $args{argpos} < @{$res->{comp_subcommand_names}//[]}) {
                    require Complete::Util;
                    return Complete::Util::complete_array_elem(
                        word      => $res->{comp_subcommand_name}[$args{argpos}],
                        array     => $res->{comp_subcommand_names}[$args{argpos}],
                        summaries => $res->{comp_subcommand_summaries}[$args{argpos}]
                    );
                }

                $args{getopt_res} = $res;
                $args{subcommand} = $res->{comp_subcommand_name};
                $cmdspec{completion}->(%args) if $cmdspec{completion};
            },
        );

        if ($shell eq 'bash') {
            print Complete::Bash::format_completion($compres);
        } elsif ($shell eq 'tcsh') {
            print Complete::Tcsh::format_completion($compres);
        } else {
            die "Unknown shell '$shell'";
        }

        exit 0;
    }

    # cleanup unneeded details
    $res;
}

1;
# ABSTRACT: Process command-line options, with subcommands and completion

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Long::Subcommand - Process command-line options, with subcommands and completion

=head1 VERSION

This document describes version 0.104 of Getopt::Long::Subcommand (from Perl distribution Getopt-Long-Subcommand), released on 2021-05-30.

=head1 SYNOPSIS

 use Getopt::Long::Subcommand; # exports GetOptions

 my %opts;
 my $res = GetOptions(

     summary => 'Summary about your program ...',

     # common options recognized by all subcommands
     options => {
         'help|h|?' => {
             summary => 'Display help message',
             handler => sub {
                 my ($cb, $val, $res) = @_;
                 if ($res->{subcommand}) {
                     say "Help message for $res->{subcommand} ...";
                 } else {
                     say "General help message ...";
                 }
                 exit 0;
             },
         'version|v' => {
             summary => 'Display program version',
             handler => sub {
                 say "Program version $main::VERSION";
                 exit 0;
             },
         'verbose' => {
             handler => \$opts{verbose},
         },
     },

     # list your subcommands here
     subcommands => {
         subcmd1 => {
             summary => 'The first subcommand',
             # subcommand-specific options
             options => {
                 'foo=i' => {
                     handler => \$opts{foo},
                 },
             },
         },
         subcmd1 => {
             summary => 'The second subcommand',
             options => {
                 'bar=s' => \$opts{bar},
                 'baz'   => \$opts{baz},
             },
         },
     },

     # tell how to complete option value and arguments. see
     # Getopt::Long::Complete for more details, the arguments are the same
     # except there is an additional 'subcommand' that gives the subcommand
     # name.
     completion => sub {
         my %args = @_;
         ...
     },

 );
 die "GetOptions failed!\n" unless $res->{success};
 say "Running subcommand $res->{subcommand} ...";

To run your script:

 % script
 Missing subcommand

 % script --help
 General help message ...

 % script subcmd1
 Running subcommand subcmd1 ...

 % script subcmd1 --help
 Help message for subcmd1 ...

 % script --verbose subcmd2 --baz --bar val
 Running subcommand subcmd2 ...

 % script subcmd3
 Unknown subcommand 'subcmd3'
 GetOptions failed!

=head1 DESCRIPTION

This module extends L<Getopt::Long> with subcommands and tab completion ability.

How parsing works: First we call C<Getopt::Long::GetOptions> with the top-level
options, passing through unknown options if we have subcommands. Then,
subcommand name is taken from the first argument. If subcommand has options, the
process is repeated. So C<Getopt::Long::GetOptions> is called once at every
level.

Completion: Scripts using this module can complete themselves. Just put your
script somewhere in your C<PATH> and run something like this in your bash shell:
C<complete -C script-name script-name>. See also L<shcompgen> to manage
completion scripts for multiple applications easily.

How completion works: Environment variable C<COMP_LINE> or C<COMMAND_LINE> (for
tcsh) is first checked. If it exists, we are in completion mode and C<@ARGV> is
parsed/formed from it. We then perform parsing to get subcommand names. Finally
we hand it off to L<Complete::Getopt::Long>.

=head1 FUNCTIONS

=head2 GetOptions(%cmdspec) => hash

Exported by default.

Process options and/or subcommand names specified in C<%cmdspec>, and remove
them from C<@ARGV> (thus modifying it). Will warn to STDERR on errors. Actual
command-line options parsing will be done using L<Getopt::Long>.

Return hash structure, with these keys: C<success> (bool, false if parsing
options failed e.g. unknown option/subcommand, illegal option value, etc),
C<subcommand> (array of str, subcommand name, if there is any; nested
subcommands will be listed in order, e.g. C<< ["sub1", "subsub1"] >>).

Arguments:

=over

=item * summary => str

Used by autohelp (not yet implemented).

=item * options => hash

A hash of option names and its specification. The specification is the same as
what you would feed to L<Getopt::Long>'s C<GetOptions>.

=item * subcommands => hash

A hash of subcommand name and its specification. The specification looks like
C<GetOptions> argument, with keys like C<summary>, C<options>, C<subcommands>
(for nested subcommands).

=item * default_subcommand => str

Default subcommand to use if no subcommand name is set. Subcommand can be set
using the first argument, or your option handler can also set the subcommand
using:

 $_[2]{subcommand_name} = 'something';

=item * configure => arrayref

Custom Getopt::Long configuration. The default is:

 ['no_ignore_case', 'no_getopt_compat', 'gnu_compat', 'bundling']

Note that even though you use custom configuration here, the tab completion
(performed by L<Complete::Getopt::Long> only supports C<no_ignore_case>,
C<gnu_compat>, and C<no_getopt_compat>.

=back

Differences with C<Getopt::Long>'s C<GetOptions>:

=over

=item *

Accept a command/subcommand specification (C<%cmdspec>) instead of just options
specification (C<%ospec>) like in C<Getopt::Long>).

=item *

This module's function returns hash instead of bool.

=item *

Coderefs in C<options> will receive an extra argument C<$res> which is the
result hash (being built). So the arguments that the coderefs get is:

 ($callback, $value, $res)

=back

=head1 FAQ

=head2 How to avoid modifying @ARGV? How to process from another array, like Getopt::Long's GetOptionsFromArray?

Instead of adding another function, you can use C<local>.

 {
     local @ARGV = ['--some', 'value'];
     GetOptions(...);
 }
 # the original @ARGV is restored

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Getopt-Long-Subcommand>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Getopt-Long-Subcommand>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Getopt-Long-Subcommand>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 CAVEATS

=head2 Common options take precedence over subcommand options

Common options (e.g. C<--help>) are parsed and removed from the command-line
first. This is done for convenience so you can do something like C<cmd subc
--help> or C<cmd --help subc> to get help. The consequence is you cannot have a
subcommand option with the same name as common option.

Similarly, options for a subcommand takes precedence over its sub-subcommand,
and so on.

=head1 SEE ALSO

L<Getopt::Long>

L<Getopt::Long::Complete>

L<Perinci::CmdLine> - a more full featured command-line application framework,
also with subcommands and completion.

L<Pod::Weaver::Section::Completion::GetoptLongSubcommand>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
