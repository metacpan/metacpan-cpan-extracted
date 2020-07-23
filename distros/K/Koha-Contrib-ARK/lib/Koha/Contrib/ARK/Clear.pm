package Koha::Contrib::ARK::Clear;
# ABSTRACT: Clear Koha ARK field
$Koha::Contrib::ARK::Clear::VERSION = '1.0.5';
use Moose;
use Modern::Perl;

with 'Koha::Contrib::ARK::Action';


sub action {
    my ($self, $biblionumber, $record) = @_;

    return unless $record;

    my $ark = $self->ark;
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
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::ARK::Clear - Clear Koha ARK field

=head1 VERSION

version 1.0.5

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
