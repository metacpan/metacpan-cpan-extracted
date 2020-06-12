use strict;
use warnings;
package Devel::Gladiator; # git description: v0.07-22-g8e8e311
# ABSTRACT: Walk Perl's arena
# KEYWORDS: development debugging memory allocation usage leaks cycles arena

our $VERSION = '0.08';

use base 'Exporter';

our %EXPORT_TAGS = ( 'all' => [ qw(
    walk_arena arena_ref_counts arena_table
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

sub arena_ref_counts {
    my $all = Devel::Gladiator::walk_arena();
    my %ct;
    foreach my $it (@$all) {
        $ct{ref $it}++;
        if (ref $it eq "REF") {
            $ct{"REF-" . ref $$it}++;
        }
    }
    $all = undef;
    return \%ct;
}

sub arena_table {
    my $ct = arena_ref_counts();
    my $ret;
    $ret .= "ARENA COUNTS:\n";
    foreach my $k (sort { $ct->{$b} <=> $ct->{$a} || $a cmp $b } keys %$ct) {
        $ret .= sprintf(" %4d $k\n", $ct->{$k});
    }
    return $ret;
}

use XSLoader;
XSLoader::load(
    __PACKAGE__,
    $VERSION,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Gladiator - Walk Perl's arena

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  use Devel::Gladiator qw(walk_arena arena_ref_counts arena_table);

  my $all = walk_arena();

  foreach my $sv ( @$all ) {
      warn "live object: $sv\n";
  }

  warn arena_table(); # prints counts keyed by class

  # how to spot new entries in the arena after running some code
  use Devel::Gladiator qw(walk_arena);
  my %dump1 = map { ("$_" => $_) } @{walk_arena()};
  # do something
  my %dump2 = map { $dump1{$_} ? () : ("$_" => $_) } @{walk_arena()};
  use Devel::Peek; Dump \%dump2;

=head1 DESCRIPTION

L<Devel::Gladiator> iterates Perl's internal memory structures and can be used
to enumerate all the currently live SVs.

This can be used to hunt leaks and to profile memory usage.

=head1 EXPORTS

=head2 walk_arena

Returns an array reference containing all the live SVs. Note that this will
include a reference back to itself, so you should manually clear this array
(via C<@$arena = ()>) when you are done with it, if you don't want to create a
memory leak.

=head2 arena_ref_counts

=for stopwords reftype

Returns a hash keyed by class and reftype of all the live SVs.

This is a convenient way to find out how many objects of a given class exist at
a certain point.

=head2 arena_table

Formats a string table based on C<arena_ref_counts> suitable for printing.

=head1 LIMITATIONS

This code may not work on perls 5.6.x and 5.8.x if L<PadWalker> is installed.
(Patches gratefully accepted!)

=head1 SEE ALSO

=over 4

=item *

L<Become a hero plumber|http://blog.woobling.org/2009/05/become-hero-plumber.html>

=item *

L<Test::Memory::Cycle>

=item *

L<Devel::Cycle>

=item *

L<Devel::Refcount>

=item *

L<Devel::Leak>

=item *

L<Data::Structure::Util>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Gladiator>
(or L<bug-Devel-Gladiator@rt.cpan.org|mailto:bug-Devel-Gladiator@rt.cpan.org>).

=head1 AUTHOR

Artur Bergman <sky@apple.com>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge יובל קוג'מן (Yuval Kogman) Jesse Luehrs Brad Fitzpatrick mohawk Curtis Brandt

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Brad Fitzpatrick <brad@danga.com>

=item *

mohawk <mohawk2@users.noreply.github.com>

=item *

Curtis Brandt <curtisjbrandt@gmail.com>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2006 by Artur Bergman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
