package Facebook::Graph::Cmdline;
{
  $Facebook::Graph::Cmdline::VERSION = '0.123490';
}

#ABSTRACT: Extends Facebook::Graph with embedded HTTP for Oauth and token saving

use Any::Moose;
use v5.10;

extends 'Facebook::Graph';
with 'Facebook::Graph::Cmdline::Role::HTTPAccessToken';

#Is there a better way to do MooseX vs MouseX 'with' loading?
#can import with "use Any::Moose 'X::SimpleConfig'" but that doesn't
#provide the action of "with," Mo*se::Util::apply_all_roles()
if (Any::Moose::moose_is_preferred)
{
    with 'MooseX::SimpleConfig';
    with 'MooseX::Getopt';
}
else
{
    with 'MouseX::SimpleConfig';
    with 'MouseX::Getopt';
}
# requires provided by ::SimpleConfig
with 'Facebook::Graph::Cmdline::Role::SaveAccessToken';

no Any::Moose;
__PACKAGE__->meta->make_immutable;

__END__
=pod

=head1 NAME

Facebook::Graph::Cmdline - Extends Facebook::Graph with embedded HTTP for Oauth and token saving

=head1 VERSION

version 0.123490

=head1 AUTHOR

Andrew Grangaard <spazm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Grangaard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

