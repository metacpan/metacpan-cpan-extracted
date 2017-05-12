package Geo::Direction::Name::Spec::Chinese;

use strict;
use warnings;
use Carp;
use version; our $VERSION = qv('0.0.1');
use Geo::Direction::Name::Spec::Dizhi;
use Geo::Direction::Name::Spec::Bagua;

BEGIN
{
    if ( $] >= 5.006 )
    {
        require utf8; import utf8;
    }
}

sub allowed_dev { qw(8 12 24) }

sub default_dev { 8 }

sub new {
    my $class = shift;
    
    my $self = bless { }, $class;

    foreach my $spec (qw(dizhi bagua)) {
        my $sclass = "Geo::Direction::Name::Spec::" .ucfirst("$spec");
        $self->{"spec_$spec"} = $sclass->new;
    }
    
    $self;
}

sub locale {
    my $self       =   shift;
    
    my @locales;
    
    foreach my $spec (qw(dizhi bagua)) {
        my $spec_o   = $self->{"spec_$spec"};
        push ( @locales, $spec_o->locale(@_) );
    }
    
    \@locales;
}

sub to_string {
    my $self      = shift;
    my $option    = $_[1] || {};
    my $devide    = $option->{devide} || $self->default_dev;
    
    croak ("Devide parameter must be ". join( ",", $self->allowed_dev ) ) unless ( grep { $devide == $_ } $self->allowed_dev );

    my $spec_o = $devide == 8 ? $self->{'spec_bagua'} : $self->{'spec_dizhi'};

    $spec_o->to_string(@_);
}

sub from_string {
    my $self      = shift;

    my $dizhi = $self->{'spec_dizhi'}->from_string(@_);
    defined($dizhi) ? $dizhi : $self->{'spec_bagua'}->from_string(@_);
}

1;
__END__

=encoding utf-8

=head1 NAME

Geo::Direction::Name::Spec::Chinese - Add chinese traditional direction specification to Geo::Direction::Name

=head1 SYNOPSIS

  # After install this module:
  
  use Geo::Direction::Name;
  
  my $dirn = Geo::Direction::Name->new({spec=>'chinese',locale=>'ja_JP'});
  
  my $dir = $dirn->from_string('éq');
  # 0.000
  
  my $str = $dirn->to_string(45.0,{ devide => 8 });
  # çØ

=head1 DESCRIPTION

Geo::Direction::Name::Spec::Chinese adds chinese traditional direction specification 
to Geo::Direction::Name.

Chinese traditional direction has some variation of specification, so this module select
specification by deviding number of direction.

=over 4

=item * Bagua specification

Deviding number is 8. 
You can see information of Bagua specification in L<http://en.wikipedia.org/wiki/Bagua_(concept)>.

=item * Dizhi specification

Deviding number is 12. 
You can see information of Dizhi specification in L<http://en.wikipedia.org/wiki/Dizhi>.

=item * Tiangan, Dizhi and Bagua combined specification

Deviding number is 24. 
Combined Bagua, Dizhi, and Tiangan specifications.
You can see information of Tiangan specification in L<http://en.wikipedia.org/wiki/Celestial_stem>.

=back


=head1 OVERRIDE / INTERNAL METHOD

=over 4

=item * new

=item * allowed_dev

=item * default_dev

=item * locale

=item * to_string

=item * from_string

=back


=head1 AUTHOR

OHTSUKA Ko-hei E<lt>nene@kokogiko.netE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
