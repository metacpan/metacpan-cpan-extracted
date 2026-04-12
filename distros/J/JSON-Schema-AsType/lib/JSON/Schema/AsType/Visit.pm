package JSON::Schema::AsType::Visit;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::Visit::VERSION = '1.0.0';
# ABSTRACT: Visit each node of a schema.


use Carp;

sub visit {
    my ( $ref, $fcn ) = @_;
    my $ctx = { _depth => 0 };
    _visit( $ref, $fcn, $ctx );
    return $ctx;
}

sub _visit {
    my ( $ref, $fcn, $ctx ) = @_;
    my $type = ref($ref);
    return if $type eq 'JSON::PP::Boolean';
    croak("'$ref' is not an ARRAY or HASH")
      unless $type eq 'ARRAY' || $type eq 'HASH';
    my @elems = $type eq 'ARRAY' ? ( 0 .. $#$ref ) : ( sort keys %$ref );
    for my $idx (@elems) {
        my ( $v, $vr );
        $v  = $type eq 'ARRAY' ? $ref->[$idx]      : $ref->{$idx};
        $vr = $type eq 'ARRAY' ? \( $ref->[$idx] ) : \( $ref->{$idx} );
        local $_ = $v;

        $fcn->( $idx, $vr, $ctx );
        if ( ref($v) eq 'ARRAY' || ref($v) eq 'HASH' ) {
            $ctx->{_depth}++;
            push $ctx->{_path}->@*, $idx;
            _visit( $v, $fcn, $ctx );
            $ctx->{_depth}--;
            pop $ctx->{_path}->@*;
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Visit - Visit each node of a schema.

=head1 VERSION

version 1.0.0

=head1 DESCRIPTION 

Internal module for L<JSON::Schema:::AsType>. Slightly tweaked version of 
L<Data::Visitor::Tiny>.

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
