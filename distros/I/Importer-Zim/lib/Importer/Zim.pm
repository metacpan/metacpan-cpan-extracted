
package Importer::Zim;
$Importer::Zim::VERSION = '0.8.0';
# ABSTRACT: Import functions à la Invader Zim

use 5.010001;
use warnings;

use Module::Runtime ();

use Importer::Zim::Utils 0.8.0 qw(DEBUG carp croak);

sub import {    # Load +Base if import() is called
    require Importer::Zim::Base;
    Importer::Zim::Base->VERSION('0.12.0');
    no warnings 'redefine';
    *import = \&_import;
    goto &_import;
}

sub _import {
    unshift @_, shift->backend(@_);
    goto &Importer::Zim::Base::import_into;
}

my %MIN_VERSION = do {
    my %v = (
        '+Lexical'    => '0.10.0',
        '+EndOfScope' => '0.4.0',
        '+Unit'       => '0.5.0',
        '+Bogus'      => '0.12.0',
    );
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
    my @how = split ',',
      ( ( ref $_[2] eq 'HASH' ? $_[2]->{-how} : undef )
        // '+Lexical,+EndOfScope,+Unit,+Bogus' );
    for my $how (@how) {
        my $backend = backend_class($how);
        my @version
          = exists $MIN_VERSION{$backend} ? ( $MIN_VERSION{$backend} ) : ();
        my $mod = eval { &Module::Runtime::use_module( $backend, @version ) };
        _trace_backend( $mod, $backend, @version ) if DEBUG;
        return $mod if $mod;
    }
    croak qq{Can't load any backend};
}

sub export_to {
    goto &{ __PACKAGE__->backend->can('export_to') };
}

sub _trace_backend {
    my ( $mod, $backend, $version ) = @_;
    my $rv = $version ? " $version+" : '';
    unless ($mod) {
        carp qq{Failed to load "$backend"$rv backend};
        return;
    }
    my $v = $mod->VERSION // 'NA';
    carp qq{Loaded "$backend"$rv ($v) backend};
}

no Importer::Zim::Utils qw(DEBUG carp);

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
#pod a behavior akin to L<Exporter> without the corresponding namespace pollution.
#pod
#pod =head1 BACKENDS
#pod
#pod L<Importer::Zim> will try the following backends in order
#pod until one succeeds to load.
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod L<Importer::Zim::Lexical> - symbols are imported as lexical subroutines
#pod
#pod =item *
#pod
#pod L<Importer::Zim::EndOfScope> - symbols are imported to caller namespace
#pod while surrounding scope is compiled
#pod
#pod =item *
#pod
#pod L<Importer::Zim::Unit> - symbols are imported to caller namespace
#pod while current unit is compiled
#pod
#pod =back
#pod
#pod Read also L<Importer::Zim::Cookbook/WHICH BACKEND?>.
#pod
#pod =head1 METHODS
#pod
#pod =head2 import
#pod
#pod     Importer::Zim->import($class => @imports);
#pod     Importer::Zim->import($class => \%opts => @imports);
#pod
#pod =head1 FUNCTIONS
#pod
#pod =head2 export_to
#pod
#pod     Importer::Zim::export_to($target, %imports);
#pod     Importer::Zim::export_to($target, \%imports);
#pod
#pod =head1 DEBUGGING
#pod
#pod You can set the C<IMPORTER_ZIM_DEBUG> environment variable
#pod for get some diagnostics information printed to C<STDERR>.
#pod
#pod     IMPORTER_ZIM_DEBUG=1
#pod
#pod =head1 SEE ALSO
#pod
#pod L<zim>
#pod
#pod L<Importer::Zim::Cookbook>
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

version 0.8.0

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
a behavior akin to L<Exporter> without the corresponding namespace pollution.

=head1 BACKENDS

L<Importer::Zim> will try the following backends in order
until one succeeds to load.

=over 4

=item *

L<Importer::Zim::Lexical> - symbols are imported as lexical subroutines

=item *

L<Importer::Zim::EndOfScope> - symbols are imported to caller namespace
while surrounding scope is compiled

=item *

L<Importer::Zim::Unit> - symbols are imported to caller namespace
while current unit is compiled

=back

Read also L<Importer::Zim::Cookbook/WHICH BACKEND?>.

=head1 METHODS

=head2 import

    Importer::Zim->import($class => @imports);
    Importer::Zim->import($class => \%opts => @imports);

=head1 FUNCTIONS

=head2 export_to

    Importer::Zim::export_to($target, %imports);
    Importer::Zim::export_to($target, \%imports);

=head1 DEBUGGING

You can set the C<IMPORTER_ZIM_DEBUG> environment variable
for get some diagnostics information printed to C<STDERR>.

    IMPORTER_ZIM_DEBUG=1

=head1 SEE ALSO

L<zim>

L<Importer::Zim::Cookbook>

L<Importer> and L<Lexical::Importer>

L<lexically>

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
