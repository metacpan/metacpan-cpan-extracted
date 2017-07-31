package HTML::FormHandler::Field::Result;
# ABSTRACT: result class for fields
$HTML::FormHandler::Field::Result::VERSION = '0.40068';
use Moose;
with 'HTML::FormHandler::Result::Role';


has 'value' => (
    is        => 'ro',
    writer    => '_set_value',
    clearer   => '_clear_value',
    predicate => 'has_value',
);

has 'field_def' => (
    is     => 'ro',
    isa    => 'HTML::FormHandler::Field',
    writer => '_set_field_def',
);

has 'missing' => ( is => 'rw',  isa => 'Bool' );

sub fif {
    my $self = shift;
    return $self->field_def->fif($self);
}

sub fields_fif {
    my ( $self, $prefix ) = @_;
    return $self->field_def->fields_fif( $self, $prefix );
}

sub render {
    my $self = shift;
    return $self->field_def->render($self);
}


sub peek {
    my ( $self, $indent ) = @_;
    $indent ||= '';
    my $name = $self->field_def ? $self->field_def->full_name : $self->name;
    my $type = $self->field_def ? $self->field_def->type : 'unknown';
    my $string = $indent . "result " . $name . "  type: " . $type . "\n";
    $string .= $indent . "....value => " . $self->value . "\n" if $self->has_value;
    if( $self->has_results ) {
        $indent .= '  ';
        foreach my $res ( $self->results ) {
            $string .= $res->peek( $indent );
        }
    }
    return $string;
}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::Result - result class for fields

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

Result class for L<HTML::FormHandler::Field>

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
