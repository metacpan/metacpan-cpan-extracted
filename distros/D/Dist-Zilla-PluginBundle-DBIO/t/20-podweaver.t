use strict;
use warnings;

use Test::More;
use Pod::Weaver;
use Pod::Elemental;
use PPI;
use Software::License::Perl_5;

# Pins what the @DBIO / @DBIO::Heritage PodWeaver bundles produce: the
# inline =attr / =method commands are collected into ATTRIBUTES / METHODS
# sections, NAME comes from the "# ABSTRACT:" comment, and the Heritage
# variant adds the DBIx::Class copyright attribution.
#
# This doubles as the reference for the DBIO POD conventions -- see the
# dbio-perl-release skill.

# Weave a sample module with the bundle configured in corpus/<flavour>/weaver.ini
# and return the resulting POD string.
sub weave {
  my ($flavour, $pod) = @_;
  my $weaver = Pod::Weaver->new_from_config({ root => "t/corpus/$flavour" });
  my $ppi = PPI::Document->new(\"package DBIO::Demo;\n# ABSTRACT: a demo module\nour \$VERSION = '0.001';\n1;\n");
  my $woven = $weaver->weave_document({
    pod_document => Pod::Elemental->read_string($pod),
    ppi_document => $ppi,
    authors      => ['Test Author <test@example.com>'],
    license      => Software::License::Perl_5->new({ holder => 'DBIO Authors', year => 2005 }),
  });
  return $woven->as_pod_string;
}

my $SAMPLE = <<'POD';
=method connect

Connects to the database.

=attr dsn

The data source name.

=cut
POD

# --- standard @DBIO bundle ---
{
  my $out = weave('standard', $SAMPLE);

  like $out, qr/^=head1 NAME\s*\n\s*\nDBIO::Demo - a demo module/m,
    'NAME section from package + # ABSTRACT:';
  like $out, qr/^=head1 ATTRIBUTES\b.*^=head2 dsn\b/ms,
    '=attr collected into an ATTRIBUTES section';
  like $out, qr/^=head1 METHODS\b.*^=head2 connect\b/ms,
    '=method collected into a METHODS section';
  like $out, qr/^=head1 (?:AUTHOR|AUTHORS)\b/m, 'AUTHOR section present';
  like $out, qr/^=head1 COPYRIGHT AND LICENSE\b/m, 'COPYRIGHT section present';

  # ATTRIBUTES is woven before METHODS
  ok index($out, '=head1 ATTRIBUTES') < index($out, '=head1 METHODS'),
    'ATTRIBUTES section comes before METHODS';

  unlike $out, qr/DBIx::Class/,
    'standard bundle does NOT add DBIx::Class attribution';
}

# --- @DBIO::Heritage bundle adds DBIx::Class attribution ---
{
  my $out = weave('heritage', $SAMPLE);

  like $out, qr/^=head1 METHODS\b.*^=head2 connect\b/ms,
    'heritage bundle still collects =method into METHODS';
  like $out, qr/DBIx::Class Authors/,
    'heritage bundle adds "Portions Copyright ... DBIx::Class Authors"';
  like $out, qr/Based on DBIx::Class/,
    'heritage bundle notes it is based on DBIx::Class';
}

done_testing;
