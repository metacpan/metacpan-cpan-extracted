#
# This file is part of Dist-Metadata
#
# This software is copyright (c) 2011 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Dist::Metadata::Test::LikePause;

# ABSTRACT: Fake dist for testing metadata determination

our $VERSION = '0.1';

# This should be excluded unless "include_inner_packages" is true
package ExtraPackage;

our $VERSION = '0.2';
