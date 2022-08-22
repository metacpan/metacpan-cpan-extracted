package Jenkins::i18n::Warnings;

use 5.014004;
use strict;
use warnings;
use Hash::Util qw(lock_keys);
use Carp qw(confess);
use Cwd;

our $VERSION = '0.06';

=pod

=head1 NAME

Jenkins::i18n::Warnings - class to handle translation warnings

=head1 SYNOPSIS

  use Jenkins::i18n::Warnings;

=head1 DESCRIPTION

C<Jenkins::i18n::Warnings>

=head2 EXPORT

None by default.

=head1 ATTRIBUTES

All attributes are "private".

=head1 METHODS

=head2 new

Creates a new instance.

Expects no parameters, returns a new instance.

=cut

sub new {
    my ( $class, $silent ) = @_;

    my $self = {
        types => {
            empty        => 'Empty',
            unused       => 'Unused',
            same         => 'Same',
            non_jenkins  => 'Non Jenkins',
            search_found => 'Found match on given term',
            ignored      => 'Ignored due expected value'
        },
        silent => $silent
    };

    if ( $self->{is_add} ) {
        $self->{types}->{missing} = 'Adding';
    }
    else {
        $self->{types}->{missing} = 'Missing';
    }

    bless $self, $class;
    $self->reset;
    lock_keys( %{$self} );
    return $self;
}

=head2 add

Adds a new warnings.

Each warning has a type, so the message must be identified. Valid types are:

=over

=item *

empty: translation files with keys that have an empty value.

=item *

unused: translation files with keys that are deprecated.

=item *

same: translation files that have keys with unstranslated text (still in
English).

=item *

non_jenkins: translation files with keys that are part of Hudson, not Jenkins.

=item *

missing: translation files that are missing.

=back

Expects as positional parameters:

=over

=item 1

The warning type.

=item 2

The warning message.

=back

=cut

sub add {
    my ( $self, $type, $value ) = @_;
    confess "type is a required parameter" unless ($type);
    confess "'$type' is not a valid type"
        unless ( exists( $self->{types}->{$type} ) );
    confess "value is a required parameter" unless ($value);
    push( @{ $self->{$type} }, $value );
    return 1;
}

=head2 has_unused

Returns true (1) or false (0) if there are unused warnings;

=cut

sub has_unused {
    my $self  = shift;
    my $total = scalar( @{ $self->{unused} } );
    return 1 if ( $total > 0 );
    return 0;
}

=head2 reset

Removes all captured warnings, bringing the instance to it's original state.

=cut

sub reset {
    my $self = shift;

    foreach my $type ( keys %{ $self->{types} } ) {
        $self->{$type} = [];
    }

    return 1;
}

=head2 summary

Prints to C<STDERR> all collected warnings so far, one per line.

Expects as parameter the translation file being processed.

=cut

sub summary {
    my ( $self, $file ) = @_;

    confess 'The path to the file translation file is required'
        unless ( defined($file) );

    my $has_any = 0;

    foreach my $type ( keys( %{ $self->{types} } ) ) {
        if ( scalar( @{ $self->{$type} } ) > 0 ) {
            $has_any = 1;
            last;
        }
    }

    # required for predicable warnings order
    my @sorted_types = sort( keys( %{ $self->{types} } ) );

    if ( ($has_any) and ( not $self->{silent} ) ) {
        my $rel = $self->_relative_path($file);
        warn "Got warnings for $rel:\n";

        foreach my $type (@sorted_types) {
            foreach my $item ( @{ $self->{$type} } ) {
                warn "\t$self->{types}->{$type} '$item'\n";
            }
        }

        return 1;
    }

    return 0;
}

sub _relative_path {
    my ( $self, $file_path ) = @_;
    my $curr_dir = getcwd;

    if ( $file_path =~ /^$curr_dir/ ) {
        $file_path =~ s#$curr_dir/##;
    }

    return $file_path;
}

=head2 has_missing

Returns true (1) or false (0) if there are missing warnings collected.

=cut

sub has_missing {
    my $self  = shift;
    my $total = scalar( @{ $self->{missing} } );
    return 1 if ( $total > 0 );
    return 0;
}

=head2 has_found

Returns true (1) or false (0) if there are warnings regarding terms that were
found in the properties values.

=cut

sub has_found {
    my $self  = shift;
    my $total = scalar( @{ $self->{search_found} } );
    return 1 if ( $total > 0 );
    return 0;
}

1;
__END__

=head1 SEE ALSO

=over

=item *

L<Jenkins::i18n::ProcOpts>

=item *

L<Carp>

=item *

L<Hash::Util>

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

The original `translation-tool.pl` script was licensed through the MIT License,
copyright (c) 2004-, Kohsuke Kawaguchi, Sun Microsystems, Inc., and a number of
other of contributors. Translations files generated by the Jenkins Translation
Tool CLI are distributed with the same MIT License.

=cut
