package JavaScript::Engine;

our $VERSION = '0.066';

use JE;

=head1 NAME

JavaScript::Engine - Pure-Perl ECMAScript (JavaScript) engine

=head1 DESCRIPTION

This is just a pointer to L<JE>, a pure-Perl JS engine.

"JE" stands for 
JavaScript::Engine. I named it this, following the example of PPI, to avoid
long class names like JavaScript::Engine::Object::Error::ReferenceError,
which I thought would be a little ridiculous, and also time-consuming to
type.

I included this module
in the JE distribution so that
one might be able to find JE when typing C<i /javascript/> in the CPAN
shell or when looking under modules/by-module/JavaScript/ on the CPAN.

=head1 AUTHOR

Father Chrysostomos <sprout at cpan.org>

=cut

1; # End of JavaScript::Engine
