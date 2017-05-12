use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Impl::Singleton;
use base 'Class::Singleton';
use Sereal qw/encode_sereal decode_sereal/;
use Data::Compare qw//;
use Marpa::R2 2.078000;
use Log::Any qw/$log/;

# ABSTRACT: Singleton hosting all the grammar precompiled Marpa::R2::Scanless::G objects

our $VERSION = '0.020'; # VERSION


sub _new_instance {
    my ($class) = @_;
    my $self  = bless {_G => {} }, $class;
    return $self;
}


sub G {
    my ($self, $grammarOptionsHashp) = @_;

    $grammarOptionsHashp //= {};

    #
    # Search the key
    #
    my $key = undef;
    foreach (keys %{$self->{_G}}) {
      my $thisKey = $_;
      my $thisOptionsHashp = decode_sereal($thisKey);
      my $c = new Data::Compare($grammarOptionsHashp, $thisOptionsHashp);
      if ($c->Cmp) {
        $key = $thisKey;
        last;
      }
    }
    #
    # Create a new key if necessary
    #
    if (! defined($key)) {
      $log->debugf('Creating grammar key');
      $key = encode_sereal($grammarOptionsHashp);
    }

    if (! defined($self->{_G}->{$key})) {
      #
      # Create the grammar object
      #
      $log->debugf('Creating grammar object');
      $self->{_G}->{$key} = Marpa::R2::Scanless::G->new($grammarOptionsHashp);
    } else {
      $log->debugf('Found cached grammar object');
    }

    return $self->{_G}->{$key};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Impl::Singleton - Singleton hosting all the grammar precompiled Marpa::R2::Scanless::G objects

=head1 VERSION

version 0.020

=head1 DESCRIPTION

This modules is a singleton used for caching all precompiled Marpa::R2::Scanless::G objects.

=head1 SUBROUTINES/METHODS

=head2 G($self, $grammarOptionsHashp)

Cached Marpa::R2::Scanless::G object for grammar with options $grammarOptionsHashp.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
