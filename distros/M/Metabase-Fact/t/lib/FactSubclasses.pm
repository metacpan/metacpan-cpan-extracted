package FactSubClasses;
use strict;
use warnings;

use Metabase::Fact::String;
use Metabase::Fact::Hash;

package FactOne;
our @ISA = ('Metabase::Fact::String');
sub content_as_bytes   { return reverse( $_[0]->{content} ) }
sub content_from_bytes { return reverse( $_[1] ) }

package FactTwo;
our @ISA = ('Metabase::Fact::String');
sub content_as_bytes   { return reverse( $_[0]->{content} ) }
sub content_from_bytes { return reverse( $_[1] ) }

package FactThree;
our @ISA = ('Metabase::Fact::String');

sub validate_content {
    $_[0]->SUPER::validate_content;
    die "content not positive length" unless length $_[0]->content > 0;
}

sub content_metadata {
    return { 'length' => [ '//num' => length $_[0]->content ] };
}

package FactFour;
our @ISA = ('Metabase::Fact::Hash');
sub required_keys { qw/ first / }
sub optional_keys { qw/ second / }

sub content_metadata {
    return { 'size' => [ '//num' => scalar keys %{ $_[0]->content } ] };
}

1;
