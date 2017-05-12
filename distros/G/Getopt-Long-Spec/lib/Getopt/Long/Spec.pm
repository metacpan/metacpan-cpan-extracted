use strict;
use warnings;
package Getopt::Long::Spec;
{
  $Getopt::Long::Spec::VERSION = '0.002';
}
# ABSTRACT: translate Getopt::Long specs into a hash of attributes, and back again
use Getopt::Long::Spec::Builder;
use Getopt::Long::Spec::Parser;

sub new { return bless {}, shift }

sub parse {
  my $self = shift;
  return Getopt::Long::Spec::Parser->parse(@_);
}

sub build {
  my $self = shift;
  return Getopt::Long::Spec::Builder->build(@_);
}

1 && q{ I do these things because, well, who's stopping me? }; # truth


=pod

=head1 NAME

Getopt::Long::Spec - translate Getopt::Long specs into a hash of attributes, and back again

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Getopt::Long::Spec;

  my $gls = Getopt::Long::Spec->new;

  my %attrs = $gls->parse('foo|f=i@{3,4}');

  my $spec  = $gls->build(
    long         => 'foo',
    short        => 'f',
    val_required => 1,
    val_type     => 'int',
    dest_type    => 'array',
    min_vals     => 3,
    max_vals     => 4,
  );

=head1 DESCRIPTION

This dist provides a means of parsing L<Getopt::Long>'s option specifications
and turning them into hashes describing the spec. Furthermore, it can do the
inverse, turning a hash into an option spec!

Care has been taken to ensure that the output of L</parse> can always be fed
back into L</build> to get the exact same spec - essentially round-tripping
the spec passed to parse.

I'm not yet sure it works the other way arround, that the hashes are round-tripped,
but I am less concerned with that for no other reason than the fact that the code
is already twisted enough as it is to ensure the former situation. :)

=head1 METHODS

=head2 new

Simple constructor, takes no options.

=head2 parse

Given a valid L<Getopt::Long>
L<option specification|Getopt::Long/Summary-of-Option-Specifications>,
this method returns a hash describing the spec (see synopsis, above).

This can be called as an object or class method. It will throw an exception
on any error parsing the spec.

=head2 build

Given a hash describing the attributes of a L<Getopt::Long> option spec,
builds and returns the spec described.

This can be called as an object or class method. It will throw an exception
on any error interpreting the attributes in the hash, for example, if the
attributes conflict with each other, or if they would result in building
an option spec that GoL would reject.

The attributes that may be used are as follows:

=begin :list

= long

The canonical long version of the option

= short

The canonical short version of the option

= aliases

An arrayref of strings, each is a logn or short alias for the option

= val_required

Indicates that a value is required when using this option.

= val_type

Indicates the type of value. Must be one of qw(str int float ext), corresponding
to the [sifo] type indicators in a GoL spec

= dest_type

Indicates the data type of where the value for the option will be stored.
Must be one of qw( array hash ), corresponding to the [@%] desttype
indicators in a GoL spec.

= min_vals

When using a "repetition" clause in a GoL spec, (for example {3,4}), this
is the number that is before the comma - it is the minimum number of arguments
that GoL will consume when using this option.

= max_vals

When using a "repetition" clause in a GoL spec, (for example {3,4}), this
is the number that is after the comma - it is the maximum number of arguments
that GoL will consume when using this option.

= num_vals

When using a "repetition" clause with only I<one> number, (for example {5}),
this is the exact number of arguments that GoL will consume when using this
option.

=end :list

=head1 WHY??!?

At some point I decided I wanted to create the ultimate command-line option processor.
However, there are already so many out there, that I also wanted to be compatible with
the most used of them. Since L<Getopt::Long> is pretty much the de-facto standard in
option processors, I realized, I need to make whatever I build able to use GoL's
option specifications... hence this module.

=head1 AUTHOR

Stephen R. Scaffidi <sscaffidi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Stephen R. Scaffidi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

