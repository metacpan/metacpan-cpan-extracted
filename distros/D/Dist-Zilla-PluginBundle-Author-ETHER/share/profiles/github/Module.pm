use strict;
use warnings;
no if "$]" >= 5.031008, feature => 'indirect';
package {{ $name }};
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: ...
# KEYWORDS: ...

our $VERSION = '{{ $dist->version }}';

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

=head2 C<foo>

...

=head1 ACKNOWLEDGEMENTS

...

=head1 SEE ALSO

=for :list
* L<foo>

=cut
