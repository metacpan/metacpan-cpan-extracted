package Koha::Contrib::ARK::Clear;
# ABSTRACT: Clear Koha ARK field
$Koha::Contrib::ARK::Clear::VERSION = '1.1.2';
use Moose;
use Modern::Perl;

with 'Koha::Contrib::ARK::Action';


sub action {
    my $self = shift;
    my $ark = $self->ark;
    my $current = $ark->current;
    my $biblio = $current->{biblio};
    my $record = $biblio->{record};

    return unless $record;

    my $ka = $ark->c->{ark}->{koha}->{ark};
    my ($tag, $letter) = ($ka->{tag}, $ka->{letter});

    my $more = $ka->{tag};
    $more .= '$' . $ka->{letter} if $ka->{letter};
    $self->ark->what_append('clear', $more);
    if ( $letter ) {
        for my $field ( $record->field($tag) ) {
            my @subf = grep {
                my $keep = $_->[0] ne $letter;
                $keep;
            } @{$field->subf};
            $field->subf( \@subf );
        }
        $record->fields( [ grep {
            $_->tag eq $tag && @{$_->subf} == 0 ? 0 : 1;
        } @{ $record->fields } ] );
    }
    else {
        $record->delete($tag);
    }

    $ark->current_modified();
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::ARK::Clear - Clear Koha ARK field

=head1 VERSION

version 1.1.2

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
