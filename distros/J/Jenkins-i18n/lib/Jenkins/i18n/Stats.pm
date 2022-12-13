package Jenkins::i18n::Stats;

use 5.014004;
use strict;
use warnings;
use base       qw(Class::Accessor);
use Hash::Util qw(lock_keys);
use Carp       qw(confess);
use Set::Tiny;

my @ATTRIBUTES = qw(files missing unused empty same no_jenkins keys);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(@ATTRIBUTES);

our $VERSION = '0.10';

=pod

=head1 NAME

Jenkins::i18n::Stats - class to provide translations processing statistics

=head1 SYNOPSIS

  use Jenkins::i18n::Stats;

=head1 DESCRIPTION

C<Jenkins::i18n::Stats>

=head2 EXPORT

None by default.


=head1 METHODS

=head2 new

Creates a new instance.

=cut

sub new {
    my $class = shift;
    my $self  = {};

    foreach my $attrib (@ATTRIBUTES) {
        $self->{$attrib} = 0;
    }

    $self->{unique_keys} = Set::Tiny->new;

    bless $self, $class;
    lock_keys( %{$self} );
    return $self;
}

=head2 get_keys

Return the number of all keys retrieve from all files processed, ignoring if
they are repeated several times.

=head2 get_files

Returns the number of found translation files.

=head2 get_missing

Returns the number of keys that are missing after comparing a language to the
original in English.

=head2 get_unused

Returns the number of keys that are available in the a language but not in the
original English.

=head2 get_empty

Returns the number of keys in the language that are available but doesn't
actually have a translated value.

=head2 get_same

Returns the number of keys that have the same values as the original in
English. Not necessarilly an error.

=head2 get_no_jenkins

Returns the number of keys that are not related to Jenkins, but coming from
Hudson.

=cut

sub _inc {
    my ( $self, $item ) = @_;
    confess "item is a required parameter" unless ($item);
    confess "there is no such counter '$item'"
        unless ( exists( $self->{$item} ) );
    $self->{$item}++;
    return 1;
}

=head2 inc_files

Increments the C<files> counter.

=cut

sub inc_files {
    shift->_inc('files');
}

=head2 inc_missing

Increments the C<missing> counter.

=cut

sub inc_missing {
    shift->_inc('missing');
}

=head2 inc_unused

Increments the C<unused> counter.

=cut

sub inc_unused {
    shift->_inc('unused');
}

=head2 inc_empty

Increments the C<empty> counter.

=cut

sub inc_empty {
    shift->_inc('empty');
}

=head2 inc_same

Increments the C<same> counter.

=cut

sub inc_same {
    shift->_inc('same');
}

=head2 inc_no_jenkins

Increments the C<no_jenkins> counter.

=cut

sub inc_no_jenkins {
    shift->_inc('no_jenkins');
}

=head2 add_key

Increments the keys counters.

This is required in order to allow the counting of unique keys processed, as
well all the keys processed.

=cut

sub add_key {
    my ( $self, $key ) = @_;
    $self->_inc('keys');
    $self->{unique_keys}->insert($key);
}

=head2 get_unique_keys

Returns the number of unique keys processed.

=cut

sub get_unique_keys {
    return shift->{unique_keys}->size();
}

sub _done {
    my $self = shift;
    return (  $self->{keys}
            - $self->{missing}
            - $self->{unused}
            - $self->{empty}
            - $self->{same}
            - $self->{no_jenkins} );
}

=head2 perc_done

Calculates how much of the translation is completed.

Requires no parameters.

Returns a float as the percentage of the translation that is completed.

=cut

sub perc_done {
    my $self = shift;
    return ( ( $self->_done / $self->{keys} ) * 100 );
}

=head2 summary

Returns a summary of all statistics in text format.

The summary is returned as a hash reference.

=cut

sub summary {
    my $self = shift;

    unless ( $self->{keys} == 0 ) {
        my %summary = ( done => $self->_done, pdone => $self->perc_done );
        my @wanted  = qw(missing unused empty same no_jenkins);

        foreach my $wanted (@wanted) {
            $summary{$wanted} = $self->{$wanted};
            $summary{"p$wanted"} = $self->{$wanted} / $self->{keys} * 100;
        }

        return \%summary;

    }

    return {};
}

=head2 files

Getter for the C<files> attribute.

=cut

sub files {
    my $self = shift;
    return $self->{files};
}

1;
__END__

=head1 SEE ALSO

=over

=item *

L<Config::Properties>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 of Alceu Rodrigues de Freitas Junior,
E<lt>arfreitas@cpan.orgE<gt>

This file is part of Jenkins Translation Tool project.

Jenkins Translation Tool is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your option)
any later version.

Jenkins Translation Tool is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Jenkins Translation Tool. If not, see (http://www.gnu.org/licenses/).

The original C<translation-tool.pl> script was licensed through the MIT
License, copyright (c) 2004-, Kohsuke Kawaguchi, Sun Microsystems, Inc., and a
number of other of contributors. Translations files generated by the Jenkins
Translation Tool CLI are distributed with the same MIT License.

=cut
