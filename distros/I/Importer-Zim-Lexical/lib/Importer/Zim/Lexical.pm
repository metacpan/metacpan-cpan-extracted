
package Importer::Zim::Lexical;
$Importer::Zim::Lexical::VERSION = '0.8.0';
# ABSTRACT: Import functions as lexical subroutines

use 5.018;

use Importer::Zim::Base 0.8.0;
BEGIN { our @ISA = qw(Importer::Zim::Base); }

use Sub::Inject 0.2.0;
use Importer::Zim::Utils 0.8.0 qw(DEBUG carp);

sub import {
    my $class = shift;

    carp "$class->import(@_)" if DEBUG;
    my @exports = $class->_prepare_args(@_);

    @_ = map { @{$_}{qw(export code)} } @exports;
    goto &Sub::Inject::sub_inject;
}

no Importer::Zim::Utils qw(DEBUG carp);

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Importer::Zim::Lexical 'Scalar::Util' => 'blessed';
#pod     use Importer::Zim::Lexical 'Scalar::Util' =>
#pod       ( 'blessed' => { -as => 'typeof' } );
#pod
#pod     use Importer::Zim::Lexical 'Mango::BSON' => ':bson';
#pod
#pod     use Importer::Zim::Lexical 'Foo' => { -version => '3.0' } => 'foo';
#pod
#pod     use Importer::Zim::Lexical 'Krazy::Taco' => qw(tacos burritos poop);
#pod
#pod =head1 DESCRIPTION
#pod
#pod    "It's... INCREDIBLE! There's stuff down here I've never even
#pod    dreamed of! I'm gonna try to blow it up."
#pod      – Dib
#pod
#pod This is a backend for L<Importer::Zim> which gives lexical scope
#pod to imported subroutines.
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

Importer::Zim::Lexical - Import functions as lexical subroutines

=head1 VERSION

version 0.8.0

=head1 SYNOPSIS

    use Importer::Zim::Lexical 'Scalar::Util' => 'blessed';
    use Importer::Zim::Lexical 'Scalar::Util' =>
      ( 'blessed' => { -as => 'typeof' } );

    use Importer::Zim::Lexical 'Mango::BSON' => ':bson';

    use Importer::Zim::Lexical 'Foo' => { -version => '3.0' } => 'foo';

    use Importer::Zim::Lexical 'Krazy::Taco' => qw(tacos burritos poop);

=head1 DESCRIPTION

   "It's... INCREDIBLE! There's stuff down here I've never even
   dreamed of! I'm gonna try to blow it up."
     – Dib

This is a backend for L<Importer::Zim> which gives lexical scope
to imported subroutines.

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
