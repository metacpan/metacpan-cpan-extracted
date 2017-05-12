package Gen::Test::Rinci::FuncResult;

our $DATE = '2015-09-03'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;
#use experimental 'smartmatch';
#use Log::Any '$log';

use Carp;
use Data::Dump::OneLine qw(dump1);
use Test::More 0.98;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(gen_test_func);

our %SPEC;

$SPEC{gen_test_func} = {
    v => 1.1,
    summary => 'Generate a test function for a function',
    description => <<'_',

This function (A) will generate a function (B).

A accepts, among others, the name or the reference to the function that you want
to test (T) and the name of the generated function, B.

B will run T once with some specified arguments, catch exception, and test its
result. The result is expected to be an enveloped result (see the documentation
of `Rinci::function` for more details about enveloped result).

B will accept the following arguments:

* name (str)

  Name of the test. Will default to "T (ARGS...)" to show the name of the target
  function and the arguments that it is called with.

* args (hash or array)

  Argument to feed to function T.

* dies (bool, default => 0)

  Whether function T should die when run. If set to 1, further tests will not be
  done except the test that function dies.

* status (int, default => 200)

  Will test the result's status code.

* result (any)

  If specified, will test the actual result of the function.

* run (code)

  Instead of running function T with `args`, will execute this code instead.

* posttest (code)

  Run this code for additional tests.

Todo:

* Handle function with `result_naked` => 1.

_
    args => {
        name => {
            summary => 'Name of the test function to generate (B)',
            schema  => ['str*'],
            description => <<'_',

Can be fully qualified, e.g. `Pkg::SubPkg::funcname` or unqualified `funcname`
(where the package will be taken from the `package` argument). Relevant for when
installing the function.

_
            pos => 0,
            req => 1,
        },
        package => {
            summary => 'Perl package to put this function in',
            description => <<'_',

Relevant only when installing the function.

_
        },
        func => {
            summary => 'Target function to test',
            schema  => ['any*' => {of => ['code*']}],
            req => 1,
        },
        install => {
            schema  => [bool => default => 1],
            summary => 'Whether to install the function',
        },
    },
};
sub gen_test_func {
    my %genargs = @_;

    my ($uqname, $package);
    my $fqname = $genargs{name}
        or die "Please specify name (name of generated function)";
    my $targetf = $genargs{func}
        or die "Please specify func (arget function to test)";

    my @caller = caller(1);
    if ($fqname =~ /(.+)::(.+)/) {
        $package = $1;
        $uqname  = $2;
    } else {
        $package = $genargs{package} // $caller[0] // "";
        $uqname  = $fqname;
        $fqname  = "$package\::$uqname";
    }

    my $func = sub {
        my %tfargs = @_;
        my $suc = 1; # whether the whole test function succeeds

        my $args = $tfargs{args} // {};
        my $name = $tfargs{name} // "$fqname ".dump1($args);
        subtest $name => sub {
            my $res;
            eval {
                if ($tfargs{run}) {
                    $res = $tfargs{run}->(%tfargs);
                } else {
                    $res = $targetf->(
                        ref($args) eq 'HASH' ? %$args :
                            ref($args) eq 'ARRAY' ? @$args : $args);
                }
            };
            my $eval_err = $@;

            # test that function does not die
            my $dies = $tfargs{dies} // 0;
            if (!$dies) {
                ok(!$eval_err, "func doesn't die")
                    or do { diag "func died: '$eval_err'"; $suc=0; goto DONE };
            } else {
                ok($eval_err, "func dies") or $suc = 0;
                goto DONE;
            }

            # test that result is well-formed
            ok(defined($res), "result is defined")
                or do { $suc = 0; goto DONE };
            ok(ref($res) eq 'ARRAY', "result is an array")
                or do { $suc = 0; goto DONE };

            # test status code
            my $status = $tfargs{status} // 200;
            is($res->[0], $status, "status is $status") or $suc = 0;

            # test message
            if (defined $tfargs{message}) {
                is($res->[1], $tfargs{message}, "message") or $suc = 0;
            }

            if (exists $tfargs{result}) {
                is_deeply($res->[2], $tfargs{result}, "result")
                    or do { $suc = 0; diag explain "result is: ", $res->[2] };
            }

            if ($tfargs{posttest}) {
                $tfargs{posttest}->($res) or $suc = 0;
            }

          DONE:
            return $suc;
        }; # subtest
    };

    # XXX
    my $meta = {v=>1.1};

    if ($genargs{install} // 1) {
        no strict 'refs';
        no warnings;
        #$log->tracef("Installing function as %s ...", $fqname);
        *{ $fqname } = $func;
        #${$package . "::SPEC"}{$uqname} = $meta;
    }

    [200, "OK", {code=>$func, meta=>$meta}];
}

1;
# ABSTRACT: Generate a test function for a function

__END__

=pod

=encoding UTF-8

=head1 NAME

Gen::Test::Rinci::FuncResult - Generate a test function for a function

=head1 VERSION

This document describes version 0.05 of Gen::Test::Rinci::FuncResult (from Perl distribution Gen-Test-Rinci-FuncResult), released on 2015-09-03.

=head1 SYNOPSIS

 use Gen::Test::Rinci::FuncResult qw(gen_test_func);
 use Test::More;

 sub divide {
     my %args = @_;
     my ($a, $b) = ($args{a}, $args{b});
     return [500, "undefined"] if $a == 0 && $b == 0;
     [200, "OK", $a/$b];
 }

 gen_test_func(name => 'test_divide', func => \&divide);

 test_divide(args=>{a=>6, b=>3}, result=>2);
 test_divide(args=>{a=>6, b=>0}, dies=>1);
 test_divide(args=>{a=>0, b=>0}, status=>500);
 done_testing;

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 gen_test_func(%args) -> [status, msg, result, meta]

Generate a test function for a function.

This function (A) will generate a function (B).

A accepts, among others, the name or the reference to the function that you want
to test (T) and the name of the generated function, B.

B will run T once with some specified arguments, catch exception, and test its
result. The result is expected to be an enveloped result (see the documentation
of C<Rinci::function> for more details about enveloped result).

B will accept the following arguments:

=over

=item * name (str)

Name of the test. Will default to "T (ARGS...)" to show the name of the target
function and the arguments that it is called with.

=item * args (hash or array)

Argument to feed to function T.

=item * dies (bool, default => 0)

Whether function T should die when run. If set to 1, further tests will not be
done except the test that function dies.

=item * status (int, default => 200)

Will test the result's status code.

=item * result (any)

If specified, will test the actual result of the function.

=item * run (code)

Instead of running function T with C<args>, will execute this code instead.

=item * posttest (code)

Run this code for additional tests.

=back

Todo:

=over

=item * Handle function with C<result_naked> => 1.

=back

Arguments ('*' denotes required arguments):

=over 4

=item * B<func>* => I<code>

Target function to test.

=item * B<install> => I<bool> (default: 1)

Whether to install the function.

=item * B<name>* => I<str>

Name of the test function to generate (B).

Can be fully qualified, e.g. C<Pkg::SubPkg::funcname> or unqualified C<funcname>
(where the package will be taken from the C<package> argument). Relevant for when
installing the function.

=item * B<package> => I<any>

Perl package to put this function in.

Relevant only when installing the function.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 FAQ

=head1 SEE ALSO

L<Rinci>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Gen-Test-Rinci-FuncResult>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Gen-Test-Rinci-FuncResult>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Gen-Test-Rinci-FuncResult>

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
