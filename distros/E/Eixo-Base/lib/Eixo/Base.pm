package Eixo::Base;

use 5.008001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Eixo::Base ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.510';


# Preloaded methods go here.

1;

__END__

=head1 NAME

Eixo::Base - Another Perl extension for Classes and Objects


=head1 SYNOPSIS

  package A;

  use parent qw(Eixo::Base::Clase);

  # attribute setters and getters are created automatically
  has(
      id => undef,
      size => undef,
  );

  # to initialize something in object instantiation
  sub initialize {
    my ($self,%args) = @_;

    if($args{size} > 10) {
        $self->size = 10;
    }

    # initialize flog function
    $self->flog(sub{ 
        print $_[0]
    });

    
    return $self;
  }

  # Log input in this method
  sub my_method :Log {
  ...
  }

  # check signature when calling the method
  sub my_method :Sig(i,B){
  ...
  }


=head1 DESCRIPTION


=head1 SEE ALSO

=head1 AUTHOR

Francisco Maseda, E<lt>frmadem@gmail.comE<gt>

Javier Gomez, E<lt>alambike@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Francisco Maseda

Copyright (C) 2014 by Javier Gomez

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut
