package Gideon::Plugin::ResultSet;
{
  $Gideon::Plugin::ResultSet::VERSION = '0.0.3';
}
use Moose;
use Gideon::ResultSet;

#ABSTRACT: Plugin for creating Gideon::ResulSet

extends 'Gideon::Plugin';

sub find {
    my ( $self, $target, %query ) = @_;

    if ( wantarray() ) {
        my $rs = $self->next->find( $target, %query );
        return @$rs;
    }
    else {
        return Gideon::ResultSet->new(
            driver => $self->next,
            target => $target,
            query  => \%query,
        );
    }
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Gideon::Plugin::ResultSet - Plugin for creating Gideon::ResulSet

=head1 VERSION

version 0.0.3

=head1 DESCRIPTION

When C<find> is called in scalar context returns L<Gideon::ResultSet> preserving
query and options. This prevents calling the database until is absolutely necessary

=head1 NAME

Gideon::Plugin::ResultSet

=head1 VERSION

version 0.0.3

=head1 AUTHOR

Mariano Wahlmann, Gines Razanov

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mariano Wahlmann, Gines Razanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
