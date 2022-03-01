package Git::Lint::Check;

use strict;
use warnings;

our $VERSION = '0.010';

sub new {
    my $class = shift;
    my $self  = {};

    bless $self, $class;

    return $self;
}

1;

__END__

=pod

=head1 NAME

Git::Lint::Check - constructor for Git::Lint::Check modules

=head1 SYNOPSIS

 use Git::Lint::Check;

 my $check = Git::Lint::Check->new();

=head1 DESCRIPTION

C<Git::Lint::Check> provides a contructor for child modules.

This module is not meant to be initialized directly.

=head1 CONSTRUCTOR

=over

=item new

Returns the C<Git::Lint::Check> object.

=back

=cut
