
BEGIN {
    require Importer::Zim;
    *zim:: = *Importer::Zim::;
}

package zim;
$zim::VERSION = '0.2.0';
1;

#pod =encoding utf8
#pod
#pod =head1 NAME
#pod
#pod zim - Import functions à la Invader Zim
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use zim 'Scalar::Util' => 'blessed';
#pod     use zim 'Scalar::Util' => 'blessed' => { -as => 'typeof' };
#pod
#pod     use zim 'Foo' => { -version => '3.0' } => 'foo';
#pod
#pod =head1 DESCRIPTION
#pod
#pod L<zim> is an alias to L<Importer::Zim>.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

zim

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

    use zim 'Scalar::Util' => 'blessed';
    use zim 'Scalar::Util' => 'blessed' => { -as => 'typeof' };

    use zim 'Foo' => { -version => '3.0' } => 'foo';

=head1 DESCRIPTION

L<zim> is an alias to L<Importer::Zim>.

=head1 NAME

zim - Import functions à la Invader Zim

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
