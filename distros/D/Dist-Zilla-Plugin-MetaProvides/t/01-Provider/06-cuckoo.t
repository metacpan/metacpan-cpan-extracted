
use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use Path::Tiny qw( path );
use Test::DZil qw( simple_ini Builder );

{
  package    # PAUSE
    Dist::Zilla::Plugin::FakePlugin;

  use Moose;
  use Dist::Zilla::MetaProvides::ProvideRecord;

  with 'Dist::Zilla::Role::Plugin';
  with 'Dist::Zilla::Role::MetaProvider::Provider';

  sub provides {
    my $self = shift;
    return $self->_apply_meta_noindex(
      Dist::Zilla::MetaProvides::ProvideRecord->new(
        module  => 'FakeModule',
        file    => 'C:\temp\notevenonwindows.pl',
        version => '3.1414',
        parent  => $self,
      ),
      Dist::Zilla::MetaProvides::ProvideRecord->new(
        module  => 'Example',
        file    => 'lib/Example.pm',
        version => '3.1414',
        parent  => $self,
      ),
      Dist::Zilla::MetaProvides::ProvideRecord->new(
        module  => 'Example::Hidden',
        file    => 'lib/Example.pm',
        version => '3.1414',
        parent  => $self,
      ),

    );
  }

  __PACKAGE__->meta->make_immutable;
  $INC{'Dist/Zilla/Plugin/FakePlugin.pm'} = 1;
}

my $test_module = <<'EOF';
package Example;

1;
EOF

my $builder = Builder->from_config(
  {
    dist_root => 'invalid',
  },
  {
    add_files => {
      path('source/dist.ini') => simple_ini( 'GatherDir', [ 'FakePlugin' => { meta_noindex => 1 } ] ),
      path('source/lib/Example.pm') => $test_module,
    },
  },
);

$builder->chrome->logger->set_debug(1);
$builder->build;

ok( ( grep { /for module <Fake/ } @{ $builder->log_messages } ), "Fake namespace without matching file warned" );
ok( !( grep { /for module <Example>/ } @{ $builder->log_messages } ), "Example with matching file doesnt warn" );
ok( ( grep { /for module <Example::Hidden>/ } @{ $builder->log_messages } ), "Example::Hidden cuckoo warns" );

note explain $builder->log_messages;
done_testing;
