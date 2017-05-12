use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Impl::Logger;

# ABSTRACT: Log::Any implementation on top of Marpa

use diagnostics;
use MarpaX::Languages::ECMAScript::AST::Exceptions qw/:all/;
use Log::Any;

our $VERSION = '0.020'; # VERSION

sub BEGIN {
    #
    ## Some Log implementation specificities
    #
    my $log4perl = eval 'use Log::Log4perl; 1;' || 0; ## no critic
    if ($log4perl) {
	#
	## Here we put know hooks for logger implementations
	#
	Log::Log4perl->wrapper_register(__PACKAGE__);
    }
}

sub TIEHANDLE {
  my($class, %options) = @_;

  my $self = {
              level => exists($options{level}) ? ($options{level} || 'trace') : 'trace',
              category => exists($options{category}) ? $options{category} : undef, # undef is ok
             };

  $self->{logger} = Log::Any->get_logger(category => $self->{category});

  bless $self, $class;
}

sub PRINT {
  my $self = shift;
  my $logger = $self->{logger} || '';
  my $level = $self->{level} || '';
  if ($logger && $level) {
    $logger->trace(@_);
  }
  return 1;
}

sub PRINTF {
  my $self = shift;
  return $self->PRINT(sprintf(@_));
}

sub UNTIE {
  my ($obj, $count) = @_;
  if ($count) {
    InternalError(error => "untie attempted while $count inner references still exist");
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Impl::Logger - Log::Any implementation on top of Marpa

=head1 VERSION

version 0.020

=head1 DESCRIPTION

This module is a Log::Any wrapper on top of Marpa, instantiated with a trace_file_handle tied to this package

=head1 SEE ALSO

L<Log::Any>, L<http://osdir.com/ml/lang.perl.modules.log4perl.devel/2007-03/msg00030.html>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
