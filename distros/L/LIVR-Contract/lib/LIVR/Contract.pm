package LIVR::Contract;

use strict;
use warnings;

use Exporter 'import';
use Carp qw/croak/;

use Validator::LIVR;
use Class::Method::Modifiers qw/install_modifier/;
use LIVR::Contract::Exception;
use Scalar::Util qw/blessed/;

our @EXPORT = ( 'contract' );
our @CARP_NOT = (__PACKAGE__);

our $VERSION = '0.04';

sub contract {
    my ( $subname, %args ) = @_;
    croak "Subname is required" unless $subname;

    return __PACKAGE__->new(
        'subname'  => $subname,
        'package'  => scalar( caller ),
        'ensures'  => $args{ensures},
        'requires' => $args{requires},
    )->enable();
}

sub new {
    my ( $class, %args ) = @_;

    croak '"subname" is required' unless $args{subname};
    croak '"package" is required' unless $args{package};

    my $self = bless {
        subname           => $args{subname},
        package           => $args{package},
        ensures           => $args{ensures},
        requires          => $args{requires},
        input_preparator  => $args{input_preparator},
        output_preparator => $args{output_preparator},
        on_fail           => $args{on_fail},
        input_validator   => undef,
        output_validator  => undef,
    }, $class;

    return $self;
}

sub enable {
    my $self = shift;

    install_modifier(
        $self->{package},
        'around',
        $self->{subname},
        sub {
            my $orig  = shift;

            my $input = $self->_get_input_preparator->( @_ );
            $self->_validate_input( $input );

            my $is_wantarray = wantarray;
            my $output = $is_wantarray ? [ $orig->( @_ ) ] : $orig->( @_ );

            my $prepared_output = $self->_get_output_preparator->( $is_wantarray ? @$output : $output );
            $self->_validate_output( $prepared_output );

            return $is_wantarray ? @$output : $output;
        }
    );
}

sub _validate_input {
    my ( $self, $input ) = @_;
    return unless $self->{requires};

    my $validator = $self->{input_validator} ||= Validator::LIVR->new( $self->{requires} )->prepare();

    if ( !$validator->validate( $input ) ) {
        $self->_get_on_fail->( 'input', $self->{package}, $self->{subname}, $validator->get_errors() );
    }
}

sub _validate_output {
    my ( $self, $output ) = @_;
    return unless $self->{ensures};

    my $validator = $self->{output_validator} ||= Validator::LIVR->new( $self->{ensures} )->prepare();

    if ( !$validator->validate( $output ) ) {
        $self->_get_on_fail->( 'output', $self->{package}, $self->{subname}, $validator->get_errors() );
    }
}

sub _get_input_preparator {
    my $self = shift;

    return $self->{input_preparator} ||= sub {
        my %numbered;
        for (my $i=0; $i< @_; $i++) {
            $numbered{$i} = $_[$i];
        }

        my %named;
        foreach ( my $i = @_ % 2; $i < @_; $i += 2 ) {
            if ( ref $_[$i] ) {
                undef %named;
                last;
            } else {
                $named{ $_[$i] } = $_[$i+1];
            }
        }

        return {%numbered, %named};
    };
}

sub _get_output_preparator {
    my $self = shift;

    return $self->{output_preparator} ||=  sub {
        my %numbered;

        for (my $i=0; $i< @_; $i++) {
            $numbered{$i} = $_[$i];
        }

        return \%numbered;
    };
}

sub _get_on_fail {
    my $self = shift;

    return $self->{on_fail} ||=   sub {
        my ( $type, $package, $subname, $errors ) = @_;

        local $Carp::Internal{ (__PACKAGE__) } = 1;

        die LIVR::Contract::Exception->new(
            type    => $type,
            package => $package,
            subname => $subname,
            errors  => $errors
        );
    }
}


=head1 NAME

LIVR::Contract - Design by Contract in Perl with Language Independent Validation Rules (LIVR).

=head1 SYNOPSIS

  # Common usage
  use LIVR::Contract;

  # Positional arguments
  contract 'my_method1' => (
      requires => {
          0 => [ 'required' ]
          1 => [ 'required', 'positive_integer' ]
          2 => [ 'required' ],
      },
      ensures => {
          0 => ['required', 'positive_integer' ]
      }
  );

  # Named arguments
  contract 'my_method2' => (
      requires => {
          0    => [ 'required' ],
          id   => [ 'required', 'positive_integer' ],
          name => [ 'required' ],
      },
      ensures => {
          0 => ['required', 'positive_integer' ]
      }
  );

  # Named arguments in hashref
  contract 'my_method3' => (
      requires => {
          0 => [ 'required' ],
          1 => [ 'required', { nested_object => {
                  id   => [ 'required', 'positive_integer' ],
                  name => [ 'required' ],
              }
          }
      },
      ensures => {
          0 => ['required', 'positive_integer' ]
      }
  );
  
  sub my_method1 {
      my ($self, $id, $name) = @_;
      return 100;
  }

  sub my_method2 {
      my ($self, %named_args) = @_;
      return 100;
  }

  sub my_method3 {
      my ($self, $named_args_hashref) = @_;
      return 100;
  }

  # Somewhere in your code
  $self->my_method1( 100, 'Some Name');

  # Somewhere in your code
  $self->my_method2(
      id   => 100,
      name => 'Some Name',
  );

  # Somewhere in your code
  $self->my_method3({
      id   => 100,
      name => 'Some Name',
  });



=head1 WARNING

B<This software is under heavy development and considered ALPHA
quality. Things might be broken, not all
features have been implemented, and APIs are likely to change. YOU
HAVE BEEN WARNED.>

=head1 DESCRIPTION

L<LIVR::Contract> design by Contract in Perl with Language Independent Validation Rules (LIVR). Uses L<Validator::LIVR> underneath.

See L<https://github.com/koorchik/LIVR> for rules descriptions.

=head1 TODO

=over 4

=item * Contracts in separate files (Roles)

=back

=head1 AUTHOR

Viktor Turskyi, C<< <koorchik at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to Github L<https://github.com/koorchik/LIVR-Contract>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LIVR::Contract

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Viktor Turskyi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;
