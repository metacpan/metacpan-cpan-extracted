use strict;
use warnings;
use Test::More;
use Path::Tiny;

# The dzil-test action and its SimpiCI twin install and *run* CPAN code in every
# consumer's CI. A plain-http mirror makes that download unauthenticated: anyone
# on the path can swap a tarball and gets code execution in the CI job. cpanm
# itself defaults to https for that reason; an explicit `--mirror http://...`
# in our CI files would quietly put the old behaviour back. This test keeps the
# shipped defaults, the twin and the docs on https and in step with each other.

my $root   = path(__FILE__)->parent->parent;
my $action = $root->child('.github', 'actions', 'dzil-test', 'action.yml');

plan skip_all => 'CI action files not present in this tree'
  unless $action->is_file;

# default of the cpanm-opts input, read without a YAML parser: the next
# `default:` inside the `cpanm-opts:` mapping.
sub action_cpanm_default {
  my ($yaml) = @_;
  my ($default) = $yaml =~ m{
    ^[ ]{2}cpanm-opts:[ ]*\n
    (?: ^[ ]{4}(?!default:).*\n )*
    ^[ ]{4}default:[ ]*'([^']*)'
  }mx;
  return $default;
}

my $default = action_cpanm_default($action->slurp_utf8);

ok defined $default, 'action.yml declares a default for cpanm-opts'
  or BAIL_OUT('cannot read the cpanm-opts default from action.yml');

like $default, qr{--mirror[ =]https://\S+},
  'action default installs from an https mirror';
unlike $default, qr{http://},
  'action default names no plain-http URL';

# Every file CI executes or that tells a consumer what to paste into CI.
my @ci_files;
for my $dir (map { $root->child(@$_) } ['.github'], ['simpici-provider']) {
  next unless $dir->is_dir;
  $dir->visit(
    sub { push @ci_files, $_[0] if $_[0]->is_file },
    { recurse => 1 },
  );
}
ok scalar(@ci_files), 'found CI files to scan';

for my $file (sort @ci_files) {
  my @hits = grep { m{http://} } $file->lines_utf8({ chomp => 1 });
  is_deeply \@hits, [], $file->relative($root) . ' names no plain-http URL';
}

# Prose that shows consumers how to wire up CI: no http mirror there either.
# (Ordinary http hyperlinks elsewhere in the POD are not this test's business.)
my @docs = grep { $_->is_file } (
  $root->child('README.md'),
  $root->child('lib', 'Dist', 'Zilla', 'PluginBundle', 'Author', 'GETTY.pm'),
);
for my $file (@docs) {
  my @hits = grep { m{mirror[ =]+http://|http://cpan\.metacpan\.org} }
    $file->lines_utf8({ chomp => 1 });
  is_deeply \@hits, [], $file->relative($root) . ' shows no plain-http CPAN mirror';
}

# The action README quotes the default; it must be the real one.
my $readme = $action->sibling('README.md');
if ($readme->is_file) {
  my ($quoted) = $readme->slurp_utf8 =~ m{^\|\s*`cpanm-opts`\s*\|\s*`([^`]*)`}m;
  is $quoted, $default, 'action README quotes the cpanm-opts default of action.yml';
}

# The SimpiCI helper is the twin of the action: same mirror by default.
my $emit = $root->child('simpici-provider', 'emit.sh');
if ($emit->is_file) {
  my ($twin) = $emit->slurp_utf8 =~ m{PERL_CPANM_OPT="\$\{PERL_CPANM_OPT:-([^\}]*)\}"};
  is $twin, $default, 'SimpiCI provider and action share the same cpanm default';
}

# And the dzil-perl image's build ARG is the third copy of that default.
my $containerfile = $root->child('simpici-provider', 'dzil-perl', 'Containerfile');
if ($containerfile->is_file) {
  my ($arg) = $containerfile->slurp_utf8 =~ m{^ARG\s+PERL_CPANM_OPT="([^"]*)"}m;
  is $arg, $default, 'dzil-perl Containerfile ARG shares the cpanm default';
}

done_testing;
