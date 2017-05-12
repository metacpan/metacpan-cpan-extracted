package LWP::UserAgent::Snapshot;
use strict;
use warnings;
use Carp;
use Digest::MD5 ();
use HTTP::Response;
use base 'LWP::UserAgent';

use version; our $VERSION = qv('0.2');

=head1 NAME

LWP::UserAgent::Snapshot - modifies the behaviour of C<LWP::UserAgent> to record and playback data.

=head1 SYNOPSIS

  use WWW::Mechanize;
  use LWP::UserAgent::Snapshot;

  @WWW::Mechanize::ISA = ('LWP::UserAgent::Snapshot');

  my $mech = WWW::Mechanize->new;

  $mech->record_to("data_dir"); # turn on recording to data_dir/

  # naviate some web pages

  WWW::Mechanize->record_to(undef); # turn off recording
  WWW::Mechanize->mock_from("data_dir"); # turn on playback

  # Navigating the same urls should now work as before, but without
  # any network access. This is useful for testing.


=head1 DESCRIPTION

If this subclass of C<LWP::UserAgent> is inserted into the C<@ISA>
inheritance list of C<WWW::Mechanize>, it allows it to record request
and response data to a set of files, then play back responses from
that data.

For suggestions on the use of this class in testing, see
L<LWP::UserAgent::Snapshot::UsageGuide>.

=cut

our ($MOCK_DIR, $DUMP_DIR);
our $INDEX = 0;

# reads the content of a file as a single scalar

sub _read_from_file 
{
    my $file = shift;
    Carp::croak "can't open file $file: $!"
        unless open my $in, "<", $file;
    local $/;
    my $content = <$in>;
    close $in;
    utime +(time) x 2, $file; # touch file, so we can see which ones were used
    return $content;
}

# writes a scalar as the content of a file

sub _write_to_file 
{
    my $file = shift;
    Carp::croak "can't open file $file: $!"
        unless open my $out, ">", $file;
    print $out @_;
    close $out;
}

# appends a scalar to the content of a file

sub _append_to_file 
{
    my $file = shift;
    Carp::croak "can't open file $file: $!"
        unless open my $out, ">>", $file;
    print $out @_;
    close $out;
}


# a mock version of simple_request which gets its responses from $MOCK_DIR
# based on the MD5 hash of the request

sub _mock_simple_request
{
    return shift->SUPER::simple_request(@_)
        unless $MOCK_DIR;

    my ($self, $request, $content_handler, $read_size_hint) = @_;

    my $uri = $request->uri;
    my $method = $request->method;
#    print ">>> $INDEX $method $uri\n"; # DEBUG

    my $digest = Digest::MD5::md5_hex($request->as_string);    
    $request = $self->prepare_request($request);

    my @response_file = glob "$MOCK_DIR/$digest-response-*";
    Carp::croak "no cached response for request digest $digest:\n",$request->as_string
            unless @response_file;
    Carp::carp "multiple cached responses for request digest $digest to ",
        $request->uri,", using first" if @response_file>1;

    my $response = HTTP::Response->parse(_read_from_file $response_file[0]);
    $response->request($request);

    my $cookie_jar = $self->cookie_jar;
    $cookie_jar->extract_cookies($response) if $cookie_jar;

    my $response_status = $response->status_line;
#    print ">>> $INDEX status $response_status $digest\n"; # DEBUG

    # handle extra arguments
    if ($content_handler) 
    {
        if (ref $content_handler eq 'CODE')
        {
            $content_handler->($response->content(undef));            
        }
        else
        {
            Carp::croak "could not open file '$content_handler' for writing: $!" 
                unless open my $fh, ">", $content_handler;
            print $fh $response->content(undef);
            close $fh;
        }
    }
    

    return $response;
}


=head1 CLASS METHODS

=head2 C<< $class->record_to($dir) >>

If C<$dir> is supplied, turns on recording to that directory. Otherwise,
turns off recording.

=cut

sub record_to 
{
    my $class = shift;
    my $dir = shift;
    Carp::croak "no such directory '$dir'" unless !defined $dir or -d $dir;

    $DUMP_DIR = $dir;
}


=head2 C<< $class->mock_from($dir) >>

If C<$dir> is supplied, turns on playback from that
directory. Otherwise, turns off playback.

=cut

sub mock_from
{
    my $class = shift;
    my $dir = shift;
    Carp::croak "no such directory '$dir'" unless !defined $dir or -d $dir;

    $MOCK_DIR = $dir;
}




=head1 PUBLIC INSTANCE METHODS

=head2 C<< $response = $obj->simple_request($request) >>

Overrides C<< LWP::UserAgent->simple_request >> and implements the
recording/playback mechanism, when enabled.

=cut

sub simple_request
{
    my $self = shift;
    my $request = shift;
    $INDEX++;

    return $self->_mock_simple_request($request, @_)
        unless $DUMP_DIR;

    my $digest = Digest::MD5::md5_hex($request->as_string);

    my $request_file = sprintf "$DUMP_DIR/$digest-request-%03d.txt", $INDEX;
    my $response_file = sprintf "$DUMP_DIR/$digest-response-%03d.html", $INDEX;
    my $index_file = "$DUMP_DIR/index.txt";

    _write_to_file $request_file, $request->as_string;

    my $response = $self->_mock_simple_request($request, @_);

    _write_to_file $response_file, $response->as_string;

    my $uri = $request->uri;
    my $method = $request->method;
    my $response_status = $response->code;
    _append_to_file $index_file, "$digest $method $uri $response_status\n";

    return $response;
}

=head1 CAVEATS

Because we associate each URL visited with its content as downloaded
on the first visit, this means we assume the website does not change -
in particular, that a given URL's content does not depend on when it's
visited, by what route, or other stateful information.

=head1 SEE ALSO

L<WWW::Mechanize> and L<LWP::UserAgent> for general information.

Similar tools include the unix C<wget> command.

=head1 AUTHOR

Nick Woolley  C<< <cpan.wu-lee@noodlefactory.co.uk> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Nick Woolley C<< <cpan.wu-lee@noodlefactory.co.uk> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


=cut

1;
