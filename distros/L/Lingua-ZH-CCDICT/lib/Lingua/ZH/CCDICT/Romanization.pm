package Lingua::ZH::CCDICT::Romanization;

use strict;
use warnings;

use Params::Validate qw( validate SCALAR BOOLEAN );

use overload
    ( '""'   => sub { $_[0]->syllable() },
      'bool' => sub { 1 },
      'cmp'  => sub { return
                          ( $_[2] ?
                            ( $_[1] cmp $_[0]->syllable() ) :
                            ( $_[0]->syllable() cmp $_[1] )
                          ); },
    );


sub new
{
    my $class = shift;

    my %p = validate( @_,
                      { syllable => { type => SCALAR },
                        obsolete => { type => BOOLEAN },
                      },
                    );

    unless ( $p{syllable} =~ /^[a-z1-9']+$/ )
    {
        warn "Bad romanization: $p{syllable}\n" if $ENV{DEBUG_CCDICT_SOURCE};
        return;
    }
    warn "FOUND\n" if $p{syllable} eq q{s'uk8};
    return bless \%p, $class;
}

sub syllable
{
    return $_[0]->{syllable};
}

sub is_obsolete
{
    return $_[0]->{obsolete};
}

# deprecated
sub obsolete
{
    return $_[0]->is_obsolete();
}


1;

__END__

=head1 NAME

Lingua::ZH::CCDICT::Romanization - A romanization of a Chinese character

=head1 SYNOPSIS

  print $romanization->syllable();

=head1 DESCRIPTION

This class represents a romanization of a Chinese character.

=head1 METHODS

This class provides two methods.

=head2 $romanization->syllable()

This is the romanized syllable, with the tone indicated via a number
at the end of the syllable.

=head2 $romanization->is_obsolete()

This is a boolean indicating whether or not the romanizatio is
considered obsolete.

=head1 OVERLOADING

All objects of this class are overloaded so that they stringify to the
value of the C<syllable()> method. This overloading is also done for
string comparisons. In addition, they are overloaded in a boolean
context to return true.

=head1 AUTHOR

David Rolsky <autarch@urth.org>

=head1 COPYRIGHT

Copyright (c) 2002-2007 David Rolsky.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
