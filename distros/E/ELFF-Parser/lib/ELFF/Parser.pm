package ELFF::Parser;

# ELFF-Parser is a perl module for parsing ELFF formatted log files.
#
# Copyright (C) 2007-2010 Mark Warren <mwarren42@gmail.com>
# 
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA


=pod

=head1 NAME

ELFF::Parser - parse ELFF formatted log files

=head1 SYNOPSIS

   use ELFF::Parser;

   $p = new ELFF::Parser();
   while(<LOGFILE>) {
      $res = $p->parse_line($_);

      if($res->{directive} && $res->{directive} eq 'Start-Date') {
         print "Log starts at $res->{value}\n";
      }
      elsif($res->{href}) {
         print $res->{href}{'rs-bytes'}, "\n";
      }
      elsif($res->{aref}) {
         print "Detected log format change, or no fields directive\n";
         foreach my $field (@{$res->{aref}}) {
           print "  found field: $field\n";
         }
         print "\n";
      }
      else {
         print STDERR "Failed to parse log line\n";
      }
   }

=head1 DESCRIPTION

C<ELFF::Parser> parses ELFF formatted logs.  For a description of ELFF
(Extended Log File Format), see http://www.w3.org/TR/WD-logfile.html.  In
brief, ELFF log files consist of directives (meta-data about the logs)
and logs.  C<ELFF::Parser> parses both, extracting log format information
from the directives and using it to build hashes for each log entry.
If log format information isn't available or becomes invalidated (see
the L</"ELFF PROBLEMS"> section below), C<ELFF::Parser> will return
arrays for each log entry instead of hashes.

=head1 CONSTRUCTOR

=over 4

=item $ep = new ELFF::Parser()

Creates a new C<ELFF::Parser> object.

=back

=head1 METHODS

=over 4

=item $res = $ep->parse_line($line)

Parse an ELFF log line.  The returned result will be a hash reference that
contains different information depending on the state of the object and
the type of line parsed (i.e. directive or log entry).

If the line is a directive, the returned hash will have the following
keys:

	$res->{directive}	the name of the directive
	$res->{value}		the value of the directive

If the line is a Fields directive, the result will contain a 'fields'
key as well, which is an array reference containing the fields.

	foreach my $field (@{$res->{fields}}) {
		print "Found field $field\n";
	}

Since C<ELFF::Parser> builds hashes for you for each log entry, you
generally don't need to worry about the fields.

If the line is a log entry, and the C<ELFF::Parser> object has parsed
a fields directive already, the result hash will contain a 'href'
key whose value is a hash reference containing the log entry data.

	print "client to proxy bytes: ", $res->{href}{'cs-bytes'}, "\n";

If no fields directive has been parsed, or C<ELFF::Parser> detects a
change in log format (see the L</"ELFF PROBLEMS"> section below), an
array reference may be returned instead:

	foreach my $field (@{$res->{aref}}) {
		print "data: ", $field, "\n";
	}

If C<parse_line()> detects a malformed line, it will return undef.

=back

=head1 ELFF PROBLEMS

There is one particularly annoying thing about ELFF log files, which is
that the ELFF standard doesn't require that a new Fields directive be
inserted into the log file when the log format changes.  Because of this,
if the log format changes in the middle of a log file, there is very
little that a parser can do to detect the change.  All reporting software
that I have seen simply ignores logs as soon as a change in format
is detected (i.e. when errors are encountered extracting statistics
from the logs).  This is a shortcoming in the ELFF standard, and I'm
afraid that C<ELFF::Parser> doesn't handle the problem much better.
C<ELFF::Parser> detects log format changes by checking the number of
fields in each log entry.  If the number of fields in a log entry differs
from the number of fields specified in the Fields directive, C<ELFF::Parser>
will invalidate the format and start returning arrays of fields for
each message instead of hashes.  This way, the log data is still
available to you, and you can attempt to recover from the problem
yourself.  However, if the number of fields in the log messages
doesn't change when the log format changes (e.g. when fields are
re-ordered, or when the same number of fields is added and removed),
C<ELFF::Parser> will not detected the format change.

Thankfully, log formats usually don't change on their own, so
administrators can modify their procedures such that the impact
of this shortcoming is minimized (e.g. rotate the log file
immediately after changing the log format to force a new fields
directive to be logged).

=head1 HOMEPAGE

L<http://sourceforge.net/projects/elff-parser/>

=head1 BUGS

None that I know of, but please let me know if you find one.  Please
report bugs via the SourceForge tracker.

=head1 AUTHOR

Copyright (c) 2007 Mark Warren <mwarren42@gmail.com>

=head1 LICENSE AND DISCLAIMER

This software is distributed under the terms of the GNU Lesser General
Public License.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

=cut

use 5.00;
use strict;
use Carp;

our $VERSION = '0.92';


sub new {
	my $class = shift;

	my $self = {
		# we use number of fields to detect log format changes.  it's
		# not perfect, but we don't understand the log content, so this
		# is the best that we can do
		'fields' => 0,

		# revmap is used to figure out the name of each field as we
		# build the result hash in parse_line
		'revmap' => {},
	};

	return bless $self, $class;
}

sub parse_line {
	my ($self, $line) = @_;
	chomp($line);

	my $res = {};

	# if the line is a directive, handle it here
	if($line && substr($line, 0, 1) eq '#') {
		# some vendors put whitespace between # and the directive name, remove it
		$line =~ s/^#\s+/#/;

		@$res{('directive', 'value')} = split(/\s+/, $line, 2);
		$res->{directive} =~ s/(?:^#|:$)//g;

		if($res->{directive} eq 'Fields') {
			$self->{revmap} = tokenize($res->{value});
			$self->{fields} = $#{$self->{revmap}};
			@{$res->{fields}} = @{$self->{revmap}};
		}

		return $res;
	}

	# not a directive, regular log

	my $flds = tokenize($line);
	return undef unless $flds;

	# no field names - return array
	unless($self->{revmap}) {
		$res->{aref} = $flds;
		return $res;
	}

	# change in format, invalidate fields and return array
	if($#$flds != $self->{fields}) {
		$self->{revmap} = undef;
		$res->{aref} = $flds;
		return $res;
	}

	# return href
	my %href;
	@href{@{$self->{revmap}}} = @$flds;
	$res->{href} = \%href;

	return $res;
}


require XSLoader;
XSLoader::load('ELFF::Parser', $VERSION);


1;
