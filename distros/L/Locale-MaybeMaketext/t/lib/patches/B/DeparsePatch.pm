## no critic (TestingAndDebugging::RequireUseStrict,TestingAndDebugging::RequireUseWarnings)
package B::DeparsePatch;
use B::Deparse;

sub import {

=encoding utf8

=head1 NAME

B::DeparsePatch - Patches B as it is broken between versions 1.40 and 1.54

=head1 AUTHORS

Copied from https://github.com/os-autoinst/os-autoinst-common/pull/19/commits/5c88dafa1169c54dea718815161ddd99b6e3b99e
https://github.com/os-autoinst/os-autoinst-common/pull/19

=head1 LICENSE


Licence: MIT License https://github.com/os-autoinst/os-autoinst-common/blob/master/LICENSE
MIT License

Copyright (c) 2019 openQA Development

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=head1 SEE ALSO

Monkeypatch B::Deparse
https://progress.opensuse.org/issues/40895
related: https://github.com/pjcj/Devel--Cover/issues/142
http://perlpunks.de/corelist/mversion?module=B::Deparse

=cut

    if (
        $B::Deparse::VERSION
        and ( $B::Deparse::VERSION >= '1.40' and ( $B::Deparse::VERSION <= '1.54' ) ) ## no critic (ValuesAndExpressions::ProhibitMismatchedOperators)
    ) {

        package B::Deparse;        ## no critic (Modules::ProhibitMultiplePackages)
        no warnings 'redefine';    ## no critic (TestingAndDebugging::ProhibitNoWarnings)
        no strict 'refs';          ## no critic (TestingAndDebugging::ProhibitNoStrict)

        *{'B::Deparse::walk_lineseq'} = sub {

            my ( $self, $op, $kids, $callback ) = @_;
            my @kids = @{$kids};
            for ( my $i = 0; $i < @kids; $i++ ) {    ## no critic (ControlStructures::ProhibitCStyleForLoops)
                my $expr = q{};
                if ( is_state $kids[$i] ) {

      # Patch for:
      # Use of uninitialized value $expr in concatenation (.) or string at /usr/lib/perl5/5.26.1/B/Deparse.pm line 1794.
                    $expr = $self->deparse( $kids[ $i++ ], 0 ) // q{};    # prevent undef $expr
                    if ( $i > $#kids ) {
                        $callback->( $expr, $i );
                        last;
                    }
                }
                if ( is_for_loop( $kids[$i] ) ) {
                    $callback->(
                        $expr . $self->for_loop( $kids[$i], 0 ),
                        $i += $kids[$i]->sibling->name eq 'unstack' ? 2 : 1
                    );
                    next;
                }
                my $expr2 = $self->deparse( $kids[$i], ( @kids != 1 ) / 2 ) // q{};    # prevent undef $expr2
                $expr2 =~ s/^sub :(?!:)/+sub :/;                                       # statement label otherwise
                $expr .= $expr2;
                $callback->( $expr, $i );
            }

        };

        #warn "Deparse patch applied for $B::Deparse::VERSION\n";

    }
    return 1;
}

1;
