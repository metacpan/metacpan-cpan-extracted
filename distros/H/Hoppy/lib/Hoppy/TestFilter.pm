package Hoppy::TestFilter;
use strict;
use warnings;
use base qw(POE::Filter::Line);

my $c;

sub FRAMING_BUFFER () { 0 }

sub new {
    my $class = shift;
    $c = shift;
    my $self =
      $class->SUPER::new( InputRegexp => qr/\x00|\n/, OutputLiteral => "\x00" );
    return $self;
}

sub get_one_start {
    my $self = shift;
    $self->SUPER::get_one_start(@_);
    if ( $self->[FRAMING_BUFFER] =~ /\n$/s ) {
        my $session_id = POE::Kernel->get_active_session->ID;
        $c->{test_client}->{$session_id} = 1;
    }
}

sub put {
    my $self       = shift;
    my $session_id = POE::Kernel->get_active_session->ID;
    if ( $c->{test_client}->{$session_id} ) {
        my $lines = shift;
        my @raw;
        foreach (@$lines) {
            push @raw, $_ . "\n";
        }
        return \@raw;
    }
    else {
        $self->SUPER::put(@_);
    }
}

1;
__END__

=head1 NAME

Hoppy::TestFilter - Custom POE::Filter for Test Mode. (delived from POE::Filter::Line) 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 FRAMING_BUFFER

=head2 new()

=head2 get_one_start()

=head2 put()

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut