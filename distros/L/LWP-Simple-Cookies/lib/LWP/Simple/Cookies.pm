package LWP::Simple::Cookies;
use strict;
use vars '$VERSION';
use LWP::Simple '$ua';

BEGIN {
    $VERSION = 0.01;
}

sub import {
    my $pkg = shift;
    
    require HTTP::Cookies;

    $ua->cookie_jar( @_
                     ? HTTP::Cookies->new( @_ )
                     : {} );
}

1;

__END__

=head1 NAME

LWP::Simple::Cookies - adds cookie support to LWP::Simple

=head1 SYNOPSIS

 use LWP::Simple;
 use LWP::Simple::Cookies ( autosave => 1,
                            file => "$ENV{'HOME'}/lwp_cookies.dat" );

 # Cookies are now used.
 get( ... );

=head1 DESCRIPTION

This module alters the operation of LWP::Simple so that it keeps track of
any cookies presented by the server. Any import options are passed directly
to HTTP::Cookies->new.

=head1 CAVEAT

You are allowed to neglect to load the LWP::Simple module but be aware that
doing this prevents all of LWP::Simple's functions from being imported
into your code. Use of this module as in the example mostly closely mirrors
a normal LWP::Simple experience.

=head1 SEE ALSO

L<LWP::Simple>, L<HTTP::Cookies>

=head1 AUTHOR

Joshua b. Jore E<lt>jjore@cpan.orgE<gt>

=cut
