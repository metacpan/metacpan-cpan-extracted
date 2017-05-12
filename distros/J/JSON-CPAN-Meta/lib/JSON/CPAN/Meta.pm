use strict;
use warnings;
package JSON::CPAN::Meta;
our $VERSION = '7.001';

=head1 NAME

JSON::CPAN::Meta - (deprecated) replace META.yml with META.json

=head1 DESCRIPTION

B<Achtung!>  This library will soon be obsolete as tools move to use the
official L<CPAN::Meta::Spec> JSON files.

CPAN distributions contain a file, F<META.yml>, which contains a description of
the distribution and its contents.  This document is notionally written in
YAML, a powerful data serialization format.  Perl has long lacked any reliable,
full implementation of YAML.  Instead, it has numerous incompatible and partial
implementations.

One of the least complete implementations, YAML::Tiny has been advanced to be
the standard mechanism for parsing these documents.  This defeats the purpose
of using a powerful serialization language without the benefit of a very simple
and easily understood data format.

JSON, unlike YAML, is lacking in features but is extremely easy to parse and
generate correctly.  Further, JSON documents are almost always valid YAML
documents.  Thus, a META.yml file may contain JSON without violating the spec
or introducing the sort of problems you'd expect from a poorly implemented YAML
emitter... or so you'd think.  In reality, the CPAN toolchain has become
addicted to half-baked YAML implementations, in part because they're all we
have an in part because the META.yml specification over-specifies what it means
to be YAML, conflicting with the YAML specification itself!

JSON-CPAN-Meta contains plugins to allow distribution-building tools to produce
META.json files that contain JSON content.  This ditches all the baggage that
goes along with META.yml in favor of a file that old tools won't find and that
new tools will have no problem understanding.

=head1 SEE ALSO

L<ExtUtils::MakeMaker::JSONMETA>

L<Module::Install::JSONMETA>

L<Module::Build::JSONMETA>

=head1 AUTHOR AND COPYRIGHT

Copyright (C) 2009, Ricardo Signes, C<rjbs@cpan.org>

This is free software, distributed under the same terms as perl5.

=cut

1;
