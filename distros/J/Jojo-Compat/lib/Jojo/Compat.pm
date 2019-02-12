
package Jojo::Compat;

our $VERSION = '0.1.0';

# ABSTRACT: Jojo::Base and Jojo::Role for pure Perl environments

use Importer::Zim 'Module::Spec::V2' => 'try_module', 'need_module';

sub import {

    unless ( try_module('Jojo::Role~0.5.0') ) {
        need_module('Jojo::Role::Compat');
        *Jojo::Role:: = \*Jojo::Role::Compat::;
        $INC{'Jojo/Role.pm'} = $INC{'Jojo/Role/Compat.pm'};
    }

    unless ( try_module('Jojo::Base~0.7.0') ) {
        need_module('Jojo::Base::Compat');
        *Jojo::Base:: = \*Jojo::Base::Compat::;
        $INC{'Jojo/Base.pm'} = $INC{'Jojo/Base/Compat.pm'};
    }
}

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Jojo::Compat;    # before any code which uses Jojo::Base and/or Jojo::Role
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is meant to help run code which uses L<Jojo::Base> and L<Jojo::Role>
#pod on installations where L<Sub::Inject> is not available.
#pod L<Sub::Inject> is the module responsible for the magic of lexical imports
#pod and requires a C compiler to build. L<Jojo::Compat> provides an
#pod alternative that uses clean imports via L<Importer::Zim> instead.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Jojo::Base>, L<Jojo::Role>.
#pod
#pod =head1 ACKNOWLEDGEMENTS
#pod
#pod The development of this library has been sponsored by Connectivity, Inc.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Jojo::Compat - Jojo::Base and Jojo::Role for pure Perl environments

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

    use Jojo::Compat;    # before any code which uses Jojo::Base and/or Jojo::Role

=head1 DESCRIPTION

This is meant to help run code which uses L<Jojo::Base> and L<Jojo::Role>
on installations where L<Sub::Inject> is not available.
L<Sub::Inject> is the module responsible for the magic of lexical imports
and requires a C compiler to build. L<Jojo::Compat> provides an
alternative that uses clean imports via L<Importer::Zim> instead.

=head1 SEE ALSO

L<Jojo::Base>, L<Jojo::Role>.

=head1 ACKNOWLEDGEMENTS

The development of this library has been sponsored by Connectivity, Inc.

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
