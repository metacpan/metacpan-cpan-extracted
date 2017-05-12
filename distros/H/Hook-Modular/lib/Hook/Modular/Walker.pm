use 5.008;
use strict;
use warnings;

package Hook::Modular::Walker;
BEGIN {
  $Hook::Modular::Walker::VERSION = '1.101050';
}
# ABSTRACT: Methods that walk over the workflow
use Carp;
use Scalar::Util qw(blessed);
use UNIVERSAL;

sub new {
    my $class = shift;
    my $self = @_ ? {@_} : {};
    bless $self, $class;
}
*isa = \&UNIVERSAL::isa;

sub decode_utf8 {
    my ($self, $stuff) = @_;
    $self = $self->new(apply_keys => 1) unless ref $self;
    $self->apply(sub { utf8::decode($_[0]) unless utf8::is_utf8($_[0]) })
      ->($stuff);
}

sub apply($&;@) {    ## no critic
    my $self   = shift;
    my $code   = shift;
    my $keyapp = $self->{apply_keys} ? sub { $code->(shift) } : sub { shift };
    my $curry;       # recursive so can't init
    $curry = sub {
        my @retval;
        for my $arg (@_) {
            my $class = ref $arg;
            croak 'blessed reference forbidden'
              if !$self->{apply_blessed} and blessed $arg;
            my $val =
                !$class ? $code->($arg)
              : isa($arg, 'ARRAY') ? [ $curry->(@$arg) ]
              : isa($arg, 'HASH')
              ? { map { $keyapp->($_) => $curry->($arg->{$_}) } keys %$arg }
              : isa($arg, 'SCALAR') ? \do { $curry->($$arg) }
              : isa($arg, 'REF') && $self->{apply_ref} ? \do { $curry->($$arg) }
              : isa($arg, 'GLOB') ? *{ $curry->(*$arg) }
              : isa($arg, 'CODE') && $self->{apply_code} ? $code->($arg)
              :   croak "I don't know how to apply to $class";
            bless $val, $class if blessed $arg;
            push @retval, $val;
        }
        return wantarray ? @retval : $retval[0];
    };
    @_ ? $curry->(@_) : $curry;
}

sub serialize {
    shift;   # we don't need the class
    my $stuff = shift;
    my $curry;
    $curry = sub {
        my @retval;
        for my $arg (@_) {
            my $class = ref $arg;
            my $val =
                blessed $arg && $arg->can('serialize') ? $arg->serialize
              : !$class ? $arg
              : isa($arg, 'ARRAY') ? [ $curry->(@$arg) ]
              : isa($arg, 'HASH')
              ? { map { $_ => $curry->($arg->{$_}) } keys %$arg }
              : isa($arg, 'SCALAR') ? \do { $curry->($$arg) }
              : isa($arg, 'REF')    ? \do { $curry->($$arg) }
              : isa($arg, 'GLOB')   ? *{ $curry->(*$arg) }
              : isa($arg, 'CODE')   ? $arg
              :   croak "I don't know how to apply to $class";
            push @retval, $val;
        }
        return wantarray ? @retval : $retval[0];
    };
    $curry->($stuff->clone);
}
1;


__END__
=pod

=for stopwords isa

=head1 NAME

Hook::Modular::Walker - Methods that walk over the workflow

=head1 VERSION

version 1.101050

=head1 METHODS

=head2 apply

FIXME

=head2 decode_utf8

FIXME

=head2 isa

FIXME

=head2 new

FIXME

=head2 serialize

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Hook-Modular>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Hook-Modular/>.

The development version lives at
L<http://github.com/hanekomu/Hook-Modular/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

  Marcel Gruenauer <marcel@cpan.org>
  Tatsuhiko Miyagawa <miyagawa@bulknews.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

