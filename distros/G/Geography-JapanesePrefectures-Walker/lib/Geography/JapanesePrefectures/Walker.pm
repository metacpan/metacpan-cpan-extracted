package Geography::JapanesePrefectures::Walker;
use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed);
use Encode;
use List::MoreUtils qw/uniq firstval/;
use Geography::JapanesePrefectures;
use Data::Visitor::Callback;

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my $param = {
        encoding => shift || 'utf8',
    };
    
    my $self = bless $param, $class;
    $self->{_geo_data} = $self->_encode_prefectures_infos;
    $self;
}

sub _encode_prefectures_infos {
    my $self = shift;

    my $prefs = Geography::JapanesePrefectures->prefectures_infos;

    my $visitor = Data::Visitor::Callback->new(                                                                                                    
        plain_value => sub {
            Encode::from_to($_, 'utf8', $self->{encoding}, 1);
        }
    ); 
    $visitor->visit($prefs);

    return $prefs;
}

sub prefectures_infos { shift->{_geo_data} }

sub prefectures {
    my $self = shift;

    return [ map { {
                    id     => $_->{id} ,
                    name   => $_->{name},
                    region => $_->{region},
                   } } @{ $self->prefectures_infos } ];
}

sub prefectures_name_for_id {
    my ($self, $id) = @_;

    my $pref = firstval { $_->{id} } grep { $_->{id} eq $id } @{ $self->prefectures_infos };
    return $pref->{name};
}

sub prefectures_name {
    my $self = shift; 

    return map { $_->{name} } @{ $self->prefectures_infos };
}

sub prefectures_regions {
    my $self = shift;

    return uniq map { $_->{region} } @{ $self->prefectures_infos };
}

sub prefectures_name_for_region {
    my ($self, $region) = @_;

    return map { $_->{name} }
           grep { $_->{region} eq $region }
           @{ $self->prefectures_infos };
}

sub prefectures_id_for_name {
    my ($self, $name) = @_;

    my $pref = firstval { $_->{id} } grep { $_->{name} eq $name } @{ $self->prefectures_infos };
    return $pref->{id};
}

=head1 NAME

Geography::JapanesePrefectures::Walker - Geography::JapanesePrefectures's wrappers.

=head1 SYNOPSIS

in your script:

    use Geography::JapanesePrefectures::Walker;
    my $g = Geography::JapanesePrefectures::Walker->new('euc-jp');
    my $prefs = $g->prefectures;

=head1 METHODS

=head2 new

create Geography::JapanesePrefectures::Walker's object.

=head2 _encode_prefectures_infos

privete method.
this method encode all data.

=head2 prefectures_infos

This method get Geography::JapanesePrefectures's all data.

=head2 prefectures

This method get Geography::JapanesePrefectures's all data.

=head2 prefectures_name_for_id

This method get Geography::JapanesePrefectures's name data for id.

=head2 prefectures_name

This method get Geography::JapanesePrefectures's name data.

=head2 prefectures_regions

This method get Geography::JapanesePrefectures's region data.

=head2 prefectures_name_for_region

This method get Geography::JapanesePrefectures's name data for region.

=head2 prefectures_id_for_name

This method get Geography::JapanesePrefectures's id data for name.

=head1 SEE ALSO

L<Geography::JapanesePrefectures>

L<Plagger::Walker>

=head1 THANKS TO

The authors of Plagger::Walker, from which a lot of code was used.

id:tokuhirom

=head1 AUTHOR

Atsushi Kobayashi, C<< <nekokak at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-geography-japaneseprefectures-walker at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geography-JapanesePrefectures-Walker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geography::JapanesePrefectures::Walker

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geography-JapanesePrefectures-Walker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geography-JapanesePrefectures-Walker>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geography-JapanesePrefectures-Walker>

=item * Search CPAN

L<http://search.cpan.org/dist/Geography-JapanesePrefectures-Walker>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Atsushi Kobayashi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Geography::JapanesePrefectures::Walker
