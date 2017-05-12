# tag: test subclass for JOAP Server

# Copyright (c) 2003, Evan Prodromou <evan@prodromou.san-francisco.ca.us>
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
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA

package MyServer;
use JOAP::Server;
use base qw(JOAP::Server);
use Error;
use MyPerson;

MyServer->Description(<<'END_OF_DESCRIPTION');
A simple server to illustrate the features of the server Perl
package. Serves one class, Person.
END_OF_DESCRIPTION

MyServer->Attributes(
    {
	%{ JOAP::Server->Attributes() }, # inherit defaults
	  'logLevel' => { type => 'i4',
	      desc => 'Level of verbosity for logging.' } } );

MyServer->Methods (
    {
	'log' => {
	    returnType => 'boolean',
	    params => [
		{ 
		    name => 'message',
		      type => 'string',
		      desc => 'message to write to log file.'
		}
	    ],
	    desc => 'Log the given message to the log file. Return true for success.'
	},
	'logLine' => {
	    returnType => 'string',
	    params => [
		{
		    name => 'line_no',
		      type => 'i4',
		      desc => 'line number in log file to read, 0-based, must be >= 0.'
		}
	    ],
	    desc => 'Read a line from the log file, and return it.'
	},
    });

MyServer->Classes (
    {
	Person => 'MyPerson'
    });

sub log {

    my($self) = shift;
    my($message) = shift;

    push @{$self->{messages}}, $message
      if ($self->logLevel > 0);

    return 1;
}

sub logLine {

    my($self) = shift;
    my($line_no) = shift;

    if ($line_no < 0 || $line_no > scalar @{$self->{messages}}) {
	throw Error::Simple('No such line', 42);
    } else {
	return $self->{messages}->[$line_no];
    }
}

1;
