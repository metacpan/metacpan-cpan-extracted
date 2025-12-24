package Getopt::Long::Bash;

our $VERSION = "0.6.0";

1;

__END__

=encoding utf-8

=head1 NAME

Getopt::Long::Bash - Bash option parsing that does what you mean

=head1 SYNOPSIS

    declare -A OPTS=(
        [verbose|v]=
        [count  |c:=i]=1
    )
    . getoptlong.sh OPTS "$@"

=head1 DESCRIPTION

=head2 Why Another Option Parser?

If you've written Bash scripts, you know the pain. You start with a
simple script, add a few options with C<getopts>, and then...

I<"Can we add a --verbose flag?">

Sorry, C<getopts> doesn't do long options.

I<"The script fails when I put the filename before the options.">

Right, C<getopts> requires options to come first.

I<"I need to pass multiple include paths.">

You'll have to handle that yourself.

I<"Can it validate that --count is a number?">

Write your own validation.

I<"Users keep asking how to use it.">

Write a help message. And keep it in sync with your code. Manually.

Sound familiar?

=head2 There Has to Be a Better Way

Perl developers have enjoyed L<Getopt::Long> for decades - a
battle-tested option parser that just works. What if Bash had
something similar?

That's exactly what B<getoptlong.sh> provides.

=head2 Define Once, Get Everything

Instead of scattered C<getopts> calls and manual validation, define
your options in one place:

    declare -A OPTS=(
        [verbose |v             ]=      # flag (increments with -vvv)
        [output  |o:            ]=      # required argument
        [config  |c?            ]=      # optional argument
        [include |I@            ]=      # array (multiple values)
        [define  |D%            ]=      # hash (key=value pairs)
        [count   |n:=i          ]=1     # integer validation
        [mode    |m:=(fast|slow)]=fast  # regex validation
    )
    . getoptlong.sh OPTS "$@"

That's it. One line to parse. You get:

=over 4

=item B<Long and short options>

C<--verbose> and C<-v> work the same way.

=item B<Option bundling>

C<-vvv> increments verbose three times.

=item B<GNU-style flexibility>

C<script.sh file.txt --verbose> works. Options and arguments mix freely.

=item B<Rich data types>

Arrays collect multiple C<--include> paths. Hashes store C<--define KEY=VALUE> pairs.

=item B<Built-in validation>

C<=i> ensures integers, C<=f> for floats, C<=(regex)> for patterns.
Bad input? Clear error message. No corrupted state.

=item B<Automatic help>

C<--help> generates usage from your definitions. Always accurate,
zero maintenance.

=item B<Callbacks>

Execute functions when options are parsed. Perfect for C<--trace>
enabling C<set -x>.

=back

=head2 Real-World Example

Here's a complete script:

    #!/usr/bin/env bash
    set -eu

    declare -A OPTS=(
        [&USAGE]="$0 [options] command..."
        [count  |c:=i # repeat count  ]=1
        [sleep  |i@=f # interval time ]=
        [trace  |x!   # trace mode    ]=
        [debug  |d    # debug level   ]=0
    )
    trace() { [[ $2 ]] && set -x || set +x; }

    . getoptlong.sh OPTS "$@"

    for (( i = 0; i < count; i++ )); do
        "$@"
        [[ ${sleep[0]:-} ]] && sleep "${sleep[0]}"
    done

Run it:

    $ repeat.sh --count=3 --sleep=0.5 echo hello
    hello
    hello
    hello

    $ repeat.sh --help
    Usage: repeat.sh [options] command...
    Options:
        --count, -c       repeat count (default: 1)
        --sleep, -i       interval time
        --trace, -x       trace mode
        --debug, -d       debug level (default: 0)

=head2 Designed for Wrapper Scripts

Building a wrapper around another command? Pass-through mode forwards
options untouched:

    [jobs|j:>make_opts]=    # Collect into array

After C<--jobs=4>, the C<make_opts> array contains C<("--jobs" "4")>,
ready to pass to the underlying command.

=head2 Subcommand Support

Call C<getoptlong> multiple times for git-style subcommands:

    # Parse global options
    getoptlong init GlobalOPTS
    getoptlong parse "$@" && eval "$(getoptlong set)"

    # Parse subcommand options
    case "$1" in
        commit) getoptlong init CommitOPTS; ... ;;
    esac

=head1 INSTALLATION

=head2 Via CPAN (Recommended)

    cpanm Getopt::Long::Bash

After installation, C<getoptlong.sh> is in your PATH.

=head2 Direct Download

    curl -o getoptlong.sh \
      https://raw.githubusercontent.com/tecolicom/getoptlong/dist/getoptlong.sh

=head2 Source Directly (For Quick Tests)

    source <(curl -fsSL \
      https://raw.githubusercontent.com/tecolicom/getoptlong/dist/getoptlong.sh)

=head1 REQUIREMENTS

Bash 4.2 or later (for associative arrays and C<declare -n>).

=head1 SEE ALSO

=over 4

=item L<getoptlong> - Complete reference manual

=item L<Getopt::Long::Bash::Tutorial> - Step-by-step getting started guide

=item L<https://github.com/tecolicom/getoptlong> - Source repository

=item L<https://qiita.com/kaz-utashiro/items/75a7df9e1a1e92797376> - Introduction article (Japanese)

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

MIT License

=cut
