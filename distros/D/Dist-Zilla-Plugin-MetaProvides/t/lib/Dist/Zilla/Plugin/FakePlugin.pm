use strict;
use warnings;

package    # PAUSE
  Dist::Zilla::Plugin::FakePlugin;

use Moose;
use Dist::Zilla::MetaProvides::ProvideRecord;

with 'Dist::Zilla::Role::MetaProvider::Provider';

sub provides {
  my $self = shift;
  return $self->_apply_meta_noindex(
    Dist::Zilla::MetaProvides::ProvideRecord->new(
      module  => 'FakeModule',
      file    => 'C:\temp\notevenonwindows.pl',
      version => '3.1414',
      parent  => $self,
    )
  );
}

__PACKAGE__->meta->make_immutable;
1;
