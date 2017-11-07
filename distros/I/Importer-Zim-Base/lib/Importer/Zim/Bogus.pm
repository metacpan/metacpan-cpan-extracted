
package Importer::Zim::Bogus;
$Importer::Zim::Bogus::VERSION = '0.10.0';
# ABSTRACT: Bogus Importer::Zim backend

use 5.010001;

use Importer::Zim::Base;
BEGIN { our @ISA = qw(Importer::Zim::Base); }

use Importer::Zim::Utils qw(DEBUG carp);

sub import {
    my $class = shift;

    carp
      qq{WARNING! Using bogus Importer::Zim backend (you may need to install a proper backend)};

    carp "$class->import(@_)" if DEBUG;
    my @exports = $class->_prepare_args(@_);

    my $caller = caller;
    no strict 'refs';
    for (@exports) {
        *{"${caller}::$_->{export}"} = $_->{code};
    }
}

no Importer::Zim::Utils qw(DEBUG carp);

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Importer::Zim::Bogus 'Scalar::Util' => 'blessed';
#pod     use Importer::Zim::Bogus 'Scalar::Util' =>
#pod       ( 'blessed' => { -as => 'typeof' } );
#pod
#pod     use Importer::Zim::Bogus 'Mango::BSON' => ':bson';
#pod
#pod     use Importer::Zim::Bogus 'Foo' => { -version => '3.0' } => 'foo';
#pod
#pod     use Importer::Zim::Bogus 'Krazy::Taco' => qw(tacos burritos poop);
#pod
#pod =head1 DESCRIPTION
#pod
#pod    "Is it supposed to be stupid?"
#pod      – Zim
#pod
#pod This is a fallback backend for L<Importer::Zim>.
#pod Only used when you have no installed legit backend.
#pod It does no cleaning at all – so it is a polluting module such
#pod as the regular L<Exporter>.
#pod
#pod The reason it exists is to provide a "working" L<Importer::Zim>
#pod after installing L<Importer::Zim> and its nominal dependencies.
#pod It will annoy you with warnings until a proper backend is installed.
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
#pod L<Importer::Zim>
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Importer::Zim::Bogus - Bogus Importer::Zim backend

=head1 VERSION

version 0.10.0

=head1 SYNOPSIS

    use Importer::Zim::Bogus 'Scalar::Util' => 'blessed';
    use Importer::Zim::Bogus 'Scalar::Util' =>
      ( 'blessed' => { -as => 'typeof' } );

    use Importer::Zim::Bogus 'Mango::BSON' => ':bson';

    use Importer::Zim::Bogus 'Foo' => { -version => '3.0' } => 'foo';

    use Importer::Zim::Bogus 'Krazy::Taco' => qw(tacos burritos poop);

=head1 DESCRIPTION

   "Is it supposed to be stupid?"
     – Zim

This is a fallback backend for L<Importer::Zim>.
Only used when you have no installed legit backend.
It does no cleaning at all – so it is a polluting module such
as the regular L<Exporter>.

The reason it exists is to provide a "working" L<Importer::Zim>
after installing L<Importer::Zim> and its nominal dependencies.
It will annoy you with warnings until a proper backend is installed.

=head1 DEBUGGING

You can set the C<IMPORTER_ZIM_DEBUG> environment variable
for get some diagnostics information printed to C<STDERR>.

    IMPORTER_ZIM_DEBUG=1

=head1 SEE ALSO

L<Importer::Zim>

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
