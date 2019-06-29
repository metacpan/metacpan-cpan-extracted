package Dist::Zilla::Stash::Contributors::Contributor;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: a Contributors stash element
$Dist::Zilla::Stash::Contributors::Contributor::VERSION = '0.1.1';
use strict;
use warnings;

use Moose;

use overload '""' => \&stringify;


has name => (
    isa => 'Str',
    is => 'ro',
    required => 1,
);


has email => (
    is => 'ro',
    required => 0,
);


sub stringify { sprintf '%s <%s>', $_[0]->name, $_[0]->email }

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Stash::Contributors::Contributor - a Contributors stash element

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

    if( my $contrib_stash = $self->zilla->stash_named('%Contributors') ) {
        my @collaborators = sort { $a->email cmp $b->email }
            $contrib_stash->all_contributors;

        $self->log( "contributor: " . $_->stringify ) for @collaborators;
    }

=head1 DESCRIPTION

Collaborator objects used in the L<Dist::Zilla::Stash::Contributors> stash.

=head1 METHODS

=head2 new( name => $name, email => $address )

Creates a new C<Dist::Zilla::Stash::Contributors::Contributor> object.

=head2 name()

Returns the name of the contributor.

=head2 email()

Returns the email address of the contributor.

=head2 stringify()

Returns the canonical string for the collaborator, of the form
"Full Name <email@address.org>".

The object will automatically call this function is used
as a string.

    say $_ for $stash->all_contributors;

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2013 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
