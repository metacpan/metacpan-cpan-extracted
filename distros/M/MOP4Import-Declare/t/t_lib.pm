package
  MOP4Import::t::t_lib;
use Exporter qw/import/;

our @EXPORT_OK = qw/catch expect_script_error no_error/;

use Test::Kantan ();

# Tcl style [catch {code}]
sub catch (&) {
  my ($code) = @_;
  local $@;
  eval {$code->()};
  $@;
};

sub expect_script_error {
  my ($script, $what, @how) = @_;
  sub {
    Test::Kantan::expect(do { eval "use strict; use warnings; $script"; $@ })
      ->$what(@how);
  };
}

sub no_error ($) {
  my ($script) = @_;
  expect_script_error($script, to_be => '');
}

1;
