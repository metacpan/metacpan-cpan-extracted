package Function::Return::Info;

use v5.14.0;
use warnings;

sub new {
    my $class = shift;
    my %args = @_;
    bless \%args => $class;
}

sub types { $_[0]->{types} }

1;
__END__

=encoding utf-8

=head1 NAME

Function::Return::Info - Information about return values

=head1 SYNOPSIS

    use Function::Return;

    sub foo :Return(Str, Int) {}

    my $info = Function::Return::info \&foo;
    my $types = $info->types; # [Str, Int]

=head1 DESCRIPTION

Function::Return::info returns objects of this class to describe return values of functions.  The following methods are available:

=head2 $info->types

Returns a list of type

=head1 SEE ALSO

L<Function::Return>

