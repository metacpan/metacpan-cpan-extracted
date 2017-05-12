package Drogo::Request;

use Drogo::Guts;
use strict;

sub new 
{
    my $class = shift;
    my $self = {};
    bless($self);
    return $self;
}

=head3 $self->uri

Returns the uri.

=cut

sub uri { Drogo::Guts::uri(@_) }


=head3 $self->header_in

Return value of header_in.

=cut

sub header_in { Drogo::Guts::header_in(@_) }

=head3 $self->request_body & $self->request
    
Returns request body.

=cut

sub request_body { Drogo::Guts::request_body(@_) }
sub request { Drogo::Guts::request(@_) }

=head3 $self->request_method

Returns the request_method.

=cut

sub request_method   { Drogo::Guts::request_method(@_) }

=head3 $self->request_part(...)

Returns reference for upload.

  {
     'filename' => 'filename',
     'tmp_file' => '/tmp/drogomp-23198-1330057261',
     'fh'       => \*{'Drogo::Guts::MultiPart::$request_part{...}'},
     'name'     => 'foo'
  }

=cut

sub request_part { Drogo::Guts::request_part(@_) }

=head3 $self->matches

Returns array of post_arguments (matching path after a matched ActionMatch attribute)
Returns array of matching elements when used with ActionRegex.

=cut

sub matches   { Drogo::Guts::matches(@_) }

=head3 $self->param(...)

Return a parameter passed via CGI--works like CGI::param.

=cut

sub param { Drogo::Guts::param(@_) }

=head3 $self->param_hash
    
Return a friendly hashref of CGI parameters.

=cut

sub param_hash { Drogo::Guts::param_hash(@_) }

=head1 AUTHORS

Bizowie <http://bizowie.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Bizowie

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
