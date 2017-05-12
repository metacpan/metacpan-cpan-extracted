package List::MoreUtils::XS;

use 5.008_001;
use strict;
use warnings;

use vars qw{$VERSION @ISA};

$VERSION = '0.418';

# Load the XS at compile-time so that redefinition warnings will be
# thrown correctly if the XS versions of part or indexes loaded

# PERL_DL_NONLAZY must be false, or any errors in loading will just
# cause the perl code to be tested
local $ENV{PERL_DL_NONLAZY} = 0 if $ENV{PERL_DL_NONLAZY};

use XSLoader ();
XSLoader::load("List::MoreUtils::XS", "$VERSION");

=pod

=head1 NAME

List::MoreUtils::XS - Provide compiled List::MoreUtils functions

=head1 SYNOPSIS

  use List::Moreutils::XS;
  use List::MoreUtils ...;

=head1 SEE ALSO

L<List::Util>, L<List::AllUtils>

=head1 AUTHOR

Jens Rehsack E<lt>rehsack AT cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Tassilo von Parseval E<lt>tassilo.von.parseval@rwth-aachen.deE<gt>

=head1 COPYRIGHT AND LICENSE

Some parts copyright 2011 Aaron Crane.

Copyright 2004 - 2010 by Tassilo von Parseval

Copyright 2013 - 2017 by Jens Rehsack

All code added with 0.417 or later is licensed under the Apache License,
Version 2.0 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

All code until 0.416 is licensed under the same terms as Perl itself,
either Perl version 5.8.4 or, at your option, any later version of
Perl 5 you may have available.

=cut

1;
