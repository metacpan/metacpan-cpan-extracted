package Mail::Decency::ContentFilter::Core::Spam;

use Moose::Role;

use version 0.74; our $VERSION = qv( "v0.1.6" );

=head1 NAME

Mail::Decency::ContentFilter::Core::Spam

=head1 DESCRIPTION

For all modules being a spam filter (scoring mails)

=head1 CLASS ATTRIBUTES

=head2 weight_innocent : Int

Default weight of innocent mails.. used in descendant modules

=cut

has weight_innocent => ( is => 'rw', isa => 'Int', default => 10 );

=head2 weight_spam : Int

Default weight of spam mails .. used in descendant modules

=cut

has weight_spam     => ( is => 'rw', isa => 'Int', default => -50 );


=head2 METHODS

=head2 pre_init

Add check params: weight_innocent, weight_spam to list of check params

=cut

before init => sub {
    my ( $self ) = @_;
    push @{ $self->{ config_params } ||=[] }, qw/ weight_innocent weight_spam /;
};

=head2 add_spam_score

=cut

sub add_spam_score {
    my ( $self, $score, $info ) = @_;
    return $self->server->add_spam_score( $score, $self, $info );
}


=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut


1;
