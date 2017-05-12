ExtUtils::BundleMaker

## Description

ExtUtils::BundleMaker is designed to support authors automatically
create a bundle of important prerequisites which aren't needed outside
of the distribution but might interfere or overload target.

Because of no dependencies are recorded within a distribution, entire
distributions of recorded dependencies are bundled.

## Copying

Copyright (C) 2014 Jens Rehsack

## Build/Installation

  cpan ExtUtils::BundleMaker
  bundlemaker --modules Test::WriteVariants=0.005 --target /tmp/Bundle.pl --name Bundle --recurse v5.14

## License

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See <http://dev.perl.org/licenses/> for more information.
