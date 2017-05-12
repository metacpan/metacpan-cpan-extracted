use strict;
use warnings;

package KSx::Search::WildCardQuery;
use base qw( KSx::Search::RegexpTermQuery );

our $VERSION = '0.05';

sub new {
    my($pack, %args) = @_;

    for($args{regexp} = delete $args{term}) {
        $_ = quotemeta; # turn it into a regexp that matches a literal str
        s/\\\*/.*/g;    # convert \*’s into .*’s
        s/(?:\.\*){2,}/.*/g; # eliminate multiple consecutive wild cards
        s/^/^/    unless s/^\.\*//;  # anchor the regexp to
        s/\z/\\z/ unless s/\.\*\z//; # the ends of the term
    }
    
    $pack->SUPER::new(%args);
}

1;

__END__

=head1 NAME

KSx::Search::WildCardQuery - Wild card query class for KinoSearch

=head1 VERSION

0.05

=head1 SYNOPSIS

    use KSx::Search::WildCardQuery
    my $query = new KSx::Search::WildCardQuery
        term  => 'foo*',
        field => 'content',
    ;

    $searcher->search($query);
    # etc.

=head1 DESCRIPTION 

This module provides search query objects for KinoSearch that perform
wild-card searches. Currently, asterisks (*) are the only wild cards
supported. An asterisks represents zero or more characters. This is a
subclass of
L<KSx::Search::RegexpTermQuery (I<q.v.>)|KSx::Search::RegexpTermQuery>.

=head1 PERFORMANCE

If a term begins with literal (non-wild-card) characters (e.g., the C<foo>
in C<foo*>), only the 'foo' words in the index will be scanned, so
this should not be too slow, as long as the prefix is fairly long, or
there are sufficiently few 'foo' words. If, however, there is no literal
prefix (e.g., C<*foo*>), the I<entire> index will be scanned, so beware.

=head1 METHODS

=head2 new

This is the constructor. It constructs. Call it with hash-style arguments
as shown in the L</SYNOPSIS>.

=head1 PREREQUISITES

L<Hash::Util::FieldHash::Compat>

The development version of L<KinoSearch> available at
L<http://www.rectangular.com/svn/kinosearch/trunk>, revision 4810 or 
higher.

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2008-9 Father Chrysostomos <sprout at, um, cpan.org>

This program is free software; you may redistribute or modify it (or both)
under the same terms as perl.

=head1 SEE ALSO

L<KinoSearch>, L<KinoSearch::Search::Query>, 
L<KSx::Search::RegexpTermQuery>, 
L<KinoSearch::Docs::Cookbook::CustomQuery>

=cut
