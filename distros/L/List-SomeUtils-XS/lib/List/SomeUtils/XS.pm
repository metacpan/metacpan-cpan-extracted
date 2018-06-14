package List::SomeUtils::XS;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.58';

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

require List::SomeUtils::PP;

# This list is copied from List::SomeUtils itself and should be updated
# when subs are added.
my @subs = qw(
    after
    after_incl
    all
    all_u
    any
    any_u
    apply
    before
    before_incl
    bsearch
    bsearchidx
    each_array
    each_arrayref
    false
    firstidx
    firstres
    firstval
    indexes
    insert_after
    insert_after_string
    lastidx
    lastres
    lastval
    mesh
    minmax
    mode
    natatime
    none
    none_u
    notall
    notall_u
    nsort_by
    one
    one_u
    onlyidx
    onlyres
    onlyval
    pairwise
    part
    singleton
    sort_by
    true
    uniq
);

for my $sub (@subs) {
    next if __PACKAGE__->can($sub);
    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    *{$sub} = List::SomeUtils::PP->can($sub);
}

1;

# ABSTRACT: XS implementation for List::SomeUtils

__END__

=pod

=encoding UTF-8

=head1 NAME

List::SomeUtils::XS - XS implementation for List::SomeUtils

=head1 VERSION

version 0.58

=head1 DESCRIPTION

There are no user-facing parts here. See L<List::SomeUtils> for API details.

You shouldn't have to install this module directly. When you install
L<List::SomeUtils>, it checks whether your system has a compiler. If it does,
then it adds a dependency on this module so that it gets installed and you
have the faster XS implementation.

This distribution requires L<List::SomeUtils> but to avoid a circular
dependency, that dependency is explicitly left out from the this
distribution's metadata. However, without LSU already installed this module
cannot function.

=head1 SEE ALSO

L<List::Util>, L<List::AllUtils>

=head1 HISTORICAL COPYRIGHT

Some parts copyright 2011 Aaron Crane.

Copyright 2004 - 2010 by Tassilo von Parseval

Copyright 2013 - 2015 by Jens Rehsack

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/List-SomeUtils-XS/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for List-SomeUtils-XS can be found at L<https://github.com/houseabsolute/List-SomeUtils-XS>.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at L<http://www.urth.org/~autarch/fs-donation.html>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
