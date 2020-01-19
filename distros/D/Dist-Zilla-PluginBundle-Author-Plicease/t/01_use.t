use Test2::V0 -no_srand => 1;

sub require_ok ($);

require_ok 'Dist::Zilla::MintingProfile::Author::Plicease';
require_ok 'Dist::Zilla::Plugin::Author::Plicease';
require_ok 'Dist::Zilla::Plugin::Author::Plicease::Core';
require_ok 'Dist::Zilla::Plugin::Author::Plicease::Init2';
require_ok 'Dist::Zilla::Plugin::Author::Plicease::MakeMaker';
require_ok 'Dist::Zilla::Plugin::Author::Plicease::MarkDownCleanup';
require_ok 'Dist::Zilla::Plugin::Author::Plicease::NoUnsafeInc';
require_ok 'Dist::Zilla::Plugin::Author::Plicease::SpecialPrereqs';
require_ok 'Dist::Zilla::Plugin::Author::Plicease::Tests';
require_ok 'Dist::Zilla::Plugin::Author::Plicease::Thanks';
require_ok 'Dist::Zilla::Plugin::Author::Plicease::Upload';
require_ok 'Dist::Zilla::PluginBundle::Author::Plicease';
done_testing;

sub require_ok ($)
{
  # special case of when I really do want require_ok.
  # I just want a test that checks that the modules
  # will compile okay.  I won't be trying to use them.
  my($mod) = @_;
  my $ctx = context();
  my $pm = "$mod.pm";
  $pm =~ s/::/\//g;
  eval { require $pm };
  my $error = $@;
  my $ok = !$error;
  $ctx->ok($ok, "require $mod");
  $ctx->diag("error: $error") if $error ne '';
  $ctx->release;
}
