## skip Test::Tabs
use Test::More;
use Test::Requires 'LWP::UserAgent';
use HTML::HTML5::Parser::UA;

$HTML::HTML5::Parser::UA::NO_LWP = '';
do './07ua.t' if -s '07ua.t';
do './t/07ua.t' if -s 't/07ua.t';

=head1 PURPOSE

Check that L<HTML::HTML5::Parser::UA> works with L<LWP::UserAgent>.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2012 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
