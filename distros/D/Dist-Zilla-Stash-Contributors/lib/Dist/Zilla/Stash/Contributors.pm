package Dist::Zilla::Stash::Contributors;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Stash containing list of contributors
$Dist::Zilla::Stash::Contributors::VERSION = '0.1.1';
use strict;
use warnings;

use Moose;

use Dist::Zilla::Stash::Contributors::Contributor;

has contributors => (
    traits => [ 'Hash' ],
    isa => 'HashRef[Dist::Zilla::Stash::Contributors::Contributor]',
    is => 'ro',
    default => sub { {} },
    handles => {
        _all_contributors => 'values',
        nbr_contributors => 'count',
    },
);


sub all_contributors {
    my $self = shift;

    return sort { $a->stringify cmp $b->stringify } $self->_all_contributors;
}


sub add_contributors {
    my ( $self, @contributors ) = @_;

    for my $c ( @contributors ) {
        my $name = $c;
        my $email;
        $email = $1 if $name =~ s/\s*<(.*?)>\s*//;

        my $object = Dist::Zilla::Stash::Contributors::Contributor->new( 
            name => $name, email => $email 
        );

        $self->contributors->{ $object->stringify } ||= $object;
    }

}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Stash::Contributors - Stash containing list of contributors

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

    my $contrib_stash = $self->zilla->stash_named('%Contributors');

    unless ( $contrib_stash ) {
        $contrib_stash = Dist::Zilla::Stash::Contributors->new;
        $self->_register_stash('%Contributors', $contrib_stash );
    }

$contrib_stash->add_contributors( 'Yanick Champoux <yanick@cpan.org>' );

=head1 DESCRIPTION

If you are a L<Dist::Zilla> user, avert your eyes and read no more: this
module is not for general consumption but for authors of plugins dealing 
with contributors harvesting or processing.

Oh, you're one of those? Excellent. Well, here's the deal: this is a 
stash that is meant to carry the contributors' information between plugins.
Plugins that gather contributors can populate the list with code looking like
this:

    sub before_build {
        my $self = shift;

        ...; # gather @collaborators, somehow

        my $contrib_stash = $self->zilla->stash_named('%Contributors');
        unless ( $contrib_stash ) {
            $contrib_stash = Dist::Zilla::Stash::Contributors->new;
            $self->_register_stash('%Contributors', $contrib_stash );
        }

        $contrib_stash->add_contributors( @contributors );
    }

and plugin that use them:

        # of course, make sure this is run *after* the gatherers did their job
    sub before_build {
        my $self = shift;

        my $contrib_stash = $self->zilla->stash_named('%Contributors')
            or return;

        my @contributors = $contrib_stash->all_contributors;
    }

And that's pretty much all you need to know beside that, internally, each contributor is represented by 
a L<Dist::Zilla::Stash::Contributors::Contributor> object.

=head1 METHODS

=head2 all_contributors()

Returns all contributors as C<Dist::Zilla::Stash::Contributors::Contributor>
objects. The collaborators are sorted alphabetically.

=head2 nbr_contributors()

Returns the number of contributors.

=head2 add_contributors( @contributors )

Adds the C<@contributors> to the stash. Duplicates are filtered out. 

Contributors can be L<Dist::Zilla::Stash::Contributors::Contributor> objects
or strings of the format 'Full Name <email@address.org>'.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2013 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
