package JSON::ize;
use base Exporter;
use JSON 2.00;
use strict;
use warnings;

our $JOBJ = JSON->new();
our $_last_out = "";

our @EXPORT = qw/jsonize jsonise J parsej pretty_json ugly_json/;
our $VERSION = "0.102";

sub jobj { $JOBJ }

sub jsonize (;$) {
  my $inp = shift;
  if (!defined $inp) {
    return $_last_out;
  }
  if (ref $inp) { # encode perl object
    return $_last_out = jobj()->encode($inp);
  }
  else { # scalar: decode if looks like json, or slurp if filename
    if (looks_like_json($inp)) {
      return $_last_out = jobj()->decode($inp);
    }
    else { # try as file
      local $/;
      my $j;
      die "'$inp' is not a existing filename, json string, or a reference" unless (-e $inp);
      open my $f, "$inp" or die "Problem with file '$inp' : $!";
      $j = <$f>;
      return $_last_out = jobj()->decode($j);
    }
  }
}

sub jsonise (;$) { jsonize($_[0]) }
sub J (;$) { jsonize($_[0]) }


sub parsej () {
  $_last_out = $JOBJ->incr_parse($_);
}

sub pretty_json { jobj()->pretty; return; }
sub ugly_json { jobj()->pretty(0); return; }

sub looks_like_json {
  my $ck = $_[0];
  return $ck =~ /^\s*[[{]/;
}

=head1 NAME

 JSON::ize - Use JSON easily in one-liners

=head1 SYNOPSIS

 $ perl -MJSON::ize -le '$j=jsonize("my.json"); print $j->{thingy};'

 $ perl -MJSON::ize -le 'J("my.json"); print J->{thingy};' # short

 $ perl -MJSON::ize -le 'print J("my.json")->{thingy};' # shorter


 $ cat my.json | perl -MJSON::ize -lne 'parsej; END{ print J->{thingy}}' # another way

 $ perl -MJSON::ize -le '$j="{\"this\":\"also\",\"works\":[1,2,3]}"; print jsonize($j)->{"this"};' # also

 $ perl -MJSON::ize -e 'pretty_json(); $j=jsonize("ugly.json"); print jsonize($j);' # pretty!

 $ perl -MJSON::ize -e 'ugly_json; print J(J("indented.json"));' # strip whsp


=head1 DESCRIPTION

JSON::ize exports a function, C<jsonize()>, that will do what you mean with the argument. 
If argument is a filename, it will try to read the file and decode it as JSON.
If argument is a string that looks like JSON, it will try to encode it.
If argument is a Perl hashref or arrayref, it will try to encode it.

The underlying L<JSON> object is

 $JSON::ize::JOBJ

=head1 METHODS

=over 

=item jsonize($j), jsonise($j), J($j)

Try to DWYM.
If called without argument, return the last value returned. Use this to retrieve
after L</parsej>.

=item parsej

Parse a piped-in stream of json. Use jsonize() (without arg) to retrieve the object.
(Uses L<JSON/incr_parse>.)

=item pretty_json()

Output pretty (indented) json.

=item ugly_json()

Output json with no extra whitespace.

=back

=head1 SEE ALSO

L<JSON>, L<JSON::XS>.

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN
 mark -dot- jensen -at- nih -dot- gov

=head1 LICENSE

Copyright (c) 2018 Mark A. Jensen.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


=cut

1;
