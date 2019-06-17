package HTML::Lint::Pluggable::Microdata;

use 5.008_001;
use strict;
use warnings;

use parent qw/ HTML::Lint::Pluggable::WhiteList /;

my %md_attrs = map { $_ => 1 } qw/
 itemid itemprop itemref itemscope itemtype /;

sub init {
    my ( $class, $lint ) = @_;
    $class->SUPER::init(
        $lint => +{
            rule => +{
                'attr-unknown' => sub {
                    my $param = shift;
                    return exists $md_attrs{ $param->{attr} } || 0;
                },
            }
        }
    );
}

1;

__END__

=for stopwords microdata

=head1 NAME

HTML::Lint::Pluggable::Microdata - allow microdata attributes
