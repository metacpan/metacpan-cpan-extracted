package JSON::XS::Sugar;
use base qw(Exporter);

# ABSTRACT: sugar for using JSON::XS

# right now the XS won't work on anything before this
use 5.014000;

use warnings;
use strict;

use Devel::CallChecker 0.003 ();
use Types::Serialiser;

our $VERSION = '1.01';

our @EXPORT_OK;

use constant JSON_TRUE => Types::Serialiser::true;
push @EXPORT_OK, qw(JSON_TRUE);

use constant JSON_FALSE => Types::Serialiser::false;
push @EXPORT_OK, qw(JSON_FALSE);

## no critic (Subroutines::ProhibitSubroutinePrototypes)

sub json_truth($) {
    return $_[0] ? JSON_TRUE : JSON_FALSE;
}
push @EXPORT_OK, qw(json_truth);

push @EXPORT_OK, qw(
    json_number
    json_string
);

# load json_number, json_string from XS
require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

1;

__END__

=pod

=head1 NAME

JSON::XS::Sugar - sugar for using JSON::XS

=head1 VERSION

version 1.01

=head1 SYNOPSIS

  use JSON::XS qw(encode_json);
  use JSON::XS::Sugar qw(
    JSON_TRUE JSON_FALSE json_truth json_number json_string
  );

  print encode_json({
     towel_location_known => JSON_TRUE,
     panic                => JSON_FALSE,
     wants_tea            => json_truth is_arthur_dent(),
     answer               => json_number "42",
     telephone_number     => json_string 2079460347,
  });

=head1 DESCRIPTION

This module allows you to easily control the output that JSON::XS generates when
it creates JSON.  In particular, it makes it easier to have JSON::XS create
C<true> and C<false> when you want, and if a scalar should be rendered as a
number or a string.

=head2 Functions

Exported on demand or may be used fully qualified.

=over

=item JSON_TRUE

A constant that will result in JSON::XS printing out C<true>. It's an alias for
C<Types::Serialiser::true>.

=item JSON_FALSE

A constant that will result in JSON::XS printing out C<false>. It's an alias for
C<Types::Serialiser::false>.

=item json_truth $something_true_or_false

A function that will return a value that will cause JSON::XS to render C<true>
or C<false> depending on if the argument passed to it was true or false.

=item json_number $scalar

A function that will return a value which will cause JSON::XS to render the
argument as a number.  This can more or less be thought of as syntactic sugar
for C<+0> (but we take extra care to ensure proper handing of very large
integers.) This function is implemented as rewriting the OP tree to a custom OP,
so there's no run time performance penalty for using this verses the Perl
solution.

=item json_string $scalar

A function that will return a value which will cause JSON::XS to render the
argument as a string. This is syntactic sugar for C<"">.  This function is
implemented as rewriting the OP tree, so there's no run time performance penalty
for using this verses the Perl solution.

=back

=head1 SUPPORT

Please report all issues with this code using the GitHub issue tracker at
L<https://github.com/maxmind/JSON-XS-Sugar-perl/issues>.

We welcome patches as pull requests against our GitHub repository at
L<https://github.com/maxmind/JSON-XS-Sugar-perl>.

=head1 THANKS

Thanks to Andrew Main (Zefram) for his help with the hairy parts of this
module and providing code to cargo-cult XS from.

=head1 BUGS

C<json_number> and C<json_string> are designed to be just as forgiving as
C<+0> and C<"">, meaning that they can be used as drop in replacements for
those constructs.  However, this means that if they're used on things that
aren't numeric or strings respectively then they will coerce just as the
corresponding Perl code would (including emitting warnings in a similar
way if warnings are enabled.)

=head1 SEE ALSO

L<JSON::XS>

=head1 AUTHOR

Mark Fowler <mfowler@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by MaxMind, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
