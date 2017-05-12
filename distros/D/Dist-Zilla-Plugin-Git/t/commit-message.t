# Test the get_commit_message method in Git::Commit

use 5.008;
use strict;
use warnings;

use Test::More 0.88;            # want done_testing

plan tests => 20;

use Dist::Zilla::File::InMemory ();
use Dist::Zilla::Plugin::Git::Commit ();
use Log::Dispatchouli ();

#=====================================================================
{
  package
      Mock_Zilla;

  use Moose;

  has version => qw(is ro);
  has files   => qw(is ro), default => sub { [] };

  sub isa { 1 }                 # just cheat and claim we're anything

  __PACKAGE__->meta->make_immutable;
};

#=====================================================================
# Utility functions
#---------------------------------------------------------------------
sub is_log
{
  my ($plugin, $expected) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  is_deeply([ map {; $_->{message} } @{ $plugin->logger->events } ],
            $expected);
} # end is_log

#---------------------------------------------------------------------
my $zilla;       # must be global, because $plugin->zilla is a weakref

sub new_plugin
{
  my $version = shift;
  my $changes = pop @_;

  $zilla  = Mock_Zilla->new(version => $version);

  if (defined $changes) {
    push @{ $zilla->files }, Dist::Zilla::File::InMemory->new(
      name => 'Changes',
      content => $changes,
    );
  }

  Dist::Zilla::Plugin::Git::Commit->new(
    plugin_name => 'Git::Commit',
    zilla       => $zilla,
    logger      => Log::Dispatchouli->new_tester,
    @_
  );
} # end new_plugin

#=====================================================================
{
  my $plugin = new_plugin('1.00');

  is($plugin->get_commit_message, "v1.00\n\n", '1.00 without Changes file');

  is_log($plugin, ['WARNING: Unable to find Changes']);
}

#---------------------------------------------------------------------
{
  my $plugin = new_plugin('1.00', <<'EOT');
This is the changelog for Foobar

1.00  2012-12-01

  Some unspecified changes
EOT

  is($plugin->get_commit_message, <<'EOM', '1.00 with blank line');
v1.00

  Some unspecified changes
EOM

  is_log($plugin, []);
}

#---------------------------------------------------------------------
{
  my $plugin = new_plugin('1.00', <<'EOT');
This is the changelog for Foobar

1.00  2012-12-01
  Some unspecified changes
EOT

  is($plugin->get_commit_message, <<'EOM', '1.00 without blank line');
v1.00

  Some unspecified changes
EOM

  is_log($plugin, []);
}

#---------------------------------------------------------------------
{
  my $plugin = new_plugin('1.01', <<'EOT');
This is the changelog for Foobar

1.01  2012-12-01

  Some unspecified changes

1.00  2012-11-30

  Some previous changes
EOT

  is($plugin->get_commit_message, <<'EOM', '1.01 with changes');
v1.01

  Some unspecified changes
EOM

  is_log($plugin, []);
}

#---------------------------------------------------------------------
{
  my $plugin = new_plugin('1.01', <<'EOT');
This is the changelog for Foobar

1.00  2012-12-01

  Some unspecified changes
EOT

  is($plugin->get_commit_message, "v1.01\n\n", '1.01 not in Changes');
  is_log($plugin, ['WARNING: Unable to find 1.01 in Changes']);
}

#---------------------------------------------------------------------
{
  my $plugin = new_plugin('1.00', <<'EOT');
This is the changelog for Foobar

1.00-TRIAL  2012-12-01
  Some unspecified changes
EOT

  is($plugin->get_commit_message, <<'EOM', '1.00-TRIAL');
v1.00

  Some unspecified changes
EOM

  is_log($plugin, []);
}

#---------------------------------------------------------------------
{
  my $plugin = new_plugin('1.00', <<'EOT');
This is the changelog for Foobar

1.00_TRIAL  2012-12-01
  Some unspecified changes
EOT

  is($plugin->get_commit_message, <<'EOM', '1.00_TRIAL');
v1.00

  Some unspecified changes
EOM

  is_log($plugin, []);
}

#---------------------------------------------------------------------
{
  my $plugin = new_plugin('1.01', <<'EOT');
This is the changelog for Foobar

1.01  2012-12-01

1.00  2012-11-30

  Some previous changes
EOT

  is($plugin->get_commit_message, "v1.01\n\n", '1.01 with no changes');
  is_log($plugin, ['WARNING: No changes listed under 1.01 in Changes']);
}

#---------------------------------------------------------------------
{
  my $plugin = new_plugin('1.01', <<'EOT');
This is the changelog for Foobar

1.01  2012-12-01

  Some unspecified changes with extra blank line


1.00  2012-11-30

  Some previous changes
EOT

  is($plugin->get_commit_message, <<'EOM', '1.01 with extra blank line');
v1.01

  Some unspecified changes with extra blank line
EOM

  is_log($plugin, []);
}

#---------------------------------------------------------------------
{
  my $plugin = new_plugin('1.00', <<'EOT');
1.00  2012-11-30

  Some unspecified changes
EOT

  is($plugin->get_commit_message, <<'EOM', '1.00 at BOF');
v1.00

  Some unspecified changes
EOM

  is_log($plugin, []);
}

#---------------------------------------------------------------------
done_testing;
