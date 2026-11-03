#!/usr/bin/env bash
# Pack bin/locale-simple into one standalone executable with PAR::Packer.
# Run from the checkout root. Output: $LOCALE_SIMPLE_BIN_OUT (default ./locale-simple).
set -euo pipefail

OUT="${LOCALE_SIMPLE_BIN_OUT:-./locale-simple}"
[ -f bin/locale-simple ] || { echo "ERROR: run from the checkout root" >&2; exit 1; }
command -v pp >/dev/null 2>&1 || { echo "ERROR: pp (PAR::Packer) is not installed" >&2; exit 1; }

# Every module needed at run time must be installed, or the loaded set below is short.
perl -Ilib -MLocale::TextDomain -MParser::MGC -MMoo -MTry::Tiny -MIO::All -Mcurry -MJSON::PP -e1 \
  || { echo "ERROR: runtime dependencies missing (cpanm --installdeps .)" >&2; exit 1; }

# The loaded set: scripts/loaded-modules.pl runs the real scrape and po2json paths, the
# help/version/error paths, and prints every module that came from its own file. pp's
# scanner reads source and misses what loads by name (Locale::TextDomain picks its gettext
# backend at run time; Moo, Parser::MGC and the scraper's parsers load lazily). verify-binary.sh
# requires the same list inside the archive.
loaded=(); while IFS= read -r m; do loaded+=("$m"); done < <(perl -Ilib scripts/loaded-modules.pl)
[ "${#loaded[@]}" -gt 25 ] || { echo "ERROR: loaded set suspiciously small (${#loaded[@]})" >&2; exit 1; }
mods=(); for m in "${loaded[@]}"; do mods+=(-M "$m"); done

# PAR_VERBATIM=1: pp's POD-stripping filter corrupts files with POD between code.
# -I lib: the checkout's lib/ wins over any installed copy.
# -M 'Locale::Simple::**': the scraper's parsers load by name on some paths only.
# -X YAML and every installed YAML::*: Scraper.pm requires YAML for --output yaml, so pp packs
# it wherever it is installed (the macOS runner has it, the Linux image does not). `pp -X NAME`
# drops exactly one file and has no wildcard, so YAML.pm alone would leave YAML::Dumper, ::Loader,
# ::Mo, ::Node and the rest packed, because the scanner still follows `require YAML` into them.
# The whole family goes, one -X per module found in @INC on this host: every binary then writes
# the same formats (po, perl, json) and --output yaml dies with "needs the YAML module".
# verify-binary.sh refuses an archive with any YAML file; a module the CLI needs is in the loaded
# set and fails the build there.
noyaml=(-X YAML)
while IFS= read -r m; do noyaml+=(-X "$m"); done < <(perl -MFile::Find -e '
  my %m;
  for my $dir (grep { !ref } @INC) {
    next unless -d "$dir/YAML";
    find({ no_chdir => 1, wanted => sub {
      return unless /\.pm\z/;
      (my $n = substr $_, length($dir) + 1) =~ s{/}{::}g;
      $n =~ s/\.pm\z//;
      $m{$n} = 1;
    } }, "$dir/YAML");
  }
  print "$_\n" for sort keys %m;')

PAR_VERBATIM=1 pp -o "$OUT" \
  -I lib \
  "${mods[@]}" \
  -M 'Locale::Simple::**' \
  "${noyaml[@]}" \
  bin/locale-simple

chmod +x "$OUT"
echo "Built $OUT ($(du -h "$OUT" | cut -f1), ${#loaded[@]} modules)"
