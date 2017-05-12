package MetaStore::Kern;

#$Id$

=head1 NAME

MetaStore::Kern - Class of kernel object.

=head1 SYNOPSIS

    use MetaStore::Kern;
    use base qw/ MetaStore::Kern /;

=head1 DESCRIPTION

Class of kernel object.

=head1 METHODS

=cut

use WebDAO::Engine;
use MetaStore::Config;
use MetaStore::Response;
use Data::Dumper;
use Carp;
use strict;
use warnings;
use base qw(WebDAO::Engine);
__PACKAGE__->mk_attr (_conf=>undef, __template_obj__=>undef,);
our $VERSION = '0.1';

=head2 init

Initialize object

=cut

sub init {
    my $self = shift;
    my (%opt) = @_;
    $self->__register_event__( $self, "_sess_ended", sub { $self->commit } );
    return $self->SUPER::init(@_);
}

sub config {
    my $self = shift;
    return $self->_conf;
}

sub response {
    my $self = shift;
    my $sess = $self->_session;
    my $resp = new MetaStore::Response::
      session => $sess,
      cv      => $sess->Cgi_obj;
    $resp->set_header( -type => 'text/html; charset=utf-8' );
    return $resp;
}

=head1 auth

Return I<Auth> object ( See MetaStore::Auth ). 
Default return C<undef>.

=cut

sub auth {
    return;
}

sub create_object {
    my $self = shift;
    return $_[0]->_createObj(@_);
}

sub _createObj {
    my $self     = shift;
    my $name_mod = $_[1];

    #try check mod via auth
    if ( my $auth = $self->auth ) {
        return unless $auth->is_access($name_mod);
    }
    return $self->SUPER::_createObj(@_);
}

=head2 execute

Use  execute2 api

=cut

sub execute {
    my $self = shift;
    return $self->execute2(@_);
}

sub parse_template {
    my $self = shift;
    my ( $template, $predefined, $template_config ) = @_;
    $predefined->{self}   = $self unless exists $predefined->{self};
    $predefined->{system} = $self unless exists $predefined->{system};
    $template_config ||= {};

    #    my $template_obj = $self->__template_obj__ || new Template
    my $template_obj = new Template
      INTERPOLATE => 0,
      EVAL_PERL   => 0,
      ABSOLUTE    => 1,
      RELATIVE    => 1,
      %{$template_config},
      VARIABLES => $predefined,
      or do { $self->_log1( "TTK Error:", [$Template::ERROR] ); return };
    $self->__template_obj__($template_obj);
    $template_obj->context->stash->update( {} );
    $template_obj->context->reset;
    my $res;
    $template_obj->process( $template, $predefined, \$res ) or do {
        my $error = $template_obj->error();
        $self->_log1( "TTK Error:" . $error . "; file: $template" );
        return;
    };
    return $res;
}

sub commit {
    my $self = shift;
}

sub _destroy {
    my $self = shift;
    $self->_conf(undef);
    $self->SUPER::_destroy(@_);
}
1;
__END__

=head1 SEE ALSO

Metasore, README

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

