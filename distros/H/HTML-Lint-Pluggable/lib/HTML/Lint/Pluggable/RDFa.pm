package HTML::Lint::Pluggable::RDFa;

use 5.008_001;
use strict;
use warnings;

use parent qw/ HTML::Lint::Pluggable::WhiteList /;

my %rdfa_attrs = map { $_ => 1 } qw/
  about content datatype inlist prefix property rel resource rev
  typeof vocab /;

sub init {
    my ( $class, $lint ) = @_;
    $class->SUPER::init(
        $lint => +{
            rule => +{
                'attr-unknown' => sub {
                    my $param = shift;
                    return exists $rdfa_attrs{ $param->{attr} } || 0;
                },
            }
        }
    );
}

1;

__END__

=for stopwords RDFa

=head1 NAME

HTML::Lint::Pluggable::RDFa - allow RDFa attributes
