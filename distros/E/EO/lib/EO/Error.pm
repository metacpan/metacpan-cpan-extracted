package EO::Error;

use strict;
use warnings;

use EO;
use Error;

our $VERSION = 0.96;
our $SILENTLY_REDEFINE_EXCEPTIONS = 1;
our @ISA = qw(Error);

sub new {
    my $class = shift;
    my %params = @_;
    my %new_params;
    local($Error::Depth) = $Error::Depth + 1;
    local($Error::Debug) = 1;
    foreach my $key (keys %params) {
      $new_params{"-$key"} = $params{$key};
    }
    $class->SUPER::new(%new_params);
}

our $AUTOLOAD;
sub AUTOLOAD {
  my $self = shift;
  my $meth = substr($AUTOLOAD, rindex($AUTOLOAD, ':') + 1);
  if (defined($self->{"-$meth"})) {
    if (@_) {
      $self->{"-$meth"} = shift;
      return $self;
    }
    return $self->{"-$meth"};
  }
  throw EO::Error::Method::NotFound
    text => "no such property $meth defined on this error";
}

sub DESTROY {}

##
## we actually want a stack trace if we have to stringify.
##
sub stringify {
  my $self = shift;
  "[".ref($self)."] - ".$self->stacktrace;
}

##
## this is a neat way of creating declarations
##
sub UNIVERSAL::exception {
  my $class = shift;
  ## it would be much nicer to use EO::Class here, but we
  ## can't really.  Not yet.
  if (UNIVERSAL::can($class, 'can')) {
    if (!$EO::Error::SILENTLY_REDEFINE_EXCEPTIONS) {
      require Carp;
      Carp::carp("not redefining exception class $class");
    }
    return;
  }
  my $args  = { @_ };
  my $parent = $args->{extends} || 'EO::Error';
  {
    no strict 'refs';
    @{ $class . '::ISA' } = ( $parent );
  }
}

1;

__END__

=head1 NAME

EO::Error - A generic base class for Exceptions

=head1 SYNOPSIS


   exception EO::Error::SomeError;
   exception EO::Error::SomeError::Whoo extends => 'EO::Error::SomeError';

   eval {
     throw EO::Error::SomeError text => 'some error has occurred';
   };

   if ($@) {
     $@->text
     $@->file
     $@->line
     $@->stacktrace
     print $@; # will stringify
   }

=head1 DESCRIPTION

This is the base class for Exceptions inside the EO module tree. To declare
an exception class simply use the C<exception> declaration followed by the
name of the exception you want to declare.  In addition to a simple
declaration you can use the extends example shown in the synopsis above.  If
you fail to catch a thrown exception your program will die with a strack
trace from that point.

=head1 AUTHOR

Arthur Bergman & James Duncan
arbergman@fotango.com
jduncan@fotango.com

=head1 COPYRIGHT

Copyright 2004 Fotango Ltd. All Rights Reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
