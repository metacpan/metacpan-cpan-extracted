package Defaults::Modern::Define;
$Defaults::Modern::Define::VERSION = '0.011001';
use strictures 2;

=for Pod::Coverage .*

=cut

# Forked from TOBYINK's PerlX::Define, copyright Toby Inkster
#  (... to avoid the Moops dep)
# This probably goes away if PerlX::Define gets pulled out later.

use Carp ();

use B ();
use Keyword::Simple ();

sub import {
  shift;
  if (@_) {
    my ($name, $val) = @_;
    my $pkg = caller;
    my $code = ref $val ?
        qq[package $pkg; sub $name () { \$val }; 1;]
        : qq[package $pkg; sub $name () { ${\ B::perlstring($val) } }; 1;];
    local $@;
    eval $code and not $@ or Carp::croak "eval: $@";
    return
  }

  Keyword::Simple::define( define => sub {
    my ($line) = @_;
    my ($ws1, $name, $ws2, $equals) =
      ($$line =~ m{\A([\n\s]*)(\w+)([\n\s]*)(=\>?)}s)
        or Carp::croak("Syntax error near 'define'");
    my $len = length join '', $ws1, $name, $ws2, $equals;
    substr $$line, 0, $len, ";use Defaults::Modern::Define $name => ";
  });
}

1;
