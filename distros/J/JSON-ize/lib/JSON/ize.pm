package JSON::ize;
use base Exporter;
use JSON::MaybeXS;
use YAML::Any qw/Dump Load LoadFile DumpFile/;
use Try::Tiny;
use strict;
use warnings;

our $JOBJ = JSON::MaybeXS->new();
our $YOBJ;
our $_last_out = "";

our @EXPORT = qw/jsonize jsonise J yamlize yamlise Y parsej pretty_json ugly_json/;
our $VERSION = "0.202";

sub jobj { $JOBJ }

sub jsonize (;$) {
  my $inp = shift;
  if (!defined $inp) {
    return $_last_out;
  }
  if (ref $inp) { # encode perl object
    my ($a,$b,$c,$subr,@rest) = caller(1);
    return $_last_out = ($subr && $subr =~ /Y|yamli[sz]e$/) ? Dump($inp) : jobj()->encode($inp);
  }
  else { # scalar: decode if looks like json or yaml, or slurp if filename
    if (looks_like_json($inp)) {
      return $_last_out = jobj()->decode($inp);
    }
    elsif (looks_like_yaml($inp)) {
      return $_last_out = Load($inp);
    }
    else { # try as file
      local $/;
      my ($j,$f);
      die "'$inp' is not a existing filename, json string, or a reference" unless (-e $inp);
      if ( eval "require PerlIO::gzip; 1" ) {
	open $f, "<:gzip(autopop)", $inp or die "Problem with file '$inp' : $!";
      }
      else {
	open $f, "$inp" or die "Problem with file '$inp' : $!";
      }
      $j = <$f>;
      try {
        $_last_out = jobj()->decode($j);
      } catch {
        /at character offset/ && do { # JSON error
          my $jerr = $_;
          if (looks_like_json($j)) { # probably really was JSON
            die "JSON decode barfed.\nJSON err: $jerr"
          }
          try { # might be YAML
            $_last_out = Load($j);
          } catch {
            if (looks_like_yaml($j)) {
              die "YAML decode barfed.\nYAML err: $_";
            }
            die "Both JSON and YAML decodes barfed.\nJSON err: $jerr\nYAML err: $_";
          };
        };
      };
      return $_last_out;
    }
  }
}

sub jsonise (;$) { jsonize($_[0]) }
sub J (;$) { jsonize($_[0]) }
sub yamlize (;$) { jsonize($_[0]) }
sub yamlise (;$) { jsonize($_[0]) }
sub Y (;$) { jsonize($_[0]) }


sub parsej () {
  $_last_out = $JOBJ->incr_parse($_);
}

sub pretty_json { jobj()->pretty; return; }
sub ugly_json { jobj()->pretty(0); return; }

sub looks_like_json {
  my $ck = $_[0];
  return $ck =~ /^\s*[[{]/;
}

sub looks_like_yaml {
  my $ck = $_[0];
  my @l = $ck =~ /^(?:---|\s+-\s\w+|\s*\w+\s?:\s+\S+)$/gm;
  return @l && ($l[0] eq '---' || @l > 2 );
}


=head1 NAME

 JSON::ize - Use JSON easily in one-liners - now with YAMLific action

=head1 SYNOPSIS

 $ perl -MJSON::ize -le '$j=jsonize("my.json"); print $j->{thingy};'

 $ perl -MJSON::ize -le '$j=jsonize("my.yaml"); print $j->{thingy};'

 # or yamlize, if you prefer

 $ perl -MJOSN::ize -le '$j=yamlize("my.yaml"); print $j->{thingy};'

 # plus yamls all the way down...

 # if you have PerlIO::gzip, this works

 $ perl -MJSON::ize -le '$j=jsonize("my.json.gz"); print $j->{thingy};'

 $ perl -MJSON::ize -le 'J("my.json"); print J->{thingy};' # short

 $ perl -MJSON::ize -le 'print J("my.json")->{thingy};' # shorter

 $ cat my.json | perl -MJSON::ize -lne 'parsej; END{ print J->{thingy}}' # another way

 $ perl -MJSON::ize -le '$j="{\"this\":\"also\",\"works\":[1,2,3]}"; print jsonize($j)->{"this"};' # also

 $ perl -MJSON::ize -e 'pretty_json(); $j=jsonize("ugly.json"); print jsonize($j);' # pretty!

 $ perl -MJSON::ize -e 'ugly_json; print J(J("indented.json"));' # strip whsp

 # JSON to YAML

 $ perl -MJSON::ize -e 'print yamlize jsonize "my.json"'

 $ perl -MJSON::ize -e 'print Y J "my.json"' 

 # and back 

 $ perl -MJSON::ize -e 'print jsonize yamlize "my.yaml"'

 $ perl -MJSON::ize -e 'print J Y "my.yaml"' 

=head1 DESCRIPTION

JSON::ize exports a function, C<jsonize()>, and some synonyms (see below), that will do what you mean with the argument. 

If argument is a filename, it will try to read the file and decode it from JSON or YAML.

If argument is a string that looks like JSON or YAML, it will try to encode it:

=over

=item *

If argument is a Perl hashref or arrayref, and you called C<jsonize()>, it will try to encode it as JSON.

=item *

If argument is a Perl hashref or arrayref, and you called C<yamlize()>, it will try to encode it as YAML.

=back

The underlying L<JSON> object is

 $JSON::ize::JOBJ

=head1 METHODS

=over 

=item jsonize($j), jsonise($j), J($j)

Try to DWYM. In particular, encode to JSON.
If called without argument, return the last value returned. Use this to retrieve
after L</parsej>.

=item yamlize($j), yamlise($j), Y($j)

Try to DWYM. In particular, encode to YAML.
If called without argument, return the last value returned.

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

Copyright (c) 2018, 2019 Mark A. Jensen.

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
