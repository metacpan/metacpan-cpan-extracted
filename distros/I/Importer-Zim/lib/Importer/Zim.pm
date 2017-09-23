
package Importer::Zim;
$Importer::Zim::VERSION = '0.3.0';
# ABSTRACT: Import functions à la Invader Zim

use 5.018;
use warnings;
use Module::Runtime ();

sub import {
    shift->backend(@_)->import(@_);
}

my %MIN_VERSION = do {
    my %v = ( '+Lexical' => '0.5.0', );
    /^\+/ and $v{ backend_class($_) } = $v{$_} for keys %v;
    %v;
};

sub backend_class {
    my $how = shift;
    return ( $how =~ s/^\+// )
      ? ( __PACKAGE__ . '::' . $how )
      : $how;
}

sub backend {
    my $how = ( ref $_[2] ? $_[2]->{-how} : undef ) // '+Lexical';
    my $backend = backend_class($how);
    my @version
      = exists $MIN_VERSION{$backend} ? ( $MIN_VERSION{$backend} ) : ();
    return &Module::Runtime::use_module( $backend, @version );
}

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Importer::Zim 'Scalar::Util' => 'blessed';
#pod     use Importer::Zim 'Scalar::Util' => 'blessed' => { -as => 'typeof' };
#pod
#pod     use Importer::Zim 'Mango::BSON' => ':bson';
#pod
#pod     use Importer::Zim 'Foo' => { -version => '3.0' } => 'foo';
#pod
#pod     use Importer::Zim 'SpaceTime::Machine' => [qw(robot rubber_pig)];
#pod
#pod =head1 DESCRIPTION
#pod
#pod    "Because, when you create a giant monster of doom,
#pod    no matter how cute, you have to... you have to... I don't know."
#pod      – Zim
#pod
#pod This pragma imports subroutines from other modules in a clean way.
#pod "Clean imports" here mean that the import symbols are available
#pod only at some scope.
#pod
#pod L<Importer::Zim> relies on pluggable backends which give a precise
#pod meaning to "available at some scope". For example,
#pod L<Importer::Zim::Lexical> creates lexical subs that go away
#pod as soon the lexical scope ends.
#pod
#pod By default, L<Importer::Zim> looks at package variables
#pod C<@EXPORT>, C<@EXPORT_OK> and C<%EXPORT_TAGS> to decide
#pod what are exportable subroutines. It tries its best to implement
#pod a behavior akin to L<Exporter> without the corresponding package polution.
#pod
#pod =head1 METHODS
#pod
#pod =head2 import
#pod
#pod     Importer::Zim->import($class => @imports);
#pod     Importer::Zim->import($class => \%opts => @imports);
#pod
#pod =head1 SEE ALSO
#pod
#pod L<zim>
#pod
#pod L<Importer> and L<Lexical::Importer>
#pod
#pod L<lexically>
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Importer::Zim - Import functions à la Invader Zim

=head1 VERSION

version 0.3.0

=head1 SYNOPSIS

    use Importer::Zim 'Scalar::Util' => 'blessed';
    use Importer::Zim 'Scalar::Util' => 'blessed' => { -as => 'typeof' };

    use Importer::Zim 'Mango::BSON' => ':bson';

    use Importer::Zim 'Foo' => { -version => '3.0' } => 'foo';

    use Importer::Zim 'SpaceTime::Machine' => [qw(robot rubber_pig)];

=head1 DESCRIPTION

   "Because, when you create a giant monster of doom,
   no matter how cute, you have to... you have to... I don't know."
     – Zim

This pragma imports subroutines from other modules in a clean way.
"Clean imports" here mean that the import symbols are available
only at some scope.

L<Importer::Zim> relies on pluggable backends which give a precise
meaning to "available at some scope". For example,
L<Importer::Zim::Lexical> creates lexical subs that go away
as soon the lexical scope ends.

By default, L<Importer::Zim> looks at package variables
C<@EXPORT>, C<@EXPORT_OK> and C<%EXPORT_TAGS> to decide
what are exportable subroutines. It tries its best to implement
a behavior akin to L<Exporter> without the corresponding package polution.

=head1 METHODS

=head2 import

    Importer::Zim->import($class => @imports);
    Importer::Zim->import($class => \%opts => @imports);

=head1 SEE ALSO

L<zim>

L<Importer> and L<Lexical::Importer>

L<lexically>

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
