use Filter::LiterateComments;

=head1 NAME

2-pod.t - Testing POD mode for Filter::LiterateComments

=head1 DESCRIPTION

This is a test file for the L<Filter::LiterateComments> module,
using the L<Test> framework:

=begin code

use Test;
plan tests => 2;

=end code

First we make sure that the module is actually loaded.

=begin code

ok(Filter::LiterateComments->VERSION);

=end code

Then we ensure that the line number is correct.

=begin code

ok(__LINE__, 31);

=end code

That's it, folks!
