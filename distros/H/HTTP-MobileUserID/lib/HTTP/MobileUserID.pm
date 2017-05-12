package HTTP::MobileUserID;

use strict;
use warnings;
use base qw/Class::Data::Accessor/;
__PACKAGE__->mk_classaccessors(qw/agent user_id supported/);

our $VERSION = '0.02';

sub new {
    my $proto = shift;
    my $self = bless {} , ref $proto || $proto;
    $self->init(@_);
    return $self;
}

sub has_user_id {  shift->user_id   }
sub no_user_id  { !shift->user_id   }
sub unsupported { !shift->supported }

*id = \&user_id;

sub init {
    my $self  = shift;
    my $agent = $self->agent(shift);
    $self->supported(1);
    
    if ( $agent->is_docomo ) {
        $self->supported(0) if $agent->html_version && $agent->html_version <= 2.0;
        return if $self->unsupported;
        $self->user_id($agent->serial_number);
    }
    elsif ( $agent->is_softbank ) {
        $self->supported(0) if $agent->is_type_c;
        return if $self->unsupported;
        my $user_id = $agent->get_header('x-jphone-uid') || 'NULL';
        $self->user_id($user_id) if $user_id ne 'NULL';
    }
    elsif ( $agent->is_ezweb ) {
        $self->user_id($agent->get_header('x-up-subno'));
    }
    else {
        $self->supported(0);
    }
}

1;

__END__

=head1 NAME

HTTP::MobileUserID - mobile user ID is returned

=head1 SYNOPSIS

  use HTTP::MobileUserID;
  use HTTP::MobileAgent;
  
  my $agent  = HTTP::MobileAgent->new;
  my $userid = HTTP::MobileUserID->new($agent);
  
  if ( $userid->supported ) {
    print $userid->id;
  }

=head1 DESCRIPTION

mobile user ID is returned

=head1 AUTHOR

Ittetsu Miyazaki E<lt>ittetsu.miyazaki@gmail.comE<gt>

Thanks to Dan Kogai

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::MobileAgent>

Nihongo Document is HTTP/MobileUserID/Nihongo.pod

=cut
