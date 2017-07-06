package # hidden from PAUSE indexer
Test::Expr;
our $VERSION = '0.000001';

use 5.012; use warnings; use autodie;
use Keyword::Declare;
use Test::More;
use Data::Dump;
use List::Util 'max';
use parent 'Exporter';
our @EXPORT = @Test::More::EXPORT;
use PPI;

sub _trim {
    my $str = shift;
    $str =~ s{\A\s*|\s*\Z}{}g;
    return $str;
}

sub import {
    my ($package) = @_;
    $package->export_to_level(1, @_);

    keyword test (Expr $expr) {
        # Break the test on the first of these...
        state $COMPARATOR = qr{\A (?: == | != | < | > | <= | >= | eq | ne | lt | gt | le | ge ) \Z}xms;

        # Decompose the test arguments...
        $expr = PPI::Document->new(\$expr);
        my %arg;
        my $curr = 'found';
        for my $component ($expr->child(0)->children) {
            if ($curr eq 'found' && $component =~ $COMPARATOR) {
                $arg{comparator} = $component;
                $curr = 'expected';
            }
            elsif ($curr eq 'expected' && $component eq '=>') {
                $curr = 'desc';
            }
            else {
                $arg{$curr} .= $component;
            }
        }

        # Tidy up any loose ends...
        $arg{desc} //= qq{q{$expr at }.__FILE__.q{ line }.__LINE__};
        $_ = _trim($_) for values %arg;

        # Work out what values to report if there's a problem...
        my @vars;
        for my $sym (@{$expr->find('PPI::Token::Symbol')}) {
            push @vars, $sym;
            my $sib = $sym;
            while (( $sib = $sib->snext_sibling )) {
                last if not $sib->isa('PPI::Structure::Subscript');
                $vars[-1] .= $sib;
            }
        }
        my $var_len = max map {length} @vars;
        my %seen;
        my @diagnostics
            = map {qq{Test::More::diag sprintf(q{    %${var_len}s --> }, q{$_}), Data::Dump::dump($_);}}
                  grep { !$seen{$_}++ }
                       @vars;

        # Build the test code...
        qq{ if ($arg{found} $arg{comparator} $arg{expected}) {
                Test::More::ok 1, $arg{desc};
            }
            else {
                Test::More::fail $arg{desc};
                Test::More::diag q{  $arg{found} !$arg{comparator} $arg{expected}};
                Test::More::diag q{  because:}; @diagnostics
                Test::More::diag "";
            }
        } =~ s{\n}{}gr;
    }
}

1;
