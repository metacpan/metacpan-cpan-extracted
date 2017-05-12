
package LWP::UserAgent::Determined;

$VERSION = '1.07';
use      LWP::UserAgent ();
@ISA = ('LWP::UserAgent');

use strict;
die "Where's _elem?!!?" unless __PACKAGE__->can('_elem');

sub timing                     { shift->_elem('timing' , @_) }
sub codes_to_determinate       { shift->_elem('codes_to_determinate' , @_) }
sub before_determined_callback { shift->_elem('before_determined_callback' , @_) }
sub after_determined_callback  { shift->_elem( 'after_determined_callback' , @_) }

#==========================================================================

sub simple_request {
    my ( $self, @args ) = @_;
    my (@timing_tries) = ( $self->timing() =~ m<(\d+(?:\.\d+)*)>g );
    my $determination = $self->codes_to_determinate();

    my $resp;
    my $before_c = $self->before_determined_callback;
    my $after_c  = $self->after_determined_callback;

    my $request = $args[0];
    foreach my $pause_if_unsuccessful ( @timing_tries, undef ) {
        $args[0] = $request->clone;
        $before_c and $before_c->(
            $self, \@timing_tries, $pause_if_unsuccessful, $determination,
            \@args
        );
        $resp = $self->SUPER::simple_request(@args);
        $after_c and $after_c->(
            $self, \@timing_tries, $pause_if_unsuccessful, $determination,
            \@args, $resp
        );

        my $code = $resp->code;
        unless ( $determination->{$code} ) {
            # normal case: all is well (or 404, etc)
            return $resp;
        }
        if ( defined $pause_if_unsuccessful ) {
            # it's undef only on the last
            sleep $pause_if_unsuccessful if $pause_if_unsuccessful;
        }
    }

    return $resp;
}

#--------------------------------------------------------------------------

sub new {
    my $self = shift->SUPER::new(@_);
    $self->_determined_init();
    return $self;
}

#--------------------------------------------------------------------------

sub _determined_init {
    my $self = shift;
    $self->timing('1,3,15');
    $self->codes_to_determinate( { map { $_ => 1 }
        '408', # Request Timeout
        '500', # Internal Server Error
        '502', # Bad Gateway
        '503', # Service Unavailable
        '504', # Gateway Timeout
    } );
    return;
}

#==========================================================================

1;
__END__


=head1 NAME

LWP::UserAgent::Determined - a virtual browser that retries errors

=head1 SYNOPSIS

  use strict;
  use LWP::UserAgent::Determined;
  my $browser = LWP::UserAgent::Determined->new;
  my $response = $browser->get($url, headers... );

=head1 DESCRIPTION

This class works just like L<LWP::UserAgent> (and is based on it, by
being a subclass of it), except that when you use it to get a web page
but run into a possibly-temporary error (like a DNS lookup timeout),
it'll wait a few seconds and retry a few times.

It also adds some methods for controlling exactly what errors are
considered retry-worthy and how many times to wait and for how many
seconds, but normally you needn't bother about these, as the default
settings are relatively sane.

=head1 METHODS

This module inherits all of L<LWP::UserAgent>'s methods,
and adds the following.

=over

=item $timing_string = $browser->timing();

=item $browser->timing( "10,30,90" )

The C<timing> method gets or sets the string that controls how many
times it should retry, and how long the pauses should be.

If you specify empty-string, this means not to retry at all.

If you specify a string consisting of a single number, like "10", that
means that if the first request doesn't succeed, then
C<< $browser->get(...) >> (or any other method based on C<request>
or C<simple_request>)
should wait 10 seconds and try again (and if that fails, then
it's final).

If you specify a string with several numbers in it (like "10,30,90"),
then that means C<$browser> can I<re>try as that many times (i.e., one
initial try, I<plus> a maximum of the three retries, because three numbers
there), and that it should wait first those numbers of seconds each time.
So C<< $browser->timing( "10,30,90" ) >> basically means:

  try the request; return it unless it's a temporary-looking error;
  sleep 10;
  retry the request; return it unless it's a temporary-looking error;
  sleep 30;
  retry the request; return it unless it's a temporary-looking error;
  sleep 90  the request;
  return it;

The default value is "1,3,15".



=item $http_codes_hr = $browser->codes_to_determinate();

This returns the hash that is the set of HTTP codes that merit a retry
(like 500 and 408, but unlike 404 or 200).  You can delete or add
entries like so;

  $http_codes_hr = $browser->codes_to_determinate();
  delete $http_codes_hr->{408};
  $http_codes_hr->{567} = 1;

(You can actually set a whole new hashset with C<<
$browser->codes_to_determinate($new_hr) >>, but there's usually no
benefit to that as opposed to the above.)

The current default is 408 (Timeout) plus some 5xx codes.



=item $browser->before_determined_callback()

=item $browser->before_determined_callback( \&some_routine );

=item $browser->after_determined_callback()

=item $browser->after_determined_callback( \&some_routine );

These read (first two) or set (second two) callbacks that are
called before the actual HTTP/FTP/etc request is made.  By default,
these are set to undef, meaning nothing special is called.  If you
want to alter try requests, or inspect responses before any retrying
is considered, you can set up these callbacks.

The arguments passed to these routines are:

=over

=item 0: the current $browser object

=item 1: an arrayref to the list of timing pauses (based on $browser->timing)

=item 2: the duration of the number of seconds we'll pause if this request
fails this time, or undef if this is the last chance.

=item 3: the value of $browser->codes_to_determinate

=item 4: an arrayref of the arguments we pass to LWP::UserAgent::simple_request
(the first of which is the request object)

=item (5): And, only for after_determined_callback, the response we
just got.

=back

Example use:

  $browser->before_determined_callback( sub {
    print "Trying ", $_[4][0]->uri, " ...\n";
  });

=back


=head1 IMPLEMENTATION

This class works by overriding LWP::UserAgent's C<simple_request> method
with its own around-method that just loops.  See the source of this
module; it's straightforward.  Relatively.


=head1 SEE ALSO

L<LWP>, L<LWP::UserAgent>


=head1 COPYRIGHT AND DISCLAIMER

Copyright 2004, Sean M. Burke, all rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.


=head1 AUTHOR

Originally created by Sean M. Burke, C<sburke@cpan.org>

Currently maintained by Jesse Vincent C<jesse@fsck.com>

=cut

