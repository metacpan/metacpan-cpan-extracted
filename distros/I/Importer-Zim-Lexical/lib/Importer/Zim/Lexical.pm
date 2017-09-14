
package Importer::Zim::Lexical;
$Importer::Zim::Lexical::VERSION = '0.4.0';
use 5.018;

BEGIN {
    require Importer::Zim::Base;
    Importer::Zim::Base->VERSION('0.3.0');
    our @ISA = qw(Importer::Zim::Base);
}

use Sub::Inject ();

use constant DEBUG => $ENV{IMPORTER_ZIM_DEBUG} || 0;

sub import {
    my $class = shift;

    warn "$class->import(@_)\n" if DEBUG;
    my @exports = $class->_prepare_args(@_);
    Sub::Inject::sub_inject( map { @{$_}{qw(export code)} } @exports );
}

1;

#pod =encoding utf8
#pod
#pod =head1 NAME
#pod
#pod Importer::Zim::Lexical - Import functions with lexical scope
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

Importer::Zim::Lexical

=head1 VERSION

version 0.4.0

=head1 SYNOPSIS

    use Importer::Zim::Lexical 'Scalar::Util' => 'blessed';
    use Importer::Zim::Lexical 'Scalar::Util' =>
      ( 'blessed' => { -as => 'typeof' } );

    use Importer::Zim::Lexical 'Mango::BSON' => ':bson';

    use Importer::Zim::Lexical 'Foo' => { -version => '3.0' } => 'foo';

=head1 NAME

Importer::Zim::Lexical - Import functions with lexical scope

=head1 DEBUGGING

You can set the C<IMPORTER_ZIM_DEBUG> environment variable
for get some diagnostics information printed to C<STDERR>.

    IMPORTER_ZIM_DEBUG=1

=head1 SEE ALSO

L<Importer::Zim>

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Adriano Ferreira

Adriano Ferreira <a.r.ferreira@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
