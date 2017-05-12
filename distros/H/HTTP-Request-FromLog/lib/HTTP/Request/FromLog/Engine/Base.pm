package HTTP::Request::FromLog::Engine::Base;

use strict;
use warnings;
use Carp ();

sub new {
    my $class = shift;
    my %args  = @_;

    __PACKAGE__->_mk_virtual_methods($_) for qw( parse );
    return bless {%args}, $class;
}

sub _mk_virtual_methods {
    my $class = shift;
    foreach my $method (@_) {
        my $slot = "${class}::${method}";
        {
            no strict 'refs';
            *{$slot} = sub {
                Carp::croak( ref( $_[0] ) . "::${method} is not overridden" );
            };
        }
    }
    return ();
}

1;

__END__

=head1 NAME

HTTP::Request::FromLog::Engine::Base - Base class for HTTP::Request::FromLog::Engine::XXX. 

=head1 SYNOPSIS

  package HTTP::Request::FromLog::Engine::MyEngine;
  use base qw(HTTP::Request::FromLog::Engine::Base);

  sub parse {
    ......
  }

=head1 DESCRIPTION

This class is base class for HTTP::Request::FromLog::Engine::XXX which you write your own custom engine class.

Every engine has to override `parse()` method.

=head1 METHOD

=head2 new()

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
