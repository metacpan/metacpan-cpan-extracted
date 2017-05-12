package Exobrain::Test;
use strict;
use warnings;

# ABSTRACT: Establish test environment for Exobrain
our $VERSION = '1.08'; # VERSION


# Set a variable to look for our config files in
# the same directory as our main program.

use FindBin qw($Bin);

$ENV{EXOBRAIN_CONFIG} = "$Bin/.exobrainrc";

# Also, go looking for extra modules there.

use lib "$Bin/lib";

1;

__END__

=pod

=head1 NAME

Exobrain::Test - Establish test environment for Exobrain

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    use Exobrain;
    use Exobrain::Test;
    use Test More;

=head1 DESCRIPTION

This module tests up a testing environment for Exobrain.
You should I<never> be using it outside of test cases.

This module may change functionality or be removed in the future.

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
