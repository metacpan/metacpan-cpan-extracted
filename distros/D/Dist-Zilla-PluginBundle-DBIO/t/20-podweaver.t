use strict;
use warnings;

use Test::More;
use Pod::Weaver;
use Pod::Elemental;
use PPI;
use Pod::Simple::Text;
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

# --- =seealso is collected into SEE ALSO (both bundles) ---
#
# The real shape in the family: an ARGUMENTLESS =seealso followed by an
# =over/=item list. All 38 occurrences across the driver dists look like this.
# Before the SEE ALSO Collect section existed, =seealso was not a POD command
# and no plugin claimed it, so it fell through [Leftovers] into the shipped
# tarball raw and Pod::Simple reported "Unknown directive: =seealso".
#
# =head1 CAPABILITIES stands in for the unnamed =head1 sections real driver
# modules carry (CAPABILITIES, ESCAPE HATCHES, QUERY PLANS, ...). They reach
# the output through [Leftovers], and SEE ALSO must come after them: it is the
# last section of the body, not a wedge in the middle of it.
my $SEEALSO_SAMPLE = <<'POD';
=head1 DESCRIPTION

Describes the module.

=method connect

Connects to the database.

=head1 CAPABILITIES

An unnamed =head1 that reaches the output through [Leftovers].

=seealso

=over 4

=item * L<DBIO::PostgreSQL> - Base PostgreSQL driver component

=item * L<DBIO::PostgreSQL::Age::Storage> - Storage class with graph methods

=back

=cut
POD

for my $flavour (qw(standard heritage)) {
  my $out = weave($flavour, $SEEALSO_SAMPLE);

  like $out, qr/^=head1 SEE ALSO$/m,
    "$flavour: =seealso is collected into a SEE ALSO section";
  unlike $out, qr/^=seealso\b/m,
    "$flavour: no raw =seealso command survives the weave";

  # The list must sit under SEE ALSO, not merely somewhere in the document.
  my ($body) = $out =~ /^=head1 SEE ALSO$(.*?)(?=^=head1 )/ms;
  ok defined $body, "$flavour: SEE ALSO section has a body";
  like $body, qr/^=item \* L<DBIO::PostgreSQL> - Base PostgreSQL driver component$/m,
    "$flavour: first =item is under SEE ALSO";
  like $body,
    qr/^=item \* L<DBIO::PostgreSQL::Age::Storage> - Storage class with graph methods$/m,
    "$flavour: second =item is under SEE ALSO";

  # Collect renames the collected command to new_command. With the default
  # (head2) an argumentless =seealso yields a bare "=head2" -- an empty
  # heading, which renders as <h2 id=""></h2>. Nothing like that may appear.
  unlike $body, qr/^=head[1-4]\s*$/m,
    "$flavour: SEE ALSO carries no empty heading";

  # Order: SEE ALSO closes the body -- after METHODS and after the leftover
  # =head1, before AUTHOR/COPYRIGHT.
  ok index($out, '=head1 METHODS') < index($out, '=head1 SEE ALSO'),
    "$flavour: SEE ALSO comes after METHODS";
  ok index($out, '=head1 CAPABILITIES') < index($out, '=head1 SEE ALSO'),
    "$flavour: SEE ALSO comes after the leftover =head1";
  ok index($out, '=head1 SEE ALSO') < index($out, '=head1 AUTHOR'),
    "$flavour: SEE ALSO comes before AUTHOR";
  ok index($out, '=head1 SEE ALSO') < index($out, '=head1 COPYRIGHT AND LICENSE'),
    "$flavour: SEE ALSO comes before COPYRIGHT AND LICENSE";

  # Pod::Simple is what reported the defect in the field; it must be quiet now.
  my $rendered = '';
  my $parser = Pod::Simple::Text->new;
  $parser->complain_stderr(0);
  $parser->output_string(\$rendered);
  $parser->parse_string_document($out);
  ok !$parser->any_errata_seen,
    "$flavour: woven POD parses with no Pod::Simple errata (no 'Unknown directive')";
  like $rendered, qr/^SEE ALSO$/m,
    "$flavour: SEE ALSO renders as a heading";
  like $rendered, qr/DBIO::PostgreSQL::Age::Storage - Storage class with graph methods/,
    "$flavour: the list renders under it";
}

done_testing;
