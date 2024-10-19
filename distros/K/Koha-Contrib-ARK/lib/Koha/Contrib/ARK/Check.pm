package Koha::Contrib::ARK::Check;
# ABSTRACT: Check Koha ARK field
$Koha::Contrib::ARK::Check::VERSION = '1.1.0';
use Moose;
use Modern::Perl;

with 'Koha::Contrib::ARK::Action';


sub action {
    my ($self, $biblionumber, $record) = @_;

    return unless $record;

    my $ark = $self->ark;
    my $ka = $self->ark->c->{ark}->{koha}->{ark};
    my ($tag, $letter) = ($ka->{tag}, $ka->{letter});

    my $ark_value = $self->ark->build_ark($biblionumber, $record);
    # Searching ARK everywhere
    my $found = 0;

    # Is a bad ARK found in the correct field?
    if (my $field = $record->field($tag)) {
        my $value = $letter ? $field->subfield($letter) : $field->value;
        $self->ark->what_append('found_bad_ark', "Found \"$value\" in place of \"$ark_value\"")
            if $value ne $ark_value;
    }

    # Is the correct ARK somewhere, good/wrong field?
    for my $field ( @{$record->fields} ) {
        if ( ref $field eq 'MARC::Moose::Field::Std' ) {
            for ( @{$field->subf} ) {
                my ($let, $value) = @$_;
                if ( $value eq $ark_value ) {
                    if ( $field->tag eq $tag && $let eq $letter ) {
                        $self->ark->what_append('found_right_field');
                        $found = 1;
                    }
                    else {
                        $self->ark->what_append('found_wrong_field',
                            'Found in ' . $field->tag . '$' . $letter);

                    }
                }
            }
        }
        else {
            if ( $field->value eq $ark_value ) {
                if ($field->tag eq $tag) {
                    $self->ark->what_append('found_right_field');
                    $found = 1;
                }
                else {
                    $self->ark->what_append('found_wrong_field',
                        'Found in ' . $field->tag);
                }
            }
        }
    }
    $self->ark->what_append('not_found')  unless $found;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::ARK::Check - Check Koha ARK field

=head1 VERSION

version 1.1.0

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
