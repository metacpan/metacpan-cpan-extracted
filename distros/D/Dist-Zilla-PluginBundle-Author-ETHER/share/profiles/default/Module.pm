use strict;
use warnings;
package {{ $name }};
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: ...
# KEYWORDS: ...

our $VERSION = '{{ $dist->version }}';

use 5.020;
use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
{{
    ($zilla_plugin) = ($name =~ /^Dist::Zilla::Plugin::(.+)$/g);

$zilla_plugin ? <<'PLUGIN'
use Moose;
with 'Dist::Zilla::Role::...';

use namespace::autoclean;

around dump_config => sub
{
  my ($orig, $self) = @_;
  my $config = $self->$orig;

  $config->{+__PACKAGE__} = {
      ...,
      blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
  };

  return $config;
};


__PACKAGE__->meta->make_immutable;
PLUGIN
: "\n1;\n"
}}__END__

=pod

=head1 SYNOPSIS

{{
$zilla_plugin ? <<SYNOPSIS
In your F<dist.ini>:

  [$zilla_plugin]
SYNOPSIS
: <<SYNOPSIS
  use $name;

  ...
SYNOPSIS
}}
=head1 DESCRIPTION

{{ $zilla_plugin ? 'This is a L<Dist::Zilla> plugin that' : '' }}...

=head1 {{ $zilla_plugin ? 'CONFIGURATION OPTIONS' : 'FUNCTIONS/METHODS' }}

=head2 foo

...

=head1 ACKNOWLEDGEMENTS

...

=head1 SEE ALSO

=for :list
* L<foo>

=cut
