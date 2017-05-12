package JavaScript::Autocomplete::Backend;

$VERSION = '0.10';

use strict;
use warnings;

=head1 NAME

JavaScript::Autocomplete::Backend - Google Suggest-compatible autocompletion
backend

=head1 SYNOPSYS

    package MyAutocompleter;
    use base qw(JavaScript::Autocomplete::Backend);

    my @NAMES = qw(alice bob charlie); 
    sub expand {
        my ($self, $query) = @_;
        # do something to expand the query
        my $re = qr/^\Q$query\E/i;
        my @names = grep /$re/, @NAMES;
        (lc $query, \@names, [], [""]);
    }

    MyAutocompleter->run;

=head1 DESCRIPTION

This is a base class for implementing an autocompletion server with the same
protocol used by Google Suggest ( http://www.google.com/webhp?complete=1&hl=en
). It is basically a CGI script that takes a word to be completed as the "qu"
parameter and returns a specially concoted JavaScript statement. For more
efficiency it should be possible to turn it into a mod_perl handler; that is
left as an exercise for the reader.

The front-end JavaScript code is discussed in
http://serversideguy.blogspot.com/2004/12/google-suggest-dissected.html .

This module is used by creating a subclass, which should override the
C<expand> method, which takes care of searching for the autocompletion results.

=head1 METHODS

=over

=item $class->run(%args)

Run the whole autocompletion process in one fell swoop. Prints everything to
standard output, including the HTTP headers. The arguments %args are passed to
the constructor.

=cut

sub run {
    my $class = shift;
    my $self = $class->new(@_);
    print $self->header;
    print($self->no_js), return unless $self->param('js');
    my ($query, $names, $values, $prefix) = $self->expand($self->query);
    print $self->output($query, $names, $values, $prefix);
}

=item $class->new(%args)

Create a new JavaScript::Autocomplete::Backend object. Currently the only
argument is C<cgi>, which should provide a L<CGI> or CGI-compatible object. If
none is provided, a new L<CGI> object is created by default.

=cut

sub new {
    my ($class, %args) = @_;
    my $cgi = $args{cgi} || (require CGI, CGI->new);
    bless { 
        cgi => $cgi, 
    }, $class;
}

=item $obj->query

Returns the string to be expanded (which usually comes from the "qu" CGI
parameter).

=cut

sub query {
    shift->param('qu');
}

=item $obj->cgi

Returns the CGI object being used.

=cut

sub cgi { shift->{cgi} }

=item $obj->param($name)

Get a CGI parameter. Just delegates the call to $self->cgi.

=cut

sub param { shift->cgi->param(@_) }

=item $obj->header(%args)

Return the HTTP headers. It just delegates to $self->cgi, but it uses the
UTF-8 encoding by default.

=cut

sub header { shift->cgi->header( -charset => 'utf-8', @_ ) }

=item $obj->output($query, $names, $values, $prefix)

Converts the expanded values into JavaScript, as expected by the calling
frontend script. $query is a string; all the other parameters are array refs.
Returns a string.

=cut

sub output {
    my ($self, $query, $names, $values, $prefix) = @_;
    my $ret = qq{sendRPCDone(frameElement, "$query", };
    $ret .= $self->as_array($names). ", ";
    $ret .= $self->as_array($values). ", ";
    $ret .= $self->as_array($prefix). ");\n";
    $ret;
}

=item $obj->expand($query)

Provide the autocompleted values for the query. Returns a 4-element list:
($query, $names, $values, $prefix). $query is the query as returned to the
frontend script (typically converted to lowercase). $names is an array ref
of results. $values is an array ref of values that are usually shown on the
right-hand side of the drop-down box in the front end; it is used by Google
for the estimated result count. The purpose of $prefix is not certain at this
time, but it appears that if the array is empty, the drop-down menu appears but
the word in the input box itself is not completed, while if the array is not 
empty (for example, contains an empty string as its only element), the
word in the input box is completed as well.

=cut

sub expand {
    my ($self, $query) = @_;
    (lc $query, [],[],[]);
}


=item $obj->as_array(\@arr)

Convert an array ref into a JavaScript Array constructor. Returns a string.
For example, 

    print $obj->as_array(["a", "b", "c"]);
    # prints 'new Array("a", "b", "c")'

=cut

sub as_array {
    my ($self, $a) = @_;
    'new Array(' . join(", ", map { qq("$_") } @$a) . ')';
}

=item $obj->no_js

Returns that message that is returned by the Google backend when the C<js>
CGI parameter is not true.

=cut

sub no_js {
    <<HTML;
<html>
<head>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
<script>
function bodyLoad() {
  if (parent == window) return;
  var frameElement = this.frameElement;
  parent.sendRPCDone(frameElement, "", new Array(), new Array(), new Array(""));
}
</script></head><body onload='bodyLoad();'></body></html>
HTML
}

=back

=head1 SEE ALSO

http://www.google.com/webhp?complete=1&hl=en

http://serversideguy.blogspot.com/2004/12/google-suggest-dissected.html

=head1 VERSION

0.10

=head1 AUTHOR

Ivan Tubert-Brohman E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2004 Ivan Tubert-Brohman. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.  

The original JavaScript frontend code is Copyright (c) 2004 Google, Inc. Use it
at your own risk or write or find a free version.

=cut

1;

