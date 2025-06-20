package Iterator::Flex::Method;

# ABSTRACT: Compartmentalize Iterator::Flex::Method::Maker

use strict;
use warnings;
use experimental 'signatures';

our $VERSION = '0.19';

# Package::Variant based modules generate constructor functions
# dynamically when those modules are imported.  However, loading the
# module via require() then calling its import method must be done
# only once, otherwise Perl will emit multiply defined errors for the
# constructor functions.

# By layering the Package::Variant based module in an inner package
# and calling its import here, the constructor function, Maker(), is
# generated just once, as Iterator::Flex::Method::Maker, and is
# available to any caller by it's fully qualified name.

Iterator::Flex::Method::Maker->import;

package Iterator::Flex::Method::Maker {

    use Iterator::Flex::Utils qw( :default ITERATOR METHODS );
    use Package::Variant importing => qw[ Role::Tiny ];
    use Module::Runtime;

    sub make_variant_package_name ( $, $package, % ) {

        $package = "Iterator::Flex::Role::Method::$package";

        if ( Role::Tiny->is_role( $package ) ) {
            require Iterator::Flex::Failure;
            Iterator::Flex::Failure::RoleExists->throw( { payload => $package } );
        }

        $INC{ Module::Runtime::module_notional_filename( $package ) } = 1;
        return $package;
    }

    sub make_variant ( $, $, $, %arg ) {
        my $name = $arg{name};
        install $name => sub {
            return $REGISTRY{ refaddr $_[0] }{ +ITERATOR }{ +METHODS }{$name}->( @_ );
        };
    }
}

1;

#
# This file is part of Iterator-Flex
#
# This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Iterator::Flex::Method - Compartmentalize Iterator::Flex::Method::Maker

=head1 VERSION

version 0.19

=head1 INTERNALS

=for Pod::Coverage make_variant_package_name
  make_variant

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-iterator-flex@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Iterator-Flex>

=head2 Source

Source is available at

  https://gitlab.com/djerius/iterator-flex

and may be cloned from

  https://gitlab.com/djerius/iterator-flex.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Iterator::Flex|Iterator::Flex>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
