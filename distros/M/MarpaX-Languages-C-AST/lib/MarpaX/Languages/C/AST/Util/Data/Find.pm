use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::C::AST::Util::Data::Find;

use Scalar::Util qw/blessed/;
use Carp qw/croak/;

our $_endOfElement = 0;

# ABSTRACT: Find data in C AST

our $VERSION = '0.47'; # VERSION


sub new {
  my ($class, %options) = @_;

  my $self  = {
               _endOfElement     => $options{endOfElement}     || sub {},
               _endOfElementArgs => $options{endOfElementArgs} || [],

               _wanted           => $options{wanted}           || sub {return 1;},
               _wantedArgs       => $options{wantedArgs}       || [],

               _callback         => $options{callback}         || sub {},
               _callbackArgs     => $options{callbackArgs}     || []
              };

  bless $self, $class;

  return $self;
}


sub process {
  my ($self, $value) = @_;

  my @worklist = ($value);
  my $rc = 0;
  do {
    my $obj = shift @worklist;

    my $ref = ref($obj);
    if ($ref eq 'SCALAR' && $obj == \$_endOfElement) {
      $obj = shift @worklist;
      $self->{_endOfElement}(@{$self->{_endOfElementArgs}}, $obj);
      $rc = 1;
    } else {
      if ($self->{_wanted}(@{$self->{_wantedArgs}}, $obj)) {
        $rc = 1;
        $self->{_callback}(@{$self->{_callbackArgs}}, $obj);
      }
      if (blessed($obj) || $ref eq 'ARRAY') {
        unshift(@worklist, @{$obj}, \$_endOfElement, $obj);
      } else {
        croak "Unsupported object type $ref\n" if $ref;
      }
    }
  } while (@worklist);

  return $rc;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::C::AST::Util::Data::Find - Find data in C AST

=head1 VERSION

version 0.47

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use MarpaX::Languages::C::AST::Util::Data::Find;

    my $data = bless [], 'C::AST::Something';

    MarpaX::Languages::C::AST::Util::Data::Find->new(
	wanted => sub { my $o = shift;
			my $class = blessed($o) || '';
			return ($class eq 'C::AST::directDeclaratorIdentifier');
	},
	callback => sub { my ($datap, $o) = @_;
			  #
			  # This object has matched.
			  #
	},
	callbackArgs => [ $data ],
	)->process($data);

=head1 DESCRIPTION

This modules is a minimalist Data::Find designed for the parse tree values of Marpa on a C source file.

=head1 SUBROUTINES/METHODS

=head2 new($class, %options)

Instance a new object. Takes as optional argument a hash that may contain the following key/values:

=over

=item endOfElement

End of element callback (CODE ref).

=item endOfElementArgs

End-Of-Element callback arguments (ARRAY ref). The endOfElement callback is called like: &$endOfElement(@{$endOfElementArgs}, $object) where $object is a reference to the object that finishes. If wanted callback is set, only wanted objects are concerned.

End of element callback (CODE ref).

=item wanted

Match callback (CODE ref).

=item wantedArgs

Match callback arguments (ARRAY ref). The matched callback is called like: &$wanted(@{$wantedArgs}, $object). Any true value means that $object has matched and will be a candidate to the processing callback.

=item callback

Process callback (CODE ref).

=item callbackArgs

Process callback arguments (ARRAY ref). The process callback is called like: &$callback(@{$callbackArgs}, $object) on every object that matched.

=back

=head2 process($self, $value)

Process search on the object $value. Returns a true value is something wanted was found.

=head1 SEE ALSO

 L<Data::Find>, L<Marpa::R2>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
