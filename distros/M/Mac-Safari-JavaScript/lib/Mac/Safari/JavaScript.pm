package Mac::Safari::JavaScript;
use base qw(Exporter);

# This isn't a problem, all Macs have at least 5.8
use 5.008;

use strict;
use warnings;

use Mac::AppleScript qw(RunAppleScript);
use JSON::XS;
use Encode qw(encode decode);
use Carp qw(croak);

use Mac::Safari::JavaScript::Exception;

our @EXPORT_OK;
our $VERSION = "1.04";

=head1 NAME

Mac::Safari::JavaScript - Run JavaScript in Safari on Mac OS X

=head1 SYNOPSIS

  use Mac::Safari::JavaScript qw(safari_js);

  # do an alert
  safari_js 'alert("Hello Safari User")';

  # return some value
  var $arrayref = safari_js 'return [1,2,3]';

  # multiple lines are okay
  safari_js <<'JAVASCRIPT';
    var fred = "bob";
    return fred;
  JAVASCRIPT
  
  # You can set variables to pass in
  safari_js 'return document.getElementById(id).href', id => "mainlink";

=head1 DESCRIPTION

This module allows you to execute JavaScript code in the Safari web
browser on Mac OS X.

The current implementation wraps the JavaScript in Applescript,
compiles it, and executes it in order to control Safari.

=head1 FUNCTIONS

Functions are exported on request, or may be called fully qualified.

=over

=item safari_js($javascript, @named_parameters)

Runs the JavaScript in the first tab of the front window of the
currently running Safari.

=over 8

=item The script

This script may safely contain newlines, unicode characters, comments etc.
Any line numbers in error messages should match up with error messages

=item Return value

C<safari_js> will do a passable job of mapping whatever you returned from
your JavaScript (using the C<return> keyword) into a Perl data structure it
will return.  If you do not return a value from JavaScript (i.e. the return
keyword is not executed) then C<safari_js> will return the empty list.  If
you return nothing (i.e. use C<return;> in your script), C<safari_js> will
return C<undef>.

Whatever you return from your JavaScript will be encoded into JSON with
Safari's native C<JSON.stringify> function and decoded on the Perl side
using the JSON::XS module.

JavaScript data structures are mapped as you might expect:  Objects to
hashrefs, Arrays to arrayrefs, strings and numbers to their normal scalar
representation, and C<null>, C<true> and C<false> to C<undef>, JSON::XS::true
(which you can treat like the scalar C<1>) and JSON::XS::false (which you
can treat like the scalar C<0>) respectivly.  Please see L<JSON::XS>
for more information.

You cannot return anything from JavaScript that has a ciruclar reference
in it (as this cannot be represented by JSON.)

=item Passing Parameters

You may pass in named parameters by passing them as name/value pairs

  safari_js $js_code_to_run, name1 => $value1, name2 => $value2, ...

The parameters are simply availble as variables in your code.

Internally parameters are converted from Perl data structures into JavaScript
using JSON::XS using the reverse mapping described above.  You may not pass
in circular data structures.  Again, see L<JSON::XS> for more infomation.

=item Exception Handling

If what you pass causes an uncaught exception within the Safari web browser
(including exceptions during by parsing your script) then a
Mac::Safari::JavaScript::Exception exception object will be raised by
C<safari_js>.  This will stringify to the exception you normally would see
in your browser and can be integated for extra info such as the line number,
etc.

=back

=cut

sub safari_js($;@) {
  my $javascript = shift;

  # create a coder objects
  my $coder = JSON::XS->new;
  $coder->allow_nonref(1);

  # handle the arguments passed in
  if (@_ % 2) {
    croak "Uneven number of parameters passed to safari_js";
  }
  my %params;
  while (@_) {
    my $key = shift;
    if (exists $params{ $key }) {
      croak "Duplicate parameter '$key' passed twice to safari_js";
    }
    # we're going to put the value into a string to
    # eval.  This means we need to escape all the meta chars
    my $value = $coder->encode(shift);
    $value =~ s/\\/\\\\/gx;  # \ -> \\
    $value =~ s/"/\\"/gx;    # " -> \"

    $params{ $key } = $value;
  }
  my $args = join ",", keys %params;
  my $values = join ",", values %params;

  # we're going to put the javascript into a string to
  # eval.  This means we need to escape all the meta chars
  $javascript =~ s/\\/\\\\/gx;  # \ -> \\
  $javascript =~ s/"/\\"/gx;    # " -> \"

  # since we've now effectivly got a multiline string (and
  # JavaScript doesn't support that) we better fix that up
  # Note that we're trying not to mess up the line numers
  # inside the eval of what we were passed
  $javascript = join '\\n"+"',split /\n/x, $javascript;

  # wrap the javascript in helper functions
  #  
  #  - use (function () { })() to avoid poluting the global namespace
  #  - use eval "" to allow syntax errors to be caught and returned as a
  #    data structure we can re-throw on the Perl side
  #  - JSON.stringify(undefined) returns, not the string "null".  We detect
  #    this and return the string "null"

  $javascript = <<"ENDOFJAVASCRIPT";
try{var result=eval("JSON.stringify((function($args){ $javascript;throw'NothingReturned'})($values));");(result===undefined)?'{"undefined":1}':'{"result":'+result+'}';}catch(e){ (e == "NothingReturned")?'{"noresult":1}':(function(){var r={error:e,name:'CustomError'};var v=['name',"line","expressionBeginOffset","expressionEndOffset","message","sourceId","sourceURL"];console.log(e);for(var i=0;i<v.length;i++)if(e[v[i]]!=undefined)r[v[i]]=e[v[i]];if(r.hasOwnProperty("expressionEndOffset")) r.expressionEndOffset-=28;if(r.hasOwnProperty("expressionBeginOffset")) r.expressionBeginOffset-=28;return JSON.stringify(r);})(); }
ENDOFJAVASCRIPT

  # escape the string escapes again as we're going to pass
  # the whole thing via Applescript now
  $javascript =~ s/\\/\\\\/gx;     # \ -> \\
  $javascript =~ s/"/\\"/gx;       # " -> \"

  # wrap it in applescript
  my $applescript = <<"ENDOFAPPLESCRIPT";
tell application "Safari"
  -- execute the javascript
  set result to do JavaScript "$javascript" in document 1

  -- then make sure we're returning a string to be consistent'
  "" & result
end tell
ENDOFAPPLESCRIPT

  # compile it an execute it using the cocca api
  # (make sure to pass it in as utf-8 bytes)
  my $json = RunAppleScript($applescript);

  # $json is now a string where each character represents a byte
  # in a utf-8 encoding of the real characters (ARGH!).  Fix that so
  # each character actually represents the character it should, um,
  # represent.
  $json = encode("iso-8859-1", $json);
  $json = decode("utf-8", $json);

  # strip off any applescript string wrapper
  $json =~ s/\A"//x;
  $json =~ s/"\z//x;
  $json =~ s/\\"/"/gx;
  $json =~ s/\\\\/\\/gx;

  # and decode this from json
  my $ds = eval {
    $coder->decode($json);
  };
  if ($@) { croak("Unexpected error returned when trying to communicate with Safari"); }

  return undef
    if exists $ds->{undefined};
  return
    if exists $ds->{noresult};
  return $ds->{result}
    if exists $ds->{result};
  croak(Mac::Safari::JavaScript::Exception->new(%{ $ds }))
    if exists $ds->{error};
  croak("Unexpected error returned when trying to communicate with Safari");
}
push @EXPORT_OK, "safari_js";

=back

=head1 AUTHOR

Written by Mark Fowler <mark@twoshortplanks.com>

Copryright Mark Fowler 2011. All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

Bugs should be reported to me via the CPAN RT system. http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mac::Safari::JavaScript

Some pages (e.g. http://developer.apple.com/) cause array stringifcation to break.  I haven't worked out why yet.

=head1 SEE ALSO

L<Mac::AppleScript>, L<Mac::Safari::JavaScript::Exception>

=cut

1;
