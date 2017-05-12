package JSON::Schema::Result;

use 5.010;
use strict;
use overload bool => \&valid;

use JSON::Schema::Error;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.016';

sub new
{
	my ($class, $result) = @_;
	return bless $result, $class;
}

sub valid
{
	my ($self) = @_;
	return $self->{'valid'};
}

sub errors
{
	my ($self) = @_;
	return map { JSON::Schema::Error->new($_); } @{$self->{'errors'}};
}

1;

__END__

=head1 NAME

JSON::Schema::Result - the result of checking an instance against a schema

=head1 SYNOPSIS

 my $validator = JSON::Schema->new($schema);
 my $json      = from_json( ... );
 my $result    = $validator->validate($json);
 
 if ($result)
 {
   print "Valid!\n";
 }
 else
 {
   print "Errors\n";
	print " - $_\n" foreach $result->errors;
 }

=head1 DESCRIPTION

L<JSON::Schema::Result> is returned by the L<JSON::Schema> C<validate>
method. It uses L<overload> to mimic a boolean. That is:

  if ($result) { foo(); } else { bar(); }

Will do "foo" if the result is positive for validity and "bar" if it's negative.

There's also a method C<errors> to get a list of errors. (Which will be
empty in the case of a positive result.) Each error is a L<JSON::Schema::Error>.

=head1 SEE ALSO

L<JSON::Schema>, L<JSON::Schema::Error>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2010-2012 Toby Inkster.

This module is tri-licensed. It is available under the X11 (a.k.a. MIT)
licence; you can also redistribute it and/or modify it under the same
terms as Perl itself.

=head2 a.k.a. "The MIT Licence"

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
