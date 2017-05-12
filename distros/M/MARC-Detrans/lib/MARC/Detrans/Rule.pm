package MARC::Detrans::Rule;

use strict;
use warnings;
use Carp qw( croak );

=head1 NAME

MARC::Detrans::Rule

=head1 SYNOPSIS

    use MARC::Detrans::Rule;
    
    my $rule = MARC::Detrans::Rule->new( 
        from    => 'b', 
        to      => 'B',
        escape  => '(B'
    );

=head1 DESCRIPTION

It's unlikely that you'll want to use MARC::Detrans::Rule directly since
other modules wrap access to it. Each detransliteration rule is represented 
as a MARC::Detrans::Rule object, which basically provides the Romanized text
and the corresponding MARC-8 or UTF-8 text, along with an escape character
(for MARC-8) rules.

=head1 METHODS

=head2 new()

Pass in the C<from> and c<to> parameters which define the original text
and what to translate to; these parameters are not limited to single
characters. In addition an C<escape> parameter can be passed in to
indicate a MARC-8 escape sequence to use. Also a C<position> parameter
can be set to C<initial>, C<medial> or C<final> if the rule applies only
when the character is found at or within a particular word boundary.

=cut

sub new {
    my ( $class, %opts ) = @_;
    croak( "must supply 'from' parameter" ) if ! exists( $opts{from} );
    croak( "must supply 'to' parameter" ) if ! exists( $opts{to} );
    $opts{to} =~ s/\^ESC/\x1B/g;
    return bless \%opts, ref($class) || $class;
}

=head2 from()

Returns the Romanized text that this rule refers to.

=cut

sub from {
    return shift->{from};
}

=head2 to()

Returns the MARC-8 or UTF-8 text that the corresponding Romanized text should
be converted to.

=cut

sub to {
    return shift->{to};
}

=head2 escape() 

Returns a MARC-8 character set escape sequence to be used, or undef if the rule
is for an UTF-8 mapping.

=cut

sub escape {
    return shift->{escape};
}

=head2 position()

Returns a position specification for the rule mapping which can be 
initial, medial, final or the empty string if there is no positional 
qualification for the rule.

=cut

sub position {
    my $p = shift->{position};
    return $p if defined($p);
    return ''; 
}

=head1 AUTHORS

=over 4

=item * Ed Summers <ehs@pobox.com>

=back

=cut

1;
