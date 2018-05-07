package Koha::Contrib::Tamil::ARK;
$Koha::Contrib::Tamil::ARK::VERSION = '0.057';
# ABSTRACT: ARK Management
use Moose;

use Modern::Perl;
use JSON;
use YAML;
use C4::Context;
use C4::Biblio;
use Try::Tiny;
use Koha::Contrib::Tamil::Koha;


has c => ( is => 'rw', isa => 'HashRef' );

has koha => (
    is => 'rw',
    isa => 'Koha::Contrib::Tamil::Koha',
    default => sub { Koha::Contrib::Tamil::Koha->new },
);

# Is the process effective. If not, output the result.
has doit => ( is => 'rw', isa => 'Bool', default => 0 );

# Verbose mode
has verbose => ( is => 'rw', isa => 'Bool', default => 0 );

has field_query => ( is => 'rw', isa => 'Str' );

sub fatal {
    say shift;
    exit;
}


sub BUILD {
    my $self = shift;

    my $c = C4::Context->preference("ARK_CONF");
    fatal("ARK_CONF Koha system preference is missing") unless $c;

    try {
        $c = decode_json($c);
    } catch {
        fatal("Error while decoding json ARK_CONF preference: $_");
    };

    my $a = $c->{ark};
    fatal("Invalid ARK_CONF preference: 'ark' variable is missing") unless $a;

    # Check koha fields
    for my $name ( qw/ id ark / ) {
        my $field = $a->{koha}->{$name};
        fatal("Missing: koha.$name") unless $field;
        fatal("Missing: koha.$name.tag") unless $field->{tag};
        fatal("Invalid koha.$name.tag") if $field->{tag} !~ /^[0-9]{3}$/;
        fatal("Missing koha.$name.letter")
            if $field->{tag} !~ /^00[0-9]$/ && ! $field->{letter};
    }

    my $id = $a->{koha}->{ark};
    my $field_query =
        $id->{letter}
        ? '//datafield[@tag="' . $id->{tag} . '"]/subfield[@code="' .
          $id->{letter} . '"]'
        : '//controlfield[@tag="' . $id->{tag} . '"]';
    $field_query = "ExtractValue(metadata, '$field_query')";
    $self->field_query( $field_query );

    $self->c($c);
}


sub foreach_biblio {
    my ($self, $param) = @_;

    my $bibs = C4::Context->dbh->selectall_arrayref($param->{query}, {});
    $bibs = [ map { $_->[0] } @$bibs ];

    for my $biblionumber (@$bibs) {
        my $record = $self->koha->get_biblio($biblionumber);
        next unless $record;
        $param->{sub}->($biblionumber, $record);
        next unless $self->doit;
        my $fc = GetFrameworkCode($biblionumber);
        ModBiblio( $record->as('Legacy'), $biblionumber, $fc );
    }
}


sub clear {
    my $self = shift;

    my $query = "
        SELECT biblionumber
        FROM biblio_metadata
        WHERE " . $self->field_query . " <> ''
    ";
    my $ka = $self->c->{ark}->{koha}->{ark};
    my ($tag, $letter) = ($ka->{tag}, $ka->{letter});
    $self->foreach_biblio({
        query => $query,
        sub => sub {
            my ($biblionumber, $record) = @_;
            say $biblionumber;
            print "BEFORE:\n", $record->as('Text') if $self->verbose;
            if ( $letter ) {
                for my $field ( $record->field($tag) ) {
                    my @subf = grep { $_->[0] ne $letter; } @{$field->subf};
                    $field->subf( \@subf );
                }
                $record->fields( [ grep {
                    $_->tag eq $tag && @{$_->subf} == 0 ? 0 : 1;
                } @{ $record->fields } ] );
            }
            else {
                $record->delete($tag);
            }
            print "AFTER:\n", $record->as('Text') if $self->verbose;
        },
    });
}


sub update {
    my $self = shift;

    my $query = "
        SELECT biblionumber
        FROM biblio_metadata
        WHERE " . $self->field_query . " = ''
    ";
    my $a = $self->c->{ark};
    $self->foreach_biblio({
        query => $query,
        sub => sub {
            my ($biblionumber, $record) = @_;
            say $biblionumber;
            my $ark = $a->{ARK};
            for my $var ( qw/ NMHA NAAN / ) {
                my $value = $a->{$var};
                $ark =~ s/{$var}/$value/;
            }
            my $kfield = $a->{koha}->{id};
            my $id = $record->field($kfield->{tag});
            if ( $id ) {
                $id = $kfield->{letter}
                    ? $id->subfield($kfield->{letter})
                    : $id->value;
            }
            $id = $biblionumber unless $id;
            $ark =~ s/{id}/$id/;
            print "BEFORE:\n", $record->as('Text') if $self->verbose;
            $kfield = $a->{koha}->{ark};
            if ( $kfield->{letter} ) {
                for my $field ( $record->field($kfield->{tag}) ) {
                    my @subf = grep { $_->[0] ne $kfield->{letter}; } @{$field->subf};
                    $field->subf( \@subf );
                }
                $record->fields( [ grep {
                    $_->tag eq $kfield->{tag} && @{$_->subf} == 0 ? 0 : 1;
                } @{ $record->fields } ] );
            }
            else {
                $record->delete($kfield->{tag});
                $record->append( MARC::Moose::Field::Control->new(
                    tag => $kfield->{tag},
                    value => $ark ) );
            }
            print "AFTER:\n", $record->as('Text') if $self->verbose;
        },
    });
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Tamil::ARK - ARK Management

=head1 VERSION

version 0.057

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
