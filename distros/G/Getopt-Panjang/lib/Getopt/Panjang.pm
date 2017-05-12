package Getopt::Panjang;

our $DATE = '2015-09-15'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
# IFUNBUILT
# use warnings;
# END IFUNBUILT

our %SPEC;
our @EXPORT    = qw();
our @EXPORT_OK = qw(get_options);

sub import {
    my $pkg = shift;
    my $caller = caller;
    my @imp = @_ ? @_ : @EXPORT;
    for my $imp (@imp) {
        if (grep {$_ eq $imp} (@EXPORT, @EXPORT_OK)) {
            *{"$caller\::$imp"} = \&{$imp};
        } else {
            die "$imp is not exported by ".__PACKAGE__;
        }
    }
}

$SPEC{get_options} = {
    v => 1.1,
    summary => 'Parse command-line options',
    args => {
        argv => {
            summary => 'Command-line arguments, which will be parsed',
            description => <<'_',

If unspecified, will default to `@ARGV`.

_
            schema => ['array*', of=>'str*'],
            pos => 0,
            greedy => 1,
        },
        spec => {
            summary => 'Options specification',
            description => <<'_',

Similar like `Getopt::Long` and `Getopt::Long::Evenless`, this argument should
be a hash. The keys should be option name specifications, while the values
should be option handlers.

Option name specification is like in `Getopt::Long::EvenLess`, e.g. `name`,
`name=s`, `name|alias=s`.

Option handler will be passed `%args` with the possible keys as follow: `name`
(str, option name), `value` (any, option value). A handler can die with an error
message to signify failed validation for the option value.

_
            schema => ['hash*', values=>'code*'],
            req => 1,
        },
    },
    result => {
        description => <<'_',

Will return 200 on parse success. If there is an error, like missing option
value or unknown option, will return 500. The result metadata will contain more
information about the error.

_
    },
};
sub get_options {
    my %args = @_;

    # XXX schema
    my $argv;
    if ($args{argv}) {
        ref($args{argv}) eq 'ARRAY' or return [400, "argv is not an array"];
        $argv = $args{argv};
    } else {
        $argv = \@ARGV;
    }
    my $spec = $args{spec} or return [400, "Please specify spec"];
    ref($args{spec}) eq 'HASH' or return [400, "spec is not a hash"];
    for (keys %$spec) {
        return [400, "spec->{$_} is not a coderef"]
            unless ref($spec->{$_}) eq 'CODE';
    }

    my %spec_by_opt_name;
    for (keys %$spec) {
        my $orig = $_;
        s/=[fios]\@?\z//;
        s/\|.+//;
        $spec_by_opt_name{$_} = $orig;
    }

    my $code_find_opt = sub {
        my ($wanted, $short_mode) = @_;
        my @candidates;
      OPT_SPEC:
        for my $speckey (keys %$spec) {
            $speckey =~ s/=[fios]\@?\z//;
            my @opts = split /\|/, $speckey;
            for my $o (@opts) {
                next if $short_mode && length($o) > 1;
                if ($o eq $wanted) {
                    # perfect match, we immediately go with this one
                    @candidates = ($opts[0]);
                    last OPT_SPEC;
                } elsif (index($o, $wanted) == 0) {
                    # prefix match, collect candidates first
                    push @candidates, $opts[0];
                    next OPT_SPEC;
                }
            }
        }
        if (!@candidates) {
            return [404, "Unknown option '$wanted'", undef,
                    {'func.unknown_opt' => $wanted}];
        } elsif (@candidates > 1) {
            return [300, "Option '$wanted' is ambiguous", undef, {
                'func.ambiguous_opt' => $wanted,
                'func.ambiguous_candidates' => [sort @candidates],
            }];
        }
        return [200, "OK", $candidates[0]];
    };

    my $code_set_val = sub {
        my $name = shift;

        my $speckey = $spec_by_opt_name{$name};
        my $handler = $spec->{$speckey};

        eval {
            $handler->(
                name  => $name,
                value => (@_ ? $_[0] : 1),
            );
        };
        if ($@) {
            return [400, "Invalid value for option '$name': $@", undef,
                    {'func.val_invalid_opt' => $name}];
        } else {
            return [200];
        }
    };

    my %unknown_opts;
    my %ambiguous_opts;
    my %val_missing_opts;
    my %val_invalid_opts;

    my $i = -1;
    my @remaining;
  ELEM:
    while (++$i < @$argv) {
        if ($argv->[$i] eq '--') {

            push @remaining, @{$argv}[$i+1 .. @$argv-1];
            last ELEM;

        } elsif ($argv->[$i] =~ /\A--(.+?)(?:=(.*))?\z/) {

            my ($used_name, $val_in_opt) = ($1, $2);
            my $findres = $code_find_opt->($used_name);
            if ($findres->[0] == 404) { # unknown opt
                push @remaining, $argv->[$i];
                $unknown_opts{ $findres->[3]{'func.unknown_opt'} }++;
                next ELEM;
            } elsif ($findres->[0] == 300) { # ambiguous
                $ambiguous_opts{ $findres->[3]{'func.ambiguous_opt'} } =
                    $findres->[3]{'func.ambiguous_candidates'};
                next ELEM;
            } elsif ($findres->[0] != 200) {
                return [500, "An unexpected error occurs", undef, {
                    'func._find_opt_res' => $findres,
                }];
            }
            my $opt = $findres->[2];

            my $speckey = $spec_by_opt_name{$opt};
            # check whether option requires an argument
            if ($speckey =~ /=[fios]\@?\z/) {
                if (defined $val_in_opt) {
                    # argument is taken after =
                    if (length $val_in_opt) {
                        my $setres = $code_set_val->($opt, $val_in_opt);
                        $val_invalid_opts{$opt} = $setres->[1]
                            unless $setres->[0] == 200;
                    } else {
                        $val_missing_opts{$used_name}++;
                        next ELEM;
                    }
                } else {
                    if ($i+1 >= @$argv) {
                        # we are the last element
                        $val_missing_opts{$used_name}++;
                        last ELEM;
                    }
                    $i++;
                    my $setres = $code_set_val->($opt, $argv->[$i]);
                    $val_invalid_opts{$opt} = $setres->[1]
                        unless $setres->[0] == 200;
                }
            } else {
                my $setres = $code_set_val->($opt);
                $val_invalid_opts{$opt} = $setres->[1]
                    unless $setres->[0] == 200;
            }

        } elsif ($argv->[$i] =~ /\A-(.*)/) {

            my $str = $1;
          SHORT_OPT:
            while ($str =~ s/(.)//) {
                my $used_name = $1;
                my $findres = $code_find_opt->($1, 'short');
                next SHORT_OPT unless $findres->[0] == 200;
                my $opt = $findres->[2];

                my $speckey = $spec_by_opt_name{$opt};
                # check whether option requires an argument
                if ($speckey =~ /=[fios]\@?\z/) {
                    if (length $str) {
                        # argument is taken from $str
                        my $setres = $code_set_val->($opt, $str);
                        $val_invalid_opts{$opt} = $setres->[1]
                            unless $setres->[0] == 200;
                        next ELEM;
                    } else {
                        if ($i+1 >= @$argv) {
                            # we are the last element
                            $val_missing_opts{$used_name}++;
                            last ELEM;
                        }
                        # take the next element as argument
                        $i++;
                        my $setres = $code_set_val->($opt, $argv->[$i]);
                        $val_invalid_opts{$opt} = $setres->[1]
                            unless $setres->[0] == 200;
                    }
                } else {
                    my $setres = $code_set_val->($opt);
                    $val_invalid_opts{$opt} = $setres->[1]
                        unless $setres->[0] == 200;
                }
            }

        } else { # argument

            push @remaining, $argv->[$i];
            next;

        }
    }

  RETURN:
    my ($status, $msg);
    if (!keys(%unknown_opts) && !keys(%ambiguous_opts) &&
            !keys(%val_missing_opts) && !keys(%val_invalid_opts)) {
        $status = 200;
        $msg = "OK";
    } else {
        $status = 500;
        my @errs;
        if (keys %unknown_opts) {
            push @errs, "Unknown option" .
                (keys(%unknown_opts) > 1 ? "s ":" ") .
                join(", ", map {"'$_'"} sort keys %unknown_opts);
        }
        for (sort keys %ambiguous_opts) {
            push @errs, "Ambiguous option '$_' (" .
                join("/", @{$ambiguous_opts{$_}}) . "?)";
        }
        if (keys %val_missing_opts) {
            push @errs, "Missing required value for option" .
                (keys(%val_missing_opts) > 1 ? "s ":" ") .
                join(", ", map {"'$_'"} sort keys %val_missing_opts);
        }
        for (keys %val_invalid_opts) {
            push @errs, "Invalid value for option '$_': " .
                $val_invalid_opts{$_};
        }
        $msg = (@errs > 1 ? "Errors in parsing command-line options: " : "").
            join("; ", @errs);
    }
    [$status, $msg, undef, {
        'func.remaining_argv' => \@remaining,
        ('func.unknown_opts'     => \%unknown_opts    )
            x (keys(%unknown_opts) ? 1:0),
        ('func.ambiguous_opts'   => \%ambiguous_opts  )
            x (keys(%ambiguous_opts) ? 1:0),
        ('func.val_missing_opts' => \%val_missing_opts)
            x (keys(%val_missing_opts) ? 1:0),
        ('func.val_invalid_opts' => \%val_invalid_opts)
            x (keys(%val_invalid_opts) ? 1:0),
    }];
}

1;
# ABSTRACT: Parse command-line options

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Panjang - Parse command-line options

=head1 VERSION

This document describes version 0.04 of Getopt::Panjang (from Perl distribution Getopt-Panjang), released on 2015-09-15.

=head1 SYNOPSIS

 use Getopt::Panjang qw(get_options);

 my $opts;
 my $res = get_options(
     # similar to Getopt::Long, except values must be coderef (handler), and
     # handler receives hash argument
     spec => {
         'bar'   => sub { $opts->{bar} = 1 },
         'baz=s' => sub { my %a = @_; $opts->{baz} = $a{value} },
         'err=s' => sub { die "Bzzt\n" },
     },
     argv => ["--baz", 1, "--bar"], # defaults to @ARGV
 );

 if ($res->[0] == 200) {
     # do stuffs with parsed options, $opts
 } else {
     die $res->[1];
 }

Sample success result when C<@ARGV> is C<< ["--baz", 1, "--bar"] >>:

 [200, "OK", undef, { "func.remaining_argv" => [] }]

Sample error result (ambiguous option) when C<@ARGV> is C<< ["--ba", 1] >>:

 [
   500,
   "Ambiguous option 'ba' (bar/baz?)",
   undef,
   {
     "func.ambiguous_opts" => { ba => ["bar", "baz"] },
     "func.remaining_argv" => [1],
   },
 ]

Sample error result (option with missing value) when C<@ARGV> is C<< ["--bar",
"--baz"] >>:

[
   500,
   "Missing required value for option 'baz'",
   undef,
   {
     "func.remaining_argv"   => [],
     "func.val_missing_opts" => { baz => 1 },
   },
 ]

Sample error result (unknown option) when C<@ARGV> is C<< ["--foo", "--qux"] >>:

 [
    500,
   "Unknown options 'foo', 'qux'",
   undef,
   {
     "func.remaining_argv" => ["--foo", "--qux"],
     "func.unknown_opts"   => { foo => 1, qux => 1 },
   },
 ]

Sample error result (option with invalid value where the option handler dies)
when C<@ARGV> is C<< ["--err", 1] >>:

 [
   500,
   "Invalid value for option 'err': Invalid value for option 'err': Bzzt\n",
   undef,
   {
     "func.remaining_argv"   => [],
     "func.val_invalid_opts" => { err => "Invalid value for option 'err': Bzzt\n" },
   },
 ]

=head1 DESCRIPTION

B<EXPERIMENTAL WORK>.

This module is similar to L<Getopt::Long>, but with a rather different
interface. After experimenting with L<Getopt::Long::Less> and
L<Getopt::Long::EvenLess> (which offers interface compatibility with
Getopt::Long), I'm now trying a different interface which will enable me to
"clean up" or do "more advanced" stuffs.

Here are the goals of Getopt::Panjang:

=over

=item * low startup overhead

Less than Getopt::Long, comparable to Getopt::Long::EvenLess.

=item * feature parity with Getopt::Long::EvenLess

More features will be offered in the future.

=item * more detailed error return

This is the main goal which motivates me to write Getopt::Panjang. In
Getopt::Long, if there is an error like an unknown option, or validation error
for an option's value, or missing option value, you only get a string warning.
Getopt::Panjang will instead return a data structure with more details so you
can know which option is missing the value, which unknown option is specified by
the user, etc. This will enable scripts/frameworks to do something about it,
e.g. suggest the correct option when mistyped.

=back

The interface differences with Getopt::Long:

=over

=item * There is only a single function, and no default exports

Getopt::Long has C<GetOptions>, C<GetOptionsFromArray>, C<GetOptionsFromString>.
We only offer C<get_options> which must be exported explicitly.

=item * capitalization of function names

Lowercase with underscores (C<get_options>) is used instead of camel case
(C<GetOptions>).

=item * C<get_options> accepts hash argument

This future-proofs the function when we want to add more configuration.

=item * option handler also accepts hash argument

This future-proofs the handler when we want to give more arguments to the
handler.

=item * There are no globals

Every configuration is specified through the C<get_options> function. This is
cleaner.

=item * C<get_options> never dies, never prints warnings

It only returns the detailed error structure so you can do whatever about it.

=item * C<get_options> never modifies argv/@ARGV

Remaining argv after parsing is returned in the result metadata.

=back

Sample startup overhead benchmark:

                            Rate     load_gl      run_gl     load_gp       run_gp run_gl_less load_gl_less load_gl_evenless run_gl_evenless   perl
 load_gl           73.23+-0.35/s          --       -2.6%      -65.4%       -65.5%      -68.0%       -70.9%           -78.9%          -80.0% -88.7%
 run_gl            75.22+-0.17/s 2.71+-0.55%          --      -64.4%       -64.6%      -67.2%       -70.1%           -78.3%          -79.4% -88.3%
 load_gp            211.4+-2.2/s 188.7+-3.3% 181.1+-2.9%          --        -0.5%       -7.7%       -16.0%           -39.1%          -42.2% -67.2%
 run_gp           212.44+-0.86/s 190.1+-1.8% 182.4+-1.3%   0.5+-1.1%           --       -7.2%       -15.6%           -38.8%          -41.9% -67.1%
 run_gl_less          229+-1.3/s 212.7+-2.3% 204.5+-1.8%   8.3+-1.3%   7.8+-0.74%          --        -9.0%           -34.0%          -37.4% -64.5%
 load_gl_less     251.76+-0.83/s   243.8+-2% 234.7+-1.4%  19.1+-1.3% 18.51+-0.62% 9.93+-0.71%           --           -27.5%          -31.2% -61.0%
 load_gl_evenless   347.1+-3.5/s   374+-5.3% 361.5+-4.8%  64.2+-2.4%   63.4+-1.8%  51.6+-1.7%   37.9+-1.5%               --           -5.1% -46.2%
 run_gl_evenless    365.7+-1.8/s 399.4+-3.4% 386.2+-2.6%      73+-2%   72.1+-1.1%  59.7+-1.2% 45.26+-0.85%        5.3+-1.2%              -- -43.4%
 perl               645.6+-6.8/s    782+-10% 758.3+-9.3% 205.3+-4.5%  203.9+-3.4% 181.9+-3.4%  156.4+-2.8%         86+-2.7%      76.5+-2.1%     --
 
 Average times:
   perl            :     1.5489ms
   run_gl_evenless :     2.7345ms
   load_gl_evenless:     2.8810ms
   load_gl_less    :     3.9720ms
   run_gl_less     :     4.3668ms
   run_gp          :     4.7072ms
   load_gp         :     4.7304ms
   run_gl          :    13.2943ms
   load_gl         :    13.6556ms

=head1 FUNCTIONS


=head2 get_options(%args) -> [status, msg, result, meta]

Parse command-line options.

Arguments ('*' denotes required arguments):

=over 4

=item * B<argv> => I<array[str]>

Command-line arguments, which will be parsed.

If unspecified, will default to C<@ARGV>.

=item * B<spec>* => I<hash>

Options specification.

Similar like C<Getopt::Long> and C<Getopt::Long::Evenless>, this argument should
be a hash. The keys should be option name specifications, while the values
should be option handlers.

Option name specification is like in C<Getopt::Long::EvenLess>, e.g. C<name>,
C<name=s>, C<name|alias=s>.

Option handler will be passed C<%args> with the possible keys as follow: C<name>
(str, option name), C<value> (any, option value). A handler can die with an error
message to signify failed validation for the option value.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


Will return 200 on parse success. If there is an error, like missing option
value or unknown option, will return 500. The result metadata will contain more
information about the error.

=for Pod::Coverage .+

=head1 SEE ALSO

L<Getopt::Long>

L<Getopt::Long::Less>, L<Getopt::Long::EvenLess>

L<Perinci::Sub::Getopt>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Getopt-Panjang>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Getopt-Panjang>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Getopt-Panjang>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
