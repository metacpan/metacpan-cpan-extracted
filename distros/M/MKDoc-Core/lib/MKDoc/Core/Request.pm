=head1 NAME

MKDoc::Core::Request - MKDoc request object.


=head1 SUMMARY

Just like CGI.pm, with a few additions.

See perldoc CGI for the base CGI OO API.

=cut
package MKDoc::Core::Request::CompileCGI;
use CGI qw(-compile :all);

package MKDoc::Core::Request;
use strict;
use warnings;
use base qw /CGI/;
use Encode;


=head1 API

=head2 $self->instance();

Returns the L<MKDoc::Core::Request> singleton - or creates it if necessary.

=cut
sub instance
{
    my $class = shift;
    $::MKD_Request ||= $class->new();
    return $::MKD_Request;
}



=head2 $self->clone();

Clones the current object and returns the copy.

=cut
sub clone
{
    my $self = shift;
    return $self->new();
}


sub self_uri
{
    my $self = shift;
    my %opt  = map { "-" . $_ => 1 } ( @_, qw /path_info query/ );
    $opt{relative}  ||= 0;
    return $self->url (\%opt);
}


sub url 
{
    my $self = shift;
    my $url  = $self->SUPER::url (@_);

    # httpd.conf example:
    #   SetEnv MKD__URL_PORT_STRIP "80,8080"
    #   SetEnv MKD__URL_PORT_STRIP_REGEX  "80\d*"
    my $port_strip = $ENV{MKD__URL_PORT_STRIP} || '';
    my $port_strip_regex = $ENV{MKD__URL_PORT_STRIP_REGEX} || '';

    # change commas to regex alternator
    $port_strip =~ tr/,/|/;
    my $port_strip_str = $port_strip || $port_strip_regex || '80';

    # assumes url always has a port specifier
    $url =~ s/(.*?\:\/\/(?:.*?\@)?)(.*):(?:${port_strip_str})(?!\d)(.*)/$1$2$3/
        if ($url =~ /(.*?\:\/\/(?:.*?\@)?)(.*):${port_strip_str}(?!\d)(.*)/);

    return $url;
}



=head2 $self->param_eq ($param_name, $param_value);

Returns TRUE if the parameter named $param_name returns
a value of $param_value.

=cut
sub param_eq
{
    my $self  = shift;
    my $param = $self->param (shift());
    my $value = shift;
    return unless (defined $param);
    return unless (defined $value);
    return $param eq $value;
}


sub param_checked
{
    my $self  = shift;
    my $param = $self->param (@_);
    return $param ? 'checked' : undef;
}


=head2 $self->param_equals ($param_name, $param_value);

Alias for param_eq().

=cut
sub param_equals
{
    my $self = shift;
    return $self->param_eq (@_);
}



=head2 $self->path_info_eq ($value);

Returns TRUE if $ENV{PATH_INFO} equals $value,
FALSE otherwise.

=cut
sub path_info_eq
{
    my $self  = shift;
    my $param = $self->path_info();
    my $value = shift;
    return unless (defined $param);
    return unless (defined $value);
    return $param eq $value;
}



=head2 $self->path_info_equals ($param_name, $param_value);

Alias for path_info_eq().

=cut
sub path_info_equals
{
    my $self = shift;
    return $self->path_info_eq (@_);
}



=head2 $self->path_info_starts_with ($value);

Returns TRUE if $ENV{PATH_INFO} starts with $value, FALSE otherwise.

=cut
sub path_info_starts_with
{
    my $self  = shift;
    my $param = $self->path_info();
    my $value = quotemeta (shift);
    return $param =~ /^$value/;
}



=head2 $self->method();

Returns the current request method being used, i.e. normally HEAD, GET or POST.

=cut
sub method
{
    my $self = shift;
    return $ENV{REQUEST_METHOD} || 'GET';
}


sub delete
{
    my $self = shift;
    while (@_) { $self->SUPER::delete (shift()) };
}


sub delete_all_fast
{
    my $self = shift;
    $self->{'.parameters'} = [];
}


=head2 $self->is_upload ($param_name);

Returns TRUE if $param_name is an upload, FALSE otherwise.

=cut
sub is_upload
{
    my ($self, $param_name) = @_;
    my @param = grep(ref && fileno($_), $self->SUPER::param ($param_name));
    return unless @param;
    return wantarray ? @param : $param[0];
}


sub param
{
    my $self  = shift;
    my $key   = shift || return $self->SUPER::param ();

    $self->is_upload ($key => @_) and return $self->SUPER::param ($key => @_);
    @_                            and return $self->SUPER::param ($key => @_);

    my @res = $self->SUPER::param ($key);
    @res = map {
        (defined $_) ? do {
            my $res = $_;
            my $octets = $_;
            my $string = Encode::decode_utf8 ($octets, Encode::FB_PERLQQ);
            $string;
        } : undef
    } @res;

    @res == 0 and return;
    @res == 1 and return shift @res;
    return wantarray ? @res : \@res;
}


# redirect() doesn't seem to work with CGI.pm 2.89
# this should fix for this particular version.
sub redirect
{
    my $self = shift;
    $CGI::VERSION == 2.89 ? return do {
        my $uri  = shift;
        my $res  = '';
        $res .= "Status: 302 Moved\n";
        $res .= "Location: $uri\n\n";
        $res;
    } : return $self->SUPER::redirect (@_);
}


1;


__END__


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

  L<Petal> TAL for perl
  MKDoc: http://www.mkdoc.com/

Help us open-source MKDoc. Join the mkdoc-modules mailing list:

  mkdoc-modules@lists.webarch.co.uk
