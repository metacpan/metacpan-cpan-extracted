#ABSTRACT: Gideon Exceptions
{

    package Gideon::Exception;
{
  $Gideon::Exception::VERSION = '0.0.3';
}
    use Moose;
    with 'Throwable';
    __PACKAGE__->meta->make_immutable;
}

{

    package Gideon::Exception::ObjectNotInStore;
{
  $Gideon::Exception::ObjectNotInStore::VERSION = '0.0.3';
}
    use Moose;
    with 'Throwable';
    __PACKAGE__->meta->make_immutable;
}

{

    package Gideon::Exception::NotFound;
{
  $Gideon::Exception::NotFound::VERSION = '0.0.3';
}
    use Moose;
    with 'Throwable';
    __PACKAGE__->meta->make_immutable;
}

{

    package Gideon::Exception::SaveFailure;
{
  $Gideon::Exception::SaveFailure::VERSION = '0.0.3';
}
    use Moose;
    with 'Throwable';
    __PACKAGE__->meta->make_immutable;
}

{

    package Gideon::Exception::UpdateFailure;
{
  $Gideon::Exception::UpdateFailure::VERSION = '0.0.3';
}
    use Moose;
    with 'Throwable';
    __PACKAGE__->meta->make_immutable;
}

{

    package Gideon::Exception::RemoveFailure;
{
  $Gideon::Exception::RemoveFailure::VERSION = '0.0.3';
}
    use Moose;
    with 'Throwable';
    __PACKAGE__->meta->make_immutable;
}

{

    package Gideon::Exception::InvalidOperation;
{
  $Gideon::Exception::InvalidOperation::VERSION = '0.0.3';
}
    use Moose;
    with 'Throwable';
    __PACKAGE__->meta->make_immutable;
}


1;

__END__

=pod

=head1 NAME

Gideon::Exception - Gideon Exceptions

=head1 VERSION

version 0.0.3

=head1 DESCRIPTION

Exception classes used by Gideon

=head1 NAME

Gideon::Exception

=head1 VERSION

version 0.0.3

=head1 AUTHOR

Mariano Wahlmann, Gines Razanov

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mariano Wahlmann, Gines Razanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
