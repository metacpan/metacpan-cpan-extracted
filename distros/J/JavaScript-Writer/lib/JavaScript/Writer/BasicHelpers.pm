use strict;
use warnings;

package JavaScript::Writer::BasicHelpers;

our $VERSION = '0.0.2';

package JavaScript::Writer;

sub delay {
    my ($self, $seconds, $block) = @_;
    $self->setTimeout($block, $seconds);
}

sub closure {
    my $self = shift;

    my %args;
    if (ref($_[0]) eq 'CODE') {
        $args{body} = $_[0];
    }
    else {
        %args = @_;
    }
    my $params = delete $args{parameters};

    my (@arguments, @values);
    while(my ($name, $value) = each %$params) {
        push @arguments, $name;
        push @values, $value;
    }
    my $jsf = $self->function(
        body => $args{body},
    );
    $jsf->arguments(@arguments);

    my $argvalue = $_;
    if (defined $args{this}) {
        $self->call(";($jsf).call", $args{this}, @values);
    }
    else {
        $self->call(";($jsf)", @values);
    }

    return $self;
}


1;

__END__

=head1 NAME

JavaScript::Writer::BasicHelpers - Basic helper methods

=head1 DESCRIPTION

This module inject several nice helper methods into JavaScript::Writer
namespace. It helps to make your Perl code shorter, (hopefully) less
painful.

=head1 METHODS

Method documentations are put into L<JavaScript::Writer>.

=head1 AUTHOR and LICENSE

See L<JavaScript::Writer>

=cut

