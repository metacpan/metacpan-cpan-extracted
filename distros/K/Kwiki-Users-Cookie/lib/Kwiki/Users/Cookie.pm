package Kwiki::Users::Cookie;
use Kwiki::Users -Base;

our $VERSION = "0.01";

const class_title => 'Kwiki users from Cookie lookup';
const user_class => 'Kwiki::User::Cookie';

sub init {
	$self->hub->config->add_file('user_cookie.yaml');
}

package Kwiki::User::Cookie;
use base 'Kwiki::User';
                   
field 'name' => '';
field 'id';

sub process_cookie {
		return shift;
}

sub fetch_user_name_from_cookie { 
		my $cookie_name = shift;
		my $cookie_value = CGI::cookie($cookie_name);
		$cookie_value = $self->process_cookie($cookie_value);
		return $cookie_value;
}

sub set_user_name {
    return unless $self->is_in_cgi;
		
		my $cookie_name = $self->hub->config->user_cookie_name;
		$cookie_name ||= $self->hub->config->user_cookie_default_name;
    
		my $name = '';
    $name = $self->fetch_user_name_from_cookie($cookie_name);
    
		$name ||= $self->hub->config->user_default_name;
    $self->name($name);
}


package Kwiki::Users::Cookie;    
__DATA__

=head1 NAME 

Kwiki::Users::Cookie - automatically set Kwiki user name from a cookie based lookup

=head1 SYNOPSIS

 $ cd /path/to/kwiki
 $ echo "users_class: Kwiki::Users::Cookie" >> config.yaml
 $ echo "users_cookie_name: user_cookie_name"    >> config.yaml

Optionally, to display the user name:

 $ cd /path/to/kwiki
 $ kwiki -add Kwiki::UserName::Cookie
 $ echo "login_url: /login.html"    >> config.yaml

=head1 DESCRIPTION

This module will set the user's name from a cookie's value.  Optionally,
that value could be used to lookup session info, etc, to set the user's name.

You might also want to use L<Kwiki::UserName::Cookie>.

=head1 AUTHORS

John Cappiello <jcap@cpan.org>

=head1 BASED ON

L<Kwiki::Users::Remote> by Ian Langworth <langworth.com> 

=head1 SEE ALSO

L<Kwiki>, L<Kwiki::UserName::Cookie>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by John Cappiello

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__config/user_cookie.yaml__
user_default_cookie_name: username 
user_default_name: AnonymousGnome
