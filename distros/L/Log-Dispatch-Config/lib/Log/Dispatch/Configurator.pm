package Log::Dispatch::Configurator;

use strict;
use vars qw($VERSION);
$VERSION = '1.00';

sub new {
    my($class, $file) = @_;
    bless { file   => $file }, $class;
}

sub myinit {
    my $self = shift;
    $self->{LDC_ctime} = 0 unless defined $self->{LDC_ctime};
    $self->{LDC_watch} = 0 unless defined $self->{LDC_watch};
}

sub reload { }

sub needs_reload {
    my $self = shift;
    return $self->{LDC_ctime} < (stat($self->{file}))[9];
}

sub should_watch {
    my $self = shift;
    $self->{LDC_watch} = shift if @_;
    return $self->{LDC_watch};
}

sub _abstract_method {
    require Carp;
    Carp::croak(shift, " is an abstract method of ", __PACKAGE__);
}

sub get_attrs_global { _abstract_method('get_attrs_global') }
sub get_attrs        { _abstract_method('get_attrs') }

1;
__END__

=head1 NAME

Log::Dispatch::Configurator - Abstract Configurator class

=head1 SYNOPSIS

  package Log::Dispatch::Configurator::Foo;
  use base qw(Log::Dispatch::Configurator);

  # should implement
  sub get_attrs_global { }
  sub get_attrs        { }

  # optional
  sub reload       { }
  sub needs_reload { }

=head1 DESCRIPTION

Log::Dispatch::Configurator is an abstract class of config parser. If
you make new configurator implementation, you should inherit from this
class.

See L<Log::Dispatch::Config/"PLUGGABLE CONFIGURATOR"> for details.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Log::Dispatch::Config>

=cut

