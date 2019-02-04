use 5.014;  # because we use the 'non-destructive substitution' feature (s///r)
use utf8;
use strict;
use warnings;
package Banal::Dist::Zilla::Role::Text::Template::Selfish;
# vim: set ts=2 sts=2 sw=2 tw=115 et :
# ABSTRACT: A role that gives you a 'fill_in_string' method with \$self included in the stash (as $o and $self).
# KEYWORDS: author bundle distribution tool

our $VERSION = '0.198';
# AUTHORITY

use Moose::Role;
requires qw( _extra_args payload );
with
    'Dist::Zilla::Role::TextTemplate', # Gives us simple string templating for free (à la Text::Template)
    ;


use Dist::Zilla::Util;

use Scalar::Util qw(refaddr);
use List::Util 1.45 qw(first all any none pairs uniq);
use List::MoreUtils qw(arrayify);


# TABULO : a custom 'has' to save some typing and lines ... :-)
# The '*' in the prototype allows bareword attribute names.
sub haz (*@) { my $name=shift; has ( $name => ( is => 'ro', init_arg => undef, lazy => 1, @_)); }

use namespace::autoclean;

haz template_delim_start => (
  isa  => 'Str',
  default  => sub { my $o = $_[0];  eval { $o->payload->{delim_start} }  // '{{' },
);

haz template_delim_end => (
  isa  => 'Str',
  default  => sub { my $o = $_[0];  eval { $o->payload->{delim_end} }  // '}}' },
);

haz template_delim => (
  isa  => 'ArrayRef',
  default  => sub { [ $_[0]->template_delim_start, $_[0]->template_delim_end ] },
);


has +delim => (
  default  => sub { $_[0]->template_delim },
);



# Wrap the 'fill_in_string' method, so that it
around fill_in_string => sub {
    my $orig    = shift;
    my ($self, $string, $stash, $args) = ( shift, shift, shift, shift);
    my $zilla = eval { $self->zilla };  # In case we have a zilla object available.
    $stash  //= +{};

    local $_ = \$self;  # TODO: Test this. If it works, we will have a shorthand for $self within the template.
    #  NOTE: Text::Template requires objects to be passed with additional referencing.
    $stash   = +{ o=>\$self, self=>\$self, %$stash, SELF=>\$self};


    $self->$orig($string, $stash, $args, @_);

};




1;

=pod

=encoding UTF-8

=head1 NAME

Banal::Dist::Zilla::Role::Text::Template::Selfish - A role that gives you a 'fill_in_string' method with \$self included in the stash (as $o and $self).

=head1 VERSION

version 0.198

=head1 SYNOPSIS

In your F<dist.ini>:

    [...]
    year=2018
    msg = May {{year}} bring you happiness.

=head1 DESCRIPTION

=for stopwords TABULO
=for stopwords GitHub DZIL

This is a practical utility role that gives you a 'fill_in_string' method with \$self (== $o) included in the stash stash.

=head2 WARNING

Please note that, although this module needs to be on CPAN for obvious reasons,
it is really intended to be a collection of personal preferences, which are
expected to be in great flux, at least for the time being.

Therefore, please do NOT base your own distributions on this one, since anything
can change at any moment without prior notice, while I get accustomed to dzil
myself and form those preferences in the first place...
Absolutely nothing in this distribution is guaranteed to remain constant or
be maintained at this point. Who knows, I may even give up on dzil altogether...

You have been warned.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::PluginBundle::Author::TABULO>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-Author-TABULO>
(or L<bug-Dist-Zilla-PluginBundle-Author-TABULO@rt.cpan.org|mailto:bug-Dist-Zilla-PluginBundle-Author-TABULO@rt.cpan.org>).

=head1 AUTHOR

Tabulo <tabulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tabulo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#region pod


#endregion pod
