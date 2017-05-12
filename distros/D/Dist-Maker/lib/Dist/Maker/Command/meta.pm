package Dist::Maker::Command::meta;
use Mouse;
use MouseX::StrictConstructor;

use Dist::Maker;
use Dist::Maker::Util qw(parse_options usage);

extends 'Dist::Maker::Base';

sub pass_through { 0 }

sub option_spec {
    return qw(version help usage);
}

sub run {
    my $self = shift;

    my($options) = $self->parse_options(@_);

    if($options->{version}) {
        print $self->version_message;
    }
    else {
        usage();
    }
    return 1;
}

sub version_message {
    my($self) = @_;
    return <<"END_DISPLAY";
This is Dist::Maker, version $Dist::Maker::VERSION.
END_DISPLAY
}

no Mouse;
__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Dist::Maker::Command::meta - Meta commands

=head1 DESCRIPTION

The C<meta> command is commands for C<dim> itself.
That is, C<--help>, C<--usage> and C<--version> for C<dim>
is handled by this module.

=cut
