package Megaport::Internal::_Obj;

use 5.10.0;
use strict;
use warnings;

our $AUTOLOAD;

sub new {
  my ($class, %hash) = @_;

  bless \%hash, $class;
}

sub AUTOLOAD {
  my ($self) = @_;
  my $command = $AUTOLOAD;
  $command =~ s/.*://;

  if ($self->can($command)) {
    $self->{$command};
  }
}

sub can {
  my ($self, $field) = @_;

  return sub {
    $self->{$field}
  } if $self->{$field};
}

sub DESTROY { }

1;
__END__
=encoding utf-8
=head1 NAME

Megaport::Internal::_Obj - Turn JSON objects into Perl objects with accessors

=head1 SYNOPSIS

    my $eq1 = $mp->session->locations->get(id => 2);
    say $eq1->name, $eq1->address->{street};

=head1 DESCRIPTION

This is a horrible hack to produce Perl objects with accessors for various pieces of data returned by the Megaport API.

Honestly, it might not even make release. Would love a better way to do this, accessors vs hashrefs feel so much nicer.

=head1 AUTHOR

Cameron Daniel E<lt>cdaniel@cpan.orgE<gt>

=cut
