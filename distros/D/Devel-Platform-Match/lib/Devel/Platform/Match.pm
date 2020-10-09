package Devel::Platform::Match;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-09'; # DATE
our $DIST = 'Devel-Platform-Match'; # DIST
our $VERSION = '0.005'; # VERSION

use 5.014;
use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

use Exporter qw(import);
our @EXPORT_OK = qw(
                       match_platform
                       match_platform_bool
                       parse_platform_spec
               );

our %SPEC;
our $_val;
our $RE =
    qr{
          (?&CLAUSES) (?{ $_val = $^R->[1] })

          (?(DEFINE)
              (?<CLAUSES>
                  (?{ [$^R, []] })
                  (?&CLAUSE) # [[$^R, []], $clause]
                  (?{ [$^R->[0][0], [$^R->[1]]] })
                  (?:
                      (?:\s*,\s* | \s+)
                      (?&CLAUSE)
                      (?{
                          push @{$^R->[0][1]}, $^R->[1];
                          $^R->[0];
                      })
                  )*
                  \s*
              )

              (?<CLAUSE>
                  (?{ [$^R, []] }) # to be filled as [$^R, [$leftop, $op, $literal]]
                  ((?&LEFTOP)) (?{ push @{ $^R->[1] }, $^N; $^R }) # [$^R, [$^R, $leftop]]
                  (?{
                      #use Data::Dmp; say "D:setting leftop: ", dmp $^R;
                      push @{ $^R->[1] }, $^R->[0];
                      $^R;
                  })

                  (
                      \s*(?:=~|!~)\s* |
                      \s*(?:!=|<>|>=?|<=?|==?)\s* |
                      \s++(?:eq|ne|lt|gt|le|ge)\s++ |
                      \s+(?:isnt|is)\s+
                  )
                  (?{
                      my $op = $^N;
                      $op =~ s/^\s+//; $op =~ s/\s+$//;
                      $^R->[1][1] = $op;
                      $^R;
                  })

                  (?:
                      (?&LITERAL) # [[$^R0, [$attr, $op]], $literal]
                      (?{
                          push @{ $^R->[0][1] }, $^R->[1];
                          $^R->[0];
                      })
                  |
                      (\w[^\s\]]*) # allow unquoted string
                      (?{
                          $^R->[1][2] = $^N;
                          $^R;
                      })
                  )
              )

              (?<LEFTOP>
                  [A-Za-z_][A-Za-z0-9_]*
              )

              (?<LITERAL>
                  (?&LITERAL_NUMBER)
              |
                  (?&LITERAL_STRING_DQUOTE)
              |
                  (?&LITERAL_STRING_SQUOTE)
              |
                  (?&LITERAL_REGEX)
              |
                  true (?{ [$^R, 1] })
              |
                  false (?{ [$^R, 0] })
              |
                  null (?{ [$^R, undef] })
              )

              (?<LITERAL_NUMBER>
                  (
                      -?
                      (?: 0 | [1-9]\d* )
                      (?: \. \d+ )?
                      (?: [eE] [-+]? \d+ )?
                  )
                  (?{ [$^R, 0+$^N] })
              )

              (?<LITERAL_STRING_DQUOTE>
                  (
                      "
                      (?:
                          [^\\"]+
                      |
                          \\ [0-7]{1,3}
                      |
                          \\ x [0-9A-Fa-f]{1,2}
                      |
                          \\ ["\\'tnrfbae]
                      )*
                      "
                  )
                  (?{ [$^R, eval $^N] })
              )

              (?<LITERAL_STRING_SQUOTE>
                  (
                      '
                      (?:
                          [^\\']+
                      |
                          \\ .
                      )*
                      '
                  )
                  (?{ [$^R, eval $^N] })
              )

              (?<LITERAL_REGEX>
                  (
                      /
                      (?:
                          [^/\\]+
                      |
                          \\ .
                      )*
                      /
                      [ims]*
                  )
                  (?{ my $re = eval "qr$^N"; die if $@; [$^R, $re] })
              )

          ) # DEFINE
  }x;

our %aliases = (
    "linux32"      => "osflag=linux archname=i686",
    "linux64"      => "osflag=linux archname=x86_64",

    "linux-i386"   => "osflag=linux archname=i386",
    "linux-i686"   => "osflag=linux archname=i686",
    "linux-amd64"  => "osflag=linux archname=x86_64",
    "linux-x86_64" => "osflag=linux archname=x86_64",
    "win32"        => "osflag=Win32 archname=i686", # or i386?
    "win64"        => "osflag=Win32 archname=x86_64",
    "all"          => "",
);
for (keys %aliases) { $aliases{$_} = parse_platform_spec( $aliases{$_} ) or die "BUG: alias does not parse: '$aliases{$_}'" }

$SPEC{parse_platform_spec} = {
    v => 1.1,
    summary => 'Parse platform specification string into array of clauses',
    args_as => 'array',
    args => {
        spec => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
    examples => [
        {
            summary => "coercion of alias",
            args => {spec=>"linux32"},
            result => [["osflag","=","linux"], ["archname","=", "i686"]],
            test => 0, #args_as array not supported yet?
        },
        {
            args => {spec=>"osflag!=linux"},
            result => [["osflag","!=","linux"]],
            test => 0, #args_as array not supported yet?
        },
        {
            args => {spec=>"foo"},
            result => undef,
            test => 0, #args_as array not supported yet?
        },
    ],
};
sub parse_platform_spec {
    state $re = qr{\A\s*$RE\s*\z};

    local $_ = shift;
    return [] if $_ eq '';
    return $aliases{$_} if $aliases{$_};

    local $^R;
    local $_val;
    if ($_ =~ $re) {
        return $_val;
    } else {
        return undef;
    }
}

$SPEC{match_platform} = {
    v => 1.1,
    summary => 'Match platform information against platform spec',
    args_as => 'array',
    args => {
        spec => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        info => {
            summary => 'Hash(ref) of information returned by Devel::Platform::Info\'s get_info()',
            description => <<'_',

If not specified, will retrieve from <pm:Devel::Platform::Info>.

_
            schema => 'hash*',
            pos => 1,
        },
        quiet => {
            schema => 'bool*',
            pos => 2,
        },
    },
    description => <<'_',

See section "PLATFORM MATCHING" for details on how matching is done.

_
    examples => [
        {
            args => {info=>{osflag=>"linux", oslabel=>"Debian"}, spec=>"osflag=linux"},
            naked_result => 1,
            test => 0, #args_as array not supported yet?
        },
    ],
};
sub match_platform {
    my ($spec, $info, $quiet) = @_;

    unless ($info) {
        require Devel::Platform::Info;
        $info = Devel::Platform::Info->new->get_info;
    }

    my $parsed_spec;
    eval {
        $parsed_spec = parse_platform_spec($spec);
    };
    return [500, "Can't parse platform spec '$spec': $@"] if $@;
    return [412, "Invalid syntax in platform spec '$spec'"] unless $parsed_spec;

    my $match = 1;
    my $mismatch_reason;
    for my $clause (@{ $parsed_spec }) {
        no warnings 'numeric', 'uninitialized';

        my ($key, $op, $op_val) = @$clause;
        unless (exists $info->{$key}) {
            $match = 0;
            $mismatch_reason = "No key '$key'";
            last;
        }
        my $info_val = $info->{$key};

        # normalization
        if ($key eq 'archname') {
            if ($op_val   && $op_val   eq 'amd64') { $op_val   = 'x86_64' }
            if ($info_val && $info_val eq 'amd64') { $info_val = 'x86_64' }
        }

        # XXX support version (dotted) comparison?

        if ($op eq '=' || $op eq '==') {
            if (looks_like_number($op_val)) {
                do { $match=0; $mismatch_reason = "fails $key $info_val == $op_val"; last } unless $info_val == $op_val;
            } else {
                do { $match=0; $mismatch_reason = "fails $key $info_val eq $op_val"; last } unless $info_val eq $op_val;
            }
        } elsif ($op eq 'eq') {
            do { $match=0; $mismatch_reason = "fails $key $info_val eq $op_val"; last } unless $info_val eq $op_val;
        } elsif ($op eq '!=' || $op eq '<>') {
            if (looks_like_number($op_val)) {
                do { $match=0; $mismatch_reason = "fails $key $info_val != $op_val"; last } unless $info_val != $op_val;
            } else {
                do { $match=0; $mismatch_reason = "fails $key $info_val ne $op_val"; last } unless $info_val ne $op_val;
            }
        } elsif ($op eq 'ne') {
            do { $match=0; $mismatch_reason = "fails $key $info_val ne $op_val"; last } unless $info_val ne $op_val;
        } elsif ($op eq '>') {
            if (looks_like_number($op_val)) {
                do { $match=0; $mismatch_reason = "fails $key $info_val > $op_val"; last } unless $info_val >  $op_val;
            } else {
                do { $match=0; $mismatch_reason = "fails $key $info_val gt $op_val"; last } unless $info_val gt $op_val;
            }
        } elsif ($op eq 'gt') {
            do { $match=0; $mismatch_reason = "fails $key $info_val gt $op_val"; last } unless $info_val gt $op_val;
        } elsif ($op eq '>=') {
            if (looks_like_number($op_val)) {
                do { $match=0; $mismatch_reason = "fails $key $info_val >= $op_val"; last } unless $info_val >=  $op_val;
            } else {
                do { $match=0; $mismatch_reason = "fails $key $info_val != $op_val"; last } unless $info_val ge $op_val;
            }
        } elsif ($op eq 'ge') {
            do { $match=0; $mismatch_reason = "fails $key $info_val ge $op_val"; last } unless $info_val ge $op_val;
        } elsif ($op eq '<') {
            if (looks_like_number($op_val)) {
                do { $match=0; $mismatch_reason = "fails $key $info_val < $op_val"; last } unless $info_val <  $op_val;
            } else {
                do { $match=0; $mismatch_reason = "fails $key $info_val lt $op_val"; last } unless $info_val lt $op_val;
            }
        } elsif ($op eq 'lt') {
            do { $match=0; $mismatch_reason = "fails $key $info_val lt $op_val"; last } unless $info_val lt $op_val;
        } elsif ($op eq '<=') {
            if (looks_like_number($op_val)) {
                do { $match=0; $mismatch_reason = "fails $key $info_val <= $op_val"; last } unless $info_val <= $op_val;
            } else {
                do { $match=0; $mismatch_reason = "fails $key $info_val le $op_val"; last } unless $info_val le $op_val;
            }
        } elsif ($op eq 'le') {
            do { $match=0; $mismatch_reason = "fails $key $info_val le $op_val"; last } unless $info_val le $op_val;
        } elsif ($op eq 'is') {
            if (!defined($op_val)) {
                do { $match=0; $mismatch_reason = "fails $key undef is undef"; last } unless !defined($info_val);
            } elsif ($op_val) {
                do { $match=0; $mismatch_reason = "fails $key $info_val is true"; last } unless $info_val;
            } else {
                do { $match=0; $mismatch_reason = "fails $key $info_val is false"; last } unless !$info_val;
            }
        } elsif ($op eq 'isnt') {
            if (!defined($op_val)) {
                do { $match=0; $mismatch_reason = "fails $key $info_val isnt undef"; last } unless defined($info_val);
            } elsif ($op_val) {
                do { $match=0; $mismatch_reason = "fails $key $info_val isnt false"; last } unless !$info_val;
            } else {
                do { $match=0; $mismatch_reason = "fails $key $info_val isnt true"; last } unless $info_val;
            }
        } elsif ($op eq '=~') {
            do { $match=0; $mismatch_reason = "fails $key $info_val =~ $op_val"; last } unless $info_val =~ $op_val;
        } elsif ($op eq '!~') {
            do { $match=0; $mismatch_reason = "fails $key $info_val !~ $op_val"; last } unless $info_val !~ $op_val;
        } else {
            die "BUG: Unsupported operator '$op' in attr_selector";
        }
    } # for clause

    [200, "OK", $match, {
        'cmdline.result' => $quiet ? "" : ($match ? "Platform matches" : "Platform does NOT match ($mismatch_reason)"),
        'cmdline.exit_code' => $match ? 0:1,
    }];
}

sub match_platform_bool {
    my $res = match_platform(@_);
    $res->[0] == 200 && $res->[2] ? 1:0;
}

1;
# ABSTRACT: Match platform information with platform specification

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Platform::Match - Match platform information with platform specification

=head1 VERSION

This document describes version 0.005 of Devel::Platform::Match (from Perl distribution Devel-Platform-Match), released on 2020-10-09.

=head1 SYNOPSIS

 use Devel::Platform::Match qw(
     match_platform
     match_platform_bool
     parse_platform_spec
 );

 # assuming we're on an Ubuntu Linux 20.04 64bit
 my $envres = match_platform("osflag=linux"); # -> [200, "OK", 1]
 my $envres = match_platform("linux32");      # -> [200, "OK", 0] # linux32 is alias for "osflag=linux archname=x86"; archname doesn't match
 my $envres = match_platform("win64");        # -> [200, "OK", 0] # win64 is alias for "osflag=Win32 archname=x86_64"; osflag doesn't match
 my $envres = match_platform("osflag=linux oslabel=~/Debian|Ubuntu|Mint/");                 # -> [200, "OK", 1]
 my $envres = match_platform("osflag=linux, oslabel=~/Debian|Ubuntu|Mint/, osvers >= 21"); # -> [200, "OK", 0] # osvers doesn't match
 my $envres = match_platform("foo");                                                       # -> [412, "Invalid syntax in platform spec 'foo'"]

=head1 DESCRIPTION

This module lets you match platform information with platform specification.

=head1 PLATFORM SPECIFICATION SYNTAX

Platform specification syntax is modelled after CSS attribute selector (more
specifically, L<Data::CSel>'s attribute selector).

Platform specification is a whitespace- (or comma-) separated list of clauses.

Each clause is of the form: C<key> C<op> C<literal>.

C<key> is any key of the hash returned by L<Devel::Platform::Info>.

C<op> is operator supported by L<Data::CSel>.

C<literal> is a bareword number or word, or a quoted string. See Data::CSel for
more information.

A platform specification with zero clauses (C<"">) will match all platforms.

For convenience, some aliases will be coerced into a proper platform
specification first:

    "linux32"      => "osflag=linux archname=i686",
    "linux64"      => "osflag=linux archname=x86_64",
    "linux-i386"   => "osflag=linux archname=i386",
    "linux-i686"   => "osflag=linux archname=i686",
    "linux-amd64"  => "osflag=linux archname=x86_64",
    "linux-x86_64" => "osflag=linux archname=x86_64",
    "win32"        => "osflag=Win32 archname=i686",
    "win64"        => "osflag=Win32 archname=x86_64",
    "all"          => "",

Some examples of valid and invalid platform specifications:

 specification                  parse result                                            note
 -------------                  ------------                                            ----
 linux32                        [["osflag","=","linux"], ["archname","=","x86"]]        coerced to "osflag=linux archname=x86" before parsing
 oslabel=Ubuntu                 [["oslabel","=","Ubuntu"]]
 osflag=linux oslabel=Ubuntu    [["osflag","=","linux"], ["oslabel","=","Ubuntu"]]
 osflag=linux, oslabel=Ubuntu   [["osflag","=","linux"], ["oslabel","=","Ubuntu"]]      either whitespace or comma is okay as separator
 oslabel=~/Debian|Ubuntu/       [["oslabel","=~",qr/Debian|Ubuntu/]]
 is32bit=1                      [["is32bit","=",1]]                                     any 32bit platform
 is32bit is true                [["is32bit","is",1]]                                    any 64bit platform
 "" (empty string)              []                                                      no clauses, will match any platform info
 foo                            undef                                                   invalid syntax, unknown alias
 oslabel=Ubuntu,oslabel=Debian  [["osflag","=","Ubuntu"], ["osflag","=","Debian"]]      valid, but won't match any platform
 archname=amd64                 [["archname","=","amd64"]]                              Will match platform info {archname=>"x86_64"} because of normalization

=head1 PLATFORM MATCHING

First, some normalization is performed on the info hash. For L<archname>,
"amd64" will be coerced to "x86_64".

Then each clause will be tested. When the hash does not have the key specified
in the clause, the test fails.

Platform matches if all clauses pass.

=head1 FUNCTIONS


=head2 match_platform

Usage:

 match_platform($spec, $info, $quiet) -> [status, msg, payload, meta]

Match platform information against platform spec.

Examples:

=over

=item * Example #1:

 match_platform("osflag=linux", { osflag => "linux", oslabel => "Debian" });

Result:

 [200, "OK (envelope generated)", 1]

=back

See section "PLATFORM MATCHING" for details on how matching is done.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$info> => I<hash>

Hash(ref) of information returned by Devel::Platform::Info's get_info().

If not specified, will retrieve from L<Devel::Platform::Info>.

=item * B<$quiet> => I<bool>

=item * B<$spec>* => I<str>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 parse_platform_spec

Usage:

 parse_platform_spec($spec) -> array

Parse platform specification string into array of clauses.

Examples:

=over

=item * coercion of alias:

 parse_platform_spec("linux32"); # -> undef

=item * Example #2:

 parse_platform_spec("osflag!=linux"); # -> undef

=item * Example #3:

 parse_platform_spec("foo"); # -> undef

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$spec>* => I<str>


=back

Return value:  (array)


=head2 match_platform_bool

Usage:

 my $match = match_platform_bool($spec [ , $info [ , $quiet ] ]); # -> bool

Just like L</match_platform> but return a simple boolean value.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Devel-Platform-Match>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Devel-Platform-Match>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Platform-Match>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Devel::Platform::Info>

L<App::PlatformMatchUtils> provides CLI's for L</parse_platform_spec> and
L</match_platform>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
