package Mason::CodeCache;
$Mason::CodeCache::VERSION = '2.24';
use Devel::GlobalDestruction;
use Mason::Moose;
use Mason::Util;

has 'datastore' => ( is => 'ro', isa => 'HashRef', default => sub { {} } );

method get ($key) {
    return $self->{datastore}->{$key};
}

method set ($key, $data) {
    $self->{datastore}->{$key} = $data;
}

method remove ($key) {
    if ( my $entry = $self->{datastore}->{$key} ) {
        if ( !in_global_destruction() ) {
            my $compc = $entry->{compc};
            $compc->_unset_class_cmeta();
            $compc->meta->make_mutable();
            Mason::Util::delete_package($compc);
        }
        delete $self->{datastore}->{$key};
    }
}

method get_keys () {
    return keys( %{ $self->{datastore} } );
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=head1 NAME

Mason::CodeCache - Result returned from Mason request

=head1 DESCRIPTION

Internal class that manages the cache of components for L<Mason::Interp>.

=head1 SEE ALSO

L<Mason|Mason>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
