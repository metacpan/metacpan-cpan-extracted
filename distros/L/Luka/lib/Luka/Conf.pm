# $Id: Conf.pm,v 1.5 2006/02/27 21:43:59 toni Exp $
package Luka::Conf;
use strict;
use Carp;
use Sys::Syslog;
use warnings;
use Config::IniFiles;
use Luka::Exceptions;
use Data::Dumper;
use vars qw($DEBUG);
$DEBUG=undef;

=head1 NAME

Luka::Conf - Configuration file interface class.

=head1 SYNOPSIS

    $conf = Luka::Conf->new( conf => $conf, syslogd => $syslogd );
    my $ip     = $conf->get_conf('global','expected_ip');

=cut

sub get_conf { 
    my $self = shift @_;
    return $self->_parse_config_ini(@_); 
}

sub _parse_config_ini {
    my ($self,$section,$param) = @_;

    if (not $self->{conf_obj}->SectionExists($section) ) {
	if ($self->{syslogd}) {
	    openlog(__PACKAGE__, 'pid,nowait','daemon');
	    syslog('warning', "Luka system not functional for script '%s'. " .
		   "Couldn't read its section in config file '%s'" , $section , $self->{conf_file});
	    closelog;
	}
	throw Luka::Exception::Program(error => "Luka system not functional for '$section' script. " . 
				       "Couldn't read its section '$section' in config file '" . $self->{conf_file} . "'.\n");

    } elsif (defined $DEBUG and defined($self->{syslogd})) {
	my $call_file = (caller(1))[1];
	my $call_line = (caller(1))[2];
	openlog(__PACKAGE__, 'pid,nowait','daemon');
	syslog('debug', "Called from file %s, line %s",
	       $call_file, $call_line ); 
	syslog('debug', "Reading config file '%s', " .
	       "section '%s', param '%s'.", $self->{conf_file}, $section, $param); 
	closelog;
    }

    return $self->{conf_obj}->val($section,$param);
};

sub new {
    my $class = shift;
    my $type = ref($class) || $class;
    my $self;
    if (defined(@_)) {
	my $arg  = 
	    defined $_[0] && UNIVERSAL::isa($_[0], 'HASH') 
	    ? shift 
	    : { @_ };
	$self = bless { arg => $arg }, $type;
    } else {
	$self = bless {}, $type;
    }
    
    $self->{conf_file} = defined($self->{arg}->{conf})    ? $self->{arg}->{conf}    : "luka.conf";
    $self->{syslogd}   = defined($self->{arg}->{syslogd}) ? $self->{arg}->{syslogd} : undef;
    my ($cfg,$val);

    eval { $cfg = Config::IniFiles->new( -file => $self->{conf_file} ) };
    if ($@) {
	my $error = $@;
	if ($self->{syslogd}) {
	    openlog(__PACKAGE__, 'pid,nowait','daemon');
	    syslog('warning', "Luka system disabled. Couldn't read its config file '%s': %s", $self->{conf_file}, $error->message);
	    closelog;
	};
	throw Luka::Exception::Program
	    (error => "Luka system disabled. Couldn't read its config file '" . 
	     $self->{conf_file} . "': " . $error->message);
    } else {
	$self->{conf_obj} = $cfg;
    }
    
    return $self;
}

1;

=head1 SEE ALSO

L<Config::IniFiles>, L<Luka>

=head1 AUTHOR

Toni Prug <toni@irational.org>

=head1 COPYRIGHT

Copyright (c) 2006. Toni Prug. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

See L<http://www.gnu.org/licenses/gpl.html>

=cut
